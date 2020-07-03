import json
import os
from os import path
import subprocess
import requests
import xmltodict

from mycroft.messagebus.message import Message
from mycroft.skills.core import MycroftSkill
from mycroft.util import get_ipc_directory
from mycroft.util.log import LOG
from mycroft.util.parse import normalize
from mycroft import intent_file_handler 

from msm import (
    AlreadyInstalled,
    AlreadyRemoved,
    CloneException,
    GitException,
    MsmException,
    MultipleSkillMatches,
    PipRequirementsException,
    SkillEntry,
    SkillNotFound,
    SkillRequirementsException,
    SystemRequirementsException
)

from mycroft.skills.msm_wrapper import build_msm_config, create_msm

class SkillInstallerMobile(MycroftSkill):
    _msm = None
    
    def __init__(self):
        super().__init__('SkillInstallerMobile')
        self.skillInformation = {}
        
    @property
    def msm(self):
        if self._msm is None:
            msm_config = build_msm_config(self.config_core)
            self._msm = create_msm(msm_config)

        return self._msm

    def initialize(self):
        self.bus.on('skillinstallermobile.aiix.home', self.show_home_screen)
        self.add_event('skillinstallermobile.aiix.home', self.show_home_screen)
        self.gui.register_handler('skillinstallermobile.aiix.home', self.show_home_screen)
        self.gui.register_handler('skillinstallermobile.aiix.install', self.install_from_giturl)
        self.gui.register_handler('skillinstallermobile.aiix.remove', self.uninstall_from_giturl)
                        
    def show_home_screen(self):
        LOG.info("in Show Homescreen")
        self.gui.show_page("loading.qml")
        self.build_home_screen()
    
    def build_home_screen(self):
        LOG.info("in Build Homescreen")
        skillModel = self.build_skill_list()
        self.gui.clear()
        self.enclosure.display_manager.remove_active()
        self.gui['process'] = False
        self.gui['processMessage'] = ""
        self.gui['skillModel'] = skillModel
        self.gui.show_page("home.qml")
        
    def update_home_screen(self):
        self.gui['processMessage'] = "Updating List"
        skillModel = self.build_skill_list()
        self.gui['skillModel'] = skillModel
        self.gui.show_page("home.qml")
        self.gui['process'] = False

        
    def build_skill_list(self): 
        skillModel = {}
        skillListModel = []
        pling_categories_url = "https://api.kde-look.org/ocs/v1/content/data?categories=608&pagesize=100"
        getSkillCategories = requests.get(pling_categories_url)
        parseCategories = xmltodict.parse(getSkillCategories.text)
        skillInformation = parseCategories['ocs']['data']['content']
        for contents in skillInformation:
            skillJsonUrl = contents['downloadlink1']
            getSkillJson = requests.get(skillJsonUrl)
            getSkillInfo = getSkillJson.json()
            isSkillInstalled = self.checkInstalled(getSkillInfo['url'])
            skillBlock = {"skillName": getSkillInfo['name'], "skillUrl": getSkillInfo['url'], "skillBranch": getSkillInfo['branch'], "skillImage": contents['previewpic1'], "category": contents['typename'], "skillDescription": contents["description"], "skillID": contents["id"], "skillInstalled": isSkillInstalled}
            skillListModel.append(skillBlock)
        
        skillModel["contents"] = skillListModel
        return skillModel
    
    def install_from_giturl(self, message):
        gitLink = message.data["downloadLink"]
        gitBranch = message.data["branch"]
        if gitLink:
            LOG.info("installing skill" + gitLink)
            repo_name = SkillEntry.extract_repo_name(gitLink)
            try:
                self.gui['process'] = True
                self.gui['processMessage'] = "Installing Skill"
                self.msm.install(gitLink)
                self.update_home_screen()
            except MsmException as e:
                self.gui['process'] = False
                self.gui['processMessage'] = ""
                LOG.info('MSM failed: ' + repr(e))
        
        if gitBranch:
            repo_name = SkillEntry.extract_repo_name(gitLink)
            repo_author = SkillEntry.extract_author(gitLink)
            skill_path = "/opt/mycroft/skills/" + repo_name + "." + repo_author.lower()
            process = subprocess.Popen(["git", "checkout", gitBranch], stdout=subprocess.PIPE, cwd=skill_path)
            output = process.communicate()[0]
            LOG.info(output)
    
    def uninstall_from_giturl(self, message):
        gitLink = message.data["downloadLink"]
        if gitLink:
            repo_name = SkillEntry.extract_repo_name(gitLink)
            try:
                self.gui['process'] = True
                self.gui['processMessage'] = "Removing Skill"
                self.msm.remove(gitLink)
                self.update_home_screen()
            except MsmException as e:
                self.gui['process'] = False
                self.gui['processMessage'] = ""
                LOG.info('MSM failed: ' + repr(e))
    
    def checkInstalled(self, url):
        repo_name = SkillEntry.extract_repo_name(url)
        repo_author = SkillEntry.extract_author(url)
        skill_path = "/opt/mycroft/skills/" + repo_name + "." + repo_author.lower()
        LOG.info(skill_path)
        if path.exists(skill_path):
            LOG.info("Found Skill Installed")
            return True
        else:
            LOG.info("Skill Not Installed")
            return False
    
def create_skill():
    return SkillInstallerMobile()

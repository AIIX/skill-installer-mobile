import json
import os
from os import path
import subprocess
import requests
import xmltodict
import threading

from mycroft.skills.core import MycroftSkill
from mycroft.util.log import LOG

from msm import (
    MsmException,
    SkillEntry
)

from mycroft.skills.msm_wrapper import build_msm_config, create_msm


class SkillInstallerMobile(MycroftSkill):
    _msm = None
    
    def __init__(self):
        super().__init__('SkillInstallerMobile')
        self.apps_white_list = ['youtube-skill.aiix', 'soundcloud-audio-player.aiix', 'skill-wikidata.aiix',
                                'bitchute-skill.aiix', 'skystream.aiix', 'twitch-streams.aiix', 'food-wizard.aiix']
        self.apps_white_list_id = ["1336153", "1346946", "1362744", "1389861", "1392895", "1444313", "1336547", "1399481"]
        self.skillInformation = {}
        self.skillInstalledListModel = []
        self.skillAvailableListModel = []
        self.skillInformation = {}
        self.skilllistmodel = []
        self.threads = []
        
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
        self.gui.show_page("loading.qml", override_idle=True)
        self.build_home_screen()
    
    def build_home_screen(self):
        LOG.info("in Build Homescreen")
        skill_model = self.build_skill_list()
        self.gui.clear()
        self.enclosure.display_manager.remove_active()
        LOG.info(skill_model)
        self.gui['process'] = False
        self.gui['processMessage'] = ""
        self.gui["skillInstalledModel"] = skill_model[0]
        self.gui["skillAvailableModel"] = skill_model[1]
        self.gui.show_page("home.qml", override_idle=True)
        
    def update_home_screen(self):
        self.gui['processMessage'] = "Updating List"
        skill_model = self.build_skill_list()
        self.gui["skillInstalledModel"] = skill_model[0]
        self.gui["skillAvailableModel"] = skill_model[1]
        self.gui.show_page("home.qml", override_idle=True)
        self.gui['process'] = False

    def build_skill_list(self):
        skillInstalledModel = {}
        skillAvailableModel = {}
        self.skillInstalledListModel.clear()
        self.skillAvailableListModel.clear()
        pling_categories_url = "https://api.kde-look.org/ocs/v1/content/data?categories=608&pagesize=100"
        getskillcategories = requests.get(pling_categories_url)
        parsecategories = xmltodict.parse(getskillcategories.text)
        skillinformation = parsecategories['ocs']['data']['content']
        for contents in skillinformation:
            if contents["id"] not in self.apps_white_list_id:
                LOG.info("blacklisted skill")
            else:
                skilljsonurl = contents['downloadlink1']
                t = threading.Thread(target=self.build_pling_list, args=(skilljsonurl, contents,))
                self.threads.append(t)
                t.start()

        for t in self.threads:
            t.join()
            
        skillInstalledModel["contents"] = self.skillInstalledListModel
        skillAvailableModel["contents"] = self.skillAvailableListModel
        skillModel = [skillInstalledModel, skillAvailableModel]
        return skillModel

    def build_pling_list(self, url, contents):
        getskilljson = requests.get(url)
        getskillinfo = getskilljson.json()
        skillfoldername = str(getskillinfo['skillname']).lower()
        skillfolderauthor = str(getskillinfo['authorname']).lower()
        skill_white_list_names = skillfoldername + "." + skillfolderauthor
        isskillinstalled = self.check_installed(skill_white_list_names)
        if skill_white_list_names in self.apps_white_list:
            skillblock = {"skillname": getskillinfo['name'], "skillurl": getskillinfo['url'],
                          "skillbranch": getskillinfo['branch'], "skillimage": contents['previewpic1'],
                          "category": contents['typename'], "skilldescription": contents["description"],
                          "skillid": contents["id"], "skillexamples": getskillinfo["examples"],
                          "skillinstalled": isskillinstalled}
            
            if isskillinstalled:
                if not any(d['skillid'] == contents["id"] for d in self.skillInstalledListModel):
                    self.skillInstalledListModel.append(skillblock)
            else:
                if not any(d['skillid'] == contents["id"] for d in self.skillAvailableListModel):
                    self.skillAvailableListModel.append(skillblock)

    def install_from_giturl(self, message):
        git_link = message.data["skillurl"]
        git_branch = message.data["skillbranch"]
        if git_link:
            LOG.info("installing skill" + git_link)
            repo_name = SkillEntry.extract_repo_name(git_link)
            try:
                self.gui['process'] = True
                self.gui['processmessage'] = "installing skill"
                self.msm.install(git_link)
                self.update_home_screen()
                hashomepage = self.check_skill_for_home(git_link)
                if hashomepage:
                    self.check_android_entry_exist_with_home(git_link, message)
                else:
                    self.check_android_entry_exist_without_home(git_link, message)

            except MsmException as e:
                self.gui['process'] = False
                self.gui['processmessage'] = ""
                LOG.info('msm failed: ' + repr(e))

        if git_branch:
            repo_name = SkillEntry.extract_repo_name(git_link)
            repo_author = SkillEntry.extract_author(git_link)
            skill_path = "/opt/mycroft/skills/" + repo_name + "." + repo_author.lower()
            process = subprocess.Popen(["git", "checkout", git_branch], stdout=subprocess.PIPE, cwd=skill_path)
            output = process.communicate()[0]
            LOG.info(output)
    
    def uninstall_from_giturl(self, message):
        git_link = message.data["skillurl"]
        if git_link:
            repo_name = SkillEntry.extract_repo_name(git_link)
            try:
                self.gui['process'] = True
                self.gui['processMessage'] = "removing skill"
                self.msm.remove(git_link)
                self.update_home_screen()
            except MsmException as e:
                self.gui['process'] = False
                self.gui['processMessage'] = ""
                LOG.info('MSM failed: ' + repr(e))
    
    def check_installed(self, skillfolder):
        skill_path = "/opt/mycroft/skills/" + skillfolder.lower()
        LOG.info(skill_path)
        if path.exists(skill_path):
            LOG.info("Found Skill Installed")
            return True
        else:
            LOG.info("Skill Not Installed")
            return False

    def check_android_entry_exist_with_home(self, url, message):
        repo_name = SkillEntry.extract_repo_name(url)
        repo_author = SkillEntry.extract_author(url)
        android_json = "android.json"
        android_path = "/opt/mycroft/skills/" + repo_name + "." + repo_author.lower() + "/" + android_json
        if not path.exists(android_path) and not path.isfile(android_path):
            LOG.info("Android File Does Not Exist Creating Android With Home")
            self.build_android_json_with_home(message.data["skillImage"], message.data["skillName"],
                                              repo_name, repo_author)

    def check_android_entry_exist_without_home(self, url, message):
        repo_name = SkillEntry.extract_repo_name(url)
        repo_author = SkillEntry.extract_author(url)
        android_json = "android.json"
        android_path = "/opt/mycroft/skills/" + repo_name + "." + repo_author.lower() + "/" + android_json
        if not path.exists(android_path) and not path.isfile(android_path):
            LOG.info("Android File Not Exist")
            # self.build_android_json(repo_name, repo_author)

    def build_android_json_with_home(self, icon_path, skill_name, repository_name, repository_author):

        # first check if icon exist
        res_icon_path = "/opt/mycroft/skills/" + repository_name + "." + repository_author.lower() + \
                               "/res/icon/"
        icon_listing = os.listdir(res_icon_path)

        if icon_listing:
            final_res_icon_path = "/res/icon/" + icon_listing[0]

        # run extraction if empty
        else:
            extract_icon = icon_path
            icon_code = icon_path.rsplit('/', 1)[-1]
            icon_ending = icon_code.split(".")
            res_icon_create_path = "/opt/mycroft/skills/" + repository_name + "." + repository_author.lower() + \
                                   "/res/icon/" + skill_name + "." + icon_ending[1]
            f = open(res_icon_create_path, 'wb')
            f.write(requests.get(extract_icon).content)
            f.close()
            final_res_icon_path = "/res/icon/" + skill_name + "." + icon_ending[1]

        fix_skill_name = skill_name.lower().replace('skill', '')
        final_res_name = fix_skill_name.capitalize().rstrip()
        final_res_handler = "{0}.{1}.home".format(repository_name.lower(), repository_author.lower())
        android_data = {"android_icon": final_res_icon_path, "android_name": final_res_name,
                        "android_handler": final_res_handler}
        
        android_json = "android.json"
        android_path = "/opt/mycroft/skills/" + repository_name + "." + repository_author.lower() + "/" + android_json
        with open(android_path, 'w') as outfile:
            json.dump(android_data, outfile)

    def check_skill_for_home(self, url):
        repo_name = SkillEntry.extract_repo_name(url)
        repo_author = SkillEntry.extract_author(url)
        check_file = "/opt/mycroft/skills/" + repo_name + "." + repo_author.lower() + "/__init__.py"
        LOG.info(check_file)
        home_string = [".home"]
        with open(check_file) as f:
            results = {word: [] for word in home_string}
            for num, line in enumerate(f, start=1):
                for word in home_string:
                    if word in line:
                        LOG.info("Home Entry Found")
                        return True


def create_skill():
    return SkillInstallerMobile()

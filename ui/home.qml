/*
 *  Copyright 2020 by Aditya Mehra <aix.m@outlook.com>
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.

 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.

 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.9
import QtQuick.Layouts 1.4
import QtGraphicalEffects 1.0
import QtQuick.Controls 2.3
import org.kde.kirigami 2.8 as Kirigami
import Mycroft 1.0 as Mycroft 

Mycroft.Delegate {
    id: delegateSkillInstaller
    
    fillWidth: true
    
    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0
    
    property var skillsInstalledModel: sessionData.skillInstalledModel
    property var skillsAvailableModel: sessionData.skillAvailableModel
    property bool busyIndicate: sessionData.process
    property var processMessage: sessionData.processMessage
    
    onSkillsInstalledModelChanged: {
        skillInstalledModelView.forceLayout();
    }
    
    onSkillsAvailableModelChanged: {
        skillAvailableModelView.forceLayout();
    }
    
    onBusyIndicateChanged: {
        if(busyIndicate) {
            busyIndicatorPop.open()
        } else {
            busyIndicatorPop.close()
        }
    }
 
    onProcessMessageChanged: {
        status.text = processMessage
    }
 
    Rectangle {
        id: headerBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: Kirigami.Units.gridUnit * 2
        color: "#303030"
        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            horizontalOffset: 0
            verticalOffset: 2
        }
        
        RowLayout {
            width: parent.width
            height: parent.height
            anchors.verticalCenter: parent.verticalCenter
            
            ToolButton {
                Kirigami.Theme.colorSet: Kirigami.Theme.Button
                Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                flat: true
                
                contentItem: Image {
                    anchors.centerIn: parent
                    width: Kirigami.Units.iconSizes.smallMedium
                    height: Kirigami.Units.iconSizes.smallMedium
                    source: "back.png"
                }
                
                onClicked: {
                    delegateSkillInstaller.parent.backRequested()
                }
            }
            
            Kirigami.Heading {
                id: headingLabel
                level: 2
                text: "Mycroft Skill Installer"
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
    
    ColumnLayout {
        anchors.top: headerBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        PaneItem {
            id: p1
            Layout.preferredHeight: Kirigami.Units.gridUnit * 2
            Layout.alignment: Qt.AlignTop
            title: "Installed Skills " + "(" + skillInstalledModelView.count + ")"
            
            onCurrentChanged: {
                if(!current){
                    p2.current = true
                }
            }
            
            Kirigami.CardsListView {
                id: skillInstalledModelView
                anchors.fill: parent
                clip: true
                model: skillsInstalledModel.contents
                spacing: Kirigami.Units.smallSpacing
                delegate: SkillDelegateInstalled{}
            }
        }
        
        PaneItem {
            id: p2
            Layout.preferredHeight: Kirigami.Units.gridUnit * 2
            Layout.alignment: Qt.AlignTop
            title: "Available Skills " + "(" + skillAvailableModelView.count + ")"
            current: true
            
            onCurrentChanged: {
                if(!current){
                    p1.current = true
                }
            }
            
            Kirigami.CardsListView {
                id: skillAvailableModelView
                anchors.fill: parent
                clip: true
                model: skillsAvailableModel.contents
                spacing: Kirigami.Units.smallSpacing
                delegate: SkillDelegateAvailable{}
            }
        }
    }
    
     Popup {
        id: busyIndicatorPop
        width: parent.width
        height: parent.height
        background: Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.5)
        }
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
        
        Kirigami.Heading {
            id: status
            level: 1
            anchors.bottom: bIndi.top
            anchors.bottomMargin: Kirigami.Units.largeSpacing
            anchors.horizontalCenter: parent.horizontalCenter
            color: Kirigami.Theme.textColor
        }
        
        BusyIndicator {
            id: bIndi
            running: busyIndicatorPop.opened ? 1 : 0
            anchors.centerIn: parent
        }
    }
}

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
    id: root
    
    fillWidth: true
    
    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0
    
    skillBackgroundSource: Qt.resolvedUrl("images/background.jpg")
    property var skillsModel: sessionData.skillModel
    property bool busyIndicate: sessionData.process
    property var processMessage: sessionData.processMessage
    
    onSkillsModelChanged: {
        skillModelView.forceLayout();
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
        anchors.leftMargin: -1
        anchors.rightMargin: -1
        anchors.topMargin: -1
        height: Kirigami.Units.gridUnit * 3
        color: Kirigami.Theme.backgroundColor
        
        Button {
            id: btnBack
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Kirigami.Units.largeSpacing
            width: Kirigami.Units.iconSizes.large
            height: width
            Kirigami.Theme.colorSet: Kirigami.Theme.Button
            
            contentItem: Item {
                Image {
                    anchors.centerIn: parent
                    width: Kirigami.Units.iconSizes.medium
                    height: Kirigami.Units.iconSizes.medium
                    source: Qt.resolvedUrl("images/back.png")
                }
            }
            
            onClicked: {
                Mycroft.MycroftController.sendRequest("mycroft.gui.screen.close", {})
            }
        }
        
        Kirigami.Heading {
            anchors.centerIn: parent
            level: 2
            text: "Mycroft Skill Installer"
        }
    }
    
    Kirigami.Separator {
        id: headerSept
        anchors.top: headerBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Kirigami.Theme.linkColor
    }
    
    Kirigami.CardsListView {
        id: skillModelView
        anchors.top: headerSept.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        clip: true
        model: skillsModel.contents
        delegate: SkillDelegate{}
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

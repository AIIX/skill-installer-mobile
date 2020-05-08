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

Kirigami.AbstractCard {
    contentItem: Item {
        implicitWidth: parent.width
        implicitHeight: skillImage.height
        
        Image {
            id: skillImage
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            height: Kirigami.Units.gridUnit * 3.5
            width: Kirigami.Units.gridUnit * 3.5
            source: modelData.skillImage
        }
        
        Label {
            id: skillNameLabel
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: skillImage.right
            anchors.leftMargin: Kirigami.Units.largeSpacing
            anchors.right: btnRect.left
            anchors.margins: 12
            text: modelData.skillName
            font.pointSize: 10
            color: Kirigami.Theme.textColor
        }
        
        Button {
            id: btnRect
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: Kirigami.Units.gridUnit * 3
            height: width
            Kirigami.Theme.colorSet: Kirigami.Theme.Button
            
            contentItem: Item {
                Image {
                    anchors.centerIn: parent
                    width: Kirigami.Units.iconSizes.large
                    height: Kirigami.Units.iconSizes.large
                    source: modelData.skillInstalled ? "images/remove.png" : "images/down.png"
                }
            }
            
            onClicked: {
                if(!modelData.skillInstalled) {
                    triggerGuiEvent("skillinstallermobile.aiix.install", {"downloadLink": modelData.skillUrl, "branch": modelData.skillBranch})
                } else {
                    triggerGuiEvent("skillinstallermobile.aiix.remove", {"downloadLink": modelData.skillUrl, "branch": modelData.skillBranch})
                }
            }
        }
    }
}

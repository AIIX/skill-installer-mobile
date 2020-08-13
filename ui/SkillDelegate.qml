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
    
    background: Rectangle {
        color: Kirigami.Theme.backgroundColor
        radius: 3
        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            horizontalOffset: 0
            verticalOffset: 2
        }
    }
    
    contentItem: Item {
        implicitWidth: parent.width
        implicitHeight: skillImage.height
        
        Image {
            id: skillImage
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            height: Kirigami.Units.gridUnit * 3.5
            width: Kirigami.Units.gridUnit * 3.5
            source: modelData.skillimage
        }
        
        ColumnLayout {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: skillImage.right
            anchors.leftMargin: Kirigami.Units.largeSpacing
            anchors.right: btnRect.left
            anchors.margins: 12
            
            Kirigami.Heading {
                id: skillNameLabel
                text: modelData.skillname
                wrapMode: Text.WordWrap
                Layout.maximumWidth: parent.width
                maximumLineCount: 2
                level: 3
                color: Kirigami.Theme.textColor
            }
            
            Label {
                id: skillDescriptionLabel
                text: "Try saying: " + modelData.skillexamples[0]
                wrapMode: Text.WordWrap
                Layout.maximumWidth: parent.width
                maximumLineCount: 2
                color: Kirigami.Theme.textColor
            }
        }
        
        Button {
            id: btnRect
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: Kirigami.Units.gridUnit * 3
            height: width
            flat: true
            Kirigami.Theme.colorSet: Kirigami.Theme.Button
            
            background: Rectangle {
                color: "transparent"
            }
            
            contentItem: Item {
                Image {
                    anchors.centerIn: parent
                    width: Kirigami.Units.iconSizes.smallMedium
                    height: Kirigami.Units.iconSizes.smallMedium
                    source: modelData.skillinstalled ? "images/remove.png" : "images/down.png"
                }
            }
            
            onClicked: {
                if(!modelData.skillInstalled) {
                    triggerGuiEvent("skillinstallermobile.aiix.install", modelData)
                } else {
                    triggerGuiEvent("skillinstallermobile.aiix.remove", modelData)
                }
            }
        }
    }
}

import QtQuick 2.9
import QtQuick.Layouts 1.4
import org.kde.kirigami 2.8 as Kirigami

Item {
    default property var contentItem: null
    property string title: "panel"
    id: root
    Layout.fillWidth: true
    height: 30
    Layout.fillHeight: current
    property bool current: false
    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        Rectangle {
            id: bar
            Layout.fillWidth: true
            height: Kirigami.Units.gridUnit * 2            
            color:  root.current ? "#303030" : "#202020"
            Text {
                anchors.fill: parent
                anchors.margins: Kirigami.Units.largeSpacing
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                color: "white"
                text: root.title
            }
            Text {
                anchors{
                    right: parent.right
                    top: parent.top
                    bottom: parent.bottom
                    margins: Kirigami.Units.largeSpacing
                }
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
                color: "white"
                text: "^"
                rotation: root.current ? "180" : 0
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.current = !root.current;
                    if(root.parent.currentItem !== null) {
                        if(root.parent.currentItem !== root)
                            root.parent.currentItem.current = false;
                    }

                    root.parent.currentItem = root;
                }
            }
        }
        
        Rectangle {
            id: container
            Layout.fillWidth: true
            implicitHeight: root.height - bar.height
            clip: true
            color: "transparent"
            Behavior on implicitHeight {
                PropertyAnimation { duration: 100 }
            }
        }
        Component.onCompleted: {
            if(root.contentItem !== null)
                root.contentItem.parent = container;
        }
    }
} 

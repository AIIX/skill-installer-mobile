import QtQuick 2.4
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.3
import org.kde.kirigami 2.4 as Kirigami
import Mycroft 1.0 as Mycroft

Mycroft.Delegate {
    id: logoLoadingPage
    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0

    Control {
        id: statusArea
        anchors.fill: parent
        
        background: Image {
            source: Qt.resolvedUrl("images/background.png")
        }
        
        contentItem: Item {
            AnimatedImage {
                id: busyIndicatorComponent
                anchors.bottom: parent.bottom
                anchors.bottomMargin: statusArea.height / 6
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.horizontalCenterOffset: -Kirigami.Units.gridUnit * 6
                width: Kirigami.Units.iconSizes.smallMedium
                height: Kirigami.Units.iconSizes.smallMedium
                playing: true
                source: "images/spinner.gif"
            }
            
            Kirigami.Heading {
                id: loadingStatusArea
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: busyIndicatorComponent.verticalCenter
                level: 2
                text: "Loading..."
            }
        }
    }
}
 

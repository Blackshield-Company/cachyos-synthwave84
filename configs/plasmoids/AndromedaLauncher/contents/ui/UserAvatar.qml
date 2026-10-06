import QtQuick 2.12
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.components 1.0 as KirigamiComponents
import org.kde.kcmutils as KCM

Item {

    readonly property color borderGradientColor1: plasmoid.configuration.glowColor == 0 ? "#FE4450" :
                                                plasmoid.configuration.glowColor == 1 ? "#FEDE5D" :
                                                "#FE4450"
    readonly property color borderGradientColor2: plasmoid.configuration.glowColor == 0 ? "#FF7EDB" :
                                                plasmoid.configuration.glowColor == 1 ? "#F3E70F" :
                                                "#FF00FF"
    readonly property color borderGradientColor3: plasmoid.configuration.glowColor == 0 ? "#ff00ff" :
                                                plasmoid.configuration.glowColor == 1 ? "#8A6A15" :
                                                "#FF7EDB"

    KirigamiComponents.AvatarButton {
        id: mainFaceIcon
        source: kuser.faceIconUrl
        anchors {
            fill: parent
            margins: Kirigami.Units.smallSpacing
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: false
            onClicked: {
            KCM.KCMLauncher.openSystemSettings("kcm_users")
            root.toggle()
            }
        }
    }

    Rectangle {
        visible: plasmoid.configuration.enableGlow
        anchors.centerIn: mainFaceIcon
        width: parent.width - 4 // Subtract to prevent fringing
        height: width
        radius: width / 2
        
        gradient: Gradient {
            GradientStop { position: 0.0; color: borderGradientColor1 }
            GradientStop { position: 0.33; color: borderGradientColor2 }
            GradientStop { position: 1.0; color: borderGradientColor3 }
        }

        z:-1
        rotation: 270
        transformOrigin: Item.Center
    }
}
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.theme
import qs.config
import qs.services
import qs.components

Surface {
    id: root

    pane: true

    required property var notification
    property bool popup: false

    readonly property bool critical: Notifs.isCritical(notification)
    readonly property var actions: (notification?.actions ?? []).filter(a => a.identifier !== "default")
    readonly property string image: Notifs.picture(notification?.image ?? "")

    implicitHeight: content.implicitHeight + 28
    radius: 18
    color: Tokens.black
    border.width: 1
    property color borderTint: hover.hovered ? Tokens.muted : Tokens.line
    border.color: borderTint

    Behavior on borderTint { ColorAnimation { duration: Tokens.animFast } }

    HoverHandler {
        id: hover
        onHoveredChanged: if (root.popup) Notifs.hold(root.notification, hovered)
    }

    Component.onDestruction: if (root.popup && hover.hovered) Notifs.hold(root.notification, false)

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (Notifs.niloKind(root.notification) !== "") {
                Nilo.open();
                return;
            }
            const action = (root.notification?.actions ?? []).find(a => a.identifier === "default");
            if (action) action.invoke();
            if (root.popup) Notifs.hidePopup(root.notification);
        }
    }

    ColumnLayout {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 14
        anchors.leftMargin: 16
        anchors.rightMargin: 14
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                visible: root.critical
                implicitWidth: 6
                implicitHeight: 6
                radius: 3
                color: Tokens.interrupt
            }

            AppIcon {
                size: 16
                icon: root.notification?.appIcon ?? ""
                visible: (root.notification?.appIcon ?? "") !== ""
            }

            Label {
                Layout.fillWidth: true
                text: root.notification?.appName || Lang.notice
            }

            Ico {
                glyph: Icons.close
                font.pixelSize: 14
                color: closeArea.containsMouse ? Tokens.ink : Tokens.muted

                MouseArea {
                    id: closeArea
                    anchors.fill: parent
                    anchors.margins: -6
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    Accessible.role: Accessible.Button
                    Accessible.name: Lang.dismiss
                    Accessible.onPressAction: root.notification.dismiss()
                    onClicked: root.notification.dismiss()
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                Txt {
                    Layout.fillWidth: true
                    text: root.notification?.summary ?? ""
                    font.pixelSize: 15
                    font.weight: Font.Medium
                }

                Txt {
                    Layout.fillWidth: true
                    text: Notifs.markup(root.notification?.body ?? "")
                    visible: text !== ""
                    color: Tokens.dim
                    font.pixelSize: 13
                    wrapMode: Text.Wrap
                    maximumLineCount: root.popup ? 4 : 2
                    textFormat: Text.StyledText
                }
            }

            Image {
                id: picture
                visible: root.image !== "" && status !== Image.Error
                Layout.preferredWidth: 48
                Layout.preferredHeight: 48
                source: root.image
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }

        Flow {
            Layout.fillWidth: true
            Layout.topMargin: 4
            visible: root.actions.length > 0
            spacing: 6

            Repeater {
                model: root.actions

                KeyButton {
                    required property var modelData

                    text: modelData.text
                    onClicked: modelData.invoke()
                }
            }
        }
    }
}

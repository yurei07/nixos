import QtQuick
import qs.theme
import qs.config
import qs.services
import qs.components

Item {
    id: root

    readonly property var pages: [
        { name: "you", title: Lang.cfgYou, file: "PageYou.qml" },
        { name: "region", title: Lang.cfgRegion, file: "PageRegion.qml" },
        { name: "look", title: Lang.cfgLook, file: "PageLook.qml" },
        { name: "apps", title: Lang.cfgApps, file: "PageApps.qml" },
        { name: "screens", title: Lang.cfgScreens, file: "PageScreens.qml" },
        { name: "keys", title: Lang.cfgKeys, file: "PageKeys.qml" },
        { name: "system", title: Lang.cfgSystem, file: "PageSystem.qml" },
        { name: "generations", title: Lang.cfgGenerations, file: "PageGenerations.qml" },
        { name: "devices", title: Lang.cfgDevices, file: "PageDevices.qml" }
    ]
    readonly property var current: pages.find(page => page.name === Machine.page) ?? pages[0]

    // Up and down go through the pages, from the list or from nowhere in particular; a control
    // with the focus keeps its arrows.
    function turn(by: int): void {
        const at = pages.indexOf(current);
        Machine.page = pages[Math.max(0, Math.min(pages.length - 1, at + by))].name;
    }

    focus: true
    Keys.onUpPressed: event => {
        if (root.activeFocus || side.activeFocus)
            root.turn(-1);
        else
            event.accepted = false;
    }
    Keys.onDownPressed: event => {
        if (root.activeFocus || side.activeFocus)
            root.turn(1);
        else
            event.accepted = false;
    }

    Column {
        id: side
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 28
        width: 196
        spacing: 4
        activeFocusOnTab: true

        Accessible.role: Accessible.PageTabList
        Accessible.name: Lang.cfgTitle

        Logo {
            size: 30
        }

        Label {
            text: Lang.cfgTitle
            bottomPadding: 22
        }

        Repeater {
            model: root.pages

            Surface {
                id: item

                required property var modelData
                readonly property bool chosen: root.current.name === modelData.name

                x: -14
                width: side.width + 14
                height: 36
                radius: 10
                color: item.chosen ? Tokens.raised : navArea.containsMouse ? Tokens.surface : "transparent"

                Accessible.role: Accessible.PageTab
                Accessible.name: item.modelData.title
                Accessible.selectable: true
                Accessible.selected: item.chosen
                Accessible.onPressAction: Machine.page = item.modelData.name

                Behavior on color { ColorAnimation { duration: Tokens.animFast } }

                FocusRing {
                    shown: side.activeFocus && item.chosen
                    round: item.radius
                }

                Txt {
                    anchors.verticalCenter: parent.verticalCenter
                    x: 14
                    text: item.modelData.title
                    color: item.chosen || navArea.containsMouse ? Tokens.ink : Tokens.dim

                    Behavior on color { ColorAnimation { duration: Tokens.animFast } }
                }

                MouseArea {
                    id: navArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Machine.page = item.modelData.name
                }
            }
        }
    }

    CircleButton {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 20
        size: 32
        glyph: Icons.close
        label: Lang.welClose
        onClicked: Machine.hide()
    }

    Loader {
        anchors.left: side.right
        anchors.leftMargin: 36
        anchors.right: parent.right
        anchors.rightMargin: 64
        anchors.top: parent.top
        anchors.topMargin: 30
        anchors.bottom: bar.top
        anchors.bottomMargin: 14
        source: Qt.resolvedUrl(root.current.file)
    }

    ApplyBar {
        id: bar
        anchors.left: side.right
        anchors.leftMargin: 36
        anchors.right: parent.right
        anchors.rightMargin: 28
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 18
    }
}

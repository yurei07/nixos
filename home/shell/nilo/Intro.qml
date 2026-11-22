import QtQuick
import qs.theme
import qs.config
import qs.services
import qs.components

Item {
    id: root

    property int page: 0
    readonly property int pages: 5
    readonly property real column: Math.min(580, width - 64)

    readonly property bool asking: page === 3 && access.asking !== ""

    signal finished()

    // A bind's keys as caps, from what the machine sets it to: «SUPER + I» is Super and I.
    function caps(combo: var): var {
        return String(combo ?? "").split("+").map(part => part.trim()).filter(part => part !== "")
            .map(part => /^space$/i.test(part) ? Lang.keySpace : Case.key(part));
    }

    function back(): bool {
        if (!asking) return false;
        access.asking = "";
        return true;
    }

    function next(): void {
        if (asking) return access.authorize();
        if (page === 2) {
            if (models.current >= 0) models.choose(models.current);
            if (!Nilo.installed && Nilo.current && !(Nilo.pull && Nilo.pull.status !== "error"))
                Nilo.download(Nilo.current.tag);
        }
        if (page < pages - 1) {
            page++;
            models.current = -1;
            access.current = -1;
        } else {
            Nilo.set("onboarded", true);
            finished();
        }
    }

    function move(step: int): bool {
        if (page === 2) { models.moveBy(step); return true; }
        if (page === 3) {
            access.moveBy(step);
            const row = access.rowAt(access.current);
            if (row) reveal(row);
            return true;
        }
        return false;
    }

    function reveal(row: Item): void {
        const y = row.mapToItem(access, 0, 0).y;
        if (y < accessFlick.contentY)
            accessFlick.contentY = Math.max(0, y);
        else if (y + row.height > accessFlick.contentY + accessFlick.height)
            accessFlick.contentY = Math.max(0, Math.min(accessFlick.contentHeight - accessFlick.height, y + row.height - accessFlick.height));
    }

    function toggle(): bool {
        if (page === 2 && models.current >= 0) { models.choose(models.current); return true; }
        if (page === 3 && access.current >= 0) { access.toggle(access.current); return true; }
        return false;
    }

    component Page: Item {
        property bool here: false

        anchors.fill: parent
        opacity: here ? 1 : 0
        visible: opacity > 0
        transform: Translate { y: here ? 0 : 12; Behavior on y { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } } }

        Behavior on opacity { NumberAnimation { duration: 220 } }
    }

    component Way: Row {
        id: way
        property alias keys: caps.model
        property string text: ""
        spacing: 18

        Item {
            width: 170
            height: 30

            Row {
                anchors.right: parent.right
                spacing: 6

                Repeater {
                    id: caps
                    Keycap { required property string modelData; text: modelData }
                }
            }
        }

        Txt {
            anchors.verticalCenter: parent.verticalCenter
            text: way.text
            color: Tokens.dim
        }
    }

    Item {
        id: stage
        anchors.top: parent.top
        anchors.bottom: footer.top
        anchors.left: parent.left
        anchors.right: parent.right

        Page {
            here: root.page === 0

            Column {
                anchors.centerIn: parent
                width: root.column
                spacing: 16

                DotText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Lang.introHello
                    font.pixelSize: 34
                }

                Txt {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    elide: Text.ElideNone
                    text: Lang.introLocal
                    color: Tokens.dim
                    font.pixelSize: 15
                    lineHeight: 1.3
                }
            }
        }

        Page {
            here: root.page === 1

            Column {
                anchors.centerIn: parent
                width: root.column
                spacing: 18

                Txt {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Lang.introCall
                    font.pixelSize: 20
                }

                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 12

                    Way { keys: root.caps(Config.binds.nilo); text: Lang.introBind; visible: keys.length > 0 }
                    Way { keys: ["Copilot"]; text: Lang.introCopilot }
                    Way { keys: root.caps(Config.binds.launcher).concat(["?"]); text: Lang.introLauncher; visible: keys.length > 1 }
                }

                Txt {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    elide: Text.ElideNone
                    text: Case.count(Nilo.settings.keepAlive ?? 5, Lang.introSleepOne, Lang.introSleep)
                    color: Tokens.muted
                    font.pixelSize: 13
                    lineHeight: 1.3
                }
            }
        }

        Page {
            here: root.page === 2

            Column {
                anchors.centerIn: parent
                width: root.column
                spacing: 6

                Txt {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Lang.introModel
                    font.pixelSize: 20
                }

                Item { width: 1; height: 8 }

                ModelList {
                    id: models
                    width: parent.width
                }

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: Nilo.pull !== null && Nilo.pull.status !== "error"
                    text: Lang.introKeepsDownloading
                    topPadding: 6
                }
            }
        }

        Page {
            here: root.page === 3

            Column {
                id: accessPage
                anchors.horizontalCenter: parent.horizontalCenter
                y: Math.max(0, (parent.height - height) / 2)
                width: root.column
                spacing: 14

                Column {
                    id: accessHead
                    width: parent.width
                    spacing: 6

                    Txt {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Lang.introAccess
                        font.pixelSize: 20
                    }
                }

                Flickable {
                    id: accessFlick
                    width: parent.width
                    height: Math.max(0, Math.min(access.implicitHeight, stage.height - accessHead.height - accessPage.spacing))
                    contentHeight: access.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    AccessList {
                        id: access
                        width: accessFlick.width
                        onGrew: row => root.reveal(row)
                    }
                }
            }
        }

        Page {
            here: root.page === 4

            Column {
                anchors.centerIn: parent
                width: root.column
                spacing: 14

                DotText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Lang.introDone
                    font.pixelSize: 34
                }
            }
        }
    }

    Item {
        id: footer
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.column
        height: 40

        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Repeater {
                model: root.pages

                Rectangle {
                    required property int index
                    width: index === root.page ? 18 : 6
                    height: 6
                    radius: 3
                    color: index === root.page ? Tokens.ink : index < root.page ? Tokens.dim : Tokens.off

                    Behavior on width { NumberAnimation { duration: Tokens.animNormal; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: Tokens.animNormal } }

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        enabled: index < root.page
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.page = index
                    }
                }
            }
        }

        KeyButton {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: root.page === root.pages - 1 ? Lang.introStart : Lang.introNext
            accent: true
            onClicked: root.next()
        }
    }
}

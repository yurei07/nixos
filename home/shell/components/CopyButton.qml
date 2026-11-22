import QtQuick
import Quickshell.Io
import qs.theme
import qs.config

Row {
    id: root

    property string text: ""
    property bool wordFirst: false
    property bool copied: false

    spacing: 8
    layoutDirection: wordFirst ? Qt.RightToLeft : Qt.LeftToRight

    function copy(): void {
        if (copier.running)
            return;
        copier.input = root.text;
        copier.running = true;
    }

    // Through stdin: on its command line the text, a secret in Nilo's code perhaps, could be read
    // in /proc for as long as it stays the selection, and past 128 KiB it wouldn't start at all.
    // Copied is said once wl-copy has it.
    Process {
        id: copier

        property string input: ""

        command: [Config.cmd.wlCopy]
        stdinEnabled: true
        onStarted: {
            write(input);
            input = "";
            stdinEnabled = false;
        }
        onExited: code => {
            stdinEnabled = true;
            if (code !== 0)
                return;
            root.copied = true;
            bump.restart();
            settle.restart();
        }
    }

    Ico {
        id: icon
        anchors.verticalCenter: parent.verticalCenter
        glyph: root.copied ? Icons.check : Icons.copy
        font.pixelSize: 15
        color: root.copied || area.containsMouse ? Tokens.ink : Tokens.muted

        MouseArea {
            id: area
            anchors.fill: parent
            anchors.margins: -8
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.copy()
        }
    }

    Label {
        anchors.verticalCenter: parent.verticalCenter
        text: Lang.niloCopied
        color: Tokens.ink
        opacity: root.copied ? 1 : 0

        Behavior on opacity { NumberAnimation { duration: Tokens.animFast } }
    }

    SequentialAnimation {
        id: bump
        NumberAnimation { target: icon; property: "scale"; to: 1.35; duration: 90; easing.type: Easing.OutCubic }
        NumberAnimation { target: icon; property: "scale"; to: 1; duration: 180; easing.type: Easing.OutCubic }
    }

    Timer {
        id: settle
        interval: 1600
        onTriggered: root.copied = false
    }
}

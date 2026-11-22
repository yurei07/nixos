import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.config
import qs.services
import qs.components

Item {
    id: root

    property bool asking: false
    property bool showLog: false
    readonly property bool hasLog: Machine.log !== "" && (Machine.busy || Machine.phase === "failed" || Machine.phase === "warning")

    implicitHeight: 56 + (showLog && hasLog ? logBox.height + 12 : 0)

    readonly property bool fingerWait: Machine.phase === "auth" && Machine.auth === "finger"

    function go(password: string): void {
        if (password === "" && !Machine.fingerprint) {
            ask.grab();
            return;
        }
        Machine.apply(password);
    }

    Connections {
        target: Machine
        function onFailureChanged(): void {
            if (Machine.kind === "settings" && (Machine.failure === "finger" || Machine.failure === "password")) {
                root.asking = true;
                ask.grab();
            }
        }
        function onPhaseChanged(): void {
            if (Machine.phase === "applying")
                root.asking = false;
        }
    }

    Surface {
        id: logBox
        visible: root.showLog && root.hasLog
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 170
        radius: 12
        color: Tokens.surface
        border.width: 1
        border.color: Tokens.line

        Flickable {
            id: logView
            anchors.fill: parent
            anchors.margins: 12
            clip: true
            contentHeight: logText.implicitHeight
            contentY: Math.max(0, contentHeight - height)
            boundsBehavior: Flickable.StopAtBounds

            Text {
                id: logText
                width: logView.width
                text: Machine.log
                color: Tokens.dim
                font.family: Tokens.fontMono
                font.pixelSize: 11
                wrapMode: Text.WrapAnywhere
            }
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: row.top
        anchors.bottomMargin: 6
        height: 1
        color: Tokens.line
    }

    RowLayout {
        id: row
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 50
        spacing: 12

        Column {
            Layout.fillWidth: true
            spacing: 3

            Alert {
                width: parent.width
                text: Machine.statusTitle
                wrong: Machine.phase === "failed"
                color: Tokens.ink
                font.family: Tokens.fontSans
                font.pixelSize: 14
            }

            Label {
                width: parent.width
                visible: text !== ""
                text: Machine.statusSub !== "" ? Machine.statusSub
                    : root.asking && !Machine.busy && Updates.dev !== "" ? Lang.cfgDevBuilds.arg(Updates.dev) : ""
            }
        }

        KeyButton {
            visible: root.hasLog
            text: root.showLog ? Lang.cfgHideLog : Lang.cfgShowLog
            onClicked: root.showLog = !root.showLog
        }

        // While the finger is awaited, the password can be typed instead.
        PasswordAsk {
            id: ask
            visible: root.asking && Machine.changes > 0 && (!Machine.busy || root.fingerWait)
            confirm: Machine.busy ? "" : Lang.cfgApply
            onEntered: password => root.go(password)
            onCancelled: {
                if (root.fingerWait)
                    Machine.cancelFinger();
                root.asking = false;
            }
        }

        KeyButton {
            visible: !root.asking && Machine.changes > 0 && !Machine.busy
            text: Lang.cfgDiscard
            onClicked: Machine.discard()
        }

        KeyButton {
            visible: !root.asking && Machine.changes > 0 && !Machine.busy
            accent: true
            text: Lang.cfgApply
            onClicked: {
                root.asking = true;
                Updates.readDev();
                if (Machine.fingerprint)
                    Machine.apply("");
            }
        }
    }
}

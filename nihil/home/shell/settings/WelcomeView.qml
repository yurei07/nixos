import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.config
import qs.services
import qs.components

Item {
    id: root

    property var steps: ["hello", "frame", "basics", "you", "region", "look", "system", "done"]
    readonly property var files: ({ network: "PageNetwork.qml", you: "PageYou.qml", region: "PageRegion.qml", look: "PageLook.qml", system: "PageSystem.qml" })

    Component.onCompleted: {
        if (!Network.connected)
            steps = ["hello", "network"].concat(steps.slice(1));
    }
    property int step: 0
    readonly property string current: steps[step]
    readonly property bool last: step === steps.length - 1
    readonly property bool applied: Machine.phase === "done" || Machine.phase === "warning"
    readonly property bool asking: last && Machine.changes > 0 && !Machine.busy && !applied
    // While the finger is awaited, the password can be typed instead, as in Preferences.
    readonly property bool fingerWait: last && Machine.phase === "auth" && Machine.auth === "finger"
    readonly property string firstName: String(Machine.get("user.fullName", "")).trim().split(" ")[0]
    // What it says of the touchpad is true of these only, each with three fingers: changed, or off,
    // it says nothing of them.
    readonly property bool threeFingers: ["workspaces", "close", "launcher", "maximize"].every(name => (Config.gestures ?? {})[name] === 3)

    function key(name: string): string {
        const combo = Config.binds[name];
        return combo === null || combo === undefined ? "—" : combo;
    }

    function finish(): void {
        if (root.fingerWait) {
            if (password.text !== "")
                Machine.apply(password.text);
            password.clear();
            return;
        }
        if (root.asking) {
            if (password.text === "" && !Machine.fingerprint) {
                password.grab();
                return;
            }
            Machine.markWelcomed();
            Machine.apply(password.text);
            password.clear();
        } else {
            Machine.endWelcome();
        }
    }

    function next(): void {
        if (root.last)
            root.finish();
        else
            root.step++;
    }

    function back(): void {
        if (root.step > 0 && !Machine.busy && !root.applied)
            root.step--;
    }

    // Enter goes on and Escape back, as the buttons below. A field keeps its Enter, and a
    // button with the focus answers for itself.
    focus: true
    // A field on the page gone keeps nothing: the keys come back here.
    onStepChanged: root.forceActiveFocus()
    Keys.onReturnPressed: event => {
        if (root.activeFocus && !event.isAutoRepeat)
            root.next();
        else
            event.accepted = false;
    }
    Keys.onEnterPressed: event => {
        if (root.activeFocus && !event.isAutoRepeat)
            root.next();
        else
            event.accepted = false;
    }
    Keys.onEscapePressed: root.back()

    Item {
        id: body
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: footer.top
        anchors.leftMargin: 56
        anchors.rightMargin: 56
        anchors.topMargin: 44
        anchors.bottomMargin: 16

        Column {
            visible: root.current === "hello"
            anchors.centerIn: parent
            width: Math.min(600, parent.width)
            spacing: 12

            Logo {
                anchors.horizontalCenter: parent.horizontalCenter
                size: 84
            }

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "ex nihilo"
                font.italic: true
            }

            Item {
                width: 1
                height: 24
            }

            Txt {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 28
                text: root.firstName !== "" ? Lang.welHello.arg(root.firstName) : Lang.welHelloAnon
            }

            Txt {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                elide: Text.ElideNone
                color: Tokens.dim
                font.pixelSize: 15
                text: Lang.welHelloBody
            }
        }

        ColumnLayout {
            visible: root.current === "frame"
            anchors.fill: parent
            spacing: 10

            Heading {
                Layout.bottomMargin: 10
                title: Lang.welFrameTitle
                sub: Lang.welFrameBody
            }

            Repeater {
                model: [
                    { what: Lang.welDashboard, where: Lang.welTop, key: root.key("dashboard") },
                    { what: Lang.welPanel, where: Lang.welSide, key: root.key("panel") },
                    { what: Lang.welLauncher, where: Lang.welBottom, key: root.key("launcher") }
                ]

                Setting {
                    required property var modelData

                    title: modelData.what
                    sub: modelData.where

                    Txt {
                        text: Case.keys(modelData.key)
                        font.family: Tokens.fontMono
                        font.pixelSize: 13
                    }
                }
            }

            Item {
                Layout.fillHeight: true
            }
        }

        ColumnLayout {
            visible: root.current === "basics"
            anchors.fill: parent
            spacing: 4

            Heading {
                Layout.bottomMargin: 10
                title: Lang.welBasicsTitle
                sub: root.threeFingers ? Lang.welBasicsBody : Lang.welBasicsKeys
            }

            // Two columns of short rows: as many keys as there may be fit in the window, which
            // rows of Preferences' height overflowed.
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 32
                rowSpacing: 0

                Repeater {
                    model: [
                        { what: Lang.bindLauncher, key: root.key("launcher") },
                        { what: Lang.bindClose, key: root.key("close") },
                        { what: Lang.welWorkspaces, key: "SUPER + 1 … 9" },
                        { what: Lang.welMoveTo, key: "SUPER + SHIFT + 1 … 9" },
                        { what: Lang.bindLock, key: root.key("lock") },
                        { what: Lang.bindSettings, key: root.key("settings") }
                    ].concat(Config.binds.copy ? [{ what: Lang.bindCopy, key: root.key("copy") }] : [])
                     .concat(Config.binds.clipboard ? [{ what: Lang.bindClipboard, key: root.key("clipboard") }] : [])
                     .concat(Config.programs.filter(program => program.keys).slice(0, 3).map(program => ({ what: program.name, key: program.keys })))

                    Item {
                        id: bind

                        required property var modelData

                        // Both columns as wide.
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        implicitHeight: 40

                        Txt {
                            anchors.left: parent.left
                            anchors.right: combo.left
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: bind.modelData.what
                            font.pixelSize: 14
                        }

                        Txt {
                            id: combo
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.min(implicitWidth, bind.width * 0.6)
                            horizontalAlignment: Text.AlignRight
                            text: Case.keys(bind.modelData.key)
                            color: Tokens.dim
                            font.family: Tokens.fontMono
                            font.pixelSize: 13
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 1
                            color: Tokens.line
                            opacity: 0.6
                        }
                    }
                }
            }

            Txt {
                Layout.fillWidth: true
                Layout.topMargin: 12
                visible: root.threeFingers
                text: Lang.welGestures
                color: Tokens.dim
                wrapMode: Text.WordWrap
                elide: Text.ElideNone
            }

            Item {
                Layout.fillHeight: true
            }
        }

        Loader {
            anchors.fill: parent
            active: root.current in root.files
            source: active ? Qt.resolvedUrl(root.files[root.current]) : ""
        }

        Column {
            visible: root.current === "done"
            anchors.centerIn: parent
            width: Math.min(560, parent.width)
            spacing: 14

            DotText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Lang.welDoneTitle
                font.pixelSize: 56
            }

            Txt {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                elide: Text.ElideNone
                color: Tokens.dim
                font.pixelSize: 15
                text: root.asking ? Lang.welDoneApply : Lang.welDoneBody
            }

            Alert {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.min(implicitWidth, parent.width)
                visible: Machine.phase !== ""
                text: Machine.statusTitle
                wrong: Machine.phase === "failed"
                color: Tokens.ink
                font.family: Tokens.fontSans
                font.pixelSize: 14
            }

            Label {
                width: parent.width
                visible: Machine.phase !== "" && text !== ""
                horizontalAlignment: Text.AlignHCenter
                text: Machine.statusSub
            }
        }
    }

    Item {
        id: footer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 28
        height: 44

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Repeater {
                model: root.steps.length

                Rectangle {
                    required property int index

                    width: 6
                    height: 6
                    radius: 3
                    color: index === root.step ? Tokens.ink : index < root.step ? Tokens.dim : Tokens.off
                }
            }
        }

        RowLayout {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            KeyButton {
                visible: !root.last
                text: Lang.welSkip
                onClicked: Machine.endWelcome()
            }

            KeyButton {
                visible: root.step > 0 && !Machine.busy && !root.applied
                text: Lang.welBack
                onClicked: root.back()
            }

            Field {
                id: password
                visible: root.asking || root.fingerWait
                onVisibleChanged: {
                    if (!visible)
                        clear();
                }
                Layout.preferredWidth: 220
                password: true
                placeholder: Lang.cfgApplyPassword
                onAccepted: root.finish()
            }

            KeyButton {
                accent: true
                text: !root.last ? Lang.welNext
                    : root.asking || root.fingerWait ? Lang.welApplyStart
                    : Machine.busy || root.applied ? Lang.welClose : Lang.welStart
                onClicked: root.next()
            }
        }
    }
}

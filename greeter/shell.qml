//@ pragma Env QT_QPA_PLATFORM=wayland
//@ pragma Env QSG_DISTANCEFIELD_ANTIALIASING=gray

// The faces, one per screen, reach the greeter's own state by id.
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd
import qs.theme
import qs.config
import qs.components

ShellRoot {
    id: root

    property int user: 0
    readonly property var person: Config.users[user] ?? { name: "", greeting: "" }

    property bool asking: false
    property bool echo: false
    property bool sent: false
    property string waiting: ""
    property string note: ""
    property bool wrong: false
    property int attempts: 0
    property bool going: false

    readonly property string skipFile: (Quickshell.env("XDG_RUNTIME_DIR") ?? "") + "/nihil-greeter-password"

    // Every screen is on (cage -m extend) and the window spans them all: the greeter shows on each,
    // so it's where one looks, whichever is off or shut (a laptop closed with a screen plugged in
    // is still a screen to cage). One field takes the keys and every face shows it. With one
    // screen, or a layout that doesn't add up, one face fills the window.
    readonly property var faces: {
        const full = [Qt.rect(0, 0, window.width, window.height)];
        const screens = Quickshell.screens;
        if (screens.length < 2)
            return full;
        let left = Infinity;
        let top = Infinity;
        for (let i = 0; i < screens.length; i++) {
            left = Math.min(left, screens[i].x);
            top = Math.min(top, screens[i].y);
        }
        const out = [];
        for (let i = 0; i < screens.length; i++) {
            const r = Qt.rect(screens[i].x - left, screens[i].y - top, screens[i].width, screens[i].height);
            if (!(r.width > 0 && r.height > 0 && r.x >= 0 && r.y >= 0
                  && r.x + r.width <= window.width + 1 && r.y + r.height <= window.height + 1))
                return full;
            out.push(r);
        }
        return out;
    }

    // The faces fade in, and out on the way to the session.
    property real shown: 0

    Behavior on shown { NumberAnimation { duration: Tokens.animSlow; easing.type: Easing.OutCubic } }

    function start(): void {
        asking = false;
        echo = false;
        sent = false;
        if (Greetd.available && person.name !== "")
            Greetd.createSession(person.name);
    }

    function submit(text: string): void {
        if (text === "" || going || sent)
            return;
        if (asking) {
            asking = false;
            sent = true;
            Greetd.respond(text);
            return;
        }
        waiting = text;
        if (!skip.running)
            skip.running = true;
    }

    // If launching fails, the faces come back instead of staying dark with the field off.
    function back(): void {
        leave.stop();
        root.going = false;
        root.shown = 1;
    }

    function other(): void {
        if (Config.users.length < 2 || going)
            return;
        user = (user + 1) % Config.users.length;
        waiting = "";
        note = "";
        wrong = false;
        input.text = "";
        Greetd.cancelSession();
        start();
    }

    // What PAM and greetd say, as NIHIL writes: a failure in its own words, the rest with a capital.
    function said(text: string): string {
        const words = text.trim();
        if (/^authentication failure$/i.test(words))
            return Lang.authFailed.replace("$ATTEMPTS", String(root.attempts));
        return words.length > 0 ? words.charAt(0).toLocaleUpperCase() + words.slice(1) : words;
    }

    function reader(message: string): bool {
        return /finger|swipe|huella|dedo|sensor|lector/i.test(message);
    }

    function dateText(date: var): string {
        const map = { "%a": "ddd", "%A": "dddd", "%d": "dd", "%e": "d", "%-d": "d", "%b": "MMM", "%B": "MMMM",
                      "%m": "MM", "%Y": "yyyy", "%y": "yy" };
        const format = String(Lang.lockDate).replace(/%-?[a-zA-Z]/g, code => map[code] ?? "");
        const text = date.toLocaleString(Qt.locale(Lang.locale), format).replace(/\./g, "");
        return text.length > 0 ? text.charAt(0).toLocaleUpperCase() + text.slice(1) : text;
    }

    Connections {
        target: Greetd

        function onAuthMessage(message: string, error: bool, responseRequired: bool, echoResponse: bool): void {
            if (responseRequired) {
                root.echo = echoResponse;
                // A password asked for again keeps what the last try said, a failure most of all.
                root.note = echoResponse ? root.said(message) : root.wrong ? root.note : "";
                if (!echoResponse && root.waiting !== "") {
                    const text = root.waiting;
                    root.waiting = "";
                    root.sent = true;
                    Greetd.respond(text);
                    return;
                }
                root.sent = false;
                root.asking = true;
                return;
            }
            root.note = root.reader(message) ? Lang.fingerprintReady : root.said(message);
            root.wrong = error;
        }

        function onAuthFailure(message: string): void {
            root.back();
            root.attempts += 1;
            root.wrong = true;
            root.note = Lang.authFailed.replace("$ATTEMPTS", String(root.attempts));
            root.waiting = "";
            root.asking = false;
            root.sent = false;
            input.text = "";
            again.restart();
        }

        function onReadyToLaunch(): void {
            root.going = true;
            leave.start();
        }

        function onError(error: string): void {
            root.back();
            root.wrong = true;
            root.note = root.said(error);
            retry.restart();
        }
    }

    Process {
        id: skip
        command: [Config.touch, root.skipFile]
        onExited: {
            Greetd.cancelSession();
            root.start();
        }
    }

    Process {
        id: ready
        command: [Config.touch, Quickshell.env("NIHIL_GREETER_READY") || "/dev/null"]
    }

    Timer {
        id: again
        interval: 300
        onTriggered: root.start()
    }

    Timer {
        id: retry
        interval: 2000
        onTriggered: root.start()
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    FloatingWindow {
        id: window

        title: "NIHIL"
        color: Tokens.black
        fullscreen: true
        visible: true

        Component.onCompleted: {
            if (Greetd.available)
                ready.running = true;
            root.start();
            root.shown = 1;
            input.forceActiveFocus();
        }

        // What's typed, for every face: kept out of sight, the one thing that takes the keys.
        TextInput {
            id: input
            width: 1
            height: 1
            opacity: 0
            echoMode: root.echo ? TextInput.Normal : TextInput.Password
            enabled: !root.going
            onTextEdited: root.wrong = false
            onAccepted: root.submit(text)
            Keys.onEscapePressed: text = ""
        }

        FileView {
            id: glassFlag
            path: Config.glass
            blockLoading: true
        }

        Repeater {
            model: root.faces

            Item {
                id: face

                required property rect modelData

                x: face.modelData.x
                y: face.modelData.y
                width: face.modelData.width
                height: face.modelData.height
                opacity: root.shown

                property Item glassBackdrop: glassFlag.text().trim() === "on" && wall.status === Image.Ready ? glassSource : null

                Image {
                    id: wall
                    anchors.fill: parent
                    source: "file://" + Config.wallpaper
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    mipmap: true
                    opacity: 0.55
                }

                Item {
                    id: glassSource
                    readonly property Item texture: wall
                    // The wallpaper covers this face's screen: from the window's corner to its own.
                    readonly property vector2d origin: Qt.vector2d(-face.x, -face.y)
                    readonly property vector2d screenSize: Qt.vector2d(face.width, face.height)
                    readonly property real dim: 0.55
                }

                Txt {
                    id: time
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: parent.height / 2 - 170 - height / 2
                    text: Qt.formatTime(clock.date, "HH:mm")
                    font.family: Tokens.fontDot
                    font.weight: Font.Bold
                    font.pixelSize: 160
                }

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: parent.height / 2 - 72 - height / 2
                    text: root.dateText(clock.date)
                    color: Tokens.dim
                    font.pixelSize: 16
                }

                Txt {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: parent.height / 2 - height / 2
                    text: root.person.greeting !== "" ? Lang.welHello.arg(root.person.greeting) : Lang.welHelloAnon
                    font.pixelSize: 17
                }

                Surface {
                    id: field

                    anchors.horizontalCenter: parent.horizontalCenter
                    y: parent.height / 2 + 56 - height / 2
                    width: 280
                    height: 46
                    radius: 8
                    color: Tokens.black
                    border.width: 1
                    property color borderTint: root.wrong ? Tokens.interrupt : root.sent || root.waiting !== "" ? Tokens.muted : Tokens.line
                    border.color: borderTint

                    Behavior on borderTint { ColorAnimation { duration: Tokens.animFast } }

                    // What a prompt that may be seen asks for, as typed.
                    Text {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        visible: root.echo
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideLeft
                        text: input.text
                        color: Tokens.ink
                        font.family: Tokens.fontMono
                        font.pixelSize: 14
                    }

                    Row {
                        anchors.centerIn: parent
                        spacing: 7
                        visible: !root.echo

                        Repeater {
                            model: Math.min(input.text.length, 15)

                            Rectangle {
                                width: 10
                                height: 10
                                radius: 5
                                color: Tokens.ink
                            }
                        }
                    }

                    Label {
                        anchors.centerIn: parent
                        visible: input.text.length === 0
                        text: Lang.password
                        font.pixelSize: 13
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.IBeamCursor
                        onClicked: input.forceActiveFocus()
                    }
                }

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: parent.height / 2 + 110 - height / 2
                    text: root.note
                    color: root.wrong ? Tokens.ink : Tokens.muted
                    font.pixelSize: 12
                }

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: parent.height / 2 + 140 - height / 2
                    visible: Config.users.length > 1
                    text: root.person.name
                    color: nextUser.containsMouse ? Tokens.ink : Tokens.dim
                    font.pixelSize: 12

                    MouseArea {
                        id: nextUser
                        anchors.fill: parent
                        anchors.margins: -6
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.other()
                    }
                }

                Row {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 36
                    spacing: 28

                    Repeater {
                        model: [
                            { label: Lang.actReboot, command: Config.reboot },
                            { label: Lang.actPowerOff, command: Config.powerOff }
                        ]

                        // A second click within 3 s does it: one by chance doesn't turn the computer off.
                        Label {
                            id: action

                            required property var modelData
                            property bool armed: false

                            text: armed ? Lang.confirmTo.arg(modelData.label.toLowerCase()) : modelData.label
                            color: armed || area.containsMouse ? Tokens.ink : Tokens.muted
                            font.pixelSize: 12

                            Behavior on color { ColorAnimation { duration: Tokens.animFast } }

                            Timer {
                                id: disarm
                                interval: 3000
                                onTriggered: action.armed = false
                            }

                            MouseArea {
                                id: area
                                anchors.fill: parent
                                anchors.margins: -8
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (action.armed) {
                                        Quickshell.execDetached(action.modelData.command);
                                        return;
                                    }
                                    action.armed = true;
                                    disarm.restart();
                                }
                            }
                        }
                    }
                }

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 40
                    text: Tokens.motto
                    color: Tokens.off
                    font.italic: true
                    font.pixelSize: 12
                }
            }
        }

        NumberAnimation {
            id: leave
            target: root
            property: "shown"
            to: 0
            duration: Tokens.animNormal
            onFinished: Greetd.launch(Config.session, Config.environment)
        }
    }
}

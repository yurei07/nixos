import QtQuick
import QtQuick.Shapes
import qs.theme

Item {
    id: root

    property string mood: "idle"
    property real eyeWidth: 22
    property real eyeHeight: 54
    property real gap: 34
    property bool looking: false
    property real lookX: 0
    property real lookY: 0
    property int pulse: 0
    property bool live: visible && opacity > 0

    implicitWidth: 2 * eyeWidth + gap
    implicitHeight: eyeHeight

    readonly property bool closed: mood === "asleep" || mood === "off"
    readonly property bool tiny: eyeHeight < 24

    readonly property real openness: closed ? 0.14
        : mood === "waking" ? 0.55
        : mood === "thinking" ? 0.8
        : mood === "error" ? 0.7
        : mood === "searching" ? 0.88 : 1
    property real open: openness
    property real blink: 1
    property real squash: 1
    property real grow: mood === "alert" ? 1.12 : 1
    property real smile: mood === "happy" ? 1 : 0
    property color tint: mood === "error" ? Tokens.interrupt : Tokens.ink

    property real gazeX: 0
    property real gazeY: 0
    property string previous: ""

    Behavior on open { NumberAnimation { duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.6 } }
    Behavior on grow { NumberAnimation { duration: 260; easing.type: Easing.OutBack } }
    Behavior on smile { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
    Behavior on gazeX { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    Behavior on gazeY { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    Behavior on tint { ColorAnimation { duration: 300 } }

    function random(a: real, b: real): real { return a + Math.random() * (b - a); }

    function aim(): void {
        if (looking && (mood === "idle" || mood === "listening" || mood === "writing")) {
            gazeX = Math.max(-1, Math.min(1, lookX));
            gazeY = Math.max(-1, Math.min(1, lookY));
            return;
        }
        switch (mood) {
        case "off":
        case "asleep": gazeX = 0; gazeY = 0.35; break;
        case "waking": gazeX = random(-0.25, 0.25); gazeY = random(0, 0.3); break;
        case "listening": gazeX = Math.max(-0.7, Math.min(0.7, lookX)); gazeY = 0.5; break;
        case "thinking": gazeX = random(0.1, 0.75); gazeY = random(-0.7, -0.4); break;
        case "searching": gazeX = gazeX > 0 ? -0.75 : 0.75; gazeY = 0.1; break;
        case "writing": gazeX = random(-0.18, 0.18); gazeY = random(0.1, 0.3); break;
        case "happy": gazeX = 0; gazeY = -0.15; break;
        case "alert": gazeX = 0; gazeY = 0.55; break;
        case "error": gazeX = 0; gazeY = 0.4; break;
        default:
            if (Math.random() < 0.45) { gazeX = 0; gazeY = 0; }
            else { gazeX = random(-0.55, 0.55); gazeY = random(-0.35, 0.3); }
        }
    }

    function blinkNow(times: int): void {
        if (closed || blinking.running) return;
        blinking.loops = times;
        blinking.restart();
    }

    onMoodChanged: {
        if ((previous === "asleep" || previous === "waking" || previous === "off") && !closed && mood !== "waking")
            wake.restart();
        previous = mood;
        aim();
        glance.restart();
    }
    onLookXChanged: if (looking || mood === "listening") aim()
    onLookYChanged: if (looking) aim()
    onLookingChanged: aim()
    onPulseChanged: if (live && !bounce.running) bounce.restart()
    Component.onCompleted: { previous = mood; aim(); }

    Timer {
        id: wake
        interval: 260
        onTriggered: root.blinkNow(2)
    }

    SequentialAnimation {
        id: blinking
        NumberAnimation { target: root; property: "blink"; to: 0.06; duration: 70; easing.type: Easing.InQuad }
        NumberAnimation { target: root; property: "blink"; to: 1; duration: 130; easing.type: Easing.OutQuad }
    }

    SequentialAnimation {
        id: bounce
        NumberAnimation { target: root; property: "squash"; to: 0.86; duration: 50; easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "squash"; to: 1; duration: 140; easing.type: Easing.OutBack }
    }

    Timer {
        id: blinker
        running: root.live && !root.closed && root.mood !== "alert" && root.mood !== "happy"
        repeat: true
        interval: 3000
        onTriggered: {
            root.blinkNow(Math.random() < 0.22 ? 2 : 1);
            interval = root.mood === "waking" ? 1400 : root.mood === "thinking" ? root.random(4000, 7000)
                     : root.random(2400, 6000);
        }
    }

    Timer {
        id: glance
        running: root.live && !root.closed && root.mood !== "alert" && root.mood !== "happy" && root.mood !== "error"
        repeat: true
        interval: 1800
        onTriggered: {
            root.aim();
            interval = root.mood === "searching" ? 320 : root.mood === "thinking" ? 900
                     : root.mood === "writing" ? 1500 : root.mood === "waking" ? 2200 : root.random(1200, 3800);
        }
    }

    Item {
        id: face
        anchors.fill: parent
        opacity: root.mood === "off" ? 0.3 : 1

        SequentialAnimation on opacity {
            running: root.live && root.mood === "asleep"
            loops: Animation.Infinite
            onRunningChanged: if (!running) face.opacity = root.mood === "off" ? 0.3 : 1
            NumberAnimation { to: 0.38; duration: 2200; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0.8; duration: 2200; easing.type: Easing.InOutSine }
        }

        Repeater {
            model: 2

            Item {
                id: eye

                required property int index

                readonly property real side: index === 0 ? -1 : 1
                readonly property real full: root.eyeHeight * root.grow
                readonly property real thin: Math.max(1.5, root.eyeWidth * 0.24)

                readonly property real cx: root.width / 2 + side * (root.gap / 2 + root.eyeWidth / 2) + root.gazeX * root.gap * 0.32
                readonly property real cy: root.height / 2 + root.gazeY * root.eyeHeight * 0.16

                anchors.fill: parent

                Rectangle {
                    width: root.eyeWidth * root.grow
                    height: Math.max(eye.thin, eye.full * root.open * root.blink * root.squash * (1 - 0.6 * root.smile))
                    radius: Math.min(width, height) / 2
                    x: eye.cx - width / 2
                    y: eye.cy - height / 2
                    color: root.tint
                    opacity: 1 - root.smile
                    visible: opacity > 0
                    antialiasing: true
                }

                Shape {
                    id: arc

                    readonly property real stroke: Math.max(1.5, root.eyeWidth * 0.42)

                    width: root.eyeWidth * 1.45
                    height: root.eyeWidth * 0.95
                    x: eye.cx - width / 2
                    y: eye.cy - height * 0.7
                    opacity: root.smile
                    visible: opacity > 0
                    preferredRendererType: Shape.CurveRenderer

                    ShapePath {
                        strokeColor: root.tint
                        strokeWidth: arc.stroke
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap
                        startX: arc.stroke / 2
                        startY: arc.height - arc.stroke / 2

                        PathArc {
                            x: arc.width - arc.stroke / 2
                            y: arc.height - arc.stroke / 2
                            radiusX: (arc.width - arc.stroke) / 2
                            radiusY: arc.height - arc.stroke
                            direction: PathArc.Clockwise
                        }
                    }
                }
            }
        }
    }
}

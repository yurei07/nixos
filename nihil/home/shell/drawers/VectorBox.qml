import QtQuick
import Quickshell.Widgets
import qs.theme
import qs.config
import qs.services
import qs.components

Item {
    id: root

    property var shown: ({ id: "" })
    property string shownText: ""
    property var going: ({ kind: "" })
    readonly property bool has: (root.shown.id ?? "") !== ""
    readonly property real radius: 14
    readonly property real pitch: 7
    // Its keys show under the pointer, and with the focus: Tab, or a touch held.
    readonly property bool over: pointer.containsMouse || dropArea.containsDrag || keys.hovered || root.activeFocus
    property real head: -1
    property real flash: 0
    property color flashColor: Tokens.ink

    readonly property var actions: !root.has ? []
        : root.shown.kind === "text" ? ["copy", "save", "clear"]
        : root.shown.kind === "image" ? ["copy", "save", "open", "clear"]
        : ["save", "open", "clear"]

    readonly property var leds: {
        const inset = 1.5;
        const w = root.width - 2 * inset;
        const h = root.height - 2 * inset;
        const r = Math.min(root.radius, w / 2, h / 2);
        if (w <= 2 * r || h <= 2 * r)
            return [];
        const across = w - 2 * r;
        const down = h - 2 * r;
        const arc = Math.PI * r / 2;
        const length = 2 * (across + down) + 4 * arc;
        const count = Math.max(8, Math.floor(length / root.pitch));
        const corner = (cx, cy, from, t) => {
            const a = from + t / arc * Math.PI / 2;
            return { x: inset + cx + r * Math.cos(a), y: inset + cy + r * Math.sin(a) };
        };
        const points = [];
        for (let i = 0; i < count; i++) {
            let s = i * length / count;
            let p;
            if (s < across) p = { x: inset + r + s, y: inset };
            else if ((s -= across) < arc) p = corner(w - r, r, -Math.PI / 2, s);
            else if ((s -= arc) < down) p = { x: inset + w, y: inset + r + s };
            else if ((s -= down) < arc) p = corner(w - r, h - r, 0, s);
            else if ((s -= arc) < across) p = { x: inset + w - r - s, y: inset + h };
            else if ((s -= across) < arc) p = corner(r, h - r, Math.PI / 2, s);
            else if ((s -= arc) < down) p = { x: inset, y: inset + h - r - s };
            else p = corner(r, r, Math.PI, s - down);
            points.push(p);
        }
        return points;
    }

    function shade(index: int): color {
        const base = root.over || Vector.busy ? Tokens.muted : Tokens.off;
        let light = 0;
        if (root.head >= 0) {
            const behind = (root.head - index / root.leds.length + 1) % 1;
            light = behind < 0.3 ? 1 - behind / 0.3 : 0;
        }
        const lit = Qt.tint(base, Qt.rgba(Tokens.ink.r, Tokens.ink.g, Tokens.ink.b, light));
        return root.flash > 0 ? Qt.tint(lit, Qt.rgba(root.flashColor.r, root.flashColor.g, root.flashColor.b, root.flash)) : lit;
    }

    function glyphOf(action: string): string {
        return { copy: Icons.copy, save: Icons.download, open: Icons.open, clear: Icons.close }[action] ?? "";
    }

    function primary(): void {
        if (!root.has)
            Vector.send("");
        else
            Vector.act(root.actions[0]);
    }

    function follow(): void {
        const next = Vector.received;
        const id = next.id ?? "";
        if (id === (root.shown.id ?? ""))
            return;
        if (id === "") {
            if (root.has)
                leave.restart();
            return;
        }
        leave.stop();
        root.shown = next;
        root.shownText = Vector.text;
        arrive.restart();
        lap.restart();
    }

    Component.onCompleted: root.follow()

    Connections {
        target: Vector

        function onReceivedChanged(): void {
            root.follow();
        }

        function onTextChanged(): void {
            if ((Vector.received.id ?? "") === (root.shown.id ?? ""))
                root.shownText = Vector.text;
        }

        function onSent(item: var): void {
            root.going = item;
            fly.restart();
        }

        function onLit(what: string): void {
            if (what === "sent" || what === "received") {
                lap.restart();
            } else if (what !== "save" && what !== "open" && what !== "clear") {
                root.flashColor = what === "failed" ? Tokens.interrupt : Tokens.ink;
                blink.restart();
            }
        }
    }

    NumberAnimation {
        id: lap
        target: root
        property: "head"
        from: 0
        to: 1
        duration: 900
        easing.type: Easing.InOutSine
        onFinished: root.head = -1
    }

    SequentialAnimation {
        id: blink
        NumberAnimation { target: root; property: "flash"; to: 1; duration: 90 }
        NumberAnimation { target: root; property: "flash"; to: 0; duration: 420; easing.type: Easing.OutCubic }
    }

    ParallelAnimation {
        id: arrive
        NumberAnimation { target: content; property: "scale"; from: 0.82; to: 1; duration: 320; easing.type: Easing.OutCubic }
        NumberAnimation { target: content; property: "opacity"; from: 0; to: 1; duration: 240; easing.type: Easing.OutCubic }
    }

    SequentialAnimation {
        id: leave
        ParallelAnimation {
            NumberAnimation { target: content; property: "scale"; to: 0.25; duration: 300; easing.type: Easing.InCubic }
            NumberAnimation { target: content; property: "opacity"; to: 0; duration: 300; easing.type: Easing.InCubic }
        }
        ScriptAction {
            script: {
                root.shown = ({ id: "" });
                root.shownText = "";
                content.scale = 1;
                content.opacity = 1;
            }
        }
    }

    SequentialAnimation {
        id: fly
        ScriptAction { script: { outgoing.scale = 1; outgoing.opacity = 1; outgoing.visible = true; } }
        PauseAnimation { duration: 160 }
        ParallelAnimation {
            NumberAnimation { target: outgoing; property: "scale"; to: 0.06; duration: 520; easing.type: Easing.InCubic }
            NumberAnimation { target: outgoing; property: "opacity"; to: 0; duration: 520; easing.type: Easing.InQuad }
        }
        ScriptAction { script: outgoing.visible = false }
    }

    Timer {
        running: Vector.busy
        interval: 950
        repeat: true
        triggeredOnStart: true
        onTriggered: lap.restart()
    }

    Repeater {
        model: root.leds

        Rectangle {
            required property var modelData
            required property int index

            x: modelData.x - 1.5
            y: modelData.y - 1.5
            width: 3
            height: 3
            radius: 1.5
            color: root.shade(index)
        }
    }

    Item {
        anchors.fill: parent
        opacity: outgoing.visible ? 0 : 1

        Behavior on opacity { NumberAnimation { duration: Tokens.animFast } }

        Item {
            id: content
            anchors.fill: parent

            Ico {
                anchors.centerIn: parent
                visible: !root.has
                glyph: Icons.swap
                color: root.over ? Tokens.dim : Tokens.off
                font.pixelSize: 22
            }

            Preview {
                anchors.fill: parent
                visible: root.has
                item: root.shown
                text: root.shownText
                lit: root.over
            }
        }
    }

    Item {
        id: outgoing
        anchors.fill: parent
        visible: false

        Preview {
            anchors.fill: parent
            item: root.going
            text: root.going.preview ?? ""
            lit: true
        }
    }

    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: root.has ? root.shown.name ?? "" : Lang.vectorPaste
    Accessible.onPressAction: root.primary()
    Keys.onReturnPressed: event => { if (!event.isAutoRepeat) root.primary(); }
    Keys.onEnterPressed: event => { if (!event.isAutoRepeat) root.primary(); }
    Keys.onSpacePressed: event => { if (!event.isAutoRepeat) root.primary(); }

    FocusRing {
        round: root.radius
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.primary()
        onPressAndHold: root.forceActiveFocus()
    }

    Row {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: 12
        anchors.topMargin: 9
        spacing: 10
        opacity: root.over ? 1 : 0

        Behavior on opacity { NumberAnimation { duration: Tokens.animFast } }

        HoverHandler { id: keys }

        Repeater {
            model: root.has ? root.actions : ["paste"]

            Ico {
                id: key

                required property string modelData

                glyph: key.modelData === "paste" ? Icons.paste : root.glyphOf(key.modelData)
                color: hit.containsMouse ? (key.modelData === "clear" ? Tokens.interrupt : Tokens.ink) : Tokens.dim
                font.pixelSize: 15

                MouseArea {
                    id: hit
                    anchors.fill: parent
                    anchors.margins: -5
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    Accessible.role: Accessible.Button
                    Accessible.name: ({ copy: Lang.vectorCopy, save: Lang.vectorSave, open: Lang.vectorOpen, clear: Lang.vectorRemove, paste: Lang.vectorPaste })[key.modelData] ?? ""
                    Accessible.onPressAction: key.modelData === "paste" ? Vector.send("") : Vector.act(key.modelData)
                    onClicked: key.modelData === "paste" ? Vector.send("") : Vector.act(key.modelData)
                }
            }
        }
    }

    DropArea {
        id: dropArea
        anchors.fill: parent
        onEntered: Vector.dropping = true
        onExited: Vector.dropping = false
        onDropped: event => {
            Vector.dropping = false;
            // Vector holds one thing: of several dropped, none goes, and it says why.
            if (event.hasUrls && event.urls.length > 1) {
                Vector.refuse("many");
                return;
            }
            if (event.hasUrls && event.urls.length > 0)
                Vector.send(event.urls[0].toString());
            else if (event.hasText)
                Vector.sendText(event.text);
            event.accept();
        }
    }

    component Preview: Item {
        id: view

        property var item: ({ kind: "" })
        property string text: ""
        property bool lit: false

        ClippingRectangle {
            anchors.fill: parent
            anchors.margins: 12
            anchors.topMargin: 30
            radius: 6
            color: "transparent"
            visible: view.item.kind === "image"

            Image {
                anchors.fill: parent
                source: view.item.kind === "image" && view.item.path ? Vector.fileUrl(view.item.path) : ""
                sourceSize.width: 440
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                opacity: view.lit ? 1 : 0.8
            }
        }

        Txt {
            anchors.fill: parent
            anchors.margins: 14
            anchors.topMargin: 30
            visible: view.item.kind === "text"
            text: view.text
            color: view.lit ? Tokens.ink : Tokens.dim
            font.pixelSize: 12
            verticalAlignment: Text.AlignTop
            wrapMode: Text.Wrap
            maximumLineCount: 3
            elide: Text.ElideRight
        }

        Row {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 8
            spacing: 10
            visible: view.item.kind === "video" || view.item.kind === "file"

            Ico {
                anchors.verticalCenter: parent.verticalCenter
                glyph: view.item.kind === "video" ? Icons.video : Icons.file
                color: view.lit ? Tokens.ink : Tokens.dim
                font.pixelSize: 20
            }

            Column {
                width: parent.width - 30
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Txt {
                    width: parent.width
                    text: view.item.name ?? ""
                    color: view.lit ? Tokens.ink : Tokens.dim
                    font.pixelSize: 13
                }

                Label {
                    visible: (view.item.size ?? -1) >= 0
                    text: Dates.bytes(view.item.size ?? 0)
                }
            }
        }
    }
}

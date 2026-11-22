import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.theme
import qs.config
import qs.services
import qs.components

Flickable {
    id: page

    property var monitors: []       // hyprctl monitors all -j, by id
    property bool loaded: false
    property string chosen: ""      // the one whose settings show

    readonly property var saved: Machine.get("outputs", ({}))
    readonly property string main: Machine.get("primaryOutput", Config.primaryOutput)
    readonly property var away: Object.keys(saved).filter(name => !monitors.some(monitor => monitor.name === name))

    readonly property var rects: monitors.map(monitor => rectOf(monitor))

    readonly property var current: monitors.find(monitor => monitor.name === chosen) ?? null
    readonly property var mode: current !== null ? modeOf(current) : null
    readonly property var sizes: current !== null ? sizesOf(current) : []
    readonly property var size: sizes.find(s => mode !== null && s.width === mode.width && s.height === mode.height) ?? null

    contentHeight: column.implicitHeight + 24
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    interactive: desk.dragging === ""

    function entry(name: string): var {
        return saved[name] ?? ({});
    }

    function parseMode(text: string): var {
        const m = /^(\d+)x(\d+)@([\d.]+)/.exec(String(text));
        return m ? { width: Number(m[1]), height: Number(m[2]), rate: Math.round(Number(m[3]) * 100) / 100 } : null;
    }

    function modeOf(monitor: var): var {
        const saved = entry(monitor.name).mode;
        return (saved && saved !== "preferred" ? parseMode(saved) : null)
            ?? { width: monitor.width, height: monitor.height, rate: Math.round(monitor.refreshRate * 100) / 100 };
    }

    function scaleOf(monitor: var): real {
        return entry(monitor.name).scale ?? monitor.scale ?? 1;
    }

    function turnOf(monitor: var): int {
        return entry(monitor.name).transform ?? monitor.transform ?? 0;
    }

    function rectOf(monitor: var): var {
        const shown = modeOf(monitor), scale = scaleOf(monitor);
        const w = Math.round(shown.width / scale), h = Math.round(shown.height / scale);
        const turned = turnOf(monitor) % 2 === 1;
        const at = /^(-?\d+)x(-?\d+)$/.exec(String(entry(monitor.name).position ?? ""));
        return { name: monitor.name, x: at ? Number(at[1]) : monitor.x, y: at ? Number(at[2]) : monitor.y,
                 w: turned ? h : w, h: turned ? w : h };
    }

    function sizesOf(monitor: var): var {
        const found = {};
        for (const text of monitor.availableModes ?? []) {
            const m = parseMode(text);
            if (m === null)
                continue;
            const key = m.width + "x" + m.height;
            const size = found[key] = found[key] ?? { width: m.width, height: m.height, rates: [] };
            const same = size.rates.findIndex(rate => Math.round(rate) === Math.round(m.rate));
            if (same < 0)
                size.rates.push(m.rate);
            else if (m.rate > size.rates[same])
                size.rates[same] = m.rate;
        }
        const now = modeOf(monitor);
        const all = Object.values(found).sort((a, b) => b.width * b.height - a.width * a.height);
        if (all.length === 0)
            return [{ width: now.width, height: now.height, rates: [now.rate] }];
        const own = all[0], shape = own.width / own.height;
        const isNow = s => s.width === now.width && s.height === now.height;
        const kept = all.filter(s => !isNow(s) && Math.abs(s.width / s.height - shape) < 0.02 && s.width * 3 >= own.width).slice(0, 5);
        const shown = all.find(isNow) ?? { width: now.width, height: now.height, rates: [now.rate] };
        return kept.concat([shown]).sort((a, b) => b.width * b.height - a.width * a.height)
            .map(s => ({ width: s.width, height: s.height, rates: s.rates.slice().sort((a, b) => b - a) }));
    }

    function scalesFor(width: int, height: int, kept: real): var {
        return [1, 1.25, 1.5, 1.6, 1.75, 2, 2.5, 3].filter(scale => {
            const w = width / scale, h = height / scale;
            const whole = Math.abs(w - Math.round(w)) < 0.001 && Math.abs(h - Math.round(h)) < 0.001;
            return scale === kept || (whole && Math.max(w, h) >= 1024);
        });
    }

    function write(monitor: var, change: var): void {
        const shown = modeOf(monitor);
        const next = Object.assign({ mode: shown.width + "x" + shown.height + "@" + shown.rate,
                                     scale: scaleOf(monitor), transform: turnOf(monitor), bar: true },
                                   entry(monitor.name), change);
        const size = parseMode(next.mode) ?? shown;
        const turned = next.transform % 2 === 1;
        next.width = turned ? size.height : size.width;
        next.height = turned ? size.width : size.height;
        Machine.set("outputs." + monitor.name, next);
    }

    function pickSize(key: string): void {
        const s = sizes.find(s => s.width + "x" + s.height === key);
        if (current === null || s === undefined)
            return;
        const rate = s.rates.find(r => Math.round(r) === Math.round(mode.rate)) ?? s.rates[0];
        const was = scaleOf(current), fits = scalesFor(s.width, s.height, -1);
        const scale = fits.indexOf(was) >= 0 || fits.length === 0 ? was
            : fits.reduce((best, other) => Math.abs(other - was) < Math.abs(best - was) ? other : best);
        write(current, { mode: s.width + "x" + s.height + "@" + rate, scale: scale });
        Qt.callLater(page.relayout);
    }

    function pickRate(rate: real): void {
        if (current !== null)
            write(current, { mode: mode.width + "x" + mode.height + "@" + rate });
    }

    function pickScale(scale: real): void {
        if (current === null)
            return;
        write(current, { scale: scale });
        Qt.callLater(page.relayout);
    }

    function pickTurn(turn: int): void {
        if (current === null)
            return;
        write(current, { transform: turn });
        Qt.callLater(page.relayout);
    }

    function overlaps(a: var, b: var): bool {
        return a.x < b.x + b.w && b.x < a.x + a.w && a.y < b.y + b.h && b.y < a.y + a.h;
    }

    function nearest(value: real, lines: var, near: real): real {
        let best = value, gap = near;
        for (const line of lines) {
            if (Math.abs(value - line) < gap) {
                best = line;
                gap = Math.abs(value - line);
            }
        }
        return best;
    }

    function settle(r: var, x: real, y: real, others: var): var {
        const spots = [];
        for (const o of others) {
            const nearY = Math.max(32, 0.1 * Math.min(r.h, o.h));
            const nearX = Math.max(32, 0.1 * Math.min(r.w, o.w));
            const atY = nearest(Math.max(o.y - r.h + 1, Math.min(o.y + o.h - 1, y)), [o.y, o.y + o.h - r.h, o.y + (o.h - r.h) / 2], nearY);
            const atX = nearest(Math.max(o.x - r.w + 1, Math.min(o.x + o.w - 1, x)), [o.x, o.x + o.w - r.w, o.x + (o.w - r.w) / 2], nearX);
            spots.push({ x: o.x + o.w, y: atY }, { x: o.x - r.w, y: atY }, { x: atX, y: o.y + o.h }, { x: atX, y: o.y - r.h });
        }
        const free = spots.map(s => ({ x: Math.round(s.x), y: Math.round(s.y) }))
            .filter(s => !others.some(o => overlaps({ x: s.x, y: s.y, w: r.w, h: r.h }, o)));
        free.sort((a, b) => Math.hypot(a.x - x, a.y - y) - Math.hypot(b.x - x, b.y - y));
        return free[0] ?? { x: Math.max(...others.map(o => o.x + o.w)), y: 0 };
    }

    function arrange(placed: var): void {
        if (placed.length < 2)
            return;
        const left = Math.min(...placed.map(r => r.x)), top = Math.min(...placed.map(r => r.y));
        for (const r of placed) {
            const position = (r.x - left) + "x" + (r.y - top);
            const monitor = monitors.find(m => m.name === r.name);
            if (monitor !== undefined && entry(r.name).position !== position)
                write(monitor, { position: position });
        }
    }

    function relayout(): void {
        const placed = [];
        for (const r of rects.slice().sort((a, b) => a.x + a.y - (b.x + b.y)))
            placed.push(Object.assign({}, r, placed.length === 0 ? { x: r.x, y: r.y } : settle(r, r.x, r.y, placed)));
        arrange(placed);
    }

    Process {
        id: reader
        command: [Config.cmd.hyprctl, "monitors", "all", "-j"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    page.monitors = JSON.parse(text).sort((a, b) => a.id - b.id);
                } catch (error) {
                    page.monitors = [];
                }
                if (!page.monitors.some(monitor => monitor.name === page.chosen)) {
                    const focused = Hyprland.focusedMonitor?.name ?? "";
                    page.chosen = page.monitors.some(monitor => monitor.name === focused) ? focused : (page.monitors[0]?.name ?? "");
                }
                page.loaded = true;
            }
        }
    }

    ColumnLayout {
        id: column
        width: page.width
        spacing: 0

        Heading {
            title: Lang.cfgScreens
        }

        Txt {
            Layout.topMargin: 14
            visible: page.loaded && page.monitors.length === 0
            text: Lang.cfgScreenNone
            color: Tokens.muted
            font.pixelSize: 13
        }

        Rectangle {
            id: desk

            property string dragging: ""
            property real dragX: 0          // where it is, in logical pixels
            property real dragY: 0
            property var target: null       // where it would settle

            readonly property var bounds: {
                const r = page.rects;
                if (r.length === 0)
                    return { x: 0, y: 0, w: 1, h: 1 };
                const left = Math.min(...r.map(s => s.x)), top = Math.min(...r.map(s => s.y));
                return { x: left, y: top, w: Math.max(...r.map(s => s.x + s.w)) - left, h: Math.max(...r.map(s => s.y + s.h)) - top };
            }
            readonly property real fit: Math.max(0.01, Math.min((width - 120) / bounds.w, (height - 76) / bounds.h))
            readonly property real originX: (width - bounds.w * fit) / 2 - bounds.x * fit
            readonly property real originY: (height - bounds.h * fit) / 2 - bounds.y * fit
            readonly property var held: page.rects.find(r => r.name === dragging) ?? null

            Layout.fillWidth: true
            Layout.topMargin: 18
            Layout.preferredHeight: 232
            visible: page.monitors.length > 0
            radius: 12
            color: "transparent"
            border.width: 1
            border.color: Tokens.line

            Canvas {
                anchors.fill: parent
                anchors.margins: 6
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    ctx.fillStyle = String(Tokens.line);
                    for (let y = 6; y < height; y += 12)
                        for (let x = 6; x < width; x += 12)
                            ctx.fillRect(x - 0.75, y - 0.75, 1.5, 1.5);
                }
            }

            Rectangle {
                z: 1
                visible: desk.held !== null && desk.target !== null
                x: desk.originX + (desk.target?.x ?? 0) * desk.fit + 2
                y: desk.originY + (desk.target?.y ?? 0) * desk.fit + 2
                width: (desk.held?.w ?? 0) * desk.fit - 4
                height: (desk.held?.h ?? 0) * desk.fit - 4
                radius: 6
                color: "transparent"
                border.width: 1
                border.color: Tokens.ink
            }

            Repeater {
                model: page.monitors

                Item {
                    id: screen

                    required property var modelData
                    required property int index

                    readonly property var rect: page.rects[index] ?? ({ x: 0, y: 0, w: 1, h: 1 })
                    readonly property bool held: desk.dragging === modelData.name
                    readonly property bool picked: page.chosen === modelData.name

                    x: desk.originX + (held ? desk.dragX : rect.x) * desk.fit
                    y: desk.originY + (held ? desk.dragY : rect.y) * desk.fit
                    width: rect.w * desk.fit
                    height: rect.h * desk.fit
                    z: held ? 2 : 0
                    opacity: held ? 0.75 : modelData.disabled === true ? 0.45 : 1

                    Behavior on x { enabled: !screen.held; NumberAnimation { duration: Tokens.animNormal; easing.type: Easing.OutCubic } }
                    Behavior on y { enabled: !screen.held; NumberAnimation { duration: Tokens.animNormal; easing.type: Easing.OutCubic } }
                    Behavior on width { NumberAnimation { duration: Tokens.animNormal; easing.type: Easing.OutCubic } }
                    Behavior on height { NumberAnimation { duration: Tokens.animNormal; easing.type: Easing.OutCubic } }

                    Surface {
                        anchors.fill: parent
                        anchors.margins: 2
                        radius: 6
                        color: screen.picked ? Tokens.raised : Tokens.surface
                        border.width: 1
                        property color borderTint: screen.picked ? Tokens.ink : area.containsMouse ? Tokens.muted : Tokens.line
                        border.color: borderTint

                        Behavior on borderTint { ColorAnimation { duration: Tokens.animFast } }
                    }

                    Rectangle {
                        visible: page.entry(screen.modelData.name).bar ?? true
                        x: 5
                        y: 5
                        width: 4
                        height: parent.height - 10
                        radius: 2
                        color: screen.picked ? Tokens.dim : Tokens.off
                    }

                    DotText {
                        anchors.centerIn: parent
                        text: String(screen.modelData.id + 1)
                        font.pixelSize: Math.max(20, Math.min(46, screen.height * 0.42))
                        color: screen.picked ? Tokens.ink : Tokens.muted
                    }

                    Label {
                        x: 12
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 7
                        width: parent.width - 18
                        visible: screen.height > 50
                        text: screen.modelData.name
                        color: screen.picked ? Tokens.dim : Tokens.muted
                    }

                    Rectangle {
                        visible: page.monitors.length > 1 && page.main === screen.modelData.name
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 9
                        width: 6
                        height: 6
                        radius: 3
                        color: Tokens.ink
                    }

                    MouseArea {
                        id: area

                        property point from: Qt.point(0, 0)
                        property bool moved: false

                        anchors.fill: parent
                        hoverEnabled: true
                        preventStealing: true
                        cursorShape: screen.held ? Qt.ClosedHandCursor : page.monitors.length > 1 ? Qt.OpenHandCursor : Qt.PointingHandCursor
                        onPressed: mouse => {
                            from = Qt.point(mouse.x, mouse.y);
                            moved = false;
                            page.chosen = screen.modelData.name;
                        }
                        onPositionChanged: mouse => {
                            if (!pressed || page.monitors.length < 2)
                                return;
                            if (!moved && Math.hypot(mouse.x - from.x, mouse.y - from.y) < 4)
                                return;
                            moved = true;
                            const at = mapToItem(desk, mouse.x, mouse.y);
                            desk.dragX = (at.x - from.x - desk.originX) / desk.fit;
                            desk.dragY = (at.y - from.y - desk.originY) / desk.fit;
                            desk.dragging = screen.modelData.name;
                            desk.target = page.settle(screen.rect, desk.dragX, desk.dragY,
                                page.rects.filter(r => r.name !== screen.modelData.name));
                        }
                        onReleased: {
                            if (moved && desk.target !== null)
                                page.arrange(page.rects.map(r => r.name === screen.modelData.name ? Object.assign({}, r, desk.target) : r));
                            desk.dragging = "";
                            desk.target = null;
                            moved = false;
                        }
                        onCanceled: {
                            desk.dragging = "";
                            desk.target = null;
                            moved = false;
                        }
                    }
                }
            }

        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 22
            Layout.bottomMargin: 4
            visible: page.current !== null
            spacing: 12

            Txt {
                text: page.current?.name ?? ""
                font.pixelSize: 16
            }

            Txt {
                Layout.fillWidth: true
                text: [page.current?.make, page.current?.model].filter(part => part).join(" ")
                color: Tokens.muted
                font.pixelSize: 13
            }

            Label {
                visible: page.current?.disabled === true
                text: Lang.cfgScreenOff
            }
        }

        Setting {
            visible: page.current !== null
            title: Lang.cfgScreenMode

            Choice {
                mono: true
                options: page.sizes.map(s => ({ value: s.width + "x" + s.height, label: s.width + " × " + s.height }))
                value: page.mode !== null ? page.mode.width + "x" + page.mode.height : ""
                onPicked: value => page.pickSize(value)
            }
        }

        Setting {
            visible: page.size !== null && page.size.rates.length > 1
            title: Lang.cfgScreenRate

            Choice {
                mono: true
                options: (page.size?.rates ?? []).map(rate => ({ value: Math.round(rate), label: Math.round(rate) + " Hz", rate: rate }))
                value: page.mode !== null ? Math.round(page.mode.rate) : 0
                onPicked: value => page.pickRate((page.size?.rates ?? []).find(rate => Math.round(rate) === value) ?? value)
            }
        }

        Setting {
            visible: page.current !== null
            title: Lang.cfgScreenScale

            Choice {
                mono: true
                options: page.current === null ? [] : page.scalesFor(page.mode.width, page.mode.height, page.scaleOf(page.current))
                    .map(scale => ({ value: scale, label: Lang.cfgScreenScalePct.arg(Math.round(scale * 100)) }))
                value: page.current !== null ? page.scaleOf(page.current) : 1
                onPicked: value => page.pickScale(value)
            }
        }

        Setting {
            visible: page.current !== null
            title: Lang.cfgScreenRotation

            Choice {
                mono: true
                options: [{ value: 0, label: "0°" }, { value: 1, label: "90°" }, { value: 2, label: "180°" }, { value: 3, label: "270°" }]
                value: page.current !== null ? page.turnOf(page.current) % 4 : 0
                onPicked: value => page.pickTurn(value)
            }
        }

        Setting {
            visible: page.current !== null
            title: Lang.cfgScreenBar

            Toggle {
                on: page.current !== null && (page.entry(page.current.name).bar ?? true)
                onToggled: page.write(page.current, { bar: !on })
            }
        }

        Setting {
            visible: page.current !== null && page.monitors.length > 1
            title: Lang.cfgScreenMain

            Toggle {
                on: page.current !== null && page.main === page.current.name
                onToggled: {
                    if (on)
                        return;
                    if (!(page.current.name in page.saved))
                        page.write(page.current, {});
                    Machine.set("primaryOutput", page.current.name);
                }
            }
        }

        Repeater {
            model: page.loaded ? page.away : []

            Setting {
                id: gone

                required property string modelData

                Layout.topMargin: 10
                title: gone.modelData
                sub: Lang.cfgScreenAway

                KeyButton {
                    visible: gone.modelData !== page.main
                    text: Lang.cfgScreenForget
                    onClicked: Machine.set("outputs." + gone.modelData, undefined)
                }
            }
        }
    }
}

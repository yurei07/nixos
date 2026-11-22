import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.theme
import qs.config
import qs.services
import qs.components
import "Desk.js" as Desk
import "../nilo/Markdown.js" as Markdown

Scope {
    id: root

    readonly property var target: {
        const screens = Quickshell.screens;
        for (let i = 0; i < screens.length; i++)
            if (screens[i].name === Config.primaryOutput) return screens[i];
        return screens.length > 0 ? screens[0] : null;
    }
    // Where the widgets go, worked out as the frame works out its edges: placed by hand, not
    // within what other surfaces reserve, so the glass bends exactly what's behind them.
    readonly property int gap: 24
    readonly property bool anyBar: Quickshell.screens.some(s => Config.barOutputs.indexOf(s.name) >= 0)
    readonly property int inset: root.target !== null && (Config.barOutputs.indexOf(root.target.name) >= 0
        || (!root.anyBar && Quickshell.screens.indexOf(root.target) === 0)) ? Tokens.barWidth : Tokens.frameThickness
    readonly property int deskLeft: root.inset + root.gap
    readonly property int deskTop: Tokens.frameThickness + root.gap
    readonly property int deskEdge: Tokens.frameThickness + root.gap
    readonly property int spacing: 14
    // A widget lands on a grid, so those side by side line up.
    readonly property int cell: 8
    // How small and how big one can be made, against its own size.
    readonly property real smallest: 0.75
    readonly property real largest: 2.5
    // A new photo's size, as it comes.
    readonly property int photoWidth: 320
    readonly property int photoHeight: 248

    // The note being written, by name, in its sheet over the windows; "" while none is.
    property string writing: ""
    readonly property var noteVoices: ({ ink: String(Tokens.ink), dim: String(Tokens.dim), code: "#E6E6E6", surface: String(Tokens.surface),
                                         mono: Tokens.fontMono, icons: Tokens.fontIcons, breaks: true, tasks: true })

    function write(name: string): void {
        if (Machine.arranging || root.target === null)
            return;
        root.written();
        root.writing = name;
        words.text = Machine.widgetOptions[name]?.text ?? "";
        words.cursorPosition = words.length;
        Qt.callLater(() => words.forceActiveFocus());
    }

    // Kept as it's written, and once more as it's left.
    function written(): void {
        if (root.writing === "")
            return;
        saving.stop();
        if (words.text !== (Machine.widgetOptions[root.writing]?.text ?? ""))
            Machine.setWidgetOption(root.writing, "text", words.text);
        root.writing = "";
    }

    // Another note, as big as this one and beside it if there's room, written at once.
    function noteBeside(card: var): void {
        const at = Desk.beside({ x: card.x, y: card.y, w: card.width, h: card.height }, card.width, card.height, root.boxes(card),
                               { w: desk.width, h: desk.height }, root.spacing, root.cell);
        root.write(Machine.addWidget("note", [at.x, at.y], [Math.round(card.width), Math.round(card.height)]));
    }

    // A task's mark ticks it; any other link, of the web only, opens.
    function followNote(name: string, link: string): void {
        if (link.startsWith("task:"))
            Machine.setWidgetOption(name, "text", Markdown.toggled(Machine.widgetOptions[name]?.text ?? "", Number(link.slice(5))));
        else if (/^https?:\/\//i.test(link))
            Apps.open(link);
    }

    Connections {
        target: Machine
        function onArrangingChanged(): void {
            if (Machine.arranging)
                root.written();
        }
    }

    // One file from Files, of a kind a photo can show.
    function picture(drag: var): bool {
        return drag.hasUrls && drag.urls.length === 1 && /^file:\/\/\/.+\.(png|jpe?g|gif|bmp|webp)$/i.test(drag.urls[0].toString());
    }

    function enabled(name: string): bool {
        return Machine.widgets.indexOf(name) >= 0;
    }

    function cards(): var {
        const out = [];
        for (let i = 0; i < desk.children.length; i++) {
            if (desk.children[i].widget !== undefined)
                out.push(desk.children[i]);
        }
        return out;
    }

    // Those that were never put anywhere, one under the other, in the order they're written.
    function flow(card: var): real {
        let y = 0;
        for (const other of root.cards()) {
            if (other === card)
                return y;
            if (other.visible && other.place === null)
                y += other.height + root.spacing;
        }
        return y;
    }

    // The others, as boxes in the desk.
    function boxes(card: var): var {
        return root.cards().filter(other => other !== card && other.visible).map(other => ({ x: other.x, y: other.y, w: other.width, h: other.height }));
    }

    // The place on the grid nearest (x, y) where the card fits, a gap clear of the others.
    function room(card: var, x: real, y: real): point {
        const at = Desk.room(card.width, card.height, x, y, root.boxes(card), { w: desk.width, h: desk.height }, root.spacing, root.cell);
        return Qt.point(at.x, at.y);
    }

    // The first one moved keeps the rest where they show: from then on each one has its place.
    function drop(card: var, x: real, y: real): void {
        const places = {};
        for (const other of root.cards()) {
            if (other !== card && other.visible && other.place === null)
                places[other.widget] = [other.x, other.y];
        }
        Machine.placeWidgets(places);
        const at = root.room(card, x, y);
        Machine.placeWidgets({ [card.widget]: [at.x, at.y] });
    }

    // The size a card takes as its corner goes (dx, dy) from where it was at size `from`: its width
    // on the grid, all of it within the desk, and short of the others it would run into.
    function resized(card: var, from: real, dx: real, dy: real): real {
        return Desk.scaled({ x: card.x, y: card.y, base: card.base, tall: card.tall }, from, dx, dy, root.boxes(card),
                           { w: desk.width, h: desk.height }, { gap: root.spacing, cell: root.cell, smallest: root.smallest, largest: root.largest });
    }

    // The width and height one made to any shape takes as its corner goes (dx, dy) from `from`.
    function stretched(card: var, from: var, dx: real, dy: real): var {
        const out = Desk.stretched({ x: card.x, y: card.y, least: { w: card.least.width, h: card.least.height } }, from, dx, dy,
                                   root.boxes(card), { w: desk.width, h: desk.height }, { gap: root.spacing, cell: root.cell });
        return [out.w, out.h];
    }

    // Whether a point in the desk is on the cross, where a card dropped is taken away.
    function onBin(point: point): bool {
        return Machine.arranging && Math.hypot(point.x - (bin.x + bin.width / 2), point.y - (bin.y + bin.height / 2)) <= bin.width / 2 + 16;
    }

    // Turned on once the others have places: it goes where there's room, near the top left.
    function settle(card: var): void {
        if (!card.visible || card.place !== null || !root.cards().some(other => other.place !== null))
            return;
        const at = root.room(card, 0, 0);
        Machine.placeWidgets({ [card.widget]: [at.x, at.y] });
    }

    // Once what's shown has settled: a few turned on at once, or read from the file, one by one.
    Timer {
        id: settling
        interval: 0
        onTriggered: {
            for (const card of root.cards())
                root.settle(card);
        }
    }

    // A reading as a row of dots: its name, how full, and the figure.
    component Gauge: RowLayout {
        id: gauge

        property string name: ""
        property real value: 0
        property string reading: ""
        property bool alert: false

        Layout.fillWidth: true
        spacing: 10

        Label {
            Layout.preferredWidth: 36
            text: gauge.name
        }

        DotMeter {
            Layout.fillWidth: true
            Layout.preferredWidth: 100
            count: Math.max(8, Math.floor((width + 3) / 7))
            dot: 4
            gap: 3
            value: gauge.value
            litColor: gauge.alert ? Tokens.interrupt : Tokens.ink
        }

        Txt {
            Layout.preferredWidth: 40
            horizontalAlignment: Text.AlignRight
            text: gauge.reading
            color: Tokens.dim
            font.pixelSize: 12
        }
    }

    component Card: Surface {
        id: card

        property string widget: ""
        // Its width as it comes: all of it grows and shrinks from there, from its corner.
        property real base: 320
        // Or, made to any shape, its width and height apart, and what's in it laid out again; at
        // the least this big.
        property bool free: false
        property size least: Qt.size(200, 120)
        default property alias content: inner.data

        readonly property var place: Machine.widgetPlaces[card.widget] ?? null
        readonly property real tall: inner.implicitHeight + 40
        // How big it is: being resized, as kept, or as it comes. A number is how many times its
        // size; [width, height], for one made to any shape.
        readonly property var shape: card.sizing !== null ? card.sizing : (Machine.widgetSizes[card.widget] ?? null)
        readonly property real times: typeof card.shape === "number" ? card.shape : 1
        readonly property bool shaped: card.free && Array.isArray(card.shape)
        readonly property real size: card.free ? 1 : card.times
        // While it's dragged: where the pointer took it, in the desk and on the card, and how far it
        // has gone since. Over the cross it shrinks towards the pointer.
        property point grab: Qt.point(0, 0)
        property point hold: Qt.point(0, 0)
        property point moved: Qt.point(0, 0)
        property bool dragging: false
        readonly property bool binned: card.dragging && root.onBin(Qt.point(card.grab.x + card.moved.x, card.grab.y + card.moved.y))
        // While its corner is dragged: the size it's taking.
        property var sizing: null

        function take(area: Item, mx: real, my: real): void {
            card.grab = area.mapToItem(desk, mx, my);
            card.hold = area.mapToItem(card, mx, my);
            card.moved = Qt.point(0, 0);
            card.dragging = true;
        }

        function follow(area: Item, mx: real, my: real): void {
            if (!card.dragging)
                return;
            const now = area.mapToItem(desk, mx, my);
            card.moved = Qt.point(now.x - card.grab.x, now.y - card.grab.y);
        }

        function leave(): void {
            if (!card.dragging)
                return;
            const x = card.x, y = card.y, binned = card.binned;
            card.dragging = false;
            card.moved = Qt.point(0, 0);
            if (binned)
                Machine.removeWidget(card.widget);
            else
                root.drop(card, x, y);
        }

        function sized(): void {
            if (card.sizing === null)
                return;
            Machine.sizeWidget(card.widget, card.sizing);
            card.sizing = null;
            root.drop(card, card.x, card.y);
        }

        visible: root.enabled(card.widget)
        onVisibleChanged: settling.restart()
        width: card.shaped ? card.shape[0] : card.base * card.times
        implicitHeight: card.shaped ? card.shape[1] : card.tall * card.times
        height: implicitHeight
        // Within the desk; while dragged, where the pointer takes it, the cross included.
        readonly property real leftAt: (card.place !== null ? card.place[0] : 0) + card.moved.x
        readonly property real topAt: (card.place !== null ? card.place[1] : root.flow(card)) + card.moved.y
        x: card.dragging ? card.leftAt : Math.max(0, Math.min(desk.width - card.width, card.leftAt))
        y: card.dragging ? card.topAt : Math.max(0, Math.min(desk.height - card.height, card.topAt))
        z: card.dragging ? 1 : 0
        transform: Scale {
            origin.x: card.hold.x
            origin.y: card.hold.y
            xScale: card.binned ? 0.35 : 1
            yScale: xScale

            Behavior on xScale { NumberAnimation { duration: Tokens.animFast; easing.type: Easing.OutCubic } }
        }
        opacity: card.binned ? 0.75 : 1
        pane: true
        radius: Tokens.drawerRadius
        color: Tokens.black
        border.width: 1
        border.color: Machine.arranging ? Tokens.ink : Tokens.line

        // A long press on a card starts arranging, and goes on moving it from there.
        MouseArea {
            id: hold
            z: -1
            anchors.fill: parent
            pressAndHoldInterval: 450
            preventStealing: true
            cursorShape: Machine.arranging ? Qt.SizeAllCursor : Qt.ArrowCursor
            onPressAndHold: mouse => {
                Machine.arrangeWidgets();
                card.take(hold, mouse.x, mouse.y);
            }
            onPressed: mouse => {
                if (Machine.arranging)
                    card.take(hold, mouse.x, mouse.y);
            }
            onPositionChanged: mouse => card.follow(hold, mouse.x, mouse.y)
            onReleased: card.leave()
            onCanceled: card.leave()
        }

        Item {
            width: card.free ? card.width : card.base
            height: card.free ? card.height : card.tall
            scale: card.size
            transformOrigin: Item.TopLeft

            ColumnLayout {
                id: inner
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: card.free ? parent.bottom : undefined
                anchors.margins: 20
                anchors.leftMargin: 22
                anchors.rightMargin: 22
                spacing: 6
            }
        }

        // While arranging, all of the card moves it, its buttons too.
        MouseArea {
            id: handle
            z: 10
            anchors.fill: parent
            visible: Machine.arranging
            preventStealing: true
            cursorShape: Qt.SizeAllCursor
            onPressed: mouse => card.take(handle, mouse.x, mouse.y)
            onPositionChanged: mouse => card.follow(handle, mouse.x, mouse.y)
            onReleased: card.leave()
            onCanceled: card.leave()
        }

        // While arranging, its corner makes it bigger or smaller.
        MouseArea {
            id: corner

            property point from: Qt.point(0, 0)
            property var start: null

            z: 11
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            width: 30
            height: 30
            visible: Machine.arranging
            preventStealing: true
            cursorShape: Qt.SizeFDiagCursor
            onPressed: mouse => {
                corner.from = corner.mapToItem(desk, mouse.x, mouse.y);
                corner.start = card.free ? { w: card.width, h: card.height } : card.size;
                card.sizing = card.free ? [card.width, card.height] : card.size;
            }
            onPositionChanged: mouse => {
                if (card.sizing === null)
                    return;
                const now = corner.mapToItem(desk, mouse.x, mouse.y), dx = now.x - corner.from.x, dy = now.y - corner.from.y;
                card.sizing = card.free ? root.stretched(card, corner.start, dx, dy) : root.resized(card, corner.start, dx, dy);
            }
            onReleased: card.sized()
            onCanceled: card.sized()

            Repeater {
                model: [[0, 0], [6, 0], [0, 6]]

                Rectangle {
                    id: dot

                    required property var modelData

                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.rightMargin: 8 + dot.modelData[0]
                    anchors.bottomMargin: 8 + dot.modelData[1]
                    width: 3
                    height: 3
                    radius: 1.5
                    color: Tokens.ink
                }
            }
        }
    }

    PanelWindow {
        screen: root.target
        visible: root.target !== null
        color: "transparent"

        // Under the windows, and over them while arranging: the desktop may be covered.
        WlrLayershell.layer: Machine.arranging ? WlrLayer.Top : WlrLayer.Bottom
        WlrLayershell.namespace: "nihil-widgets"
        WlrLayershell.keyboardFocus: Machine.arranging ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore

        anchors { top: true; left: true; right: true; bottom: true }
        margins { top: root.deskTop; left: root.deskLeft; right: root.deskEdge; bottom: root.deskEdge }

        SystemClock {
            id: clock
            precision: SystemClock.Minutes
        }

        Loader {
            id: backdrop
            active: Machine.glass && root.target !== null
            sourceComponent: Backdrop {
                output: root.target.name
                origin: Qt.vector2d(root.deskLeft, root.deskTop)
                screenSize: Qt.vector2d(root.target.width, root.target.height)
            }
        }

        Item {
            id: desk
            anchors.fill: parent

            property Item glassBackdrop: Machine.glass ? backdrop.item : null

            // Esc puts back what was there when arranging began; Enter, or a click away from them,
            // keeps what's there now.
            Keys.onEscapePressed: Machine.stopArranging(false)
            Keys.onReturnPressed: Machine.stopArranging(true)
            Keys.onEnterPressed: Machine.stopArranging(true)

            Connections {
                target: Machine
                function onArrangingChanged(): void {
                    if (Machine.arranging)
                        desk.forceActiveFocus();
                }
            }

            // Arranging, the windows step back; a click away from the widgets is done.
            Rectangle {
                anchors.fill: parent
                z: -2
                visible: Machine.arranging
                color: Qt.rgba(0, 0, 0, 0.55)
                radius: Tokens.drawerRadius

                MouseArea {
                    anchors.fill: parent
                    onClicked: Machine.stopArranging(true)
                }
            }

            // A picture dropped from Files where there's no photo is a new one, where it fell.
            DropArea {
                id: deskDrop

                readonly property point at: {
                    const spot = Desk.room(root.photoWidth, root.photoHeight, deskDrop.drag.x - root.photoWidth / 2, deskDrop.drag.y - root.photoHeight / 2,
                                           root.boxes(null), { w: desk.width, h: desk.height }, root.spacing, root.cell);
                    return Qt.point(spot.x, spot.y);
                }

                anchors.fill: parent
                z: -1
                onEntered: drag => drag.accepted = root.picture(drag)
                onDropped: drop => {
                    Machine.setPhoto(decodeURIComponent(drop.urls[0].toString().slice(7)), false, "", [deskDrop.at.x, deskDrop.at.y]);
                    drop.accept();
                }
            }

            Rectangle {
                visible: deskDrop.containsDrag
                x: deskDrop.at.x
                y: deskDrop.at.y
                width: root.photoWidth
                height: root.photoHeight
                radius: Tokens.drawerRadius
                color: "transparent"
                border.width: 1
                border.color: Tokens.ink
            }

            Card {
                id: clockCard
                widget: "clock"

                DotText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                    font.pixelSize: 84
                }

                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: Case.sentence(clock.date.toLocaleString(Qt.locale(Lang.locale), Lang.dayName))
                    color: Tokens.dim
                    font.pixelSize: 12
                }

                Txt {
                    Layout.alignment: Qt.AlignHCenter
                    text: clock.date.toLocaleString(Qt.locale(Lang.locale), Lang.dateShort)
                    color: Tokens.muted
                    font.pixelSize: 13
                }
            }

            Card {
                id: networkCard
                widget: "network"
                free: true
                least: Qt.size(240, 112)

                NetRates {}

                DotScope {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: 40
                    series: SysStats.rxHistory
                    secondary: SysStats.txHistory
                }
            }

            // The month, a dot under each day with something on it, and what comes next.
            Card {
                id: calendarCard
                widget: "calendar"
                free: true
                least: Qt.size(280, calendarCard.listTop + 36)

                readonly property date now: clock.date
                readonly property int year: calendarCard.now.getFullYear()
                readonly property int month: calendarCard.now.getMonth()
                readonly property int today: calendarCard.now.getDate()
                readonly property int first: Qt.locale(Lang.locale).firstDayOfWeek
                readonly property var days: Calendar.month(calendarCard.year, calendarCard.month, calendarCard.first)
                readonly property var busy: Calendar.busy(calendarCard.year, calendarCard.month)
                // As it comes, three of what comes next; made taller, as many as fit.
                readonly property real listTop: 20 + monthGrid.y + monthGrid.height + 12
                readonly property int rows: calendarCard.shaped ? Math.max(1, Math.floor((calendarCard.height - 20 - calendarCard.listTop + 6) / 22)) : 3
                readonly property var next: Calendar.upcoming(calendarCard.now.getTime() / 1000, calendarCard.rows)
                readonly property real cell: ((calendarCard.free ? calendarCard.width : calendarCard.base) - 44) / 7

                Label {
                    text: Case.sentence(Qt.locale(Lang.locale).standaloneMonthName(calendarCard.month, Locale.LongFormat))
                        + " " + calendarCard.year
                }

                Grid {
                    id: monthGrid
                    Layout.topMargin: 4
                    columns: 7

                    Repeater {
                        model: 7

                        Item {
                            id: weekday

                            required property int index

                            width: calendarCard.cell
                            height: 18

                            Txt {
                                anchors.centerIn: parent
                                text: Case.sentence(Qt.locale(Lang.locale).dayName((calendarCard.first + weekday.index) % 7, Locale.NarrowFormat))
                                color: Tokens.muted
                                font.pixelSize: 11
                            }
                        }
                    }

                    Repeater {
                        model: 42

                        Item {
                            id: date

                            required property int index
                            readonly property var day: calendarCard.days[date.index]
                            readonly property bool isToday: date.day.inMonth && date.day.d === calendarCard.today

                            width: calendarCard.cell
                            height: 30
                            // A sixth week of nothing but the next month's days isn't drawn.
                            visible: date.index < 35 || calendarCard.days[35].inMonth

                            Rectangle {
                                anchors.centerIn: parent
                                anchors.verticalCenterOffset: -2
                                width: 24
                                height: 24
                                radius: 12
                                visible: date.isToday
                                color: Tokens.ink
                            }

                            Txt {
                                anchors.centerIn: parent
                                anchors.verticalCenterOffset: -2
                                text: date.day.d
                                color: date.isToday ? Tokens.black : date.day.inMonth ? Tokens.ink : Tokens.off
                                font.pixelSize: 12
                            }

                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 1
                                width: 4
                                height: 4
                                radius: 2
                                visible: date.day.inMonth && calendarCard.busy[date.day.d] === true
                                color: Tokens.dim
                            }
                        }
                    }
                }

                // What comes next, or where the calendars go; below, what room is left.
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.topMargin: 6
                    spacing: 6

                    Repeater {
                        model: calendarCard.next

                        RowLayout {
                            id: coming

                            required property var modelData

                            Layout.fillWidth: true
                            spacing: 12

                            Txt {
                                Layout.preferredWidth: 96
                                text: Calendar.when(coming.modelData, calendarCard.now.getTime() / 1000)
                                color: Tokens.dim
                                font.pixelSize: 12
                            }

                            Txt {
                                Layout.fillWidth: true
                                text: Calendar.title(coming.modelData)
                                font.pixelSize: 12
                            }
                        }
                    }

                    Txt {
                        visible: calendarCard.next.length === 0
                        text: Calendar.any ? Lang.calNothing : Lang.widgetCalendarNone
                        color: Tokens.muted
                        font.pixelSize: 12
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }
            }

            // How the computer is: the processor, the memory, its temperature and the system's disk.
            Card {
                id: systemCard
                widget: "system"

                Gauge {
                    name: "CPU"
                    value: SysStats.cpu
                    reading: Lang.percent.arg(Math.round(SysStats.cpu * 100))
                }

                Gauge {
                    name: "RAM"
                    value: SysStats.mem
                    reading: Lang.percent.arg(Math.round(SysStats.mem * 100))
                }

                Gauge {
                    name: "°C"
                    value: Math.min(1, SysStats.temp / 100)
                    reading: Math.round(SysStats.temp) + "°"
                    alert: SysStats.temp >= 90
                }

                Gauge {
                    name: Lang.widgetSystemDisk
                    value: SysStats.disk
                    reading: Lang.percent.arg(Math.round(SysStats.disk * 100))
                }
            }

            Card {
                id: mediaCard
                widget: "media"

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 14

                    DotScreen {
                        Layout.preferredWidth: 64
                        Layout.preferredHeight: 64
                        source: Media.art
                        pitch: 4
                        radius: 12
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Label { text: Case.sentence(Media.player) || Lang.media }

                        Txt {
                            Layout.fillWidth: true
                            text: Media.title
                            font.weight: Font.Medium
                        }

                        Txt {
                            Layout.fillWidth: true
                            text: Media.artist
                            color: Tokens.dim
                            font.pixelSize: 12
                            visible: text !== ""
                        }
                    }
                }

                DotMeter {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 100
                    count: Math.max(8, Math.floor((width + 3) / 7))
                    dot: 4
                    gap: 3
                    value: Media.progress
                }

                RowLayout {
                    Layout.fillWidth: true

                    Label { text: Media.shown(Media.position) + " / " + Media.shown(Media.length) }
                    Item { Layout.fillWidth: true }

                    MediaKeys { size: 28 }
                }
            }

            // The weather where it was told: now, today's highest and lowest, and the days after.
            Card {
                id: weatherCard
                widget: "weather"

                readonly property var forecast: Weather.current ? Weather.forecast : null
                readonly property var today: weatherCard.forecast?.days[0] ?? null

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Label {
                        text: Weather.placed && Weather.where.name ? Weather.where.name : Lang.cfgWidgetWeather
                    }

                    Item { Layout.fillWidth: true }

                    Txt {
                        text: weatherCard.forecast !== null ? Weather.skyName(weatherCard.forecast.now.code)
                            : !Weather.placed ? Lang.widgetWeatherNoPlace : Weather.failed ? Lang.widgetWeatherFailed : ""
                        color: Tokens.dim
                        font.pixelSize: 12
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    visible: weatherCard.forecast !== null
                    spacing: 14

                    Ico {
                        glyph: Weather.icon(weatherCard.forecast?.now.code ?? -1, weatherCard.forecast?.now.day ?? true)
                        color: Tokens.ink
                        font.pixelSize: 40
                    }

                    DotText {
                        text: Weather.degrees(weatherCard.forecast?.now.temp ?? 0)
                        font.pixelSize: 64
                    }

                    Item { Layout.fillWidth: true }

                    ColumnLayout {
                        visible: weatherCard.today !== null
                        spacing: 2

                        Txt {
                            Layout.alignment: Qt.AlignRight
                            text: Weather.degrees(weatherCard.today?.max ?? 0)
                        }

                        Txt {
                            Layout.alignment: Qt.AlignRight
                            text: Weather.degrees(weatherCard.today?.min ?? 0)
                            color: Tokens.dim
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 6
                    visible: weatherCard.forecast !== null
                    spacing: 0

                    Repeater {
                        model: (weatherCard.forecast?.days ?? []).slice(1, 4)

                        ColumnLayout {
                            id: ahead

                            required property var modelData

                            Layout.fillWidth: true
                            spacing: 4

                            Label {
                                Layout.alignment: Qt.AlignHCenter
                                text: Case.sentence(new Date(ahead.modelData.date + "T12:00:00").toLocaleString(Qt.locale(Lang.locale), "ddd"))
                            }

                            Ico {
                                Layout.alignment: Qt.AlignHCenter
                                glyph: Weather.icon(ahead.modelData.code, true)
                                font.pixelSize: 18
                            }

                            Row {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 6

                                Txt {
                                    text: Weather.degrees(ahead.modelData.max)
                                    font.pixelSize: 12
                                }

                                Txt {
                                    text: Weather.degrees(ahead.modelData.min)
                                    color: Tokens.dim
                                    font.pixelSize: 12
                                }
                            }
                        }
                    }
                }
            }

            // Pictures of one's own, in dots, as many as wanted.
            Repeater {
                id: photos
                model: Machine.photos

                Card {
                    id: photoCard

                    required property string modelData

                    widget: photoCard.modelData
                    free: true
                    least: Qt.size(160, 120)

                    DotScreen {
                        id: photo
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredHeight: 208
                        source: Machine.photoUrl(photoCard.modelData)
                        pitch: 4
                        radius: 12

                        Txt {
                            anchors.centerIn: parent
                            width: parent.width - 48
                            visible: photo.status === Image.Null || photo.status === Image.Error
                            text: Lang.widgetPhotoHow
                            color: Tokens.dim
                            font.pixelSize: 13
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            elide: Text.ElideNone
                        }

                        // A picture from Files, in place of the one it has.
                        DropArea {
                            id: dropping
                            anchors.fill: parent
                            onEntered: drag => drag.accepted = root.picture(drag)
                            onDropped: drop => {
                                Machine.setPhoto(decodeURIComponent(drop.urls[0].toString().slice(7)), false, photoCard.modelData, null);
                                drop.accept();
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            visible: dropping.containsDrag
                            color: "transparent"
                            radius: photo.radius
                            border.width: 1
                            border.color: Tokens.ink
                        }
                    }
                }
            }

            // Notes of one's own, as many as wanted: Markdown, written with the pencil.
            Repeater {
                id: notes
                model: Machine.notes

                Card {
                    id: noteCard

                    required property string modelData
                    readonly property string text: Machine.widgetOptions[noteCard.modelData]?.text ?? ""

                    widget: noteCard.modelData
                    base: 280
                    free: true
                    least: Qt.size(200, 120)

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Item {
                            Layout.fillWidth: true
                        }

                        CircleButton {
                            size: 26
                            glyph: Icons.plus
                            label: Lang.noteAnother
                            onClicked: root.noteBeside(noteCard)
                        }

                        CircleButton {
                            size: 26
                            glyph: Icons.pencil
                            label: Lang.noteWrite
                            onClicked: root.write(noteCard.modelData)
                        }
                    }

                    Text {
                        id: noteText
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredHeight: 96
                        text: Markdown.html(noteCard.text, root.noteVoices)
                        textFormat: Text.RichText
                        wrapMode: Text.Wrap
                        color: Tokens.ink
                        font.family: Tokens.fontSans
                        font.pixelSize: 13
                        clip: true
                        onLinkActivated: link => root.followNote(noteCard.modelData, link)

                        HoverHandler {
                            cursorShape: noteText.hoveredLink !== "" ? Qt.PointingHandCursor : Qt.ArrowCursor
                        }
                    }
                }
            }

            // A year of GitHub contributions, a dot a day: the more, the brighter.
            Card {
                id: githubCard
                widget: "github"

                readonly property int weeks: 53
                readonly property int pitch: 8
                readonly property int dot: 5
                readonly property string today: Qt.formatDate(clock.date, "yyyy-MM-dd")
                readonly property var cells: Contributions.cells(githubCard.weeks, Qt.locale(Lang.locale).firstDayOfWeek, githubCard.today)
                // Off, then lit a step at a time to full.
                readonly property var shades: [0, 0.3, 0.52, 0.75, 1].map(f => Qt.tint(Tokens.off, Qt.rgba(Tokens.ink.r, Tokens.ink.g, Tokens.ink.b, f)))

                // A year of weeks side by side, as GitHub has it.
                base: 44 + githubCard.weeks * githubCard.pitch - (githubCard.pitch - githubCard.dot)

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Label {
                        text: Contributions.user !== "" ? Contributions.user : Lang.cfgWidgetGithub
                    }

                    Item { Layout.fillWidth: true }

                    Txt {
                        text: !Contributions.valid(Contributions.user) ? Lang.widgetGithubNoUser
                            : Contributions.current && Contributions.total === 1 ? Lang.widgetGithubTotalOne
                            : Contributions.current && Contributions.total >= 0
                                ? Lang.widgetGithubTotal.arg(Contributions.total.toLocaleString(Qt.locale(Lang.locale), "f", 0))
                            : Contributions.failed ? Lang.widgetGithubFailed : ""
                        color: Tokens.dim
                        font.pixelSize: 12
                    }
                }

                Item {
                    Layout.topMargin: 6
                    Layout.preferredWidth: githubCard.weeks * githubCard.pitch - (githubCard.pitch - githubCard.dot)
                    Layout.preferredHeight: 7 * githubCard.pitch - (githubCard.pitch - githubCard.dot)

                    Repeater {
                        model: githubCard.weeks * 7

                        Rectangle {
                            required property int index
                            readonly property int level: githubCard.cells[index] ?? 0

                            x: Math.floor(index / 7) * githubCard.pitch
                            y: index % 7 * githubCard.pitch
                            width: githubCard.dot
                            height: githubCard.dot
                            radius: githubCard.dot / 2
                            visible: level >= 0
                            color: githubCard.shades[Math.max(0, level)]
                        }
                    }
                }
            }

            // Where a card dropped is taken away: turned off, or, a photo or a note, gone.
            Surface {
                id: bin

                readonly property bool hot: root.cards().some(card => card.binned)

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 20
                z: 0.5
                visible: Machine.arranging
                width: 56
                height: 56
                radius: 28
                scale: bin.hot ? 1.2 : 1
                color: Tokens.black
                border.width: 1
                border.color: bin.hot ? Tokens.ink : Tokens.line
                Accessible.name: Lang.widgetsRemove

                Behavior on scale { NumberAnimation { duration: Tokens.animFast; easing.type: Easing.OutCubic } }

                Ico {
                    anchors.centerIn: parent
                    glyph: Icons.close
                    font.pixelSize: 24
                    color: bin.hot ? Tokens.ink : Tokens.dim
                }
            }
        }
    }

    // Writing a note: its sheet over the windows, where it is, with the keyboard until Esc, its
    // tick or a click away from it.
    PanelWindow {
        screen: root.target
        visible: root.target !== null && root.writing !== ""
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "nihil-note"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        exclusionMode: ExclusionMode.Ignore

        anchors { top: true; left: true; right: true; bottom: true }
        margins { top: root.deskTop; left: root.deskLeft; right: root.deskEdge; bottom: root.deskEdge }

        MouseArea {
            anchors.fill: parent
            onClicked: root.written()
        }

        Timer {
            id: saving
            interval: 800
            onTriggered: {
                if (root.writing !== "")
                    Machine.setWidgetOption(root.writing, "text", words.text);
            }
        }

        Surface {
            id: sheet

            readonly property Item note: root.cards().find(card => card.widget === root.writing) ?? null

            x: sheet.note?.x ?? 0
            y: sheet.note?.y ?? 0
            width: sheet.note?.width ?? 280
            height: sheet.note?.height ?? 168
            radius: Tokens.drawerRadius
            color: Tokens.black
            border.width: 1
            border.color: Tokens.ink

            // A click on it stays in it.
            MouseArea {
                anchors.fill: parent
                onClicked: words.forceActiveFocus()
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                anchors.leftMargin: 22
                anchors.rightMargin: 22
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true

                    Item {
                        Layout.fillWidth: true
                    }

                    CircleButton {
                        size: 26
                        glyph: Icons.check
                        label: Lang.noteDone
                        onClicked: root.written()
                    }
                }

                Flickable {
                    id: page
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentWidth: page.width
                    contentHeight: words.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds
                    clip: true

                    // What's being written stays in sight.
                    function follow(r: rect): void {
                        if (r.y < page.contentY)
                            page.contentY = r.y;
                        else if (r.y + r.height > page.contentY + page.height)
                            page.contentY = r.y + r.height - page.height;
                    }

                    TextEdit {
                        id: words
                        width: page.width
                        wrapMode: TextEdit.Wrap
                        textFormat: TextEdit.PlainText
                        color: Tokens.ink
                        selectionColor: Tokens.ink
                        selectedTextColor: Tokens.black
                        font.family: Tokens.fontMono
                        font.pixelSize: 13
                        selectByMouse: true
                        Keys.onEscapePressed: root.written()
                        onTextChanged: {
                            if (root.writing !== "")
                                saving.restart();
                        }
                        onCursorRectangleChanged: page.follow(words.cursorRectangle)
                    }
                }
            }
        }
    }
}

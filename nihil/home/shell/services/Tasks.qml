pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "TaskMerge.js" as TaskMerge

Singleton {
    id: root

    readonly property int columns: 3
    readonly property int maxLength: 160
    property var cards: []
    property var removed: ({})
    property real clock: 0
    readonly property string path: {
        const home = Quickshell.env("HOME") ?? "";
        const state = Quickshell.env("XDG_STATE_HOME") || (home + "/.local/state");
        return state + "/nihil/tasks.json";
    }

    function inColumn(column: int): var {
        return cards.filter(card => card.column === column);
    }

    function clean(text: string): string {
        return String(text ?? "").replace(/\s+/g, " ").trim().slice(0, maxLength);
    }

    function add(text: string): void {
        const typed = clean(text);
        if (typed === "" || cards.length >= TaskMerge.CARDS_MAX) return;
        const at = stamp();
        const todo = inColumn(0);
        cards = TaskMerge.ordered(cards.concat([{ id: newId(), text: typed, column: 0, textStamp: at, placeStamp: at,
            rank: TaskMerge.rankAt(todo, todo.length, at) }]));
        save();
    }

    function edit(id: string, text: string): void {
        const typed = clean(text);
        const card = cards.find(c => c.id === id);
        if (!card || typed === "" || typed === card.text) return;
        const at = stamp();
        cards = cards.map(c => c.id === id ? Object.assign({}, c, { text: typed, textStamp: at }) : c);
        save();
    }

    function move(id: string, column: int): void {
        const to = Math.max(0, Math.min(columns - 1, column));
        const card = cards.find(c => c.id === id);
        if (!card || card.column === to) return;
        place(id, to, inColumn(to).length);
    }

    function place(id: string, column: int, index: int): void {
        const to = Math.max(0, Math.min(columns - 1, column));
        const next = TaskMerge.place(cards, id, to, index, stamp());
        if (next === cards) return;
        cards = next;
        save();
    }

    function remove(id: string): void {
        forget(cards.filter(c => c.id === id));
    }

    function clearDone(): void {
        forget(cards.filter(c => c.column === columns - 1));
    }

    function forget(gone: var): void {
        if (gone.length === 0) return;
        const next = Object.assign({}, removed);
        gone.forEach(c => { next[c.id] = stamp(); });
        cards = cards.filter(c => !(c.id in next));
        removed = TaskMerge.newest(next);
        save();
    }

    function stamp(): real {
        clock = Math.max(Date.now(), clock + 1);
        return clock;
    }

    function newId(): string {
        return Date.now().toString(36) + Math.floor(Math.random() * 46656).toString(36);
    }

    function sync(board: var): var {
        const now = Date.now();
        const merged = TaskMerge.sync({ cards: cards, removed: removed }, board ?? {}, now);
        clock = Math.max(clock, Math.min(TaskMerge.latest(merged), now + TaskMerge.AHEAD));
        cards = merged.cards;
        removed = merged.removed;
        save();
        return { cards: cards, removed: removed, now: Date.now() };
    }

    property string written: ""

    function parse(text: string): void {
        if (text === written) return;
        let data;
        try { data = JSON.parse(text); } catch (e) { console.log("tasks: " + root.path + " is not valid JSON"); return; }
        const list = Array.isArray(data) ? data : data?.cards;
        if (!Array.isArray(list)) return;
        const loaded = list
            .filter(c => c && String(c.text ?? "").trim() !== "")
            .map((c, i) => {
                const id = String(c.id ?? "");
                const card = {
                    id: TaskMerge.usable(id) ? id : newId(),
                    text: String(c.text).trim().slice(0, maxLength),
                    column: Math.max(0, Math.min(columns - 1, Number(c.column) || 0)),
                    textStamp: Number(c.textStamp) || 0,
                    placeStamp: Number(c.placeStamp) || i
                };
                if (typeof c.rank === "number" && isFinite(c.rank)) card.rank = c.rank;
                return card;
            });
        const now = Date.now();
        const merged = TaskMerge.merge(TaskMerge.trusted({ cards: loaded, removed: data?.removed }, now), {}, now);
        cards = merged.cards;
        removed = merged.removed;
        clock = Math.max(clock, Math.min(TaskMerge.latest(merged), now + TaskMerge.AHEAD));
    }

    function save(): void { saver.restart(); }

    FileView {
        id: file
        path: root.path
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.parse(text())
    }

    // The deck's boards, read here at once: see syncFile.
    FileView {
        id: incoming
        blockLoading: true
        printErrors: false
    }

    Timer {
        id: saver
        interval: 250
        onTriggered: {
            root.written = JSON.stringify({ version: 3, cards: root.cards, removed: root.removed }, null, 2) + "\n";
            file.setText(root.written);
        }
    }

    IpcHandler {
        target: "tasks"

        function add(text: string): void { root.add(text); }
        function list(): string {
            return root.cards.map(c => ["[ ]", "[~]", "[x]"][c.column] + " " + c.text).join("\n");
        }
        function state(): string {
            return JSON.stringify({ cards: root.cards, removed: root.removed, now: Date.now() });
        }
        function sync(json: string): string {
            let board;
            try { board = JSON.parse(json); } catch (e) { return ""; }
            return JSON.stringify(root.sync(board));
        }
        // The deck's board, from a file of this user's: as an argument it couldn't pass 128 KiB.
        function syncFile(path: string): string {
            const runtime = Quickshell.env("XDG_RUNTIME_DIR") ?? "";
            if (runtime === "" || !path.startsWith(runtime + "/nihil-deck-tasks-") || path.includes("/../")) return "";
            incoming.path = path;
            incoming.reload();
            const text = incoming.text();
            incoming.path = "";
            let board;
            try { board = JSON.parse(text); } catch (e) { return ""; }
            return JSON.stringify(root.sync(board));
        }
    }
}

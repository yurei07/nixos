pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Wallpaper switcher: cycles the Nothing compositions through awww/swww and
// remembers the last one in the shell's state dir.
// IPC: qs ipc -c nothing call wallpaper next|set <index>|get
Singleton {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/Pictures/wallpapers/nothing"
    // Nothing set, dark, 1920x1080: shapes, glyph, dots, stripes, arc
    readonly property var set: [
        "nothing-01-shapes-dark-1920x1080.png",
        "nothing-02-glyph-dark-1920x1080.png",
        "nothing-03-dots-dark-1920x1080.png",
        "nothing-04-stripes-dark-1920x1080.png",
        "nothing-05-arc-dark-1920x1080.png"
    ]
    property int current: 1 // glyph, like NothingWallpaperApply.sh's laptop pick

    function apply() {
        const img = dir + "/" + set[current];
        Quickshell.execDetached(["sh", "-c",
            `for _ in $(seq 1 40); do awww query >/dev/null 2>&1 && break || swww query >/dev/null 2>&1 && break; sleep 0.25; done; ` +
            `awww img -o eDP-1 '${img}' --transition-type fade --transition-duration 0.6 2>/dev/null || swww img -o eDP-1 '${img}' --transition-type fade --transition-duration 0.6; ` +
            `ln -sfn '${img}' '$HOME/.config/rofi/.current_wallpaper'`
        ]);
    }

    function next() {
        current = (current + 1) % set.length;
        apply();
    }

    function setWallpaper(i) {
        if (i >= 0 && i < set.length) {
            current = i;
            apply();
        }
    }

    FileView {
        path: Quickshell.statePath("wallpaper.json")
        watchChanges: false
        onLoaded: {
            try {
                const v = JSON.parse(text()).current;
                if (typeof v === "number")
                    root.current = Math.max(0, Math.min(root.set.length - 1, v));
            } catch (e) {}
        }
        onAdapterUpdated: writeAdapter()
        onLoadFailed: writeAdapter()

        JsonAdapter {
            id: store

            property int current: 1
        }
    }

    // keep `current` and the stored value in sync
    onCurrentChanged: store.current = current
}

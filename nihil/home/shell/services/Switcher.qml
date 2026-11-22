pragma Singleton

import QtQuick
import Quickshell

// The drawers gone through with their key held: the workspaces and the wallpapers.
Singleton {
    readonly property Held overview: Held {
        name: "overview"
        what: "all the workspaces"
    }

    readonly property Held wallpapers: Held {
        name: "wallpapers"
        what: "the wallpapers"
    }
}

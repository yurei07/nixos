//@ pragma UseQApplication
//@ pragma IconTheme @ICON_THEME@
//@ pragma Env QT_QPA_PLATFORM=wayland
//@ pragma Env QSG_DISTANCEFIELD_ANTIALIASING=gray

import QtQuick
import Quickshell
import qs.services
import qs.frame
import qs.background
import qs.settings

ShellRoot {
    readonly property var services: [Drawers, Osd, Glyph, Notifs, Battery, Audio, Network, Bt, Nilo, Machine, Clipboard, Updates, Apps, Media, Recorder, Downloads, Switcher, Vector]

    Variants {
        model: Quickshell.screens

        Frame {}
    }

    Desktop {}

    Preferences {}
}

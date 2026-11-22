pragma Singleton

import Quickshell
import qs.config

Singleton {
    function play(file: string, volume: real): void {
        if (file)
            Quickshell.execDetached([Config.cmd.pwPlay, "--volume", String(volume), file]);
    }
}

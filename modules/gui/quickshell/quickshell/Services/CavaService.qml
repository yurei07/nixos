pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property var values: Array(barsCount).fill(0)
  property int barsCount: 20

  property var config: ({
                          "general": {
                            "bars": barsCount,
                            "framerate": 60,
                            "autosens": 0,
                            "overshoot": 0,
                            "sensitivity": 200,
                            "lower_cutoff_freq": 50,
                            "higher_cutoff_freq": 12000
                          },
                          "smoothing": {
                            "monstercat": 0,
                            "noise_reduction": 77
                          },
                          "output": {
                            "method": "raw",
                            "data_format": "ascii",
                            "ascii_max_range": 100,
                            "bit_format": "8bit",
                            "channels": "mono",
                            "mono_option": "average"
                          }
                        })

  Process {
    id: process
    stdinEnabled: true
    running: MediaService.isPlaying
    command: ["cava", "-p", "/dev/stdin"]
    onExited: {
      stdinEnabled = true
      values = Array(barsCount).fill(0)
    }
    onStarted: {
      for (const k in config) {
        if (typeof config[k] !== "object") {
          write(k + "=" + config[k] + "\n")
          continue
        }
        write("[" + k + "]\n")
        const obj = config[k]
        for (const k2 in obj) {
          write(k2 + "=" + obj[k2] + "\n")
        }
      }
      stdinEnabled = false
      values = Array(barsCount).fill(0)
    }
    stdout: SplitParser {
      onRead: data => {
        root.values = data.slice(0, -1).split(";").map(v => parseInt(v, 10) / 100)
      }
    }
  }
}

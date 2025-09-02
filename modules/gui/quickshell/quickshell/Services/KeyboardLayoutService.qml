pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.Commons
import qs.Services

Singleton {
  id: root

  property string currentLayout: "Unknown"
  property int updateInterval: 1000 // Update every second

  // Timer to periodically update the layout
  Timer {
    id: updateTimer
    interval: updateInterval
    running: true
    repeat: true
    onTriggered: {
      updateLayout()
    }
  }

  // Process to get current keyboard layout using niri msg (Wayland native)
  Process {
    id: niriLayoutProcess
    running: false
    command: ["niri", "msg", "-j", "keyboard-layouts"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          const data = JSON.parse(text)
          const layoutName = data.names[data.current_idx]
          root.currentLayout = mapLayoutNameToCode(layoutName)
        } catch (e) {
          root.currentLayout = "Unknown"
        }
      }
    }
  }

  // Process to get current keyboard layout using hyprctl (Hyprland)
  Process {
    id: hyprlandLayoutProcess
    running: false
    command: ["hyprctl", "-j", "devices"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          const data = JSON.parse(text)
          // Find the main keyboard and get its active keymap
          const mainKeyboard = data.keyboards.find(kb => kb.main === true)
          if (mainKeyboard && mainKeyboard.active_keymap) {
            root.currentLayout = mapLayoutNameToCode(mainKeyboard.active_keymap)
          } else {
            root.currentLayout = "Unknown"
          }
        } catch (e) {
          root.currentLayout = "Unknown"
        }
      }
    }
  }

  // Layout name to ISO code mapping
  property var layoutMap: {
    "German": "de",
    "English (US)": "us",
    "English (UK)": "gb",
    "French": "fr",
    "Spanish": "es",
    "Italian": "it",
    "Portuguese (Brazil)": "br",
    "Portuguese": "pt",
    "Russian": "ru",
    "Polish": "pl",
    "Swedish": "se",
    "Norwegian": "no",
    "Danish": "dk",
    "Finnish": "fi",
    "Hungarian": "hu",
    "Turkish": "tr",
    "Czech": "cz",
    "Slovak": "sk",
    "Japanese": "jp",
    "Korean": "kr",
    "Chinese": "cn"
  }

  // Map layout names to ISO codes
  function mapLayoutNameToCode(layoutName) {
    return layoutMap[layoutName] || layoutName // fallback to raw name if not found
  }

  Component.onCompleted: {
    Logger.log("KeyboardLayout", "Service started")
    updateLayout()
  }

  function updateLayout() {
    if (CompositorService.isHyprland) {
      hyprlandLayoutProcess.running = true
    } else if (CompositorService.isNiri) {
      niriLayoutProcess.running = true
    } else {
      currentLayout = "Unknown"
    }
  }
}

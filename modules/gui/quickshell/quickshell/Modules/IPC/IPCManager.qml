import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Services

Item {
  id: root

  IpcHandler {
    target: "screenRecorder"
    function toggle() {
      if (ScreenRecorderService.isAvailable) {
        ScreenRecorderService.toggleRecording()
      }
    }
  }

  IpcHandler {
    target: "settings"
    function toggle() {
      settingsPanel.toggle()
    }
  }

  IpcHandler {
    target: "notifications"
    function toggleHistory() {
      notificationHistoryPanel.toggle()
    }
    function toggleDND() {
      Settings.data.notifications.doNotDisturb = !Settings.data.notifications.doNotDisturb
    }
  }

  IpcHandler {
    target: "idleInhibitor"
    function toggle() {
      return IdleInhibitorService.manualToggle()
    }
  }

  IpcHandler {
    target: "launcher"
    function toggle() {
      launcherPanel.toggle()
    }
    function clipboard() {
      launcherPanel.setSearchText(">clip ")
      launcherPanel.toggle()
    }
    function calculator() {
      launcherPanel.setSearchText(">calc ")
      launcherPanel.toggle()
    }
  }

  IpcHandler {
    target: "lockScreen"
    function toggle() {
      // Only lock if not already locked (prevents the red screen issue)
      // Note: No unlock via IPC for security reasons
      if (!lockScreen.active) {
        lockScreen.active = true
      }
    }
  }

  IpcHandler {
    target: "brightness"
    function increase() {
      BrightnessService.increaseBrightness()
    }
    function decrease() {
      BrightnessService.decreaseBrightness()
    }
  }

  IpcHandler {
    target: "darkMode"
    function toggle() {
      Settings.data.colorSchemes.darkMode = !Settings.data.colorSchemes.darkMode
    }
    function setDark() {
      Settings.data.colorSchemes.darkMode = true
    }
    function setLight() {
      Settings.data.colorSchemes.darkMode = false
    }
  }

  IpcHandler {
    target: "volume"
    function increase() {
      AudioService.increaseVolume()
    }
    function decrease() {
      AudioService.decreaseVolume()
    }
    function muteOutput() {
      AudioService.setMuted(!AudioService.muted)
    }
    function muteInput() {
      if (AudioService.source?.ready && AudioService.source?.audio) {
        AudioService.source.audio.muted = !AudioService.source.audio.muted
      }
    }
  }

  IpcHandler {
    target: "powerPanel"
    function toggle() {
      powerPanel.toggle()
    }
  }

  IpcHandler {
    target: "sidePanel"
    function toggle() {
      sidePanel.toggle()
    }
  }

  // Wallpaper IPC: trigger a new random wallpaper
  IpcHandler {
    target: "wallpaper"
    function random() {
      if (Settings.data.wallpaper.enabled) {
        WallpaperService.setRandomWallpaper()
      }
    }

    function set(path: string, screen: string) {
      if (screen === "all" || screen === "") {
        screen = undefined
      }
      WallpaperService.changeWallpaper(path, screen)
    }
  }
}

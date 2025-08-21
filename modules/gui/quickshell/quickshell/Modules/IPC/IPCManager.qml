import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services

Item {
  id: root

  IpcHandler {
    target: "settings"

    function toggle() {
      settingsPanel.toggle(Quickshell.screens[0])
    }
  }

  IpcHandler {
    target: "notifications"

    function toggleHistory() {
      notificationHistoryPanel.toggle(Quickshell.screens[0])
    }

    function toggleDoNotDisturb() {// TODO
    }
  }

  IpcHandler {
    target: "idleInhibitor"

    function toggle() {
      return IdleInhibitorService.manualToggle()
    }
  }

  IpcHandler {
    target: "appLauncher"

    function toggle() {
      appLauncherPanel.toggle(Quickshell.screens[0])
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
}

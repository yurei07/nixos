import QtQuick
import Quickshell
import qs.Commons
import qs.Modules.SettingsPanel
import qs.Services
import qs.Widgets

Item {
  id: root

  width: pill.width
  height: pill.height
  visible: Settings.data.bar.showBrightness && firstBrightnessReceived

  // Used to avoid opening the pill on Quickshell startup
  property bool firstBrightnessReceived: false

  function getIcon() {
    var brightness = BrightnessService.getMonitorForScreen(screen).brightness
    return brightness <= 0 ? "brightness_1" : brightness < 0.33 ? "brightness_low" : brightness
                                                                  < 0.66 ? "brightness_medium" : "brightness_high"
  }

  // Connection used to open the pill when brightness changes
  Connections {
    target: BrightnessService.getMonitorForScreen(screen)
    function onBrightnessUpdated() {
      Logger.log("Bar-Brightness", "OnBrightnessUpdated")

      var monitor = BrightnessService.getMonitorForScreen(screen)
      var currentBrightness = monitor.brightness

      // Ignore if this is the first time or if brightness hasn't actually changed
      if (!firstBrightnessReceived) {
        firstBrightnessReceived = true
        monitor.lastBrightness = currentBrightness
        return
      }

      // Only show pill if brightness actually changed (not just loaded from settings)
      if (Math.abs(currentBrightness - monitor.lastBrightness) > 0.1) {
        pill.show()
      }

      monitor.lastBrightness = currentBrightness
    }
  }

  NPill {
    id: pill
    icon: getIcon()
    iconCircleColor: Color.mPrimary
    collapsedIconColor: Color.mOnSurface
    autoHide: false // Important to be false so we can hover as long as we want
    text: Math.round(BrightnessService.getMonitorForScreen(screen).brightness * 100) + "%"
    tooltipText: {
      var monitor = BrightnessService.getMonitorForScreen(screen)
      return "Brightness: " + Math.round(monitor.brightness * 100) + "%\nMethod: " + monitor.method
          + "\nLeft click for advanced settings.\nScroll up/down to change brightness."
    }

    onWheel: function (angle) {
      var monitor = BrightnessService.getMonitorForScreen(screen)
      if (angle > 0) {
        monitor.increaseBrightness()
      } else if (angle < 0) {
        monitor.decreaseBrightness()
      }
    }

    onClicked: {
      settingsPanel.requestedTab = SettingsPanel.Tab.Brightness
      settingsPanel.isLoaded = true
    }
  }
}

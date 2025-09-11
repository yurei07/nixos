import QtQuick
import Quickshell
import qs.Commons
import qs.Modules.SettingsPanel
import qs.Services
import qs.Widgets

Item {
  id: root

  property ShellScreen screen
  property real scaling: 1.0

  // Widget properties passed from Bar.qml for per-instance settings
  property string widgetId: ""
  property string barSection: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0

  property var widgetMetadata: BarWidgetRegistry.widgetMetadata[widgetId]
  property var widgetSettings: {
    var section = barSection.replace("Section", "").toLowerCase()
    if (section && sectionWidgetIndex >= 0) {
      var widgets = Settings.data.bar.widgets[section]
      if (widgets && sectionWidgetIndex < widgets.length) {
        return widgets[sectionWidgetIndex]
      }
    }
    return {}
  }

  readonly property bool userAlwaysShowPercentage: (widgetSettings.alwaysShowPercentage
                                                    !== undefined) ? widgetSettings.alwaysShowPercentage : widgetMetadata.alwaysShowPercentage

  // Used to avoid opening the pill on Quickshell startup
  property bool firstBrightnessReceived: false

  implicitWidth: pill.width
  implicitHeight: pill.height
  visible: getMonitor() !== null

  function getMonitor() {
    return BrightnessService.getMonitorForScreen(screen) || null
  }

  function getIcon() {
    var monitor = getMonitor()
    var brightness = monitor ? monitor.brightness : 0
    return brightness <= 0.5 ? "brightness-low" : "brightness-high"
  }

  // Connection used to open the pill when brightness changes
  Connections {
    target: getMonitor()
    ignoreUnknownSignals: true
    function onBrightnessUpdated() {
      // Ignore if this is the first time we receive an update.
      // Most likely service just kicked off.
      if (!firstBrightnessReceived) {
        firstBrightnessReceived = true
        return
      }

      pill.show()
      hideTimerAfterChange.restart()
    }
  }

  Timer {
    id: hideTimerAfterChange
    interval: 2500
    running: false
    repeat: false
    onTriggered: pill.hide()
  }

  NPill {
    id: pill

    rightOpen: BarWidgetRegistry.getNPillDirection(root)
    icon: getIcon()
    autoHide: false // Important to be false so we can hover as long as we want
    text: {
      var monitor = getMonitor()
      return monitor ? (Math.round(monitor.brightness * 100) + "%") : ""
    }
    forceOpen: userAlwaysShowPercentage
    tooltipText: {
      var monitor = getMonitor()
      if (!monitor)
        return ""
      return "Brightness: " + Math.round(monitor.brightness * 100) + "%\nMethod: " + monitor.method
          + "\nLeft click for advanced settings.\nScroll up/down to change brightness."
    }

    onWheel: function (angle) {
      var monitor = getMonitor()
      if (!monitor)
        return
      if (angle > 0) {
        monitor.increaseBrightness()
      } else if (angle < 0) {
        monitor.decreaseBrightness()
      }
    }

    onClicked: {
      var settingsPanel = PanelService.getPanel("settingsPanel")
      settingsPanel.requestedTab = SettingsPanel.Tab.Brightness
      settingsPanel.open()
    }
  }
}

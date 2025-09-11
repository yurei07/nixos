import QtQuick
import Quickshell
import Quickshell.Services.UPower
import QtQuick.Layouts
import qs.Commons
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

  // Resolve settings: try user settings or defaults from BarWidgetRegistry
  readonly property bool alwaysShowPercentage: widgetSettings.alwaysShowPercentage
                                               !== undefined ? widgetSettings.alwaysShowPercentage : widgetMetadata.alwaysShowPercentage
  readonly property real warningThreshold: widgetSettings.warningThreshold
                                           !== undefined ? widgetSettings.warningThreshold : widgetMetadata.warningThreshold

  // Test mode
  readonly property bool testMode: false
  readonly property int testPercent: 90
  readonly property bool testCharging: false

  // Main properties
  readonly property var battery: UPower.displayDevice
  readonly property bool isReady: testMode ? true : (battery && battery.ready && battery.isLaptopBattery
                                                     && battery.isPresent)
  readonly property real percent: testMode ? testPercent : (isReady ? (battery.percentage * 100) : 0)
  readonly property bool charging: testMode ? testCharging : (isReady ? battery.state === UPowerDeviceState.Charging : false)
  property bool hasNotifiedLowBattery: false

  implicitWidth: pill.width
  implicitHeight: pill.height

  // Helper to evaluate and possibly notify
  function maybeNotify(percent, charging) {
    // Only notify once we are a below threshold
    if (!charging && !root.hasNotifiedLowBattery && percent <= warningThreshold) {
      root.hasNotifiedLowBattery = true
      ToastService.showWarning("Low Battery", `Battery is at ${Math.round(percent)}%. Please connect the charger.`)
    } else if (root.hasNotifiedLowBattery && (charging || percent > warningThreshold + 5)) {
      // Reset when charging starts or when battery recovers 5% above threshold
      root.hasNotifiedLowBattery = false
    }
  }

  // Watch for battery changes
  Connections {
    target: UPower.displayDevice
    function onPercentageChanged() {
      var currentPercent = UPower.displayDevice.percentage * 100
      var isCharging = UPower.displayDevice.state === UPowerDeviceState.Charging
      root.maybeNotify(currentPercent, isCharging)
    }

    function onStateChanged() {
      var isCharging = UPower.displayDevice.state === UPowerDeviceState.Charging
      // Reset notification flag when charging starts
      if (isCharging) {
        root.hasNotifiedLowBattery = false
      }
      // Also re-evaluate maybeNotify, as state might have changed
      var currentPercent = UPower.displayDevice.percentage * 100
      root.maybeNotify(currentPercent, isCharging)
    }
  }

  NPill {
    id: pill

    rightOpen: BarWidgetRegistry.getNPillDirection(root)
    icon: testMode ? BatteryService.getIcon(testPercent, testCharging, true) : BatteryService.getIcon(percent,
                                                                                                      charging, isReady)
    text: (isReady || testMode) ? Math.round(percent) + "%" : "-"
    autoHide: false
    forceOpen: isReady && (testMode || battery.isLaptopBattery) && alwaysShowPercentage
    disableOpen: (!isReady || (!testMode && !battery.isLaptopBattery))
    tooltipText: {
      let lines = []
      if (testMode) {
        lines.push(`Time left: ${Time.formatVagueHumanReadableDuration(12345)}.`)
        return lines.join("\n")
      }
      if (!isReady || !battery.isLaptopBattery) {
        return "No battery detected."
      }
      if (battery.timeToEmpty > 0) {
        lines.push(`Time left: ${Time.formatVagueHumanReadableDuration(battery.timeToEmpty)}.`)
      }
      if (battery.timeToFull > 0) {
        lines.push(`Time until full: ${Time.formatVagueHumanReadableDuration(battery.timeToFull)}.`)
      }
      if (battery.changeRate !== undefined) {
        const rate = battery.changeRate
        if (rate > 0) {
          lines.push(charging ? "Charging rate: " + rate.toFixed(2) + " W." : "Discharging rate: " + rate.toFixed(
                                  2) + " W.")
        } else if (rate < 0) {
          lines.push("Discharging rate: " + Math.abs(rate).toFixed(2) + " W.")
        } else {
          lines.push("Estimating...")
        }
      } else {
        lines.push(charging ? "Charging." : "Discharging.")
      }
      if (battery.healthPercentage !== undefined && battery.healthPercentage > 0) {
        lines.push("Health: " + Math.round(battery.healthPercentage) + "%")
      }
      return lines.join("\n")
    }
  }
}

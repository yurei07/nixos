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
  property string barSection: ""
  property int sectionWidgetIndex: 0
  property int sectionWidgetsCount: 0

  // Track if we've already notified to avoid spam
  property bool hasNotifiedLowBattery: false

  implicitWidth: pill.width
  implicitHeight: pill.height

  // Helper to evaluate and possibly notify
  function maybeNotify(percent, charging) {
    const p = Math.round(percent)
    // Only notify exactly at 15%, not at 0% or any other percentage
    if (!charging && p === 15 && !root.hasNotifiedLowBattery) {
      Quickshell.execDetached(
            ["notify-send", "-u", "critical", "-i", "battery-caution", "Low Battery", `Battery is at ${p}%. Please connect charger.`])
      root.hasNotifiedLowBattery = true
    }
    // Reset when charging starts or when battery recovers above 20%
    if (charging || p > 20) {
      root.hasNotifiedLowBattery = false
    }
  }

  // Watch for battery changes
  Connections {
    target: UPower.displayDevice
    function onPercentageChanged() {
      let battery = UPower.displayDevice
      let isReady = battery && battery.ready && battery.isLaptopBattery && battery.isPresent
      let percent = isReady ? (battery.percentage * 100) : 0
      let charging = isReady ? battery.state === UPowerDeviceState.Charging : false

      root.maybeNotify(percent, charging)
    }

    function onStateChanged() {
      let battery = UPower.displayDevice
      let isReady = battery && battery.ready && battery.isLaptopBattery && battery.isPresent
      let charging = isReady ? battery.state === UPowerDeviceState.Charging : false

      // Reset notification flag when charging starts
      if (charging) {
        root.hasNotifiedLowBattery = false
      }
    }
  }

  NPill {
    id: pill

    // Test mode
    property bool testMode: false
    property int testPercent: 20
    property bool testCharging: false
    property var battery: UPower.displayDevice
    property bool isReady: testMode ? true : (battery && battery.ready && battery.isLaptopBattery && battery.isPresent)
    property real percent: testMode ? testPercent : (isReady ? (battery.percentage * 100) : 0)
    property bool charging: testMode ? testCharging : (isReady ? battery.state === UPowerDeviceState.Charging : false)

    // Choose icon based on charge and charging state
    function batteryIcon() {
      if (!isReady || !battery.isLaptopBattery)
        return "battery_android_alert"
      if (charging)
        return "battery_android_bolt"
      if (percent >= 95)
        return "battery_android_full"
      // Hardcoded battery symbols
      if (percent >= 85)
        return "battery_android_6"
      if (percent >= 70)
        return "battery_android_5"
      if (percent >= 55)
        return "battery_android_4"
      if (percent >= 40)
        return "battery_android_3"
      if (percent >= 25)
        return "battery_android_2"
      if (percent >= 10)
        return "battery_android_1"
      if (percent >= 0)
        return "battery_android_0"
    }

    rightOpen: BarWidgetRegistry.getNPillDirection(root)
    icon: batteryIcon()
    text: ((isReady && battery.isLaptopBattery) || testMode) ? Math.round(percent) + "%" : "-"
    textColor: charging ? Color.mPrimary : Color.mOnSurface
    iconCircleColor: Color.mPrimary
    collapsedIconColor: Color.mOnSurface
    autoHide: false
    forceOpen: isReady && (testMode || battery.isLaptopBattery) && Settings.data.bar.alwaysShowBatteryPercentage
    disableOpen: (!isReady || (!testMode && !battery.isLaptopBattery))
    tooltipText: {
      let lines = []
      if (testMode) {
        lines.push("Time left: " + Time.formatVagueHumanReadableDuration(12345))
        return lines.join("\n")
      }
      if (!isReady || !battery.isLaptopBattery) {
        return "No battery detected"
      }
      if (battery.timeToEmpty > 0) {
        lines.push("Time left: " + Time.formatVagueHumanReadableDuration(battery.timeToEmpty))
      }
      if (battery.timeToFull > 0) {
        lines.push("Time until full: " + Time.formatVagueHumanReadableDuration(battery.timeToFull))
      }
      if (battery.changeRate !== undefined) {
        const rate = battery.changeRate
        if (rate > 0) {
          lines.push(charging ? "Charging rate: " + rate.toFixed(2) + " W" : "Discharging rate: " + rate.toFixed(
                                  2) + " W")
        } else if (rate < 0) {
          lines.push("Discharging rate: " + Math.abs(rate).toFixed(2) + " W")
        } else {
          lines.push("Estimating...")
        }
      } else {
        lines.push(charging ? "Charging" : "Discharging")
      }
      if (battery.healthPercentage !== undefined && battery.healthPercentage > 0) {
        lines.push("Health: " + Math.round(battery.healthPercentage) + "%")
      }
      return lines.join("\n")
    }
  }
}

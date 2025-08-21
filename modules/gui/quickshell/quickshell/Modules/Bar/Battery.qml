import QtQuick
import Quickshell
import Quickshell.Services.UPower
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

NPill {
  id: root

  // Test mode
  property bool testMode: false
  property int testPercent: 49
  property bool testCharging: false

  property var battery: UPower.displayDevice
  property bool isReady: testMode ? true : (battery && battery.ready && battery.isLaptopBattery && battery.isPresent)
  property real percent: testMode ? testPercent : (isReady ? (battery.percentage * 100) : 0)
  property bool charging: testMode ? testCharging : (isReady ? battery.state === UPowerDeviceState.Charging : false)
  property bool show: isReady && percent > 0

  // Choose icon based on charge and charging state
  function batteryIcon() {
    if (!show)
      return ""

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

  visible: testMode || (isReady && battery.isLaptopBattery)

  icon: root.batteryIcon()
  text: Math.round(root.percent) + "%"
  textColor: charging ? Color.mPrimary : Color.mOnSurface
  forceShown: Settings.data.bar.alwaysShowBatteryPercentage
  tooltipText: {
    let lines = []

    if (testMode) {
      lines.push("Time left: " + Time.formatVagueHumanReadableDuration(12345))
      return lines.join("\n")
    }

    if (!root.isReady) {
      return ""
    }

    if (root.battery.timeToEmpty > 0) {
      lines.push("Time left: " + Time.formatVagueHumanReadableDuration(root.battery.timeToEmpty))
    }

    if (root.battery.timeToFull > 0) {
      lines.push("Time until full: " + Time.formatVagueHumanReadableDuration(root.battery.timeToFull))
    }

    if (root.battery.changeRate !== undefined) {
      const rate = root.battery.changeRate
      if (rate > 0) {
        lines.push(root.charging ? "Charging rate: " + rate.toFixed(2) + " W" : "Discharging rate: " + rate.toFixed(2) + " W")
      } else if (rate < 0) {
        lines.push("Discharging rate: " + Math.abs(rate).toFixed(2) + " W")
      } else {
        lines.push("Estimating...")
      }
    } else {
      lines.push(root.charging ? "Charging" : "Discharging")
    }

    if (root.battery.healthPercentage !== undefined && root.battery.healthPercentage > 0) {
      lines.push("Health: " + Math.round(root.battery.healthPercentage) + "%")
    }
    return lines.join("\n")
  }
}

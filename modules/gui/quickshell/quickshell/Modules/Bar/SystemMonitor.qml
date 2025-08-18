import QtQuick
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

Row {
  id: layout
  anchors.verticalCenter: parent.verticalCenter
  spacing: Style.marginSmall * scaling
  visible: Settings.data.bar.showSystemInfo

  // Ensure our width is an integer
  width: Math.floor(cpuUsageLayout.width + cpuTempLayout.width + memoryUsageLayout.width + (2 * 10))

  Row {
    id: cpuUsageLayout
    spacing: Style.marginTiny * scaling

    NText {
      id: cpuUsageIcon
      text: "speed"
      font.family: "Material Symbols Outlined"
      font.pointSize: Style.fontSizeLarge * scaling
      verticalAlignment: Text.AlignVCenter
      anchors.verticalCenter: parent.verticalCenter
    }

    NText {
      id: cpuUsageText
      text: `${SystemStatService.cpuUsage}%`
      font.pointSize: Style.fontSizeReduced * scaling
      font.weight: Style.fontWeightBold
      anchors.verticalCenter: parent.verticalCenter
      verticalAlignment: Text.AlignVCenter
      color: Color.mPrimary
    }
  }

  // CPU Temperature Component
  Row {
    id: cpuTempLayout
    spacing: Style.marginTiny * scaling

    NText {
      text: "thermometer"
      font.family: "Material Symbols Outlined"
      font.pointSize: Style.fontSizeLarge * scaling

      verticalAlignment: Text.AlignVCenter
      anchors.verticalCenter: parent.verticalCenter
    }

    NText {
      text: `${SystemStatService.cpuTemp}°C`
      font.pointSize: Style.fontSizeReduced * scaling
      font.weight: Style.fontWeightBold
      anchors.verticalCenter: parent.verticalCenter
      verticalAlignment: Text.AlignVCenter
      color: Color.mPrimary
    }
  }

  // Memory Usage Component
  Row {
    id: memoryUsageLayout
    spacing: Style.marginTiny * scaling

    NText {
      text: "memory"
      font.family: "Material Symbols Outlined"
      font.pointSize: Style.fontSizeLarge * scaling
      verticalAlignment: Text.AlignVCenter
      anchors.verticalCenter: parent.verticalCenter
    }

    NText {
      text: `${SystemStatService.memoryUsageGb}G`
      font.pointSize: Style.fontSizeReduced * scaling
      font.weight: Style.fontWeightBold
      anchors.verticalCenter: parent.verticalCenter
      verticalAlignment: Text.AlignVCenter
      color: Color.mPrimary
    }
  }
}

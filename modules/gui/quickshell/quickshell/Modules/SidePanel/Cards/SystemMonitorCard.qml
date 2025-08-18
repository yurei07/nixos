import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

// Unified system card: monitors CPU, temp, memory, disk
NBox {
  id: root

  Layout.preferredWidth: Style.baseWidgetSize * 2.625 * scaling
  implicitHeight: content.implicitHeight + Style.marginTiny * 2 * scaling

  Column {
    id: content
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.leftMargin: Style.marginSmall * scaling
    anchors.rightMargin: Style.marginSmall * scaling
    anchors.topMargin: Style.marginTiny * scaling
    anchors.bottomMargin: Style.marginMedium * scaling
    spacing: Style.marginSmall * scaling

    // Slight top padding
    Item {
      height: Style.marginTiny * scaling
    }

    NCircleStat {
      value: SystemStatService.cpuUsage
      icon: "speed"
      flat: true
      contentScale: 0.8
      width: 72 * scaling
      height: 68 * scaling
    }
    NCircleStat {
      value: SystemStatService.cpuTemp
      suffix: "°C"
      icon: "device_thermostat"
      flat: true
      contentScale: 0.8
      width: 72 * scaling
      height: 68 * scaling
    }
    NCircleStat {
      value: SystemStatService.memoryUsagePer
      icon: "memory"
      flat: true
      contentScale: 0.8
      width: 72 * scaling
      height: 68 * scaling
    }
    NCircleStat {
      value: SystemStatService.diskUsage
      icon: "hard_drive"
      flat: true
      contentScale: 0.8
      width: 72 * scaling
      height: 68 * scaling
    }

    // Extra bottom padding to shift the perceived stack slightly upward
    Item {
      height: Style.marginMedium * scaling
    }
  }
}

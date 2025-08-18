import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import qs.Commons
import qs.Services
import qs.Widgets

// Power Profiles: performance, balanced, eco
NBox {
  Layout.fillWidth: true
  Layout.preferredWidth: 1
  implicitHeight: powerRow.implicitHeight + Style.marginMedium * 2 * scaling

  // PowerProfiles service
  property var powerProfiles: PowerProfiles
  readonly property bool hasPP: powerProfiles.hasPerformanceProfile

  RowLayout {
    id: powerRow
    anchors.fill: parent
    anchors.margins: Style.marginSmall * scaling
    spacing: sidePanel.cardSpacing
    Item {
      Layout.fillWidth: true
    }
    // Performance
    NIconButton {
      icon: "speed"
      tooltipText: "Set Performance Power Profile"
      enabled: hasPP
      opacity: enabled ? Style.opacityFull : Style.opacityMedium
      showFilled: enabled && powerProfiles.profile === PowerProfile.Performance
      showBorder: !enabled || powerProfiles.profile !== PowerProfile.Performance
      onClicked: {
        if (enabled) {
          powerProfiles.profile = PowerProfile.Performance
        }
      }
    }
    // Balanced
    NIconButton {
      icon: "balance"
      tooltipText: "Set Balanced Power Profile"
      enabled: hasPP
      opacity: enabled ? Style.opacityFull : Style.opacityMedium
      showFilled: enabled && powerProfiles.profile === PowerProfile.Balanced
      showBorder: !enabled || powerProfiles.profile !== PowerProfile.Balanced
      onClicked: {
        if (enabled) {
          powerProfiles.profile = PowerProfile.Balanced
        }
      }
    }
    // Eco
    NIconButton {
      icon: "eco"
      tooltipText: "Set Eco Power Profile"
      enabled: hasPP
      opacity: enabled ? Style.opacityFull : Style.opacityMedium
      showFilled: enabled && powerProfiles.profile === PowerProfile.PowerSaver
      showBorder: !enabled || powerProfiles.profile !== PowerProfile.PowerSaver
      onClicked: {
        if (enabled) {
          powerProfiles.profile = PowerProfile.PowerSaver
        }
      }
    }
    Item {
      Layout.fillWidth: true
    }
  }
}

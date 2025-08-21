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
  implicitHeight: powerRow.implicitHeight + Style.marginM * 2 * scaling

  // PowerProfiles service
  property var powerProfiles: PowerProfiles
  readonly property bool hasPP: powerProfiles.hasPerformanceProfile
  property real spacing: 0

  RowLayout {
    id: powerRow
    anchors.fill: parent
    anchors.margins: Style.marginS * scaling
    spacing: spacing
    Item {
      Layout.fillWidth: true
    }
    // Performance
    NIconButton {
      icon: "speed"
      tooltipText: "Set Performance Power Profile"
      enabled: hasPP
      opacity: enabled ? Style.opacityFull : Style.opacityMedium
      colorBg: (enabled && powerProfiles.profile === PowerProfile.Performance) ? Color.mPrimary : Color.mSurfaceVariant
      colorFg: (enabled && powerProfiles.profile === PowerProfile.Performance) ? Color.mOnPrimary : Color.mPrimary
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
      colorBg: (enabled && powerProfiles.profile === PowerProfile.Balanced) ? Color.mPrimary : Color.mSurfaceVariant
      colorFg: (enabled && powerProfiles.profile === PowerProfile.Balanced) ? Color.mOnPrimary : Color.mPrimary
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
      colorBg: (enabled && powerProfiles.profile === PowerProfile.PowerSaver) ? Color.mPrimary : Color.mSurfaceVariant
      colorFg: (enabled && powerProfiles.profile === PowerProfile.PowerSaver) ? Color.mOnPrimary : Color.mPrimary
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

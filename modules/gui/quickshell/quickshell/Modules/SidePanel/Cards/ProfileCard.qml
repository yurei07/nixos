import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.Modules.SettingsPanel
import qs.Modules.SidePanel
import qs.Commons
import qs.Services
import qs.Widgets

// Header card with avatar, user and quick actions
NBox {
  id: root

  property string uptimeText: "--"

  Layout.fillWidth: true
  // Height driven by content
  implicitHeight: content.implicitHeight + Style.marginMedium * 2 * scaling

  RowLayout {
    id: content
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.margins: Style.marginMedium * scaling
    spacing: Style.marginMedium * scaling

    NImageRounded {
      width: Style.baseWidgetSize * 1.25 * scaling
      height: Style.baseWidgetSize * 1.25 * scaling
      imagePath: Settings.data.general.avatarImage
      fallbackIcon: "person"
      borderColor: Color.mPrimary
      borderWidth: Math.max(1, Style.borderMedium * scaling)
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: Style.marginTiniest * scaling
      NText {
        text: Quickshell.env("USER") || "user"
        font.weight: Style.fontWeightBold
      }
      NText {
        text: `System Uptime: ${uptimeText}`
        color: Color.mOnSurface
      }
    }

    RowLayout {
      spacing: Style.marginSmall * scaling
      Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
      Item {
        Layout.fillWidth: true
      }
      NIconButton {
        icon: "settings"
        tooltipText: "Open Settings"
        onClicked: {
          settingsPanel.requestedTab = SettingsPanel.Tab.General
          settingsPanel.isLoaded = !settingsPanel.isLoaded
        }
      }

      NIconButton {
        id: powerButton
        icon: "power_settings_new"
        tooltipText: "Power Menu"
        onClicked: {
          powerMenu.show()
        }
      }
    }
  }

  PowerMenu {
    id: powerMenu
    anchors.top: powerButton.bottom
    anchors.right: powerButton.right
  }

  // ----------------------------------
  // Uptime
  Timer {
    interval: 60000
    repeat: true
    running: true
    onTriggered: uptimeProcess.running = true
  }

  Process {
    id: uptimeProcess
    command: ["cat", "/proc/uptime"]
    running: true

    stdout: StdioCollector {
      onStreamFinished: {
        var uptimeSeconds = parseFloat(this.text.trim().split(' ')[0])
        var minutes = Math.floor(uptimeSeconds / 60) % 60
        var hours = Math.floor(uptimeSeconds / 3600) % 24
        var days = Math.floor(uptimeSeconds / 86400)

        // Format the output
        if (days > 0) {
          uptimeText = days + "d " + hours + "h"
        } else if (hours > 0) {
          uptimeText = hours + "h" + minutes + "m"
        } else {
          uptimeText = minutes + "m"
        }

        uptimeProcess.running = false
      }
    }
  }

  function updateSystemInfo() {
    uptimeProcess.running = true
  }
}

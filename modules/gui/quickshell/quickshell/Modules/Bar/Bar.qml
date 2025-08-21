import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services
import qs.Widgets
import qs.Modules.Notification

Variants {
  model: Quickshell.screens

  delegate: PanelWindow {
    id: root

    required property ShellScreen modelData
    readonly property real scaling: ScalingService.scale(screen)
    screen: modelData

    WlrLayershell.namespace: "noctalia-bar"

    implicitHeight: Style.barHeight * scaling
    color: Color.transparent

    // If no bar activated in settings, then show them all
    visible: modelData ? (Settings.data.bar.monitors.includes(modelData.name)
                          || (Settings.data.bar.monitors.length === 0)) : false

    anchors {
      top: Settings.data.bar.position === "top"
      bottom: Settings.data.bar.position === "bottom"
      left: true
      right: true
    }

    Item {
      anchors.fill: parent
      clip: true

      // Background fill
      Rectangle {
        id: bar

        anchors.fill: parent
        color: Qt.rgba(Color.mSurface.r, Color.mSurface.g, Color.mSurface.b, Settings.data.bar.backgroundOpacity)
        layer.enabled: true
      }

      // Left
      Row {
        id: leftSection

        height: parent.height
        anchors.left: parent.left
        anchors.leftMargin: Style.marginS * scaling
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.marginS * scaling

        SystemMonitor {}

        ActiveWindow {}

        MediaMini {}
      }

      // Center
      Row {
        id: centerSection

        height: parent.height
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.marginS * scaling

        Workspace {}
      }

      // Right
      Row {
        id: rightSection

        height: parent.height
        anchors.right: bar.right
        anchors.rightMargin: Style.marginS * scaling
        anchors.verticalCenter: bar.verticalCenter
        spacing: Style.marginS * scaling

        ScreenRecorderIndicator {
          anchors.verticalCenter: parent.verticalCenter
        }

        Tray {
          anchors.verticalCenter: parent.verticalCenter
        }

        NotificationHistory {
          anchors.verticalCenter: parent.verticalCenter
        }

        WiFi {
          anchors.verticalCenter: parent.verticalCenter
        }

        Bluetooth {
          anchors.verticalCenter: parent.verticalCenter
        }

        Battery {
          anchors.verticalCenter: parent.verticalCenter
        }

        Volume {
          anchors.verticalCenter: parent.verticalCenter
        }

        Brightness {
          anchors.verticalCenter: parent.verticalCenter
        }

        Clock {
          anchors.verticalCenter: parent.verticalCenter
        }

        SidePanelToggle {}
      }
    }
  }
}

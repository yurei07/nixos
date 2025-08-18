import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
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

    implicitHeight: Style.barHeight * scaling
    color: Color.transparent

    // If no bar activated in settings, then show them all
    visible: modelData ? (Settings.data.bar.monitors.includes(modelData.name)
                          || (Settings.data.bar.monitors.length === 0)) : false

    anchors {
      top: true
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
        color: Color.mSurface
        layer.enabled: true
      }

      // Left
      Row {
        id: leftSection

        height: parent.height
        anchors.left: parent.left
        anchors.leftMargin: Style.marginSmall * scaling
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.marginSmall * scaling

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
        spacing: Style.marginSmall * scaling

        Workspace {}
      }

      // Right
      Row {
        id: rightSection

        height: parent.height
        anchors.right: bar.right
        anchors.rightMargin: Style.marginSmall * scaling
        anchors.verticalCenter: bar.verticalCenter
        spacing: Style.marginSmall * scaling

        // Screen Recording Indicator
        NIconButton {
          id: screenRecordingIndicator
          icon: "videocam"
          tooltipText: "Screen Recording Active"
          sizeMultiplier: 0.8
          showBorder: false
          showFilled: ScreenRecorderService.isRecording
          visible: ScreenRecorderService.isRecording
          anchors.verticalCenter: parent.verticalCenter
          onClicked: {
            ScreenRecorderService.toggleRecording()
          }
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

        // NIconButton {
        //   id: demoPanelToggle
        //   icon: "experiment"
        //   tooltipText: "Open Demo Panel"
        //   sizeMultiplier: 0.8
        //   showBorder: false
        //   anchors.verticalCenter: parent.verticalCenter
        //   onClicked: {
        //     demoPanel.isLoaded = !demoPanel.isLoaded
        //   }
        // }
        NIconButton {
          id: sidePanelToggle
          icon: "widgets"
          tooltipText: "Open Side Panel"
          sizeMultiplier: 0.8
          showBorder: false
          anchors.verticalCenter: parent.verticalCenter
          onClicked: {
            // Map this button's center to the screen and open the side panel below it
            const localCenterX = width / 2
            const localCenterY = height / 2
            const globalPoint = mapToItem(null, localCenterX, localCenterY)
            if (sidePanel.isLoaded) {
              // Call hide() instead of directly setting isLoaded to false
              if (sidePanel.item && sidePanel.item.hide) {
                sidePanel.item.hide()
              } else {
                sidePanel.isLoaded = false
              }
            } else if (sidePanel.openAt) {
              sidePanel.openAt(globalPoint.x, screen)
            } else {
              // Fallback: toggle if API unavailable
              sidePanel.isLoaded = true
            }
          }
        }
      }
    }
  }
}

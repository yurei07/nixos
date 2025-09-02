import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Wayland
import qs.Commons
import qs.Services
import qs.Widgets

NPanel {
  id: root

  panelWidth: 380 * scaling
  panelHeight: 500 * scaling
  panelAnchorRight: true

  panelContent: Rectangle {
    color: Color.transparent

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Style.marginL * scaling
      spacing: Style.marginM * scaling

      // HEADER
      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM * scaling

        NIcon {
          text: "bluetooth"
          font.pointSize: Style.fontSizeXXL * scaling
          color: Color.mPrimary
        }

        NText {
          text: "Bluetooth"
          font.pointSize: Style.fontSizeL * scaling
          font.weight: Style.fontWeightBold
          color: Color.mOnSurface
          Layout.fillWidth: true
        }

        NIconButton {
          icon: BluetoothService.adapter && BluetoothService.adapter.discovering ? "stop_circle" : "refresh"
          tooltipText: "Refresh Devices"
          sizeRatio: 0.8
          onClicked: {
            if (BluetoothService.adapter) {
              BluetoothService.adapter.discovering = !BluetoothService.adapter.discovering
            }
          }
        }

        NIconButton {
          icon: "close"
          tooltipText: "Close"
          sizeRatio: 0.8
          onClicked: {
            root.close()
          }
        }
      }

      NDivider {
        Layout.fillWidth: true
      }

      ScrollView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded
        clip: true
        contentWidth: availableWidth

        ColumnLayout {
          visible: BluetoothService.adapter && BluetoothService.adapter.enabled
          width: parent.width
          spacing: Style.marginM * scaling

          // Connected devices
          BluetoothDevicesList {
            label: "Connected devices"
            property var items: {
              if (!BluetoothService.adapter || !Bluetooth.devices)
                return []
              var filtered = Bluetooth.devices.values.filter(dev => dev && !dev.blocked && dev.connected)
              return BluetoothService.sortDevices(filtered)
            }
            model: items
            visible: items.length > 0
            Layout.fillWidth: true
          }

          // Known devices
          BluetoothDevicesList {
            label: "Known devices"
            tooltipText: "Left click to connect, right click to forget"
            property var items: {
              if (!BluetoothService.adapter || !Bluetooth.devices)
                return []
              var filtered = Bluetooth.devices.values.filter(dev => dev && !dev.blocked && !dev.connected
                                                             && (dev.paired || dev.trusted))
              return BluetoothService.sortDevices(filtered)
            }
            model: items
            visible: items.length > 0
            Layout.fillWidth: true
          }

          // Available devices
          BluetoothDevicesList {
            label: "Available devices"
            property var items: {
              if (!BluetoothService.adapter || !Bluetooth.devices)
                return []
              var filtered = Bluetooth.devices.values.filter(dev => dev && !dev.blocked && !dev.paired && !dev.trusted)
              return BluetoothService.sortDevices(filtered)
            }
            model: items
            visible: items.length > 0
            Layout.fillWidth: true
          }

          // Fallback
          ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.marginM * scaling
            visible: {
              if (!BluetoothService.adapter || !BluetoothService.adapter.discovering || !Bluetooth.devices) {
                return false
              }

              var availableCount = Bluetooth.devices.values.filter(dev => {
                                                                     return dev && !dev.paired && !dev.pairing
                                                                     && !dev.blocked
                                                                     && (dev.signalStrength === undefined
                                                                         || dev.signalStrength > 0)
                                                                   }).length
              return (availableCount === 0)
            }

            RowLayout {
              Layout.alignment: Qt.AlignHCenter
              spacing: Style.marginM * scaling

              NIcon {
                text: "sync"
                font.pointSize: Style.fontSizeXLL * 1.5 * scaling
                color: Color.mPrimary

                RotationAnimation on rotation {
                  running: true
                  loops: Animation.Infinite
                  from: 0
                  to: 360
                  duration: Style.animationSlow * 4
                }
              }

              NText {
                text: "Scanning for devices..."
                font.pointSize: Style.fontSizeL * scaling
                color: Color.mOnSurface
                font.weight: Style.fontWeightMedium
              }
            }

            NText {
              text: "Make sure your device is in pairing mode"
              font.pointSize: Style.fontSizeM * scaling
              color: Color.mOnSurfaceVariant
              Layout.alignment: Qt.AlignHCenter
            }
          }

          Item {
            Layout.fillHeight: true
          }
        }
      }
    }
  }
}

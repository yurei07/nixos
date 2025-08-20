import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import qs.Commons
import qs.Services
import qs.Widgets

ColumnLayout {
  id: root
  spacing: 0

  ScrollView {
    id: scrollView
    Layout.fillWidth: true
    Layout.fillHeight: true
    padding: Style.marginM * scaling
    clip: true

    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
    ScrollBar.vertical.policy: ScrollBar.AsNeeded

    ColumnLayout {
      width: scrollView.availableWidth
      spacing: 0

      Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 0
      }

      ColumnLayout {
        spacing: Style.marginL * scaling
        Layout.fillWidth: true

        NText {
          text: "Interfaces"
          font.pointSize: Style.fontSizeXXL * scaling
          font.weight: Style.fontWeightBold
          color: Color.mOnSurface
        }

        NToggle {
          label: "WiFi Enabled"
          description: "Enable WiFi connectivity."
          checked: Settings.data.network.wifiEnabled
          onToggled: checked => {
                       Settings.data.network.wifiEnabled = checked
                       NetworkService.setWifiEnabled(checked)
                       if (checked) {
                         ToastService.showNotice("WiFi", "Enabled")
                       } else {
                         ToastService.showNotice("WiFi", "Disabled")
                       }
                     }
        }

        NToggle {
          label: "Bluetooth Enabled"
          description: "Enable Bluetooth connectivity."
          checked: Settings.data.network.bluetoothEnabled
          onToggled: checked => {
                       Settings.data.network.bluetoothEnabled = checked
                       BluetoothService.setBluetoothEnabled(checked)
                       if (checked) {
                         ToastService.showNotice("Bluetooth", "Enabled")
                       } else {
                         ToastService.showNotice("Bluetooth", "Disabled")
                       }
                     }
        }
      }
    }
  }
}

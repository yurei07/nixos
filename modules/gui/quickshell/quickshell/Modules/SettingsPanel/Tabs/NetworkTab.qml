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
  spacing: Style.marginL * scaling

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

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginXL * scaling
    Layout.bottomMargin: Style.marginXL * scaling
  }
}

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
    label: "Enable Wi-Fi"
    description: "Enable Wi-Fi connectivity."
    checked: Settings.data.network.wifiEnabled
    onToggled: checked => NetworkService.setWifiEnabled(checked)
  }

  NToggle {
    label: "Enable Bluetooth"
    description: "Enable Bluetooth connectivity."
    checked: Settings.data.network.bluetoothEnabled
    onToggled: checked => BluetoothService.setBluetoothEnabled(checked)
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginXL * scaling
    Layout.bottomMargin: Style.marginXL * scaling
  }
}

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services
import qs.Widgets

NIconButton {
  id: root

  readonly property bool bluetoothEnabled: Settings.data.network.bluetoothEnabled
  sizeMultiplier: 0.8
  visible: bluetoothEnabled

  colorBg: Color.mSurfaceVariant
  colorFg: Color.mOnSurface
  colorBorder: Color.transparent
  colorBorderHover: Color.transparent

  icon: {
    // Show different icons based on connection status
    if (BluetoothService.pairedDevices.length > 0) {
      return "bluetooth_connected"
    } else if (BluetoothService.discovering) {
      return "bluetooth_searching"
    } else {
      return "bluetooth"
    }
  }
  tooltipText: "Bluetooth Devices"
  onClicked: {
    bluetoothPanel.toggle(screen)
  }

  BluetoothPanel {
    id: bluetoothPanel
  }
}

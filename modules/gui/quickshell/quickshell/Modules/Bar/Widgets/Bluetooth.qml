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

  property ShellScreen screen
  property real scaling: 1.0

  visible: Settings.data.network.bluetoothEnabled
  sizeRatio: 0.8
  colorBg: Color.mSurfaceVariant
  colorFg: Color.mOnSurface
  colorBorder: Color.transparent
  colorBorderHover: Color.transparent

  icon: "bluetooth"
  tooltipText: "Bluetooth devices"
  onClicked: PanelService.getPanel("bluetoothPanel")?.toggle(screen, this)
}

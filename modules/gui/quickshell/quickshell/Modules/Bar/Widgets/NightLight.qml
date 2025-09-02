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

  sizeRatio: 0.8

  colorBg: Color.mSurfaceVariant
  colorFg: Color.mOnSurface
  colorBorder: Color.transparent
  colorBorderHover: Color.transparent

  icon: Settings.data.nightLight.enabled ? "bedtime" : "bedtime_off"
  tooltipText: `Night light: ${Settings.data.nightLight.enabled ? "enabled" : "disabled"}\nLeft click to toggle.\nRight click to access settings.`
  onClicked: Settings.data.nightLight.enabled = !Settings.data.nightLight.enabled

  onRightClicked: {
    var settingsPanel = PanelService.getPanel("settingsPanel")
    settingsPanel.requestedTab = SettingsPanel.Tab.Display
    settingsPanel.open(screen)
  }
}

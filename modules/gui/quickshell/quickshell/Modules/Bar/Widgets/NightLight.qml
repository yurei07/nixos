import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Modules.SettingsPanel
import qs.Services
import qs.Widgets

NIconButton {
  id: root

  property ShellScreen screen
  property real scaling: 1.0

  sizeRatio: 0.8
  colorBg: Settings.data.nightLight.enabled ? (Settings.data.nightLight.forced ? Color.mTertiary : Color.mPrimary) : Color.mSurfaceVariant
  colorFg: Settings.data.nightLight.enabled ? Color.mOnPrimary : Color.mOnSurface
  colorBorder: Color.transparent
  colorBorderHover: Color.transparent

  icon: Settings.data.nightLight.enabled ? (Settings.data.nightLight.forced ? "nightlight-forced" : "nightlight-on") : "nightlight-off"
  tooltipText: `Night light: ${Settings.data.nightLight.enabled ? (Settings.data.nightLight.forced ? "forced." : "enabled.") : "disabled."}\nLeft click to cycle (disabled → normal → forced).\nRight click to access settings.`
  onClicked: {
    if (!Settings.data.nightLight.enabled) {
      Settings.data.nightLight.enabled = true
      Settings.data.nightLight.forced = false
    } else if (Settings.data.nightLight.enabled && !Settings.data.nightLight.forced) {
      Settings.data.nightLight.forced = true
    } else {
      Settings.data.nightLight.enabled = false
      Settings.data.nightLight.forced = false
    }
  }

  onRightClicked: {
    var settingsPanel = PanelService.getPanel("settingsPanel")
    settingsPanel.requestedTab = SettingsPanel.Tab.Brightness
    settingsPanel.open()
  }
}

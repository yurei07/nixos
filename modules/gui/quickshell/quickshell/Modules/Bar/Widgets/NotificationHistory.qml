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
  icon: "notifications"
  tooltipText: "Notification history"
  colorBg: Color.mSurfaceVariant
  colorFg: Color.mOnSurface
  colorBorder: Color.transparent
  colorBorderHover: Color.transparent
  onClicked: PanelService.getPanel("notificationHistoryPanel")?.toggle(screen, this)
}

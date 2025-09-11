import Quickshell
import qs.Commons
import qs.Widgets
import qs.Services

NIconButton {
  id: root

  property ShellScreen screen
  property real scaling: 1.0

  icon: "dark-mode"
  tooltipText: "Toggle light/dark mode"
  sizeRatio: 0.8

  colorBg: Settings.data.colorSchemes.darkMode ? Color.mSurfaceVariant : Color.mPrimary
  colorFg: Settings.data.colorSchemes.darkMode ? Color.mOnSurface : Color.mOnPrimary
  colorBorder: Color.transparent
  colorBorderHover: Color.transparent

  anchors.verticalCenter: parent.verticalCenter
  onClicked: Settings.data.colorSchemes.darkMode = !Settings.data.colorSchemes.darkMode
}

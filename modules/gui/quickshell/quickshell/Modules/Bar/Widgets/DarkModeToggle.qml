import Quickshell
import qs.Commons
import qs.Widgets
import qs.Services

NIconButton {
  id: root

  property ShellScreen screen
  property real scaling: 1.0

  icon: "contrast"
  tooltipText: "Toggle light/dark mode"
  sizeRatio: 0.8

  colorBg: Color.mSurfaceVariant
  colorFg: Color.mOnSurface
  colorBorder: Color.transparent
  colorBorderHover: Color.transparent

  anchors.verticalCenter: parent.verticalCenter
  onClicked: Settings.data.colorSchemes.darkMode = !Settings.data.colorSchemes.darkMode
}

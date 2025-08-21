import Quickshell
import qs.Commons
import qs.Widgets

NIconButton {
  id: sidePanelToggle
  icon: "widgets"
  tooltipText: "Open Side Panel"
  sizeMultiplier: 0.8

  colorBg: Color.mSurfaceVariant
  colorFg: Color.mOnSurface
  colorBorder: Color.transparent
  colorBorderHover: Color.transparent

  anchors.verticalCenter: parent.verticalCenter
  onClicked: sidePanel.toggle(screen)
}

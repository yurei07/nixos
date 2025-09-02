import Quickshell
import Quickshell.Widgets
import QtQuick.Effects
import qs.Commons
import qs.Widgets
import qs.Services

NIconButton {
  id: root

  property ShellScreen screen
  property real scaling: 1.0

  icon: Settings.data.bar.useDistroLogo ? "" : "widgets"
  tooltipText: "Open side panel"
  sizeRatio: 0.8

  colorBg: Color.mSurfaceVariant
  colorFg: Color.mOnSurface
  colorBorder: Color.transparent
  colorBorderHover: Color.transparent

  anchors.verticalCenter: parent.verticalCenter
  onClicked: PanelService.getPanel("sidePanel")?.toggle(screen)

  // When enabled, draw the distro logo instead of the icon glyph
  IconImage {
    id: logo
    anchors.centerIn: parent
    width: root.width * 0.6
    height: width
    source: Settings.data.bar.useDistroLogo ? DistroLogoService.osLogo : ""
    visible: false //Settings.data.bar.useDistroLogo && source !== ""
    smooth: true
  }

  MultiEffect {
    anchors.fill: logo
    source: logo
    //visible: logo.visible
    colorization: 1
    brightness: 1
    saturation: 1
    colorizationColor: root.hovering ? Color.mSurfaceVariant : Color.mOnSurface
  }
}

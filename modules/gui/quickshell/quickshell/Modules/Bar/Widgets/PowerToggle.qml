import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

NIconButton {
  id: root

  sizeRatio: 0.8

  icon: "power"
  tooltipText: "Power Settings"
  colorBg: Color.mSurfaceVariant
  colorFg: Color.mError
  colorBorder: Color.transparent
  colorBorderHover: Color.transparent
  onClicked: PanelService.getPanel("powerPanel")?.toggle()
}

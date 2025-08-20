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
  onClicked: {
    // Map this button's center to the screen and open the side panel below it
    const localCenterX = width / 2
    const localCenterY = height / 2
    const globalPoint = mapToItem(null, localCenterX, localCenterY)
    if (sidePanel.isLoaded) {
      // Call hide() instead of directly setting isLoaded to false
      if (sidePanel.item && sidePanel.item.hide) {
        sidePanel.item.hide()
      } else {
        sidePanel.isLoaded = false
      }
    } else if (sidePanel.openAt) {
      sidePanel.openAt(globalPoint.x, screen)
    } else {
      // Fallback: toggle if API unavailable
      sidePanel.isLoaded = true
    }
  }
}

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs.Commons
import qs.Services
import qs.Widgets

Row {
  id: root

  property ShellScreen screen
  property real scaling: 1.0
  property string barSection: ""
  property int sectionWidgetIndex: 0
  property int sectionWidgetsCount: 0

  // Use the shared service for keyboard layout
  property string currentLayout: KeyboardLayoutService.currentLayout

  width: pill.width
  height: pill.height

  NPill {
    id: pill

    rightOpen: BarWidgetRegistry.getNPillDirection(root)
    icon: "keyboard_alt"
    iconCircleColor: Color.mPrimary
    collapsedIconColor: Color.mOnSurface
    autoHide: false // Important to be false so we can hover as long as we want
    text: currentLayout
    tooltipText: "Keyboard layout: " + currentLayout

    onClicked: {

      // You could open keyboard settings here if needed
      // For now, just show the current layout
    }
  }
}

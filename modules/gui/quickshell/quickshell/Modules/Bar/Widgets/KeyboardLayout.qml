import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs.Commons
import qs.Services
import qs.Widgets

Item {
  id: root

  property ShellScreen screen
  property real scaling: 1.0

  // Widget properties passed from Bar.qml for per-instance settings
  property string widgetId: ""
  property string barSection: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0

  property var widgetMetadata: BarWidgetRegistry.widgetMetadata[widgetId]
  property var widgetSettings: {
    var section = barSection.replace("Section", "").toLowerCase()
    if (section && sectionWidgetIndex >= 0) {
      var widgets = Settings.data.bar.widgets[section]
      if (widgets && sectionWidgetIndex < widgets.length) {
        return widgets[sectionWidgetIndex]
      }
    }
    return {}
  }

  readonly property bool forceOpen: (widgetSettings.forceOpen !== undefined) ? widgetSettings.forceOpen : widgetMetadata.forceOpen

  // Use the shared service for keyboard layout
  property string currentLayout: KeyboardLayoutService.currentLayout

  implicitWidth: pill.width
  implicitHeight: pill.height

  NPill {
    id: pill

    anchors.verticalCenter: parent.verticalCenter
    rightOpen: BarWidgetRegistry.getNPillDirection(root)
    icon: "keyboard"
    autoHide: false // Important to be false so we can hover as long as we want
    text: currentLayout.toUpperCase()
    tooltipText: "Keyboard layout: " + currentLayout.toUpperCase()
    forceOpen: root.forceOpen
    fontSize: Style.fontSizeS // Use larger font size

    onClicked: {

      // You could open keyboard settings here if needed
      // For now, just show the current layout
    }
  }
}

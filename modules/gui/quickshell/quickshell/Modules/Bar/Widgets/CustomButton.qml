import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets
import qs.Modules.SettingsPanel

NIconButton {
  id: root

  // Widget properties passed from Bar.qml
  property var screen
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

  // Use settings or defaults from BarWidgetRegistry
  readonly property string customIcon: widgetSettings.icon || widgetMetadata.icon
  readonly property string leftClickExec: widgetSettings.leftClickExec || widgetMetadata.leftClickExec
  readonly property string rightClickExec: widgetSettings.rightClickExec || widgetMetadata.rightClickExec
  readonly property string middleClickExec: widgetSettings.middleClickExec || widgetMetadata.middleClickExec
  readonly property bool hasExec: (leftClickExec || rightClickExec || middleClickExec)

  enabled: hasExec
  allowClickWhenDisabled: true // we want to be able to open config with left click when its not setup properly
  colorBorder: Color.transparent
  colorBorderHover: Color.transparent
  sizeRatio: 0.8
  icon: customIcon
  tooltipText: {
    if (!hasExec) {
      return "Custom Button - Configure in settings"
    } else {
      var lines = []
      if (leftClickExec !== "") {
        lines.push(`Left click: <i>${leftClickExec}</i>.`)
      }
      if (rightClickExec !== "") {
        lines.push(`Right click: <i>${rightClickExec}</i>.`)
      }
      if (middleClickExec !== "") {
        lines.push(`Middle click: <i>${middleClickExec}</i>.`)
      }
      return lines.join("<br/>")
    }
  }

  onClicked: {
    if (leftClickExec) {
      Quickshell.execDetached(["sh", "-c", leftClickExec])
      Logger.log("CustomButton", `Executing command: ${leftClickExec}`)
    } else if (!hasExec) {
      // No script was defined, open settings
      var settingsPanel = PanelService.getPanel("settingsPanel")
      settingsPanel.requestedTab = SettingsPanel.Tab.Bar
      settingsPanel.open()
    }
  }

  onRightClicked: {
    if (rightClickExec) {
      Quickshell.execDetached(["sh", "-c", rightClickExec])
      Logger.log("CustomButton", `Executing command: ${rightClickExec}`)
    }
  }

  onMiddleClicked: {
    if (middleClickExec) {
      Quickshell.execDetached(["sh", "-c", middleClickExec])
      Logger.log("CustomButton", `Executing command: ${middleClickExec}`)
    }
  }
}

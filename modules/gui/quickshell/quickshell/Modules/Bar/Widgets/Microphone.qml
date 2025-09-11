import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.Commons
import qs.Modules.SettingsPanel
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

  readonly property bool alwaysShowPercentage: (widgetSettings.alwaysShowPercentage
                                                !== undefined) ? widgetSettings.alwaysShowPercentage : widgetMetadata.alwaysShowPercentage

  // Used to avoid opening the pill on Quickshell startup
  property bool firstInputVolumeReceived: false
  property int wheelAccumulator: 0

  implicitWidth: pill.width
  implicitHeight: pill.height

  function getIcon() {
    if (AudioService.inputMuted) {
      return "microphone-mute"
    }
    return (AudioService.inputVolume <= Number.EPSILON) ? "microphone-mute" : "microphone"
  }

  // Connection used to open the pill when input volume changes
  Connections {
    target: AudioService.source?.audio ? AudioService.source?.audio : null
    function onVolumeChanged() {
      // Logger.log("Bar:Microphone", "onInputVolumeChanged")
      if (!firstInputVolumeReceived) {
        // Ignore the first volume change
        firstInputVolumeReceived = true
      } else {
        pill.show()
        externalHideTimer.restart()
      }
    }
  }

  // Connection used to open the pill when input mute state changes
  Connections {
    target: AudioService.source?.audio ? AudioService.source?.audio : null
    function onMutedChanged() {
      // Logger.log("Bar:Microphone", "onInputMutedChanged")
      if (!firstInputVolumeReceived) {
        // Ignore the first mute change
        firstInputVolumeReceived = true
      } else {
        pill.show()
        externalHideTimer.restart()
      }
    }
  }

  Timer {
    id: externalHideTimer
    running: false
    interval: 1500
    onTriggered: {
      pill.hide()
    }
  }

  NPill {
    id: pill

    rightOpen: BarWidgetRegistry.getNPillDirection(root)
    icon: getIcon()
    autoHide: false // Important to be false so we can hover as long as we want
    text: Math.floor(AudioService.inputVolume * 100) + "%"
    forceOpen: alwaysShowPercentage
    tooltipText: "Microphone: " + Math.round(AudioService.inputVolume * 100)
                 + "%\nLeft click for advanced settings.\nScroll up/down to change volume.\nRight click to toggle mute."

    onWheel: function (delta) {
      wheelAccumulator += delta
      if (wheelAccumulator >= 120) {
        wheelAccumulator = 0
        AudioService.setInputVolume(AudioService.inputVolume + AudioService.stepVolume)
      } else if (wheelAccumulator <= -120) {
        wheelAccumulator = 0
        AudioService.setInputVolume(AudioService.inputVolume - AudioService.stepVolume)
      }
    }
    onClicked: {
      var settingsPanel = PanelService.getPanel("settingsPanel")
      settingsPanel.requestedTab = SettingsPanel.Tab.Audio
      settingsPanel.open()
    }
    onRightClicked: {
      AudioService.setInputMuted(!AudioService.inputMuted)
    }
    onMiddleClicked: {
      Quickshell.execDetached(["pwvucontrol"])
    }
  }
}

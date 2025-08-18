import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services

PanelWindow {
  id: root

  readonly property real scaling: ScalingService.scale(screen)

  property bool showOverlay: Settings.data.general.dimDesktop
  property int topMargin: Style.barHeight * scaling
  // Show dimming if this panel is opened OR if we're in a transition (to prevent flickering)
  property color overlayColor: (showOverlay && (PanelService.openedPanel === root
                                                || isTransitioning)) ? Color.applyOpacity(Color.mShadow,
                                                                                          "AA") : Color.transparent
  property bool isTransitioning: false
  signal dismissed

  function hide() {
    // Clear the panel service when hiding
    if (PanelService.openedPanel === root) {
      PanelService.openedPanel = null
    }
    isTransitioning = false
    visible = false
    root.dismissed()
  }

  function show() {
    // Ensure only one panel is visible at a time using PanelService as ephemeral storage
    try {
      if (PanelService.openedPanel && PanelService.openedPanel !== root && PanelService.openedPanel.hide) {
        // Mark both panels as transitioning to prevent dimming flicker
        isTransitioning = true
        PanelService.openedPanel.isTransitioning = true
        PanelService.openedPanel.hide()
        // Small delay to ensure smooth transition
        showTimer.start()
        return
      }
      // No previous panel, show immediately
      PanelService.openedPanel = root
      visible = true
    } catch (e) {

      // ignore
    }
  }

  implicitWidth: screen.width
  implicitHeight: screen.height
  color: visible ? overlayColor : Color.transparent
  visible: false
  WlrLayershell.exclusionMode: ExclusionMode.Ignore

  anchors.top: true
  anchors.left: true
  anchors.right: true
  anchors.bottom: true
  margins.top: topMargin

  MouseArea {
    anchors.fill: parent
    onClicked: root.hide()
  }

  Behavior on color {
    ColorAnimation {
      duration: Style.animationSlow
      easing.type: Easing.InOutCubic
    }
  }

  Timer {
    id: showTimer
    interval: 50 // Small delay to ensure smooth transition
    repeat: false
    onTriggered: {
      PanelService.openedPanel = root
      isTransitioning = false
      visible = true
    }
  }

  Component.onDestruction: {
    try {
      if (visible && Settings.openPanel === root)
        Settings.openPanel = null
    } catch (e) {

    }
  }

  onVisibleChanged: {
    try {
      if (!visible) {
        // Clear panel service when panel becomes invisible
        if (PanelService.openedPanel === root) {
          PanelService.openedPanel = null
        }
        if (Settings.openPanel === root) {
          Settings.openPanel = null
        }
        isTransitioning = false
      }
    } catch (e) {

    }
  }
}

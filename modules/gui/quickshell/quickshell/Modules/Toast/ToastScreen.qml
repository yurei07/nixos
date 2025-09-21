import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services
import qs.Widgets

Loader {
  id: root

  required property ShellScreen screen
  required property real scaling
  required property bool active

  // Local queue for this screen only
  property var messageQueue: []
  property bool isShowingToast: false

  // If true, immediately show new toasts
  property bool replaceOnNew: true

  Connections {
    target: ScalingService
    function onScaleChanged(screenName, scale) {
      if (screenName === root.screen.name) {
        root.scaling = scale
      }
    }
  }

  Connections {
    target: ToastService
    enabled: root.active

    function onNotify(message, description, type, duration) {
      root.enqueueToast({
                          "message": message,
                          "description": description,
                          "type": type,
                          "duration": duration,
                          "timestamp": Date.now()
                        })
    }
  }

  function enqueueToast(toastData) {
    if (replaceOnNew && isShowingToast) {
      // Cancel current toast and clear queue for latest toast
      messageQueue = [] // Clear existing queue
      messageQueue.push(toastData)

      // Hide current toast immediately
      if (item) {
        hideTimer.stop()
        item.hideToast() // Need to add this method to PanelWindow
      }

      // Process new toast after a brief delay
      isShowingToast = false
      quickSwitchTimer.restart()
    } else {
      // Original behavior - queue the toast
      messageQueue.push(toastData)
      processQueue()
    }
  }

  Timer {
    id: quickSwitchTimer
    interval: 50 // Brief delay for smooth transition
    onTriggered: root.processQueue()
  }

  function processQueue() {
    if (!active || !item || messageQueue.length === 0 || isShowingToast) {
      return
    }

    var data = messageQueue.shift()
    isShowingToast = true

    // Show the toast
    item.showToast(data.message, data.description, data.type, data.duration)
  }

  function onToastHidden() {
    isShowingToast = false
    // Small delay before next toast
    hideTimer.restart()
  }

  Timer {
    id: hideTimer
    interval: 200
    onTriggered: root.processQueue()
  }

  sourceComponent: PanelWindow {
    id: panel

    screen: root.screen

    anchors {
      top: true
    }

    implicitWidth: 500 * root.scaling
    implicitHeight: Math.round(toastItem.visible ? toastItem.height + Style.marginM * root.scaling : 1)

    // Set margins based on bar position
    margins.top: {
      switch (Settings.data.bar.position) {
      case "top":
        return (Style.barHeight + Style.marginS) * scaling + (Settings.data.bar.floating ? Settings.data.bar.marginVertical * Style.marginXL * scaling : 0)
      default:
        return Style.marginL * scaling
      }
    }

    color: Color.transparent

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: PanelWindow.ExclusionMode.Ignore

    function showToast(message, description, type, duration) {
      toastItem.show(message, description, type, duration)
    }

    // Add method to immediately hide toast
    function hideToast() {
      toastItem.hideImmediately()
    }

    SimpleToast {
      id: toastItem

      anchors.horizontalCenter: parent.horizontalCenter
      onHidden: root.onToastHidden()
    }
  }
}

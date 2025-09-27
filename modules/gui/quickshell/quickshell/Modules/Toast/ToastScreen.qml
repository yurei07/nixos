import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services
import qs.Widgets

Item {
  id: root

  required property ShellScreen screen
  required property real scaling
  property bool active: false

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

  // Clear queue on component destruction to prevent orphaned toasts
  Component.onDestruction: {
    messageQueue = []
    isShowingToast = false
    hideTimer.stop()
    quickSwitchTimer.stop()
  }

  function enqueueToast(toastData) {
    Logger.log("ToastScreen", "Queuing", toastData.type, ":", toastData.message, toastData.description.substr(100).replace(/\n/g, ""))

    if (replaceOnNew && isShowingToast) {
      // Cancel current toast and clear queue for latest toast
      messageQueue = [] // Clear existing queue
      messageQueue.push(toastData)

      // Hide current toast immediately
      if (windowLoader.item) {
        hideTimer.stop()
        windowLoader.item.hideToast()
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
    if (!active || messageQueue.length === 0 || isShowingToast) {
      return
    }

    var data = messageQueue.shift()
    isShowingToast = true

    // Activate the loader and show toast
    windowLoader.active = true
    // Need a small delay to ensure the window is created
    Qt.callLater(function () {
      if (windowLoader.item) {
        windowLoader.item.showToast(data.message, data.description, data.type, data.duration)
      }
    })
  }

  function onToastHidden() {
    isShowingToast = false

    // Deactivate the loader to completely remove the window
    windowLoader.active = false

    // Small delay before processing next toast
    hideTimer.restart()
  }

  Timer {
    id: hideTimer
    interval: 200
    onTriggered: root.processQueue()
  }

  // The loader that creates/destroys the PanelWindow as needed
  Loader {
    id: windowLoader
    active: false // Only active when showing a toast

    sourceComponent: PanelWindow {
      id: panel

      property alias toastItem: toastItem

      screen: root.screen

      readonly property string location: (Settings.isLoaded && Settings.data && Settings.data.notifications && Settings.data.notifications.location) ? Settings.data.notifications.location : "top_right"
      readonly property bool isTop: (location === "top") || (location.length >= 3 && location.substring(0, 3) === "top")
      readonly property bool isBottom: (location === "bottom") || (location.length >= 6 && location.substring(0, 6) === "bottom")
      readonly property bool isLeft: location.indexOf("_left") >= 0
      readonly property bool isRight: location.indexOf("_right") >= 0
      readonly property bool isCentered: (location === "top" || location === "bottom")

      // Anchor selection based on location (window edges)
      anchors.top: isTop
      anchors.bottom: isBottom
      anchors.left: isLeft
      anchors.right: isRight

      // Margins depending on bar position and chosen location
      margins.top: {
        if (!(anchors.top))
          return 0
        var base = Style.marginM * scaling
        if (Settings.data.bar.position === "top") {
          var floatExtraV = Settings.data.bar.floating ? Settings.data.bar.marginVertical * Style.marginXL * scaling : 0
          return (Style.barHeight * scaling) + base + floatExtraV
        }
        return base
      }

      margins.bottom: {
        if (!(anchors.bottom))
          return 0
        var base = Style.marginM * scaling
        if (Settings.data.bar.position === "bottom") {
          var floatExtraV = Settings.data.bar.floating ? Settings.data.bar.marginVertical * Style.marginXL * scaling : 0
          return (Style.barHeight * scaling) + base + floatExtraV
        }
        return base
      }

      margins.left: {
        if (!(anchors.left))
          return 0
        var base = Style.marginM * scaling
        if (Settings.data.bar.position === "left") {
          var floatExtraH = Settings.data.bar.floating ? Settings.data.bar.marginHorizontal * Style.marginXL * scaling : 0
          return (Style.barHeight * scaling) + base + floatExtraH
        }
        return base
      }

      margins.right: {
        if (!(anchors.right))
          return 0
        var base = Style.marginM * scaling
        if (Settings.data.bar.position === "right") {
          var floatExtraH = Settings.data.bar.floating ? Settings.data.bar.marginHorizontal * Style.marginXL * scaling : 0
          return (Style.barHeight * scaling) + base + floatExtraH
        }
        return base
      }

      implicitWidth: 420 * root.scaling
      implicitHeight: toastItem.height

      color: Color.transparent

      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      exclusionMode: PanelWindow.ExclusionMode.Ignore

      function showToast(message, description, type, duration) {
        toastItem.show(message, description, type, duration)
      }

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
}

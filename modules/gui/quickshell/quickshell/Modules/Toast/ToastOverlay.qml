import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services
import qs.Widgets

Variants {
  model: Quickshell.screens

  delegate: Loader {
    required property ShellScreen modelData
    property real scaling: ScalingService.getScreenScale(modelData)

    Connections {
      target: ScalingService
      function onScaleChanged(screenName, scale) {
        if (screenName === modelData.name) {
          scaling = scale
        }
      }
    }

    // Only show on screens that have notifications enabled
    active: Settings.isLoaded && modelData ? (Settings.data.notifications.monitors.includes(modelData.name)
                                              || (Settings.data.notifications.monitors.length === 0)) : false

    sourceComponent: PanelWindow {
      id: root

      screen: modelData

      // Position based on bar location, like Notification popup does
      anchors {
        top: Settings.data.bar.position === "top"
        bottom: Settings.data.bar.position === "bottom"
      }

      // Set a width instead of anchoring left/right so we can click on the side of the toast
      implicitWidth: 500 * scaling

      // Small height when hidden, appropriate height when visible
      implicitHeight: Math.round(toast.visible ? toast.height + Style.marginM * scaling : 1)

      // Set margins based on bar position
      margins.top: Settings.data.bar.position === "top" ? (Style.barHeight + Style.marginS) * scaling : 0
      margins.bottom: Settings.data.bar.position === "bottom" ? (Style.barHeight + Style.marginS) * scaling : 0

      // Transparent background
      color: Color.transparent

      // Overlay layer to appear above other panels
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      exclusionMode: PanelWindow.ExclusionMode.Ignore

      NToast {
        id: toast
        screen: modelData

        // Simple positioning - margins already account for bar
        targetY: Style.marginS * scaling

        // Hidden position based on bar location
        hiddenY: Settings.data.bar.position === "top" ? -toast.height - 20 : toast.height + 20

        Component.onCompleted: {
          // Register this toast with the service
          ToastService.allToasts.push(toast)

          // Connect dismissal signal
          toast.dismissed.connect(ToastService.onToastDismissed)
        }
      }
    }
  }
}

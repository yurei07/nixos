import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services
import qs.Widgets

// Unified OSD component
// Loader activates only when showing OSD, deactivates when hidden to save resources
Variants {
  model: Quickshell.screens

  delegate: Loader {
    id: root

    required property ShellScreen modelData
    property real scaling: ScalingService.getScreenScale(modelData)

    // Access the notification model from the service
    property ListModel notificationModel: NotificationService.activeList

    // If no notification display activated in settings, then show them all
    property bool canShowOnThisScreen: Settings.isLoaded && modelData && (Settings.data.osd.monitors.includes(modelData.name) || (Settings.data.osd.monitors.length === 0))

    // Loader is only active when actually showing something
    active: false

    // Current OSD display state
    property string currentOSDType: "" // "volume", "brightness", or ""

    // Volume properties
    readonly property real currentVolume: AudioService.volume
    readonly property bool isMuted: AudioService.muted
    property bool volumeInitialized: false
    property bool muteInitialized: false

    // Brightness properties
    property bool brightnessInitialized: false
    readonly property real currentBrightness: {
      if (BrightnessService.monitors.length > 0) {
        return BrightnessService.monitors[0].brightness || 0
      }
      return 0
    }

    // Get appropriate icon based on current OSD type
    function getIcon() {
      if (currentOSDType === "volume") {
        if (AudioService.muted) {
          return "volume-mute"
        }
        return (AudioService.volume <= Number.EPSILON) ? "volume-zero" : (AudioService.volume <= 0.5) ? "volume-low" : "volume-high"
      } else if (currentOSDType === "brightness") {
        return currentBrightness <= 0.5 ? "brightness-low" : "brightness-high"
      }
      return ""
    }

    // Get current value (0-1 range)
    function getCurrentValue() {
      if (currentOSDType === "volume") {
        return isMuted ? 0 : currentVolume
      } else if (currentOSDType === "brightness") {
        return currentBrightness
      }
      return 0
    }

    // Get display percentage
    function getDisplayPercentage() {
      if (currentOSDType === "volume") {
        if (isMuted)
          return "0%"
        const pct = Math.round(Math.min(1.0, currentVolume) * 100)
        return pct + "%"
      } else if (currentOSDType === "brightness") {
        const pct = Math.round(Math.min(1.0, currentBrightness) * 100)
        return pct + "%"
      }
      return ""
    }

    // Get progress bar color
    function getProgressColor() {
      if (currentOSDType === "volume") {
        if (isMuted)
          return Color.mError
        return Color.mPrimary
      }
      return Color.mPrimary
    }

    // Get icon color
    function getIconColor() {
      if (currentOSDType === "volume" && isMuted) {
        return Color.mError
      }
      return Color.mOnSurface
    }

    sourceComponent: PanelWindow {
      id: panel
      screen: modelData

      readonly property string location: (Settings.isLoaded && Settings.data && Settings.data.osd && Settings.data.osd.location) ? Settings.data.osd.location : "top_right"
      readonly property bool isTop: (location === "top") || (location.length >= 3 && location.substring(0, 3) === "top")
      readonly property bool isBottom: (location === "bottom") || (location.length >= 6 && location.substring(0, 6) === "bottom")
      readonly property bool isLeft: (location.indexOf("_left") >= 0) || (location === "left")
      readonly property bool isRight: (location.indexOf("_right") >= 0) || (location === "right")
      readonly property bool isCentered: (location === "top" || location === "bottom")
      readonly property bool verticalMode: (location === "left" || location === "right")
      readonly property int hWidth: Math.round(320 * root.scaling)
      readonly property int hHeight: Math.round(64 * root.scaling)
      // Ensure an even width to keep the vertical bar perfectly centered
      readonly property int barThickness: (function () {
        const base = Math.max(6, Math.round(6 * root.scaling))
        return (base % 2 === 0) ? base : base + 1
      })()

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

      implicitWidth: verticalMode ? hHeight : hWidth
      implicitHeight: osdItem.height

      color: Color.transparent

      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      exclusionMode: PanelWindow.ExclusionMode.Ignore

      Rectangle {
        id: osdItem

        width: parent.width
        height: panel.verticalMode ? panel.hWidth : Math.round(64 * root.scaling)
        radius: Style.radiusL * root.scaling
        color: Color.mSurface
        border.color: Color.mOutline
        border.width: (function () {
          const bw = Math.max(2, Math.round(Style.borderM * root.scaling))
          return (bw % 2 === 0) ? bw : bw + 1
        })()
        visible: false
        opacity: 0
        scale: 0.85

        anchors.horizontalCenter: verticalMode ? undefined : parent.horizontalCenter
        anchors.verticalCenter: verticalMode ? parent.verticalCenter : undefined

        Behavior on opacity {
          NumberAnimation {
            id: opacityAnimation
            duration: Style.animationNormal
            easing.type: Easing.InOutQuad
          }
        }

        Behavior on scale {
          NumberAnimation {
            id: scaleAnimation
            duration: Style.animationNormal
            easing.type: Easing.InOutQuad
          }
        }

        Timer {
          id: hideTimer
          interval: Settings.data.osd.autoHideMs
          onTriggered: osdItem.hide()
        }

        // Timer to handle visibility after animations complete
        Timer {
          id: visibilityTimer
          interval: Style.animationNormal + 50 // Add small buffer
          onTriggered: {
            osdItem.visible = false
            root.currentOSDType = ""
            // Deactivate the loader when done
            root.active = false
          }
        }

        Loader {
          id: contentLoader
          anchors.fill: parent
          active: true
          sourceComponent: verticalMode ? verticalContent : horizontalContent
        }

        Component {
          id: horizontalContent
          Item {
            anchors.fill: parent

            Row {
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              anchors.margins: Style.marginM * root.scaling
              spacing: Style.marginM * root.scaling

              NIcon {
                icon: root.getIcon()
                color: root.getIconColor()
                font.pointSize: Style.fontSizeXL * root.scaling
                anchors.verticalCenter: parent.verticalCenter

                Behavior on color {
                  ColorAnimation {
                    duration: Style.animationNormal
                    easing.type: Easing.InOutQuad
                  }
                }
              }

              // Progress bar with calculated width
              Rectangle {
                width: Math.round(220 * root.scaling)
                height: panel.barThickness
                radius: Math.round(panel.barThickness / 2)
                color: Color.mSurfaceVariant
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                  anchors.left: parent.left
                  anchors.top: parent.top
                  anchors.bottom: parent.bottom
                  width: parent.width * Math.min(1.0, root.getCurrentValue())
                  radius: parent.radius
                  color: root.getProgressColor()

                  Behavior on width {
                    NumberAnimation {
                      duration: Style.animationNormal
                      easing.type: Easing.InOutQuad
                    }
                  }
                  Behavior on color {
                    ColorAnimation {
                      duration: Style.animationNormal
                      easing.type: Easing.InOutQuad
                    }
                  }
                }
              }

              // Percentage text
              NText {
                text: root.getDisplayPercentage()
                color: Color.mOnSurface
                font.pointSize: Style.fontSizeS * root.scaling
                font.family: Settings.data.ui.fontFixed
                anchors.verticalCenter: parent.verticalCenter
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                width: Math.round(50 * root.scaling)
              }
            }
          }
        }

        Component {
          id: verticalContent
          ColumnLayout {
            // Ensure inner padding respects the rounded corners; avoid clipping the icon/text
            property int vMargin: (function () {
              const styleMargin = Math.round(Style.marginL * root.scaling)
              const cornerGuard = Math.round(osdItem.radius)
              return Math.max(styleMargin, cornerGuard)
            })()
            property int vMarginTop: Math.max(Math.round(osdItem.radius), Math.round(Style.marginS * root.scaling))
            property int balanceDelta: Math.round(Style.marginS * root.scaling)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.topMargin: vMarginTop
            anchors.bottomMargin: vMargin
            width: (function () {
              const w = parent.width - (vMargin * 2)
              return (w % 2 === 0) ? w : w - 1
            })()
            spacing: Math.round(Style.marginS * root.scaling)

            // Percentage text at top
            Item {
              Layout.fillWidth: true
              Layout.preferredHeight: percentText.implicitHeight
              NText {
                id: percentText
                text: root.getDisplayPercentage()
                color: Color.mOnSurface
                font.pointSize: Style.fontSizeS * root.scaling
                font.family: Settings.data.ui.fontFixed
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
              }
            }

            // Progress bar
            Item {
              Layout.fillWidth: true
              Layout.fillHeight: true
              Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: panel.barThickness
                radius: Math.round(panel.barThickness / 2)
                color: Color.mSurfaceVariant

                Rectangle {
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.bottom: parent.bottom
                  height: parent.height * Math.min(1.0, root.getCurrentValue())
                  radius: parent.radius
                  color: root.getProgressColor()

                  Behavior on height {
                    NumberAnimation {
                      duration: Style.animationNormal
                      easing.type: Easing.InOutQuad
                    }
                  }
                  Behavior on color {
                    ColorAnimation {
                      duration: Style.animationNormal
                      easing.type: Easing.InOutQuad
                    }
                  }
                }
              }
            }

            // Icon at bottom
            NIcon {
              icon: root.getIcon()
              color: root.getIconColor()
              font.pointSize: Style.fontSizeXL * root.scaling
              Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
              Layout.bottomMargin: vMargin + Math.round(Style.marginM * root.scaling) + balanceDelta
              Behavior on color {
                ColorAnimation {
                  duration: Style.animationNormal
                  easing.type: Easing.InOutQuad
                }
              }
            }
          }
        }

        function show() {
          // Cancel any pending hide operations
          hideTimer.stop()
          visibilityTimer.stop()

          // Make visible and animate in
          osdItem.visible = true
          // Use Qt.callLater to ensure the visible change is processed before animation
          Qt.callLater(function () {
            osdItem.opacity = 1
            osdItem.scale = 1.0
          })

          // Start the auto-hide timer
          hideTimer.start()
        }

        function hide() {
          hideTimer.stop()
          visibilityTimer.stop()

          // Start fade out animation
          osdItem.opacity = 0
          osdItem.scale = 0.85 // Less dramatic scale change for smoother effect

          // Delay hiding the element until after animation completes
          visibilityTimer.start()
        }

        function hideImmediately() {
          hideTimer.stop()
          visibilityTimer.stop()
          osdItem.opacity = 0
          osdItem.scale = 0.85
          osdItem.visible = false
          root.currentOSDType = ""
          root.active = false
        }
      }

      function showOSD() {
        osdItem.show()
      }
    }

    // Volume change monitoring
    Connections {
      target: AudioService

      function onVolumeChanged() {
        if (volumeInitialized) {
          showOSD("volume")
        }
      }

      function onMutedChanged() {
        if (muteInitialized) {
          showOSD("volume")
        }
      }
    }

    // Timer to initialize volume/mute flags after services are ready
    Timer {
      id: initTimer
      interval: 500
      running: true
      onTriggered: {
        volumeInitialized = true
        muteInitialized = true
      }
    }

    // Brightness change monitoring
    Connections {
      target: BrightnessService

      function onMonitorsChanged() {
        connectBrightnessMonitors()
      }
    }

    Component.onCompleted: {
      connectBrightnessMonitors()
    }

    function connectBrightnessMonitors() {
      for (var i = 0; i < BrightnessService.monitors.length; i++) {
        let monitor = BrightnessService.monitors[i]
        // Disconnect first to avoid duplicate connections
        monitor.brightnessUpdated.disconnect(onBrightnessChanged)
        monitor.brightnessUpdated.connect(onBrightnessChanged)
      }
    }

    function onBrightnessChanged(newBrightness) {
      if (!brightnessInitialized) {
        brightnessInitialized = true
      } else {
        showOSD("brightness")
      }
    }

    function showOSD(type) {
      // Check if OSD is enabled in settings and can show on this screen
      if (!Settings.data.osd.enabled || !canShowOnThisScreen) {
        return
      }

      // Update the current OSD type
      currentOSDType = type

      // Activate the loader if not already active
      if (!root.active) {
        root.active = true
      }

      // Show the OSD (may need to wait for loader to create the item)
      if (root.item) {
        root.item.showOSD()
      } else {
        // If item not ready yet, wait for it
        Qt.callLater(function () {
          if (root.item) {
            root.item.showOSD()
          }
        })
      }
    }

    function hideOSD() {
      if (root.item && root.item.osdItem) {
        root.item.osdItem.hideImmediately()
      } else if (root.active) {
        // If loader is active but item isn't ready, just deactivate
        root.active = false
      }
    }
  }
}

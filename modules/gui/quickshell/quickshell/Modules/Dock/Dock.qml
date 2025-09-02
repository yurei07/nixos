import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
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

    active: Settings.isLoaded && modelData ? Settings.data.dock.monitors.includes(modelData.name) : false

    sourceComponent: PanelWindow {
      id: dockWindow

      screen: modelData

      property bool autoHide: Settings.data.dock.autoHide
      property bool hidden: autoHide
      property int hideDelay: 500
      property int showDelay: 100
      property int hideAnimationDuration: Style.animationFast
      property int showAnimationDuration: Style.animationFast
      property int peekHeight: 7 * scaling
      property int fullHeight: dockContainer.height
      property int iconSize: 36

      // Bar positioning properties
      property bool barAtBottom: Settings.data.bar.position === "bottom"
      property int barHeight: barAtBottom ? (Settings.data.bar.height || 30) * scaling : 0
      property int dockSpacing: 4 * scaling // Space between dock and bar

      // Track hover state
      property bool dockHovered: false
      property bool anyAppHovered: false

      // Dock is positioned at the bottom
      anchors.bottom: true

      // Dock should be above bar but not create its own exclusion zone
      exclusionMode: ExclusionMode.Ignore
      focusable: false

      // Make the window transparent
      color: Color.transparent

      // Set the window size - always include space for peek area when auto-hide is enabled
      implicitWidth: dockContainer.width
      implicitHeight: fullHeight + (barAtBottom ? barHeight + dockSpacing : 0)

      // Position the entire window above the bar when bar is at bottom
      margins.bottom: barAtBottom ? barHeight : 0

      // Watch for autoHide setting changes
      onAutoHideChanged: {
        if (!autoHide) {
          // If auto-hide is disabled, show the dock
          hidden = false
          hideTimer.stop()
          showTimer.stop()
        } else {
          // If auto-hide is enabled, start hidden
          hidden = true
        }
      }

      // Timer for auto-hide delay
      Timer {
        id: hideTimer
        interval: hideDelay
        onTriggered: {
          if (autoHide && !dockHovered && !anyAppHovered && !peekArea.containsMouse) {
            hidden = true
          }
        }
      }

      // Timer for show delay
      Timer {
        id: showTimer
        interval: showDelay
        onTriggered: {
          if (autoHide) {
            hidden = false
          }
        }
      }

      // Peek area that remains visible when dock is hidden
      MouseArea {
        id: peekArea
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: peekHeight + dockSpacing
        hoverEnabled: autoHide
        visible: autoHide

        onEntered: {
          if (autoHide && hidden) {
            showTimer.start()
          }
        }

        onExited: {
          if (autoHide && !hidden && !dockHovered && !anyAppHovered) {
            hideTimer.restart()
          }
        }
      }

      Rectangle {
        id: dockContainer
        width: dock.width + 48 * scaling
        height: iconSize * 1.4 * scaling
        color: Color.mSurface
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: dockSpacing
        topLeftRadius: Style.radiusL * scaling
        topRightRadius: Style.radiusL * scaling

        // Animate the dock sliding up and down
        transform: Translate {
          y: hidden ? (fullHeight - peekHeight) : 0

          Behavior on y {
            NumberAnimation {
              duration: hidden ? hideAnimationDuration : showAnimationDuration
              easing.type: Easing.InOutQuad
            }
          }
        }

        // Drop shadow for better visibility when bar is transparent
        layer.enabled: true
        layer.effect: MultiEffect {
          shadowEnabled: true
          shadowColor: Qt.rgba(0, 0, 0, 0.3)
          shadowBlur: 0.5
          shadowVerticalOffset: 2
          shadowHorizontalOffset: 0
        }

        MouseArea {
          id: dockMouseArea
          anchors.fill: parent
          hoverEnabled: true

          onEntered: {
            dockHovered = true
            if (autoHide) {
              showTimer.stop()
              hideTimer.stop()
              if (hidden) {
                hidden = false
              }
            }
          }

          onExited: {
            dockHovered = false
            // Only start hide timer if we're not hovering over any app or the peek area
            if (autoHide && !anyAppHovered && !peekArea.containsMouse) {
              hideTimer.restart()
            }
          }
        }

        Item {
          id: dock
          width: runningAppsRow.width
          height: parent.height - (20 * scaling)
          anchors.centerIn: parent

          NTooltip {
            id: appTooltip
            visible: false
            positionAbove: true
          }

          function getAppIcon(toplevel: Toplevel): string {
            if (!toplevel)
              return ""
            return Icons.iconForAppId(toplevel.appId?.toLowerCase())
          }

          Row {
            id: runningAppsRow
            spacing: Style.marginL * scaling
            height: parent.height
            anchors.centerIn: parent

            Repeater {
              model: ToplevelManager ? ToplevelManager.toplevels : null

              delegate: Rectangle {
                id: appButton
                width: iconSize * scaling
                height: iconSize * scaling
                color: Color.transparent
                radius: Style.radiusM * scaling

                property bool isActive: ToplevelManager.activeToplevel && ToplevelManager.activeToplevel === modelData
                property bool hovered: appMouseArea.containsMouse
                property string appId: modelData ? modelData.appId : ""
                property string appTitle: modelData ? modelData.title : ""

                // Hover background
                Rectangle {
                  id: hoverBackground
                  anchors.fill: parent
                  color: appButton.hovered ? Color.mSurfaceVariant : Color.transparent
                  radius: parent.radius
                  opacity: appButton.hovered ? 0.8 : 0

                  Behavior on opacity {
                    NumberAnimation {
                      duration: Style.animationFast
                      easing.type: Easing.OutQuad
                    }
                  }
                }

                // The icon
                Image {
                  id: appIcon
                  width: iconSize * scaling
                  height: iconSize * scaling
                  anchors.centerIn: parent
                  source: dock.getAppIcon(modelData)
                  visible: source.toString() !== ""
                  smooth: true
                  mipmap: false
                  antialiasing: false
                  fillMode: Image.PreserveAspectFit

                  scale: appButton.hovered ? 1.1 : 1.0

                  Behavior on scale {
                    NumberAnimation {
                      duration: Style.animationFast
                      easing.type: Easing.OutBack
                    }
                  }
                }

                // Fall back if no icon
                NText {
                  anchors.centerIn: parent
                  visible: !appIcon.visible
                  text: "question_mark"
                  font.family: "Material Symbols Rounded"
                  font.pointSize: iconSize * 0.7 * scaling
                  color: appButton.isActive ? Color.mPrimary : Color.mOnSurfaceVariant

                  scale: appButton.hovered ? 1.1 : 1.0

                  Behavior on scale {
                    NumberAnimation {
                      duration: Style.animationFast
                      easing.type: Easing.OutBack
                    }
                  }
                }

                MouseArea {
                  id: appMouseArea
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  acceptedButtons: Qt.LeftButton | Qt.MiddleButton

                  onEntered: {
                    anyAppHovered = true
                    const appName = appButton.appTitle || appButton.appId || "Unknown"
                    appTooltip.text = appName.length > 40 ? appName.substring(0, 37) + "..." : appName
                    appTooltip.target = appButton
                    appTooltip.isVisible = true
                    if (autoHide) {
                      showTimer.stop()
                      hideTimer.stop()
                      if (hidden) {
                        hidden = false
                      }
                    }
                  }

                  onExited: {
                    anyAppHovered = false
                    appTooltip.hide()
                    // Only start hide timer if we're not hovering over the dock or peek area
                    if (autoHide && !dockHovered && !peekArea.containsMouse) {
                      hideTimer.restart()
                    }
                  }

                  onClicked: function (mouse) {
                    if (mouse.button === Qt.MiddleButton && modelData?.close) {
                      modelData.close()
                    }
                    if (mouse.button === Qt.LeftButton && modelData?.activate) {
                      modelData.activate()
                    }
                  }
                }

                Rectangle {
                  visible: isActive
                  width: iconSize * 0.75
                  height: 4 * scaling
                  color: Color.mPrimary
                  radius: Style.radiusXS
                  anchors.top: parent.bottom
                  anchors.horizontalCenter: parent.horizontalCenter
                  anchors.topMargin: Style.marginXXS * scaling
                }
              }
            }
          }
        }
      }
    }
  }
}

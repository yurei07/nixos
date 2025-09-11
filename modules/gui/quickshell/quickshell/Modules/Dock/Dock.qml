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

      WlrLayershell.namespace: "noctalia-dock"

      readonly property bool autoHide: Settings.data.dock.autoHide
      readonly property int hideDelay: 500
      readonly property int showDelay: 100
      readonly property int hideAnimationDuration: Style.animationFast
      readonly property int showAnimationDuration: Style.animationFast
      readonly property int peekHeight: 7 * scaling
      readonly property int fullHeight: dockContainer.height
      readonly property int iconSize: 36 * scaling
      readonly property int floatingMargin: 12 * scaling // Margin to make dock float

      // Bar detection and positioning properties
      readonly property bool hasBar: modelData.name ? (Settings.data.bar.monitors.includes(modelData.name)
                                                       || (Settings.data.bar.monitors.length === 0)) : false
      readonly property bool barAtBottom: hasBar && Settings.data.bar.position === "bottom"
      readonly property bool barAtTop: hasBar && Settings.data.bar.position === "top"
      readonly property int barHeight: (barAtBottom || barAtTop) ? (Settings.data.bar.height || 30) * scaling : 0
      readonly property int dockSpacing: 8 * scaling // Space between dock and bar/edge

      // Track hover state
      property bool dockHovered: false
      property bool anyAppHovered: false
      property bool hidden: autoHide

      // Dock is positioned at the bottom
      anchors.bottom: true

      // Dock should be above bar but not create its own exclusion zone
      exclusionMode: ExclusionMode.Ignore
      focusable: false

      // Make the window transparent
      color: Color.transparent

      // Set the window size - include extra height only if bar is at bottom
      implicitWidth: dockContainer.width + (floatingMargin * 2)
      implicitHeight: fullHeight + floatingMargin + (barAtBottom ? barHeight + dockSpacing : 0)

      // Position the entire window above the bar only when bar is at bottom
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
        height: peekHeight + floatingMargin + (barAtBottom ? dockSpacing : 0)
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
        width: dockLayout.implicitWidth + Style.marginL * scaling * 2
        height: Math.round(iconSize * 1.6)
        color: Qt.alpha(Color.mSurface, Settings.data.dock.backgroundOpacity)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: floatingMargin + (barAtBottom ? dockSpacing : 0)
        radius: Style.radiusL * scaling
        border.width: Math.max(1, Style.borderS * scaling)
        border.color: Color.mOutline

        // Fade and zoom animation properties
        opacity: hidden ? 0 : 1
        scale: hidden ? 0.85 : 1

        Behavior on opacity {
          NumberAnimation {
            duration: hidden ? hideAnimationDuration : showAnimationDuration
            easing.type: Easing.InOutQuad
          }
        }

        Behavior on scale {
          NumberAnimation {
            duration: hidden ? hideAnimationDuration : showAnimationDuration
            easing.type: hidden ? Easing.InQuad : Easing.OutBack
            easing.overshoot: hidden ? 0 : 1.05
          }
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
          width: dockLayout.implicitWidth
          height: parent.height - (Style.marginM * 2 * scaling)
          anchors.centerIn: parent

          function getAppIcon(toplevel: Toplevel): string {
            if (!toplevel)
              return ""
            return AppIcons.iconForAppId(toplevel.appId?.toLowerCase())
          }

          RowLayout {
            id: dockLayout
            spacing: Style.marginL * scaling
            Layout.preferredHeight: parent.height
            anchors.centerIn: parent

            Repeater {
              model: ToplevelManager ? ToplevelManager.toplevels : null

              delegate: Item {
                id: appButton
                Layout.preferredWidth: iconSize
                Layout.preferredHeight: iconSize
                Layout.alignment: Qt.AlignCenter

                property bool isActive: ToplevelManager.activeToplevel && ToplevelManager.activeToplevel === modelData
                property bool hovered: appMouseArea.containsMouse
                property string appId: modelData ? modelData.appId : ""
                property string appTitle: modelData ? modelData.title : ""

                // Individual tooltip for this app
                NTooltip {
                  id: appTooltip
                  target: appButton
                  positionAbove: true
                  visible: false
                }

                // The icon with better quality settings
                Image {
                  id: appIcon
                  width: iconSize
                  height: iconSize
                  anchors.centerIn: parent
                  source: dock.getAppIcon(modelData)
                  visible: source.toString() !== ""
                  sourceSize.width: iconSize * 2
                  sourceSize.height: iconSize * 2
                  smooth: true
                  mipmap: true
                  antialiasing: true
                  fillMode: Image.PreserveAspectFit
                  cache: true

                  scale: appButton.hovered ? 1.15 : 1.0

                  Behavior on scale {
                    NumberAnimation {
                      duration: Style.animationNormal
                      easing.type: Easing.OutBack
                      easing.overshoot: 1.2
                    }
                  }
                }

                // Fall back if no icon
                NIcon {
                  anchors.centerIn: parent
                  visible: !appIcon.visible
                  icon: "question-mark"
                  font.pointSize: iconSize * 0.7
                  color: appButton.isActive ? Color.mPrimary : Color.mOnSurfaceVariant
                  scale: appButton.hovered ? 1.15 : 1.0

                  Behavior on scale {
                    NumberAnimation {
                      duration: Style.animationFast
                      easing.type: Easing.OutBack
                      easing.overshoot: 1.2
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

                // Active indicator
                Rectangle {
                  visible: isActive
                  width: iconSize * 0.2
                  height: iconSize * 0.1
                  color: Color.mPrimary
                  radius: Style.radiusXS * scaling
                  anchors.top: parent.bottom
                  anchors.horizontalCenter: parent.horizontalCenter
                  anchors.topMargin: Style.marginXXS * 1.5 * scaling

                  // Pulse animation for active indicator
                  SequentialAnimation on opacity {
                    running: isActive
                    loops: Animation.Infinite
                    NumberAnimation {
                      to: 0.6
                      duration: Style.animationSlowest
                      easing.type: Easing.InOutQuad
                    }
                    NumberAnimation {
                      to: 1.0
                      duration: Style.animationSlowest
                      easing.type: Easing.InOutQuad
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}

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

NLoader {
  isLoaded: (Settings.data.dock.monitors.length > 0)
  content: Component {
    Variants {
      model: Quickshell.screens

      PanelWindow {
        id: dockWindow

        required property ShellScreen modelData
        readonly property real scaling: ScalingService.scale(screen)
        screen: modelData

        // Auto-hide properties - make reactive to settings changes
        property bool autoHide: Settings.data.dock.autoHide
        property bool hidden: autoHide
        property int hideDelay: 500
        property int showDelay: 100
        property int hideAnimationDuration: Style.animationFast
        property int showAnimationDuration: Style.animationFast
        property int peekHeight: 2
        property int fullHeight: dockContainer.height
        property int iconSize: 36

        // Track hover state
        property bool dockHovered: false
        property bool anyAppHovered: false

        // Dock is only shown if explicitely toggled
        visible: modelData ? Settings.data.dock.monitors.includes(modelData.name) : false

        exclusionMode: ExclusionMode.Ignore

        anchors.bottom: true
        anchors.left: true
        anchors.right: true
        focusable: false
        color: Color.transparent
        implicitHeight: iconSize * 1.4 * scaling

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
            if (autoHide && !dockHovered && !anyAppHovered) {
              hidden = true
            }
          }
        }

        // Timer for show delay
        Timer {
          id: showTimer
          interval: showDelay
          onTriggered: hidden = false
        }

        // Behavior for smooth hide/show animations
        Behavior on margins.bottom {
          NumberAnimation {
            duration: hidden ? hideAnimationDuration : showAnimationDuration
            easing.type: Easing.InOutQuad
          }
        }

        MouseArea {
          id: screenEdgeMouseArea
          x: 0
          y: modelData && modelData.geometry ? modelData.geometry.height - (fullHeight + 10 * scaling) : 0
          width: screen.width
          height: fullHeight + 10 * scaling
          hoverEnabled: true
          propagateComposedEvents: true

          onEntered: {
            if (autoHide && hidden) {
              showTimer.start()
            }
          }
          onExited: {
            if (autoHide && !hidden && !dockHovered && !anyAppHovered) {
              hideTimer.start()
            }
          }
        }

        margins.bottom: hidden ? -(fullHeight - peekHeight) : 0

        Rectangle {
          id: dockContainer
          width: dock.width + 48 * scaling
          height: iconSize * 1.4 * scaling
          color: Color.mSurface
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.bottom: parent.bottom
          topLeftRadius: Style.radiusL * scaling
          topRightRadius: Style.radiusL * scaling

          MouseArea {
            id: dockMouseArea
            anchors.fill: parent
            hoverEnabled: true
            propagateComposedEvents: true

            onEntered: {
              dockHovered = true
              if (autoHide) {
                showTimer.stop()
                hideTimer.stop()
                hidden = false
              }
            }
            onExited: {
              dockHovered = false
              // Only start hide timer if we're not hovering over any app
              if (autoHide && !anyAppHovered) {
                hideTimer.start()
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
              let icon = Quickshell.iconPath(toplevel.appId?.toLowerCase(), true)
              if (!icon)
                icon = Quickshell.iconPath(toplevel.appId, true)
              if (!icon)
                icon = Quickshell.iconPath(toplevel.title?.toLowerCase(), true)
              if (!icon)
                icon = Quickshell.iconPath(toplevel.title, true)
              return icon || Quickshell.iconPath("application-x-executable", true)
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
                        hidden = false
                      }
                    }

                    onExited: {
                      anyAppHovered = false
                      appTooltip.hide()
                      // Only start hide timer if we're not hovering over the dock
                      if (autoHide && !dockHovered) {
                        hideTimer.start()
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
}

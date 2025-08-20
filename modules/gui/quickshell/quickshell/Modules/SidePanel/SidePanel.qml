import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Modules.SidePanel.Cards
import qs.Commons
import qs.Services
import qs.Widgets

NLoader {
  id: root

  // X coordinate on screen (in pixels) where the panel should align its center.
  // Set via openAt(x) from the bar button.
  property real anchorX: 0
  // Target screen to open on
  property var targetScreen: null

  function openAt(x, screen) {
    anchorX = x
    targetScreen = screen
    isLoaded = true
    // If the panel is already instantiated, update immediately
    if (item) {
      if (item.anchorX !== undefined)
        item.anchorX = anchorX
      if (item.screen !== undefined)
        item.screen = targetScreen
    }
  }

  content: Component {
    NPanel {
      id: sidePanel

      // Single source of truth for spacing between cards (both axes)
      property real cardSpacing: Style.marginL * scaling
      // X coordinate from the bar to align this panel under
      property real anchorX: root.anchorX
      // Ensure this panel attaches to the intended screen
      screen: root.targetScreen

      // Override hide function to animate first
      function hide() {
        // Start hide animation
        panelBackground.scaleValue = 0.8
        panelBackground.opacityValue = 0.0

        // Hide after animation completes
        hideTimer.start()
      }

      // Connect to NPanel's dismissed signal to handle external close events
      Connections {
        target: sidePanel
        function onDismissed() {
          // Start hide animation
          panelBackground.scaleValue = 0.8
          panelBackground.opacityValue = 0.0

          // Hide after animation completes
          hideTimer.start()
        }
      }

      // Also handle visibility changes from external sources
      onVisibleChanged: {
        if (!visible && panelBackground.opacityValue > 0) {
          // Start hide animation
          panelBackground.scaleValue = 0.8
          panelBackground.opacityValue = 0.0

          // Hide after animation completes
          hideTimer.start()
        }
      }

      // Ensure panel shows itself once created
      Component.onCompleted: show()

      // Inline helpers moved to dedicated widgets: NCard and NCircleStat
      Rectangle {
        id: panelBackground
        color: Color.mSurface
        radius: Style.radiusL * scaling
        border.color: Color.mOutline
        border.width: Math.max(1, Style.borderS * scaling)
        layer.enabled: true
        width: 460 * scaling
        property real innerMargin: sidePanel.cardSpacing
        // Height scales to content plus vertical padding
        height: content.implicitHeight + innerMargin * 2
        // Place the panel relative to the bar based on its position
        y: Settings.data.bar.position === "top" ? Style.marginS * scaling : undefined
        anchors {
          bottom: Settings.data.bar.position === "bottom" ? parent.bottom : undefined
          bottomMargin: Settings.data.bar.position === "bottom" ? Style.barHeight * scaling + Style.marginS * scaling : undefined
        }
        // Center horizontally under the anchorX, clamped to the screen bounds
        x: Math.max(Style.marginS * scaling, Math.min(parent.width - width - Style.marginS * scaling,
                                                      Math.round(anchorX - width / 2)))

        // Animation properties
        property real scaleValue: 0.8
        property real opacityValue: 0.0

        scale: scaleValue
        opacity: opacityValue

        // Animate in when component is completed
        Component.onCompleted: {
          scaleValue = 1.0
          opacityValue = 1.0
        }

        // Timer to hide panel after animation
        Timer {
          id: hideTimer
          interval: Style.animationSlow
          repeat: false
          onTriggered: {
            sidePanel.visible = false
            sidePanel.dismissed()
          }
        }

        // Prevent closing when clicking in the panel bg
        MouseArea {
          anchors.fill: parent
        }

        // Animation behaviors
        Behavior on scale {
          NumberAnimation {
            duration: Style.animationSlow
            easing.type: Easing.OutExpo
          }
        }

        Behavior on opacity {
          NumberAnimation {
            duration: Style.animationNormal
            easing.type: Easing.OutQuad
          }
        }

        // Content wrapper to ensure childrenRect drives implicit height
        Item {
          id: content
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.margins: panelBackground.innerMargin
          implicitHeight: layout.implicitHeight

          // Layout content (not vertically anchored so implicitHeight is valid)
          ColumnLayout {
            id: layout
            // Use the same spacing value horizontally and vertically
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            spacing: sidePanel.cardSpacing

            // Cards (consistent inter-card spacing via ColumnLayout spacing)
            ProfileCard {
              Layout.topMargin: 0
              Layout.bottomMargin: 0
            }
            WeatherCard {
              Layout.topMargin: 0
              Layout.bottomMargin: 0
            }

            // Middle section: media + stats column
            RowLayout {
              Layout.fillWidth: true
              Layout.topMargin: 0
              Layout.bottomMargin: 0
              spacing: sidePanel.cardSpacing

              // Media card
              MediaCard {
                id: mediaCard
                Layout.fillWidth: true
                implicitHeight: statsCard.implicitHeight
              }

              // System monitors combined in one card
              SystemMonitorCard {
                id: statsCard
              }
            }

            // Bottom actions (two grouped rows of round buttons)
            RowLayout {
              Layout.fillWidth: true
              Layout.topMargin: 0
              Layout.bottomMargin: 0
              spacing: sidePanel.cardSpacing

              // Power Profiles switcher
              PowerProfilesCard {}

              // Utilities buttons
              UtilitiesCard {}
            }
          }
        }
      }
    }
  }
}

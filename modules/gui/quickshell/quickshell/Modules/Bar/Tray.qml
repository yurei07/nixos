import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.Commons
import qs.Services
import qs.Widgets

Item {
  readonly property real itemSize: 24 * scaling

  visible: Settings.data.bar.showTray
  width: tray.width
  height: itemSize

  Row {
    id: tray

    spacing: Style.marginSmall * scaling
    Layout.alignment: Qt.AlignVCenter

    Repeater {
      id: repeater
      model: SystemTray.items
      delegate: Item {
        width: itemSize
        height: itemSize
        visible: modelData

        IconImage {
          id: trayIcon
          anchors.centerIn: parent
          width: Style.marginLarge * scaling
          height: Style.marginLarge * scaling
          smooth: false
          asynchronous: true
          backer.fillMode: Image.PreserveAspectFit
          source: {
            let icon = modelData?.icon || ""
            if (!icon) {
              return ""
            }

            // Process icon path
            if (icon.includes("?path=")) {
              // Seems qmlfmt does not support the following ES6 syntax: const[name, path] = icon.split
              const chunks = icon.split("?path=")
              const name = chunks[0]
              const path = chunks[1]
              const fileName = name.substring(name.lastIndexOf("/") + 1)
              return `file://${path}/${fileName}`
            }
            return icon
          }
          opacity: status === Image.Ready ? 1 : 0
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
          onClicked: mouse => {
                       if (!modelData) {
                         return
                       }

                       if (mouse.button === Qt.LeftButton) {
                         // Close any open menu first
                         if (trayMenu && trayMenu.visible) {
                           trayMenu.hideMenu()
                         }

                         if (!modelData.onlyMenu) {
                           modelData.activate()
                         }
                       } else if (mouse.button === Qt.MiddleButton) {
                         // Close any open menu first
                         if (trayMenu && trayMenu.visible) {
                           trayMenu.hideMenu()
                         }

                         modelData.secondaryActivate && modelData.secondaryActivate()
                       } else if (mouse.button === Qt.RightButton) {
                         trayTooltip.hide()
                         // If menu is already visible, close it
                         if (trayMenu && trayMenu.visible) {
                           trayMenu.hideMenu()
                           return
                         }

                         if (modelData.hasMenu && modelData.menu && trayMenu) {
                           // Anchor the menu to the tray icon item (parent) and position it below the icon
                           const menuX = (width / 2) - (trayMenu.width / 2)
                           const menuY = (Style.barHeight * scaling)
                           trayMenu.menu = modelData.menu
                           trayMenu.showAt(parent, menuX, menuY)
                           trayPanel.show()
                         } else {

                           Logger.log("Tray", "No menu available for", modelData.id, "or trayMenu not set")
                         }
                       }
                     }
          onEntered: trayTooltip.show()
          onExited: trayTooltip.hide()
        }

        NTooltip {
          id: trayTooltip
          target: trayIcon
          text: modelData.tooltipTitle || modelData.name || modelData.id || "Tray Item"
        }
      }
    }
  }

  // Attached TrayMenu drop down
  // Wrapped in NPanel so we can detect click outside of the menu to close the TrayMenu
  NPanel {
    id: trayPanel
    showOverlay: false // no colors overlay even if activated in settings

    // Override hide function to animate first
    function hide() {
      // Start hide animation
      trayMenuRect.scaleValue = 0.8
      trayMenuRect.opacityValue = 0.0

      // Hide after animation completes
      hideTimer.start()
    }

    Connections {
      target: trayPanel
      ignoreUnknownSignals: true
      function onDismissed() {
        // Start hide animation
        trayMenuRect.scaleValue = 0.8
        trayMenuRect.opacityValue = 0.0

        // Hide after animation completes
        hideTimer.start()
      }
    }

    // Also handle visibility changes from external sources
    onVisibleChanged: {
      if (!visible && trayMenuRect.opacityValue > 0) {
        // Start hide animation
        trayMenuRect.scaleValue = 0.8
        trayMenuRect.opacityValue = 0.0

        // Hide after animation completes
        hideTimer.start()
      }
    }

    // Timer to hide panel after animation
    Timer {
      id: hideTimer
      interval: Style.animationSlow
      repeat: false
      onTriggered: {
        trayPanel.visible = false
        trayMenu.hideMenu()
      }
    }

    Rectangle {
      id: trayMenuRect
      color: Color.transparent
      anchors.fill: parent

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

      TrayMenu {
        id: trayMenu
      }
    }
  }
}

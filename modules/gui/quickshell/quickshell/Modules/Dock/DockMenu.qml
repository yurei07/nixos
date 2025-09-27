import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Commons
import qs.Services
import qs.Widgets

PopupWindow {
  id: root

  property var toplevel: null
  property Item anchorItem: null
  property real scaling: 1.0
  property bool hovered: menuMouseArea.containsMouse || activateMouseArea.containsMouse || pinMouseArea.containsMouse || closeMouseArea.containsMouse
  property var onAppClosed: null // Callback function for when an app is closed

  signal requestClose

  implicitWidth: 140 * scaling
  implicitHeight: contextMenuColumn.implicitHeight + (Style.marginM * scaling * 2)
  color: Color.transparent
  visible: false

  // Helper functions for pin/unpin functionality
  function isAppPinned(appId) {
    if (!appId)
      return false
    const pinnedApps = Settings.data.dock.pinnedApps || []
    return pinnedApps.includes(appId)
  }

  function toggleAppPin(appId) {
    if (!appId)
      return

    let pinnedApps = (Settings.data.dock.pinnedApps || []).slice() // Create a copy
    const isPinned = pinnedApps.includes(appId)

    if (isPinned) {
      // Unpin: remove from array
      pinnedApps = pinnedApps.filter(id => id !== appId)
    } else {
      // Pin: add to array
      pinnedApps.push(appId)
    }

    // Update the settings
    Settings.data.dock.pinnedApps = pinnedApps
  }

  anchor.item: anchorItem
  anchor.rect.x: anchorItem ? (anchorItem.width - implicitWidth) / 2 : 0
  anchor.rect.y: anchorItem ? -implicitHeight - (Style.marginM * scaling) : 0

  function show(item, toplevelData) {
    if (!item) {
      Logger.warn("DockMenu", "anchorItem is undefined, won't show menu.")
      return
    }

    anchorItem = item
    toplevel = toplevelData
    visible = true
  }

  function hide() {
    visible = false
  }

  // Close menu when clicking on background, track hover for the whole menu area
  MouseArea {
    id: menuMouseArea
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: function (mouse) {
      if (mouse.button === Qt.RightButton) {
        root.hide() // Close on right-click
      } else {
        root.hide() // Close when clicking on the background (outside menu content)
      }
    }
  }

  Shortcut {
    sequences: ["Escape"]
    enabled: root.visible
    onActivated: root.hide()
  }

  Rectangle {
    anchors.fill: parent
    color: Color.mSurfaceVariant
    radius: Style.radiusS * scaling
    border.color: Color.mOutline
    border.width: Math.max(1, Style.borderS * scaling)

    // Prevent clicks inside the menu from closing it
    MouseArea {
      anchors.fill: parent
      onClicked: {

      } // Do nothing, just consume the click
    }

    Column {
      id: contextMenuColumn
      anchors.fill: parent
      anchors.margins: Style.marginM * scaling
      spacing: 0

      // Focus item
      Rectangle {
        width: parent.width
        height: 32 * scaling
        color: activateMouseArea.containsMouse ? Color.mTertiary : Color.transparent
        radius: Style.radiusXS * scaling

        Row {
          anchors.left: parent.left
          anchors.leftMargin: Style.marginS * scaling
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.marginS * scaling

          NIcon {
            icon: "eye"
            font.pointSize: Style.fontSizeL * scaling
            color: activateMouseArea.containsMouse ? Color.mOnTertiary : Color.mOnSurfaceVariant
            anchors.verticalCenter: parent.verticalCenter
          }

          NText {
            text: I18n.tr("dock.menu.focus")
            font.pointSize: Style.fontSizeS * scaling
            color: activateMouseArea.containsMouse ? Color.mOnTertiary : Color.mOnSurfaceVariant
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        MouseArea {
          id: activateMouseArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor

          onClicked: {
            if (root.toplevel?.activate) {
              root.toplevel.activate()
            }
            root.requestClose()
          }
        }
      }

      // Pin/Unpin item
      Rectangle {
        width: parent.width
        height: 32 * scaling
        color: pinMouseArea.containsMouse ? Color.mTertiary : Color.transparent
        radius: Style.radiusXS * scaling

        Row {
          anchors.left: parent.left
          anchors.leftMargin: Style.marginS * scaling
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.marginS * scaling

          NIcon {
            icon: {
              if (!root.toplevel)
                return "pin"
              return root.isAppPinned(root.toplevel.appId) ? "unpin" : "pin"
            }
            font.pointSize: Style.fontSizeL * scaling
            color: pinMouseArea.containsMouse ? Color.mOnTertiary : Color.mOnSurfaceVariant
            anchors.verticalCenter: parent.verticalCenter
          }

          NText {
            text: {
              if (!root.toplevel)
                return I18n.tr("dock.menu.pin")
              return root.isAppPinned(root.toplevel.appId) ? I18n.tr("dock.menu.unpin") : I18n.tr("dock.menu.pin")
            }
            font.pointSize: Style.fontSizeS * scaling
            color: pinMouseArea.containsMouse ? Color.mOnTertiary : Color.mOnSurfaceVariant
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        MouseArea {
          id: pinMouseArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor

          onClicked: {
            if (root.toplevel?.appId) {
              root.toggleAppPin(root.toplevel.appId)
            }
            //root.hide()
            root.requestClose()
          }
        }
      }

      // Close item
      Rectangle {
        width: parent.width
        height: 32 * scaling
        color: closeMouseArea.containsMouse ? Color.mTertiary : Color.transparent
        radius: Style.radiusXS * scaling

        Row {
          anchors.left: parent.left
          anchors.leftMargin: Style.marginS * scaling
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.marginS * scaling

          NIcon {
            icon: "close"
            font.pointSize: Style.fontSizeL * scaling
            color: closeMouseArea.containsMouse ? Color.mOnTertiary : Color.mOnSurfaceVariant
            anchors.verticalCenter: parent.verticalCenter
          }

          NText {
            text: I18n.tr("dock.menu.close")
            font.pointSize: Style.fontSizeS * scaling
            color: closeMouseArea.containsMouse ? Color.mOnTertiary : Color.mOnSurfaceVariant
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        MouseArea {
          id: closeMouseArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor

          onClicked: {
            // Check if toplevel is still valid before trying to close it
            const isValidToplevel = root.toplevel && ToplevelManager && ToplevelManager.toplevels.values.includes(root.toplevel)

            if (isValidToplevel && root.toplevel.close) {
              root.toplevel.close()
              // Trigger immediate dock update callback if provided
              if (root.onAppClosed && typeof root.onAppClosed === "function") {
                Qt.callLater(root.onAppClosed)
              }
            } else {
              Logger.warn("DockMenu", "Cannot close app - invalid toplevel reference")
            }
            root.hide()
            root.requestClose()
          }
        }
      }
    }
  }
}

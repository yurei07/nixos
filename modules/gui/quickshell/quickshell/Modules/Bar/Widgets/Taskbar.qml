pragma ComponentBehavior

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import qs.Commons
import qs.Services
import qs.Widgets

Rectangle {
  id: root
  property ShellScreen screen
  property real scaling: 1.0

  readonly property real itemSize: Style.baseWidgetSize * 0.8 * scaling

  // Always visible when there are toplevels
  implicitWidth: taskbarLayout.implicitWidth + Style.marginM * scaling * 2
  implicitHeight: Math.round(Style.capsuleHeight * scaling)
  radius: Math.round(Style.radiusM * scaling)
  color: Color.mSurfaceVariant

  RowLayout {
    id: taskbarLayout
    anchors.centerIn: parent
    spacing: Style.marginXXS * root.scaling

    Repeater {
      model: ToplevelManager && ToplevelManager.toplevels ? ToplevelManager.toplevels : []
      delegate: Item {
        id: taskbarItem
        required property Toplevel modelData
        property Toplevel toplevel: modelData
        property bool isActive: ToplevelManager.activeToplevel === modelData

        Layout.preferredWidth: root.itemSize
        Layout.preferredHeight: root.itemSize
        Layout.alignment: Qt.AlignCenter

        Rectangle {
          id: iconBackground
          anchors.centerIn: parent
          width: root.itemSize * 0.75
          height: root.itemSize * 0.75
          color: taskbarItem.isActive ? Color.mPrimary : root.color
          border.width: 0
          radius: Math.round(Style.radiusXS * root.scaling)
          border.color: "transparent"
          z: -1

          IconImage {
            id: appIcon
            anchors.centerIn: parent
            width: Style.marginL * root.scaling
            height: Style.marginL * root.scaling
            source: AppIcons.iconForAppId(taskbarItem.modelData.appId)
            smooth: true
          }
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          acceptedButtons: Qt.LeftButton | Qt.RightButton

          onPressed: function (mouse) {
            if (!taskbarItem.modelData)
              return

            if (mouse.button === Qt.LeftButton) {
              try {
                taskbarItem.modelData.activate()
              } catch (error) {
                Logger.error("Taskbar", "Failed to activate toplevel: " + error)
              }
            } else if (mouse.button === Qt.RightButton) {
              try {
                taskbarItem.modelData.close()
              } catch (error) {
                Logger.error("Taskbar", "Failed to close toplevel: " + error)
              }
            }
          }
          onEntered: taskbarTooltip.show()
          onExited: taskbarTooltip.hide()
        }

        NTooltip {
          id: taskbarTooltip
          text: taskbarItem.modelData.title || taskbarItem.modelData.appId || "Unknown App."
          target: taskbarItem
          positionAbove: Settings.data.bar.position === "bottom"
        }
      }
    }
  }
}

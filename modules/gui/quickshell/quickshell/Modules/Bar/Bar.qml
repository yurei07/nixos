import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.UPower
import qs.Commons
import qs.Services
import qs.Widgets
import qs.Modules.Notification

Variants {
  model: Quickshell.screens

  delegate: Loader {
    id: root

    required property ShellScreen modelData
    property real scaling: ScalingService.getScreenScale(modelData)

    Connections {
      target: ScalingService
      function onScaleChanged(screenName, scale) {
        if ((modelData !== null) && (screenName === modelData.name)) {
          scaling = scale
        }
      }
    }

    active: Settings.isLoaded && modelData && modelData.name ? (Settings.data.bar.monitors.includes(modelData.name)
                                                                || (Settings.data.bar.monitors.length === 0)) : false

    sourceComponent: PanelWindow {
      screen: modelData || null

      WlrLayershell.namespace: "noctalia-bar"

      implicitHeight: Math.round(Style.barHeight * scaling)
      color: Color.transparent

      anchors {
        top: Settings.data.bar.position === "top"
        bottom: Settings.data.bar.position === "bottom"
        left: true
        right: true
      }

      Item {
        anchors.fill: parent
        clip: true

        // Background fill
        Rectangle {
          id: bar

          anchors.fill: parent
          color: Qt.alpha(Color.mSurface, Settings.data.bar.backgroundOpacity)
        }

        // ------------------------------
        // Left Section - Dynamic Widgets
        Row {
          id: leftSection
          objectName: "leftSection"

          height: parent.height
          anchors.left: parent.left
          anchors.leftMargin: Style.marginS * scaling
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.marginS * scaling

          Repeater {
            model: Settings.data.bar.widgets.left
            delegate: NWidgetLoader {
              widgetId: (modelData.id !== undefined ? modelData.id : "")
              widgetProps: {
                "screen": root.modelData || null,
                "scaling": ScalingService.getScreenScale(screen),
                "widgetId": modelData.id,
                "barSection": parent.objectName,
                "sectionWidgetIndex": index,
                "sectionWidgetsCount": Settings.data.bar.widgets.left.length
              }
              anchors.verticalCenter: parent.verticalCenter
            }
          }
        }

        // ------------------------------
        // Center Section - Dynamic Widgets
        Row {
          id: centerSection
          objectName: "centerSection"

          height: parent.height
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.marginS * scaling

          Repeater {
            model: Settings.data.bar.widgets.center
            delegate: NWidgetLoader {
              widgetId: (modelData.id !== undefined ? modelData.id : "")
              widgetProps: {
                "screen": root.modelData || null,
                "scaling": ScalingService.getScreenScale(screen),
                "widgetId": modelData.id,
                "barSection": parent.objectName,
                "sectionWidgetIndex": index,
                "sectionWidgetsCount": Settings.data.bar.widgets.center.length
              }
              anchors.verticalCenter: parent.verticalCenter
            }
          }
        }

        // ------------------------------
        // Right Section - Dynamic Widgets
        Row {
          id: rightSection
          objectName: "rightSection"

          height: parent.height
          anchors.right: bar.right
          anchors.rightMargin: Style.marginS * scaling
          anchors.verticalCenter: bar.verticalCenter
          spacing: Style.marginS * scaling

          Repeater {
            model: Settings.data.bar.widgets.right
            delegate: NWidgetLoader {
              widgetId: (modelData.id !== undefined ? modelData.id : "")
              widgetProps: {
                "screen": root.modelData || null,
                "scaling": ScalingService.getScreenScale(screen),
                "widgetId": modelData.id,
                "barSection": parent.objectName,
                "sectionWidgetIndex": index,
                "sectionWidgetsCount": Settings.data.bar.widgets.right.length
              }
              anchors.verticalCenter: parent.verticalCenter
            }
          }
        }
      }
    }
  }
}

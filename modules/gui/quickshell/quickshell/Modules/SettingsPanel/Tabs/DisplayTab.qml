import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

ColumnLayout {
  id: root

  // Helper functions to update arrays immutably
  function addMonitor(list, name) {
    const arr = (list || []).slice()
    if (!arr.includes(name))
      arr.push(name)
    return arr
  }
  function removeMonitor(list, name) {
    return (list || []).filter(function (n) {
      return n !== name
    })
  }

  NText {
    text: "Monitor-specific configuration"
    font.pointSize: Style.fontSizeL * scaling
    font.weight: Style.fontWeightBold
  }

  NText {
    text: "Bars and notifications appear on all displays by default. Choose specific displays below to limit where they're shown."
    font.pointSize: Style.fontSizeM * scaling
    color: Color.mOnSurfaceVariant
    wrapMode: Text.WordWrap
    Layout.fillWidth: true
  }

  ColumnLayout {
    spacing: Style.marginL * scaling
    Layout.topMargin: Style.marginL * scaling

    Repeater {
      model: Quickshell.screens || []
      delegate: Rectangle {
        Layout.fillWidth: true
        Layout.minimumWidth: 550 * scaling
        radius: Style.radiusM * scaling
        color: Color.mSurface
        border.color: Color.mOutline
        border.width: Math.max(1, Style.borderS * scaling)
        implicitHeight: contentCol.implicitHeight + Style.marginXL * 2 * scaling

        property real localScaling: ScalingService.getScreenScale(modelData)
        Connections {
          target: ScalingService
          function onScaleChanged(screenName, scale) {
            if (screenName === modelData.name) {
              localScaling = scale
            }
          }
        }

        ColumnLayout {
          id: contentCol
          anchors.fill: parent
          anchors.margins: Style.marginL * scaling
          spacing: Style.marginXXS * scaling

          NText {
            text: (modelData.name || "Unknown")
            font.pointSize: Style.fontSizeXL * scaling
            font.weight: Style.fontWeightBold
            color: Color.mSecondary
          }

          NText {
            text: `Resolution: ${modelData.width}x${modelData.height} - Position: (${modelData.x}, ${modelData.y})`
            font.pointSize: Style.fontSizeXS * scaling
            color: Color.mOnSurfaceVariant
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
          }

          ColumnLayout {
            spacing: Style.marginL * scaling
            Layout.fillWidth: true

            NToggle {
              Layout.fillWidth: true
              label: "Bar"
              description: "Enable the bar on this monitor."
              checked: (Settings.data.bar.monitors || []).indexOf(modelData.name) !== -1
              onToggled: checked => {
                           if (checked) {
                             Settings.data.bar.monitors = addMonitor(Settings.data.bar.monitors, modelData.name)
                           } else {
                             Settings.data.bar.monitors = removeMonitor(Settings.data.bar.monitors, modelData.name)
                           }
                         }
            }

            NToggle {
              Layout.fillWidth: true
              label: "Notifications"
              description: "Enable notifications on this monitor."
              checked: (Settings.data.notifications.monitors || []).indexOf(modelData.name) !== -1
              onToggled: checked => {
                           if (checked) {
                             Settings.data.notifications.monitors = addMonitor(Settings.data.notifications.monitors,
                                                                               modelData.name)
                           } else {
                             Settings.data.notifications.monitors = removeMonitor(Settings.data.notifications.monitors,
                                                                                  modelData.name)
                           }
                         }
            }

            NToggle {
              Layout.fillWidth: true
              label: "Dock"
              description: "Enable the dock on this monitor."
              checked: (Settings.data.dock.monitors || []).indexOf(modelData.name) !== -1
              onToggled: checked => {
                           if (checked) {
                             Settings.data.dock.monitors = addMonitor(Settings.data.dock.monitors, modelData.name)
                           } else {
                             Settings.data.dock.monitors = removeMonitor(Settings.data.dock.monitors, modelData.name)
                           }
                         }
            }

            ColumnLayout {
              spacing: Style.marginS * scaling
              Layout.fillWidth: true

              RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginL * scaling

                ColumnLayout {
                  spacing: Style.marginXXS * scaling
                  Layout.fillWidth: true

                  NText {
                    text: "Scale"
                    font.pointSize: Style.fontSizeM * scaling
                    font.weight: Style.fontWeightBold
                    color: Color.mOnSurface
                  }
                  NText {
                    text: "Scale the user interface on this monitor."
                    font.pointSize: Style.fontSizeS * scaling
                    color: Color.mOnSurfaceVariant
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                  }
                }

                NText {
                  text: `${Math.round(localScaling * 100)}%`
                  Layout.alignment: Qt.AlignVCenter
                  Layout.minimumWidth: 50 * scaling
                  horizontalAlignment: Text.AlignRight
                }
              }

              RowLayout {
                spacing: Style.marginS * scaling
                Layout.fillWidth: true

                NSlider {
                  id: scaleSlider
                  from: 0.7
                  to: 1.8
                  stepSize: 0.01
                  value: localScaling
                  onPressedChanged: ScalingService.setScreenScale(modelData, value)
                  Layout.fillWidth: true
                  Layout.minimumWidth: 150 * scaling
                }

                NIconButton {
                  icon: "refresh"
                  tooltipText: "Reset scaling"
                  onClicked: ScalingService.setScreenScale(modelData, 1.0)
                }
              }
            }
          }
        }
      }
    }
  }
}

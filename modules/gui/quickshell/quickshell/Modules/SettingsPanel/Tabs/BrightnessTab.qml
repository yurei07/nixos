import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

Item {
  property real scaling: 1
  readonly property string tabIcon: "brightness_6"
  readonly property string tabLabel: "Brightness"
  Layout.fillWidth: true
  Layout.fillHeight: true

  ScrollView {
    anchors.fill: parent
    clip: true
    ScrollBar.vertical.policy: ScrollBar.AsNeeded
    ScrollBar.horizontal.policy: ScrollBar.AsNeeded
    contentWidth: parent.width

    ColumnLayout {
      width: parent.width
      ColumnLayout {
        spacing: Style.marginLarge * scaling
        Layout.margins: Style.marginLarge * scaling
        Layout.fillWidth: true

        NText {
          text: "Brightness Settings"
          font.pointSize: Style.fontSizeXL * scaling
          font.weight: Style.fontWeightBold
          color: Color.mOnSurface
        }

        NText {
          text: "Configure brightness controls and monitor settings."
          font.pointSize: Style.fontSize * scaling
          color: Color.mOnSurfaceVariant
        }

        // Bar Visibility Section
        ColumnLayout {
          spacing: Style.marginSmall * scaling
          Layout.fillWidth: true
          Layout.topMargin: Style.marginLarge * scaling

          NText {
            text: "Bar Integration"
            font.pointSize: Style.fontSizeLarge * scaling
            font.weight: Style.fontWeightBold
            color: Color.mOnSurface
          }

          NToggle {
            label: "Show Brightness Icon"
            description: "Display the brightness control icon in the top bar"
            checked: Settings.data.bar.showBrightness
            onToggled: checked => {
                         Settings.data.bar.showBrightness = checked
                       }
          }
        }

        NDivider {
          Layout.fillWidth: true
          Layout.topMargin: Style.marginLarge * scaling
          Layout.bottomMargin: Style.marginLarge * scaling
        }

        // Brightness Step Section
        ColumnLayout {
          spacing: Style.marginSmall * scaling
          Layout.fillWidth: true

          NText {
            text: "Brightness Step Size"
            font.pointSize: Style.fontSizeLarge * scaling
            font.weight: Style.fontWeightBold
            color: Color.mOnSurface
          }

          NText {
            text: "Adjust the step size for brightness changes (scroll wheel, keyboard shortcuts)"
            font.pointSize: Style.fontSizeSmall * scaling
            color: Color.mOnSurfaceVariant
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginMedium * scaling

            NSlider {
              Layout.fillWidth: true
              from: 1
              to: 50
              value: Settings.data.brightness.brightnessStep
              stepSize: 1
              onPressedChanged: {
                if (!pressed) {
                  Settings.data.brightness.brightnessStep = value
                }
              }
            }

            NText {
              text: Settings.data.brightness.brightnessStep + "%"
              Layout.alignment: Qt.AlignVCenter
              color: Color.mOnSurface
              font.pointSize: Style.fontSizeMedium * scaling
              font.weight: Style.fontWeightBold
            }
          }
        }

        NDivider {
          Layout.fillWidth: true
          Layout.topMargin: Style.marginLarge * scaling
          Layout.bottomMargin: Style.marginLarge * scaling
        }

        // Monitor Overview Section
        ColumnLayout {
          spacing: Style.marginSmall * scaling
          Layout.fillWidth: true

          NText {
            text: "Monitor Brightness Overview"
            font.pointSize: Style.fontSizeLarge * scaling
            font.weight: Style.fontWeightBold
            color: Color.mOnSurface
          }

          NText {
            text: "Current brightness levels for all detected monitors"
            font.pointSize: Style.fontSizeSmall * scaling
            color: Color.mOnSurfaceVariant
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
          }

          // Single monitor display using the same data source as the bar icon
          Repeater {
            model: BrightnessService.monitors
            Rectangle {
              Layout.fillWidth: true
              radius: Style.radiusMedium * scaling
              color: Color.mSurface
              border.color: Color.mOutline
              border.width: Math.max(1, Style.borderThin * scaling)
              implicitHeight: contentCol.implicitHeight + Style.marginXL * 2 * scaling

              ColumnLayout {
                id: contentCol
                anchors.fill: parent
                anchors.margins: Style.marginLarge * scaling
                spacing: Style.marginMedium * scaling

                RowLayout {
                  Layout.fillWidth: true
                  spacing: Style.marginMedium * scaling

                  NText {
                    text: `${model.modelData.name} [${model.modelData.model}]`
                    font.pointSize: Style.fontSizeLarge * scaling
                    font.weight: Style.fontWeightBold
                    color: Color.mSecondary
                  }

                  Item {
                    Layout.fillWidth: true
                  }

                  NText {
                    text: model.method
                    font.pointSize: Style.fontSizeSmall * scaling
                    color: Color.mOnSurfaceVariant
                    Layout.alignment: Qt.AlignRight
                  }
                }

                RowLayout {
                  Layout.fillWidth: true
                  spacing: Style.marginMedium * scaling

                  NText {
                    text: "Brightness:"
                    font.pointSize: Style.fontSizeMedium * scaling
                    color: Color.mOnSurface
                  }

                  NSlider {
                    Layout.fillWidth: true
                    from: 0
                    to: 1
                    value: model.brightness
                    stepSize: 0.05
                    onPressedChanged: {
                      if (!pressed) {
                        var monitor = BrightnessService.getMonitorForScreen(model.modelData)
                        monitor.setBrightness(value)
                      }
                    }
                  }

                  NText {
                    text: Math.round(model.brightness * 100) + "%"
                    font.pointSize: Style.fontSizeMedium * scaling
                    font.weight: Style.fontWeightBold
                    color: Color.mPrimary
                    Layout.alignment: Qt.AlignRight
                  }
                }
              }
            }
          }
        }

        Item {
          Layout.fillHeight: true
        }
      }
    }
  }
}

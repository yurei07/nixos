import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

ColumnLayout {
  id: root

  spacing: 0

  ScrollView {
    id: scrollView

    Layout.fillWidth: true
    Layout.fillHeight: true
    padding: Style.marginM * scaling
    clip: true
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
    ScrollBar.vertical.policy: ScrollBar.AsNeeded

    ColumnLayout {
      width: scrollView.availableWidth
      spacing: 0

      Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 0
      }

      ColumnLayout {
        spacing: Style.marginL * scaling
        Layout.fillWidth: true

        NText {
          text: "Bar Components"
          font.pointSize: Style.fontSizeXXL * scaling
          font.weight: Style.fontWeightBold
          color: Color.mOnSurface
        }

        ColumnLayout {
          spacing: Style.marginXXS * scaling
          Layout.fillWidth: true

          NText {
            text: "Bar Position"
            font.pointSize: Style.fontSizeL * scaling
            font.weight: Style.fontWeightBold
            color: Color.mOnSurface
          }

          NText {
            text: "Choose where to place the bar on the screen"
            font.pointSize: Style.fontSizeXS * scaling
            color: Color.mOnSurfaceVariant
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
          }

          NComboBox {
            Layout.fillWidth: true
            model: ListModel {
              ListElement {
                key: "top"
                name: "Top"
              }
              ListElement {
                key: "bottom"
                name: "Bottom"
              }
            }
            currentKey: Settings.data.bar.position
            onSelected: key => {
              Settings.data.bar.position = key
            }
          }
        }

        NToggle {
          label: "Show Active Window"
          description: "Display the title of the currently focused window."
          checked: Settings.data.bar.showActiveWindow
          onToggled: checked => {
                       Settings.data.bar.showActiveWindow = checked
                     }
        }

        NToggle {
          label: "Show Active Window's Icon"
          description: "Display the app icon next to the title of the currently focused window."
          checked: Settings.data.bar.showActiveWindowIcon
          onToggled: checked => {
                       Settings.data.bar.showActiveWindowIcon = checked
                     }
        }

        NToggle {
          label: "Show System Info"
          description: "Display system statistics (CPU, RAM, Temperature)."
          checked: Settings.data.bar.showSystemInfo
          onToggled: checked => {
                       Settings.data.bar.showSystemInfo = checked
                     }
        }

        NToggle {
          label: "Show Media"
          description: "Display media controls and information."
          checked: Settings.data.bar.showMedia
          onToggled: checked => {
                       Settings.data.bar.showMedia = checked
                     }
        }

        NToggle {
          label: "Show Notifications History"
          description: "Display a shortcut to the notifications history."
          checked: Settings.data.bar.showNotificationsHistory
          onToggled: checked => {
                       Settings.data.bar.showNotificationsHistory = checked
                     }
        }

        NToggle {
          label: "Show Applications Tray"
          description: "Display the applications tray."
          checked: Settings.data.bar.showTray
          onToggled: checked => {
                       Settings.data.bar.showTray = checked
                     }
        }

        NToggle {
          label: "Show Battery Percentage"
          description: "Show battery percentage at all times."
          checked: Settings.data.bar.alwaysShowBatteryPercentage
          onToggled: checked => {
                       Settings.data.bar.alwaysShowBatteryPercentage = checked
                     }
        }

        ColumnLayout {
          spacing: Style.marginXXS * scaling
          Layout.fillWidth: true

          NText {
            text: "Background Opacity"
            font.pointSize: Style.fontSizeL * scaling
            font.weight: Style.fontWeightBold
            color: Color.mOnSurface
          }

          NText {
            text: "Adjust the background opacity of the bar"
            font.pointSize: Style.fontSizeXS * scaling
            color: Color.mOnSurfaceVariant
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
          }

          RowLayout {
            NSlider {
              Layout.fillWidth: true
              from: 0
              to: 1
              stepSize: 0.01
              value: Settings.data.bar.backgroundOpacity
              onMoved: Settings.data.bar.backgroundOpacity = value
              cutoutColor: Color.mSurface
            }

            NText {
              text: Math.floor(Settings.data.bar.backgroundOpacity * 100) + "%"
              Layout.alignment: Qt.AlignVCenter
              Layout.leftMargin: Style.marginS * scaling
              color: Color.mOnSurface
            }
          }
        }
      }
    }
  }
}

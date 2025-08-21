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
          text: "General Settings"
          font.pointSize: Style.fontSizeXXL * scaling
          font.weight: Style.fontWeightBold
          color: Color.mOnSurface
        }

        // Profile section
        ColumnLayout {
          spacing: Style.marginS * scaling
          Layout.fillWidth: true
          Layout.topMargin: Style.marginS * scaling

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginL * scaling

            // Avatar preview
            NImageRounded {
              width: 64 * scaling
              height: 64 * scaling
              imagePath: Settings.data.general.avatarImage
              fallbackIcon: "person"
              borderColor: Color.mPrimary
              borderWidth: Math.max(1, Style.borderM)
            }

            NTextInput {
              label: "Profile Picture"
              description: "Your profile picture displayed in various places throughout the shell."
              text: Settings.data.general.avatarImage
              placeholderText: "/home/user/.face"
              Layout.fillWidth: true
              onEditingFinished: {
                Settings.data.general.avatarImage = text
              }
            }
          }
        }
      }

      NDivider {
        Layout.fillWidth: true
        Layout.topMargin: Style.marginXL * scaling
        Layout.bottomMargin: Style.marginXL * scaling
      }

      ColumnLayout {
        spacing: Style.marginL * scaling
        Layout.fillWidth: true

        NText {
          text: "User Interface"
          font.pointSize: Style.fontSizeXXL * scaling
          font.weight: Style.fontWeightBold
          color: Color.mOnSurface
          Layout.bottomMargin: Style.marginS * scaling
        }

        NToggle {
          label: "Show Corners"
          description: "Display rounded corners on the edge of the screen."
          checked: Settings.data.general.showScreenCorners
          onToggled: checked => {
                       Settings.data.general.showScreenCorners = checked
                     }
        }

        NToggle {
          label: "Dim Desktop"
          description: "Dim the desktop when panels or menus are open."
          checked: Settings.data.general.dimDesktop
          onToggled: checked => {
                       Settings.data.general.dimDesktop = checked
                     }
        }

        NToggle {
          label: "Auto-hide Dock"
          description: "Automatically hide the dock when not in use."
          checked: Settings.data.dock.autoHide
          onToggled: checked => {
                       Settings.data.dock.autoHide = checked
                     }
        }

        ColumnLayout {
          spacing: Style.marginXXS * scaling
          Layout.fillWidth: true

          NText {
            text: "Border radius"
            font.pointSize: Style.fontSizeL * scaling
            font.weight: Style.fontWeightBold
            color: Color.mOnSurface
          }

          NText {
            text: "Adjust the rounded border of all UI elements"
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
              value: Settings.data.general.radiusRatio
              onMoved: Settings.data.general.radiusRatio = value
              cutoutColor: Color.mSurface
            }

            NText {
              text: Math.floor(Settings.data.general.radiusRatio * 100) + "%"
              Layout.alignment: Qt.AlignVCenter
              Layout.leftMargin: Style.marginS * scaling
              color: Color.mOnSurface
            }
          }
        }

        NDivider {
          Layout.fillWidth: true
          Layout.topMargin: Style.marginXL * scaling
          Layout.bottomMargin: Style.marginL * scaling
        }

        NText {
          text: "Fonts"
          font.pointSize: Style.fontSizeXXL * scaling
          font.weight: Style.fontWeightBold
          color: Color.mOnSurface
          Layout.bottomMargin: Style.marginS * scaling
        }

        // Font configuration section
        ColumnLayout {
          spacing: Style.marginS * scaling
          Layout.fillWidth: true

          NTextInput {
            label: "Default Font"
            description: "Main font used throughout the interface."
            text: Settings.data.ui.fontDefault
            placeholderText: "Roboto"
            Layout.fillWidth: true
            onEditingFinished: {
              Settings.data.ui.fontDefault = text
            }
          }

          NTextInput {
            label: "Fixed Width Font"
            description: "Monospace font used for terminal and code display."
            text: Settings.data.ui.fontFixed
            placeholderText: "DejaVu Sans Mono"
            Layout.fillWidth: true
            onEditingFinished: {
              Settings.data.ui.fontFixed = text
            }
          }

          NTextInput {
            label: "Billboard Font"
            description: "Large font used for clocks and prominent displays."
            text: Settings.data.ui.fontBillboard
            placeholderText: "Inter"
            Layout.fillWidth: true
            onEditingFinished: {
              Settings.data.ui.fontBillboard = text
            }
          }
        }
      }
    }
  }
}

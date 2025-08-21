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
          text: "Launcher"
          font.pointSize: Style.fontSizeXXL * scaling
          font.weight: Style.fontWeightBold
          color: Color.mOnSurface
        }

        NToggle {
          label: "Enable Clipboard History"
          description: "Show clipboard history in the Launcher (command >clip)."
          checked: Settings.data.appLauncher.enableClipboardHistory
          onToggled: checked => {
                       Settings.data.appLauncher.enableClipboardHistory = checked
                     }
        }

        NDivider { Layout.fillWidth: true; Layout.topMargin: Style.marginL * scaling; Layout.bottomMargin: Style.marginS * scaling }

        NText {
          text: "Launcher Position"
          font.pointSize: Style.fontSizeXXL * scaling
          font.weight: Style.fontWeightBold
          color: Color.mOnSurface
          Layout.bottomMargin: Style.marginS * scaling
        }

        NComboBox {
          id: launcherPosition
          label: "Position"
          description: "Choose where the Launcher panel appears."
          Layout.fillWidth: true
          model: ListModel {
            ListElement { key: "center"; name: "Center (default)" }
            ListElement { key: "top_left"; name: "Top Left" }
            ListElement { key: "top_right"; name: "Top Right" }
            ListElement { key: "bottom_left"; name: "Bottom Left" }
            ListElement { key: "bottom_right"; name: "Bottom Right" }
          }
          currentKey: Settings.data.appLauncher.position
          onSelected: function(key) {
            Settings.data.appLauncher.position = key
          }
        }

      }
    }
  }
}



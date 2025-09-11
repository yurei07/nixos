import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

ColumnLayout {
  id: root

  ColumnLayout {
    spacing: Style.marginL * scaling

    NComboBox {
      id: launcherPosition
      label: "Position"
      description: "Choose where the Launcher panel appears."
      Layout.fillWidth: true
      model: ListModel {
        ListElement {
          key: "center"
          name: "Center (default)"
        }
        ListElement {
          key: "top_left"
          name: "Top Left"
        }
        ListElement {
          key: "top_right"
          name: "Top Right"
        }
        ListElement {
          key: "bottom_left"
          name: "Bottom Left"
        }
        ListElement {
          key: "bottom_right"
          name: "Bottom Right"
        }
        ListElement {
          key: "bottom_center"
          name: "Bottom Center"
        }
        ListElement {
          key: "top_center"
          name: "Top Center"
        }
      }
      currentKey: Settings.data.appLauncher.position
      onSelected: function (key) {
        Settings.data.appLauncher.position = key
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
        text: "Adjust the background opacity of the launcher."
        font.pointSize: Style.fontSizeXS * scaling
        color: Color.mOnSurfaceVariant
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
      }

      RowLayout {
        NSlider {
          id: launcherBgOpacity
          Layout.fillWidth: true
          from: 0.0
          to: 1.0
          stepSize: 0.01
          value: Settings.data.appLauncher.backgroundOpacity
          onMoved: Settings.data.appLauncher.backgroundOpacity = value
          cutoutColor: Color.mSurface
        }

        NText {
          text: Math.floor(Settings.data.appLauncher.backgroundOpacity * 100) + "%"
          Layout.alignment: Qt.AlignVCenter
          Layout.leftMargin: Style.marginS * scaling
          color: Color.mOnSurface
        }
      }
    }

    NToggle {
      label: "Enable Clipboard History"
      description: "Show clipboard history in the launcher."
      checked: Settings.data.appLauncher.enableClipboardHistory
      onToggled: checked => Settings.data.appLauncher.enableClipboardHistory = checked
    }

    NToggle {
      label: "Use App2Unit for Launching"
      description: "Use app2unit -- 'desktop-entry' when launching applications for better systemd integration."
      checked: Settings.data.appLauncher.useApp2Unit
      onToggled: checked => Settings.data.appLauncher.useApp2Unit = checked
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginXL * scaling
    Layout.bottomMargin: Style.marginXL * scaling
  }
}

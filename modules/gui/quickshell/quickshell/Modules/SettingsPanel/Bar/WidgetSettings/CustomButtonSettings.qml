import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import qs.Commons
import qs.Widgets
import qs.Services

ColumnLayout {
  id: root
  spacing: Style.marginM * scaling

  property var widgetData: null
  property var widgetMetadata: null

  function saveSettings() {
    var settings = Object.assign({}, widgetData || {})
    settings.icon = iconInput.text
    settings.leftClickExec = leftClickExecInput.text
    settings.rightClickExec = rightClickExecInput.text
    settings.middleClickExec = middleClickExecInput.text
    return settings
  }

  NTextInput {
    id: iconInput
    Layout.fillWidth: true
    label: "Icon Name"
    description: "Select an icon from the library."
    placeholderText: "Enter icon name (e.g., cat, gear, house, ...)"
    text: widgetData?.icon || widgetMetadata.icon
  }

  RowLayout {
    spacing: Style.marginS * scaling
    Layout.alignment: Qt.AlignLeft
    NIcon {
      Layout.alignment: Qt.AlignVCenter
      icon: iconInput.text
      visible: iconInput.text !== ""
    }
    NButton {
      text: "Browse"
      onClicked: iconPicker.open()
    }
  }

  Popup {
    id: iconPicker
    modal: true
    width: {
      var w = Math.round(Math.max(Screen.width * 0.35, 900) * scaling)
      w = Math.min(w, Screen.width - Style.marginL * 2)
      return w
    }
    height: {
      var h = Math.round(Math.max(Screen.height * 0.65, 700) * scaling)
      h = Math.min(h, Screen.height - Style.barHeight * scaling - Style.marginL * 2)
      return h
    }
    anchors.centerIn: Overlay.overlay
    padding: Style.marginXL * scaling

    property string query: ""
    property string selectedIcon: ""
    property var allIcons: Object.keys(Icons.icons)
    property var filteredIcons: allIcons.filter(function (name) {
      return query === "" || name.toLowerCase().indexOf(query.toLowerCase()) !== -1
    })
    readonly property int columns: 6
    readonly property int cellW: Math.floor(grid.width / columns)
    readonly property int cellH: Math.round(cellW * 0.7 + 36 * scaling)

    background: Rectangle {
      color: Color.mSurface
      radius: Style.radiusL * scaling
      border.color: Color.mPrimary
      border.width: Style.borderM * scaling
    }

    ColumnLayout {
      anchors.fill: parent
      spacing: Style.marginM * scaling

      // Title row
      RowLayout {
        Layout.fillWidth: true
        NText {
          text: "Icon Picker"
          font.pointSize: Style.fontSizeL * scaling
          font.weight: Style.fontWeightBold
          color: Color.mPrimary
          Layout.fillWidth: true
        }
        NIconButton {
          icon: "close"
          onClicked: iconPicker.close()
        }
      }

      NDivider {
        Layout.fillWidth: true
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginS * scaling
        NTextInput {
          Layout.fillWidth: true
          label: "Search"
          placeholderText: "Search (e.g., arrow, battery, cloud)"
          text: iconPicker.query
          onTextChanged: iconPicker.query = text.trim().toLowerCase()
        }
      }

      // Icon grid
      ScrollView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true

        GridView {
          id: grid
          anchors.fill: parent
          anchors.margins: Style.marginM * scaling
          cellWidth: iconPicker.cellW
          cellHeight: iconPicker.cellH
          model: iconPicker.filteredIcons
          delegate: Rectangle {
            width: grid.cellWidth
            height: grid.cellHeight
            radius: Style.radiusS * scaling
            clip: true
            color: (iconPicker.selectedIcon === modelData) ? Qt.alpha(Color.mPrimary, 0.15) : "transparent"
            border.color: (iconPicker.selectedIcon === modelData) ? Color.mPrimary : Qt.rgba(0, 0, 0, 0)
            border.width: (iconPicker.selectedIcon === modelData) ? Style.borderS * scaling : 0

            MouseArea {
              anchors.fill: parent
              onClicked: iconPicker.selectedIcon = modelData
              onDoubleClicked: {
                iconPicker.selectedIcon = modelData
                iconInput.text = iconPicker.selectedIcon
                iconPicker.close()
              }
            }

            ColumnLayout {
              anchors.fill: parent
              anchors.margins: Style.marginS * scaling
              spacing: Style.marginS * scaling
              Item {
                Layout.fillHeight: true
                Layout.preferredHeight: 4 * scaling
              }
              NIcon {
                Layout.alignment: Qt.AlignHCenter
                icon: modelData
                font.pointSize: 42 * scaling
              }
              NText {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                Layout.topMargin: Style.marginXS * scaling
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
                maximumLineCount: 1
                horizontalAlignment: Text.AlignHCenter
                color: Color.mOnSurfaceVariant
                font.pointSize: Style.fontSizeXS * scaling
                text: modelData
              }
              Item {
                Layout.fillHeight: true
              }
            }
          }
        }
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM * scaling
        Item {
          Layout.fillWidth: true
        }
        NButton {
          text: "Cancel"
          outlined: true
          onClicked: iconPicker.close()
        }
        NButton {
          text: "Apply"
          icon: "check"
          enabled: iconPicker.selectedIcon !== ""
          onClicked: {
            iconInput.text = iconPicker.selectedIcon
            iconPicker.close()
          }
        }
      }
    }
  }

  NTextInput {
    id: leftClickExecInput
    Layout.fillWidth: true
    label: "Left Click Command"
    placeholderText: "Enter command to execute (app or custom script)"
    text: widgetData?.leftClickExec || widgetMetadata.leftClickExec
  }

  NTextInput {
    id: rightClickExecInput
    Layout.fillWidth: true
    label: "Right Click Command"
    placeholderText: "Enter command to execute (app or custom script)"
    text: widgetData?.rightClickExec || widgetMetadata.rightClickExec
  }

  NTextInput {
    id: middleClickExecInput
    Layout.fillWidth: true
    label: "Middle Click Command"
    placeholderText: "Enter command to execute (app or custom script)"
    text: widgetData.middleClickExec || widgetMetadata.middleClickExec
  }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

Rectangle {
  id: root

  property color selectedColor: "#000000"
  property bool expanded: false

  signal colorSelected(color color)
  signal colorCancelled

  implicitWidth: expanded ? 320 * scaling : 150 * scaling
  implicitHeight: expanded ? 300 * scaling : 40 * scaling

  radius: Style.radiusM * scaling
  color: Color.mSurface
  border.color: Color.mOutline
  border.width: Math.max(1, Style.borderS * scaling)

  property var presetColors: [Color.mPrimary, Color.mSecondary, Color.mTertiary, Color.mError, Color.mSurface, Color.mSurfaceVariant, Color.mOutline, "#FFFFFF", "#000000", "#F44336", "#E91E63", "#9C27B0", "#673AB7", "#3F51B5", "#2196F3", "#03A9F4", "#00BCD4", "#009688", "#4CAF50", "#8BC34A", "#CDDC39", "#FFEB3B", "#FFC107", "#FF9800", "#FF5722", "#795548", "#9E9E9E"]

  Behavior on implicitWidth {
    NumberAnimation {
      duration: Style.animationFast
    }
  }

  Behavior on implicitHeight {
    NumberAnimation {
      duration: Style.animationFast
    }
  }

  // Collapsed view - just show current color
  MouseArea {
    visible: !root.expanded
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: root.expanded = true

    RowLayout {
      anchors.fill: parent
      anchors.margins: Style.marginS * scaling
      spacing: Style.marginS * scaling

      Rectangle {
        Layout.preferredWidth: 24 * scaling
        Layout.preferredHeight: 24 * scaling
        radius: Layout.preferredWidth * 0.5
        color: root.selectedColor
        border.color: Color.mOutline
        border.width: Math.max(1, Style.borderS * scaling)
      }

      NText {
        text: root.selectedColor.toString().toUpperCase()
        font.family: Settings.data.ui.fontFixed
        Layout.fillWidth: true
      }

      NIcon {
        text: "palette"
        color: Color.mOnSurfaceVariant
      }
    }
  }

  // Expanded view - color selection
  ColumnLayout {
    visible: root.expanded
    anchors.fill: parent
    anchors.margins: Style.marginM * scaling
    spacing: Style.marginS * scaling

    // Header
    RowLayout {
      Layout.fillWidth: true

      NText {
        text: "Select Color"
        font.weight: Style.fontWeightBold
        Layout.fillWidth: true
      }

      NIconButton {
        icon: "close"
        onClicked: root.expanded = false
      }
    }

    // Preset colors grid
    Grid {
      columns: 9
      spacing: Style.marginXS * scaling
      Layout.fillWidth: true

      Repeater {
        model: root.presetColors

        Rectangle {
          width: Math.round(29 * scaling)
          height: width
          radius: Style.radiusXS * scaling
          color: modelData
          border.color: root.selectedColor === modelData ? Color.mPrimary : Color.mOutline
          border.width: root.selectedColor === modelData ? 2 : 1

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              root.selectedColor = modelData
              // root.colorSelected(modelData)
            }
          }
        }
      }
    }

    // Custom color input
    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginS * scaling

      NTextInput {
        id: hexInput
        label: "Hex Color"
        text: root.selectedColor.toString().toUpperCase()
        fontFamily: Settings.data.ui.fontFixed
        Layout.minimumWidth: 100 * scaling
        onEditingFinished: {
          if (/^#[0-9A-F]{6}$/i.test(text)) {
            root.selectedColor = text
            root.colorSelected(text)
          }
        }
      }

      Rectangle {
        Layout.preferredWidth: 32 * scaling
        Layout.preferredHeight: 32 * scaling
        radius: Layout.preferredWidth * 0.5
        color: root.selectedColor
        border.color: Color.mOutline
        border.width: 1
        Layout.alignment: Qt.AlignBottom
        Layout.bottomMargin: 5 * scaling
      }
    }

    // Action buttons row
    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginS * scaling

      Item {
        Layout.fillWidth: true
      } // Spacer

      NButton {
        text: "Cancel"
        outlined: true
        customHeight: Style.baseWidgetSize * scaling
        fontSize: Style.fontSizeS * scaling
        onClicked: {
          root.colorCancelled()
          root.expanded = false
        }
      }

      NButton {
        text: "Apply"
        customHeight: Style.baseWidgetSize * scaling
        fontSize: Style.fontSizeS * scaling
        onClicked: {
          root.colorSelected(root.selectedColor)
          root.expanded = false
        }
      }
    }
  }
}

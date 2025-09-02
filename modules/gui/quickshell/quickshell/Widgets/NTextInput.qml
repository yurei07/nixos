import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Services

ColumnLayout {
  id: root

  property string label: ""
  property string description: ""
  property bool readOnly: false
  property bool enabled: true
  property int inputMaxWidth: 420 * scaling
  property color labelColor: Color.mOnSurface
  property color descriptionColor: Color.mOnSurfaceVariant
  property string fontFamily: Settings.data.ui.fontDefault

  property alias text: input.text
  property alias placeholderText: input.placeholderText
  property alias inputMethodHints: input.inputMethodHints
  property alias inputItem: input

  signal editingFinished

  spacing: Style.marginS * scaling
  implicitHeight: frame.height

  NLabel {
    label: root.label
    description: root.description
    labelColor: root.labelColor
    descriptionColor: root.descriptionColor
    visible: root.label !== "" || root.description !== ""
  }

  // Container
  Rectangle {
    id: frame
    implicitWidth: parent.width
    implicitHeight: Style.baseWidgetSize * 1.1 * scaling
    Layout.minimumWidth: 80 * scaling
    Layout.maximumWidth: root.inputMaxWidth
    radius: Style.radiusM * scaling
    color: Color.mSurface
    border.color: Color.mOutline
    border.width: Math.max(1, Style.borderS * scaling)

    // Focus ring
    Rectangle {
      anchors.fill: parent
      radius: frame.radius
      color: Color.transparent
      border.color: input.activeFocus ? Color.mSecondary : Color.transparent
      border.width: input.activeFocus ? Math.max(1, Style.borderS * scaling) : 0

      Behavior on border.color {
        ColorAnimation {
          duration: Style.animationFast
        }
      }
    }

    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: Style.marginM * scaling
      anchors.rightMargin: Style.marginM * scaling
      spacing: Style.marginS * scaling

      TextField {
        id: input
        Layout.fillWidth: true
        echoMode: TextInput.Normal
        readOnly: root.readOnly
        enabled: root.enabled
        color: Color.mOnSurface
        placeholderTextColor: Color.mOnSurfaceVariant
        background: null
        font.family: fontFamily
        font.pointSize: Style.fontSizeS * scaling
        onEditingFinished: root.editingFinished()
      }
    }
  }
}

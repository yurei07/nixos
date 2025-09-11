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
  property color labelColor: Color.mOnSurface
  property color descriptionColor: Color.mOnSurfaceVariant
  property string fontFamily: Settings.data.ui.fontDefault
  property real fontSize: Style.fontSizeS * scaling
  property int fontWeight: Style.fontWeightRegular

  property alias text: input.text
  property alias placeholderText: input.placeholderText
  property alias inputMethodHints: input.inputMethodHints
  property alias inputItem: input

  signal editingFinished

  spacing: Style.marginS * scaling

  NLabel {
    label: root.label
    description: root.description
    labelColor: root.labelColor
    descriptionColor: root.descriptionColor
    visible: root.label !== "" || root.description !== ""
    Layout.fillWidth: true
  }

  // Container
  Rectangle {
    id: frame

    Layout.fillWidth: true
    Layout.minimumWidth: 80 * scaling
    implicitHeight: Style.baseWidgetSize * 1.1 * scaling

    radius: Style.radiusM * scaling
    color: Color.mSurface
    border.color: input.activeFocus ? Color.mSecondary : Color.mOutline
    border.width: Math.max(1, Style.borderS * scaling)

    Behavior on border.color {
      ColorAnimation {
        duration: Style.animationFast
      }
    }

    TextField {
      id: input

      anchors.fill: parent
      anchors.leftMargin: Style.marginM * scaling
      anchors.rightMargin: Style.marginM * scaling

      verticalAlignment: TextInput.AlignVCenter

      echoMode: TextInput.Normal
      readOnly: root.readOnly
      enabled: root.enabled
      color: Color.mOnSurface
      placeholderTextColor: Qt.alpha(Color.mOnSurfaceVariant, 0.6)

      selectByMouse: true

      topPadding: 0
      bottomPadding: 0
      leftPadding: 0
      rightPadding: 0

      background: null

      font.family: root.fontFamily
      font.pointSize: root.fontSize
      font.weight: root.fontWeight

      onEditingFinished: root.editingFinished()
    }
  }
}

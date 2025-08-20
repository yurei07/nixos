import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Services

Item {
  id: root

  property string label: ""
  property string description: ""
  property bool readOnly: false
  property bool enabled: true

  property alias text: input.text
  property alias placeholderText: input.placeholderText

  signal editingFinished

  // Sizing
  implicitWidth: Style.sliderWidth * 1.6 * scaling
  implicitHeight: Style.baseWidgetSize * 2.75 * scaling

  ColumnLayout {
    spacing: Style.marginXXS * scaling
    Layout.fillWidth: true

    NLabel {
      label: root.label
      description: root.description
    }

    // Container
    Rectangle {
      id: frame
      Layout.topMargin: Style.marginXS * scaling
      implicitWidth: root.width
      implicitHeight: Style.baseWidgetSize * 1.35 * scaling
      radius: Style.radiusM * scaling
      color: Color.mSurface
      border.color: Color.mOutline
      border.width: Math.max(1, Style.borderS * scaling)

      // Focus ring
      Rectangle {
        anchors.fill: parent
        radius: frame.radius
        color: Color.transparent
        border.color: input.activeFocus ? Color.mTertiary : Color.transparent
        border.width: input.activeFocus ? Math.max(1, Style.borderS * scaling) : 0
      }

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Style.marginM * scaling
        anchors.rightMargin: Style.marginM * scaling
        spacing: Style.marginS * scaling

        // Optional leading icon slot in the future
        // Item { Layout.preferredWidth: 0 }
        TextField {
          id: input
          Layout.fillWidth: true
          echoMode: TextInput.Normal
          readOnly: root.readOnly
          enabled: root.enabled
          color: Color.mOnSurface
          placeholderTextColor: Color.mOnSurface
          background: null
          font.pointSize: Style.fontSizeXS * scaling
          onEditingFinished: root.editingFinished()
          // Text changes are observable via the aliased 'text' property (root.text) and its 'textChanged' signal.
          // No additional callback is invoked here to avoid conflicts with QML's onTextChanged handler semantics.
        }
      }
    }
  }
}

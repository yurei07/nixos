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
    spacing: Style.marginTiniest * scaling
    Layout.fillWidth: true

    NText {
      text: label
      font.pointSize: Style.fontSizeMedium * scaling
      font.weight: Style.fontWeightBold
      color: Color.mOnSurface
    }

    NText {
      text: description
      font.pointSize: Style.fontSizeSmall * scaling
      color: Color.mOnSurface
      wrapMode: Text.WordWrap
      Layout.fillWidth: true
    }

    // Container
    Rectangle {
      id: frame
      Layout.topMargin: Style.marginTiny * scaling
      implicitWidth: root.width
      implicitHeight: Style.baseWidgetSize * 1.35 * scaling
      radius: Style.radiusMedium * scaling
      color: Color.mSurface
      border.color: Color.mOutline
      border.width: Math.max(1, Style.borderThin * scaling)

      // Focus ring
      Rectangle {
        anchors.fill: parent
        radius: frame.radius
        color: Color.transparent
        border.color: input.activeFocus ? Color.mTertiary : Color.transparent
        border.width: input.activeFocus ? Math.max(1, Style.borderThin * scaling) : 0
      }

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Style.marginMedium * scaling
        anchors.rightMargin: Style.marginMedium * scaling
        spacing: Style.marginSmall * scaling

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
          font.pointSize: Style.fontSizeSmall * scaling
          onEditingFinished: root.editingFinished()
          // Text changes are observable via the aliased 'text' property (root.text) and its 'textChanged' signal.
          // No additional callback is invoked here to avoid conflicts with QML's onTextChanged handler semantics.
        }
      }
    }
  }
}

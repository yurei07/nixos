import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Services

RowLayout {
  id: root

  property string label: ""
  property string description: ""
  property bool checked: false
  property bool hovering: false
  property int baseSize: Style.baseWidgetSize

  signal toggled(bool checked)
  signal entered
  signal exited

  Layout.fillWidth: true

  ColumnLayout {
    spacing: Style.marginXXS * scaling
    Layout.fillWidth: true

    NText {
      text: label
      font.pointSize: Style.fontSizeM * scaling
      font.weight: Style.fontWeightBold
      color: Color.mOnSurface
    }

    NText {
      text: description
      font.pointSize: Style.fontSizeS * scaling
      color: Color.mOnSurfaceVariant
      wrapMode: Text.WordWrap
      Layout.fillWidth: true
    }
  }

  Rectangle {
    id: switcher

    implicitWidth: root.baseSize * 1.625 * scaling
    implicitHeight: root.baseSize * scaling
    radius: height * 0.5
    color: root.checked ? Color.mPrimary : Color.mSurface
    border.color: root.checked ? Color.mPrimary : Color.mOutline
    border.width: Math.max(1, Style.borderM * scaling)

    Rectangle {
      implicitWidth: (root.baseSize - 5) * scaling
      implicitHeight: (root.baseSize - 5) * scaling
      radius: height * 0.5
      color: root.checked ? Color.mOnPrimary : Color.mPrimary
      border.color: root.checked ? Color.mSurface : Color.mSurface
      border.width: Math.max(1, Style.borderM * scaling)
      y: 2 * scaling
      x: root.checked ? switcher.width - width - 2 * scaling : 2 * scaling

      Behavior on x {
        NumberAnimation {
          duration: Style.animationFast
          easing.type: Easing.OutCubic
        }
      }
    }

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      hoverEnabled: true
      onEntered: {
        hovering = true
        root.entered()
      }
      onExited: {
        hovering = false
        root.exited()
      }
      onClicked: {
        root.toggled(!root.checked)
      }
    }
  }
}

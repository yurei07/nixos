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

  NLabel {
    label: root.label
    description: root.description
  }

  Rectangle {
    id: switcher

    implicitWidth: root.baseSize * 1.625 * scaling
    implicitHeight: root.baseSize * scaling
    radius: height * 0.5
    color: root.checked ? Color.mPrimary : Color.mSurface
    border.color: root.checked ? Color.mPrimary : Color.mOutline
    border.width: Math.max(1, Style.borderM * scaling)

    Behavior on color {
      ColorAnimation {
        duration: Style.animationFast
      }
    }

    Behavior on border.color {
      ColorAnimation {
        duration: Style.animationFast
      }
    }

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

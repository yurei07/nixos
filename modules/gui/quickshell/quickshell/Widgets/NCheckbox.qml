import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons

RowLayout {
  id: root

  // Public API (mirrors NToggle but compact)
  property string label: ""
  property string description: ""
  property bool checked: false
  property bool hovering: false
  property color activeColor: Color.mPrimary
  property color activeOnColor: Color.mOnPrimary
  property int baseSize: Math.max(Style.baseWidgetSize * 0.8, 14)

  signal toggled(bool checked)
  signal entered
  signal exited

  Layout.fillWidth: true

  NLabel {
    label: root.label
    description: root.description
    visible: root.label !== "" || root.description !== ""
  }

  // Spacer to push the checkbox to the far right
  Item {
    Layout.fillWidth: true
  }

  Rectangle {
    id: box

    implicitWidth: root.baseSize * scaling
    implicitHeight: root.baseSize * scaling
    radius: Style.radiusXS * scaling
    color: root.checked ? root.activeColor : Color.mSurface
    border.color: root.checked ? root.activeColor : Color.mOutline
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

    NIcon {
      visible: root.checked
      anchors.centerIn: parent
      icon: "check"
      color: root.activeOnColor
      font.pointSize: Math.max(Style.fontSizeS, root.baseSize * 0.7) * scaling
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
      onClicked: root.toggled(!root.checked)
    }
  }
}

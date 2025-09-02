import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons

Rectangle {
  id: root

  // Public properties
  property string text: ""
  property string icon: ""
  property color backgroundColor: Color.mPrimary
  property color textColor: Color.mOnPrimary
  property color hoverColor: Color.mTertiary
  property color pressColor: Color.mSecondary
  property bool enabled: true
  property int fontSize: Style.fontSizeM * scaling
  property int iconSize: Style.fontSizeL * scaling
  property bool outlined: false
  property real customWidth: -1
  property real customHeight: -1

  // Signals
  signal clicked

  // Internal properties
  property bool hovered: false
  property bool pressed: false

  // Dimensions
  implicitWidth: customWidth > 0 ? customWidth : contentRow.implicitWidth + (Style.marginL * 2 * scaling)
  implicitHeight: customHeight > 0 ? customHeight : Math.max(Style.baseWidgetSize * scaling,
                                                             contentRow.implicitHeight + (Style.marginM * scaling))

  // Appearance
  radius: Style.radiusS * scaling
  color: {
    if (!enabled)
      return outlined ? Color.transparent : Qt.lighter(Color.mSurfaceVariant, 1.2)
    if (pressed)
      return pressColor
    if (hovered)
      return hoverColor
    return outlined ? Color.transparent : backgroundColor
  }

  border.width: outlined ? Math.max(1, Style.borderS * scaling) : 0
  border.color: {
    if (!enabled)
      return Color.mOutline
    if (pressed || hovered)
      return backgroundColor
    return outlined ? backgroundColor : Color.transparent
  }

  opacity: enabled ? 1.0 : 0.6

  Behavior on color {
    ColorAnimation {
      duration: Style.animationFast
      easing.type: Easing.OutCubic
    }
  }

  Behavior on border.color {
    ColorAnimation {
      duration: Style.animationFast
      easing.type: Easing.OutCubic
    }
  }

  // Content
  RowLayout {
    id: contentRow
    anchors.centerIn: parent
    spacing: Style.marginS * scaling

    // Icon (optional)
    NIcon {
      visible: root.icon !== ""
      text: root.icon
      font.pointSize: root.iconSize
      color: {
        if (!root.enabled)
          return Color.mOnSurfaceVariant
        if (root.outlined) {
          if (root.pressed || root.hovered)
            return root.backgroundColor
          return root.backgroundColor
        }
        return root.textColor
      }

      Behavior on color {
        ColorAnimation {
          duration: Style.animationFast
          easing.type: Easing.OutCubic
        }
      }
    }

    // Text
    NText {
      visible: root.text !== ""
      text: root.text
      font.pointSize: root.fontSize
      font.weight: Style.fontWeightBold
      color: {
        if (!root.enabled)
          return Color.mOnSurfaceVariant
        if (root.outlined) {
          if (root.pressed || root.hovered)
            return root.textColor
          return root.backgroundColor
        }
        return root.textColor
      }

      Behavior on color {
        ColorAnimation {
          duration: Style.animationFast
          easing.type: Easing.OutCubic
        }
      }
    }
  }

  // Ripple effect
  Rectangle {
    id: ripple
    anchors.centerIn: parent
    width: 0
    height: width
    radius: width / 2
    color: root.outlined ? root.backgroundColor : root.textColor
    opacity: 0

    ParallelAnimation {
      id: rippleAnimation

      NumberAnimation {
        target: ripple
        property: "width"
        from: 0
        to: Math.max(root.width, root.height) * 2
        duration: Style.animationFast
        easing.type: Easing.OutCubic
      }

      SequentialAnimation {
        NumberAnimation {
          target: ripple
          property: "opacity"
          from: 0
          to: 0.2
          duration: 100
          easing.type: Easing.OutCubic
        }

        NumberAnimation {
          target: ripple
          property: "opacity"
          from: 0.2
          to: 0
          duration: 300
          easing.type: Easing.InCubic
        }
      }
    }
  }

  // Mouse interaction
  MouseArea {
    id: mouseArea
    anchors.fill: parent
    enabled: root.enabled
    hoverEnabled: true
    cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

    onEntered: root.hovered = true
    onExited: {
      root.hovered = false
      root.pressed = false
    }
    onPressed: {
      root.pressed = true
      rippleAnimation.restart()
    }
    onReleased: {
      if (containsMouse) {
        root.clicked()
      }
      root.pressed = false
    }
    onCanceled: {
      root.pressed = false
      root.hovered = false
    }
  }
}

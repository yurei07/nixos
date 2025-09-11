import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import qs.Commons
import qs.Widgets
import qs.Services

Item {
  id: root

  property string label: ""
  property string description: ""
  property string type: "notice" // "notice", "warning"
  property int duration: 5000 // Auto-hide after 5 seconds, 0 = no auto-hide
  property bool persistent: false // If true, requires manual dismiss

  required property ShellScreen screen
  property real scaling: 1.0

  // Animation properties
  property real targetY: 0
  property real hiddenY: -height - 20

  signal dismissed

  width: Math.min(500 * scaling, parent.width * 0.8)
  height: Math.max(60 * scaling, contentLayout.implicitHeight + Style.marginL * 2 * scaling)

  // Position at top center of parent
  anchors.horizontalCenter: parent.horizontalCenter
  y: hiddenY
  z: 1000 // High z-index to appear above everything

  function show() {
    // NToast updates its scaling when showing.
    scaling = ScalingService.getScreenScale(screen)

    // Stop any running animations and reset state
    showAnimation.stop()
    hideAnimation.stop()
    autoHideTimer.stop()

    // Ensure we start from the hidden position
    y = hiddenY
    visible = true

    // Start the show animation
    showAnimation.start()
    if (duration > 0 && !persistent) {
      autoHideTimer.start()
    }
  }

  function hide() {
    hideAnimation.start()
  }

  // Auto-hide timer
  Timer {
    id: autoHideTimer
    interval: root.duration
    onTriggered: hide()
  }

  // Show animation
  PropertyAnimation {
    id: showAnimation
    target: root
    property: "y"
    to: targetY
    duration: Style.animationNormal
    easing.type: Easing.OutCubic
  }

  // Hide animation
  PropertyAnimation {
    id: hideAnimation
    target: root
    property: "y"
    to: hiddenY
    duration: Style.animationNormal
    easing.type: Easing.InCubic
    onFinished: {
      root.visible = false
      root.dismissed()
    }
  }

  // Main toast container
  Rectangle {
    anchors.fill: parent
    radius: Style.radiusL * scaling

    // Clean surface background
    color: Color.mSurface

    // Simple colored border all around
    border.color: {
      switch (root.type) {
      case "warning":
        return Color.mError
      case "notice":
        return Color.mPrimary
      default:
        return Color.mOutline
      }
    }
    border.width: Math.max(2, Style.borderM * scaling)

    RowLayout {
      id: contentLayout
      anchors.fill: parent
      anchors.margins: Style.marginL * scaling
      spacing: Style.marginL * scaling

      // Icon
      NIcon {
        id: icon
        icon: (root.type == "warning") ? "toast-warning" : "toast-notice"
        color: {
          switch (root.type) {
          case "warning":
            return Color.mError
          case "notice":
            return Color.mPrimary
          default:
            return Color.mPrimary
          }
        }

        font.pointSize: Style.fontSizeXXL * 1.5 * scaling // 150% size to cover two lines
        Layout.alignment: Qt.AlignVCenter
      }

      // Label and description
      ColumnLayout {
        spacing: Style.marginXXS * scaling
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter

        NText {
          Layout.fillWidth: true
          text: root.label
          color: Color.mOnSurface
          font.pointSize: Style.fontSizeM * scaling
          font.weight: Style.fontWeightBold
          wrapMode: Text.WordWrap
          visible: text.length > 0
        }

        NText {
          Layout.fillWidth: true
          text: root.description
          color: Color.mOnSurface
          font.pointSize: Style.fontSizeM * scaling
          wrapMode: Text.WordWrap
          visible: text.length > 0
        }
      }

      // Close button (only if persistent or manual dismiss needed)
      NIconButton {
        icon: "close"
        visible: root.persistent || root.duration === 0

        colorBg: Color.mSurfaceVariant
        colorFg: Color.mOnSurface
        colorBorder: Color.transparent
        colorBorderHover: Color.mOutline

        sizeRatio: 0.8
        Layout.alignment: Qt.AlignTop

        onClicked: hide()
      }
    }

    // Click to dismiss (if not persistent)
    MouseArea {
      anchors.fill: parent
      enabled: !root.persistent
      onClicked: hide()
      cursorShape: Qt.PointingHandCursor
    }
  }

  // Initial state
  Component.onCompleted: {
    visible = false
  }
}

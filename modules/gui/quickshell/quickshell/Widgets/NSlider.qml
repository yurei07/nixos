import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import qs.Commons
import qs.Services

Slider {
  id: root

  // Optional color to cut the track beneath the knob (should match surrounding background)
  property var cutoutColor
  property bool snapAlways: true
  property real heightRatio: 0.75

  readonly property real knobDiameter: Style.baseWidgetSize * heightRatio * scaling
  readonly property real trackHeight: knobDiameter * 0.5
  readonly property real cutoutExtra: Style.baseWidgetSize * 0.1 * scaling

  snapMode: snapAlways ? Slider.SnapAlways : Slider.SnapOnRelease
  implicitHeight: Math.max(trackHeight, knobDiameter)

  background: Rectangle {
    x: root.leftPadding
    y: root.topPadding + root.availableHeight / 2 - height / 2
    implicitWidth: Style.sliderWidth
    implicitHeight: trackHeight
    width: root.availableWidth
    height: implicitHeight
    radius: height / 2
    color: Color.mSurface

    Rectangle {
      id: activeTrack
      width: root.visualPosition * parent.width
      height: parent.height
      color: Color.mPrimary
      radius: parent.radius
    }

    // Circular cutout
    Rectangle {
      id: knobCutout
      width: knobDiameter + cutoutExtra
      height: knobDiameter + cutoutExtra
      radius: width / 2
      color: root.cutoutColor !== undefined ? root.cutoutColor : Color.mSurface
      x: Math.max(0, Math.min(parent.width - width,
                              root.visualPosition * (parent.width - root.knobDiameter) - cutoutExtra / 2))
      y: (parent.height - height) / 2
    }
  }

  handle: Item {
    width: knob.implicitWidth
    height: knob.implicitHeight
    x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
    y: root.topPadding + root.availableHeight / 2 - height / 2

    // Subtle shadow for a more polished look
    MultiEffect {
      anchors.fill: knob
      source: knob
      shadowEnabled: true
      shadowColor: Color.mShadow
      shadowOpacity: 0.25
      shadowHorizontalOffset: 0
      shadowVerticalOffset: 1
      shadowBlur: 8
    }

    Rectangle {
      id: knob
      implicitWidth: knobDiameter
      implicitHeight: knobDiameter
      radius: width * 0.5
      color: root.pressed ? Color.mSurfaceVariant : Color.mSurface
      border.color: Color.mPrimary
      border.width: Math.max(1, Style.borderL * scaling)

      Behavior on color {
        ColorAnimation {
          duration: Style.animationFast
        }
      }

      // Press feedback halo (using accent color, low opacity)
      Rectangle {
        anchors.centerIn: parent
        width: parent.width + 8 * scaling
        height: parent.height + 8 * scaling
        radius: width / 2
        color: Color.mPrimary
        opacity: root.pressed ? 0.16 : 0.0
      }
    }
  }
}

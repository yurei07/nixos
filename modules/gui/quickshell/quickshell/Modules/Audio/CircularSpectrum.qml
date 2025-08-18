import QtQuick
import qs.Commons
import qs.Services

// Not used ATM and need rework
Item {
  id: root
  property int innerRadius: 32 * scaling
  property int outerRadius: 64 * scaling
  property color fillColor: Color.mPrimary
  property color strokeColor: Color.mOnSurface
  property int strokeWidth: 0 * scaling
  property var values: []
  property int usableOuter: 64

  width: usableOuter * 2
  height: usableOuter * 2

  Repeater {
    model: root.values.length
    Rectangle {
      property real value: root.values[index]
      property real angle: (index / root.values.length) * 360
      width: Math.max(2 * scaling, (root.innerRadius * 2 * Math.PI) / root.values.length - 4 * scaling)
      height: value * (usableOuter - root.innerRadius)
      radius: width / 2
      color: root.fillColor
      border.color: root.strokeColor
      border.width: root.strokeWidth
      antialiasing: true

      x: root.width / 2 - width / 2 * Math.cos(Math.PI / 2 + 2 * Math.PI * index / root.values.length) - width / 2
      y: root.height / 2 - height

      transform: [
        Rotation {
          origin.x: width / 2
          origin.y: height
          //angle: (index / root.values.length) * 360
        },
        Translate {
          x: root.innerRadius * Math.cos(2 * Math.PI * index / root.values.length)
          y: root.innerRadius * Math.sin(2 * Math.PI * index / root.values.length)
        }
      ]

      Behavior on height {
        SmoothedAnimation {
          duration: Style.animationFast
        }
      }
    }
  }
}

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import qs.Commons
import qs.Services

Rectangle {
  id: root

  property string imagePath: ""
  property string fallbackIcon: ""
  property color borderColor: Color.transparent
  property real borderWidth: 0

  color: Color.transparent
  radius: parent.width * 0.5
  anchors.margins: Style.marginXXS * scaling

  Rectangle {
    color: Color.transparent
    anchors.fill: parent

    Image {
      id: img
      anchors.fill: parent
      source: imagePath
      visible: false // Hide since we're using it as shader source
      mipmap: true
      smooth: true
      asynchronous: true
      antialiasing: true
      fillMode: Image.PreserveAspectCrop
    }

    ShaderEffect {
      anchors.fill: parent

      property var source: ShaderEffectSource {
        sourceItem: img
        hideSource: true
        live: true
        recursive: false
        format: ShaderEffectSource.RGBA
      }

      property real imageOpacity: root.opacity
      fragmentShader: Qt.resolvedUrl("../Shaders/qsb/circled_image.frag.qsb")
      supportsAtlasTextures: false
      blending: true
    }

    // Fallback icon
    NIcon {
      anchors.centerIn: parent
      text: fallbackIcon
      font.pointSize: Style.fontSizeXXL * scaling
      visible: fallbackIcon !== undefined && fallbackIcon !== "" && (imagePath === undefined || imagePath === "")
      z: 0
    }
  }

  //Border
  Rectangle {
    anchors.fill: parent
    radius: parent.radius
    color: Color.transparent
    border.color: parent.borderColor
    border.width: parent.borderWidth
    antialiasing: true
    z: 10
  }
}

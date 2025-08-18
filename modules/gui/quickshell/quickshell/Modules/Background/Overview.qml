import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services
import qs.Widgets

NLoader {
  active: CompositorService.isNiri

  Component.onCompleted: {
    if (CompositorService.isNiri) {
      Logger.log("Overview", "Loading Overview component (Niri detected)")
    } else {
      Logger.log("Overview", "Skipping Overview component (Niri not detected)")
    }
  }

  sourceComponent: Variants {
    model: Quickshell.screens

    delegate: PanelWindow {
      required property ShellScreen modelData
      property string wallpaperSource: WallpaperService.currentWallpaper !== ""
                                       && !Settings.data.wallpaper.swww.enabled ? WallpaperService.currentWallpaper : ""

      visible: wallpaperSource !== "" && !Settings.data.wallpaper.swww.enabled
      color: Color.transparent
      screen: modelData
      WlrLayershell.layer: WlrLayer.Background
      WlrLayershell.exclusionMode: ExclusionMode.Ignore
      WlrLayershell.namespace: "quickshell-overview"

      anchors {
        top: true
        bottom: true
        right: true
        left: true
      }

      Image {
        id: bgImage

        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        source: wallpaperSource
        cache: true
        smooth: true
        mipmap: false
        visible: wallpaperSource !== ""
      }

      MultiEffect {
        id: overviewBgBlur

        anchors.fill: parent
        source: bgImage
        blurEnabled: true
        blur: 0.48
        blurMax: 128
      }

      Rectangle {
        anchors.fill: parent
        color: Qt.rgba(Color.mSurface.r, Color.mSurface.g, Color.mSurface.b, 0.5)
      }
    }
  }
}

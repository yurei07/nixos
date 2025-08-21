import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services

Loader {
  active: !Settings.data.wallpaper.swww.enabled

  sourceComponent: Variants {
    model: Quickshell.screens

    delegate: PanelWindow {
      required property ShellScreen modelData
      property string wallpaperSource: WallpaperService.currentWallpaper !== ""
                                       && !Settings.data.wallpaper.swww.enabled ? WallpaperService.currentWallpaper : ""

      visible: wallpaperSource !== "" && !Settings.data.wallpaper.swww.enabled

      // Force update when SWWW setting changes
      onVisibleChanged: {
        if (visible) {

        } else {

        }
      }
      color: Color.transparent
      screen: modelData
      WlrLayershell.layer: WlrLayer.Background
      WlrLayershell.exclusionMode: ExclusionMode.Ignore
      WlrLayershell.namespace: "quickshell-wallpaper"

      anchors {
        bottom: true
        top: true
        right: true
        left: true
      }

      margins {
        top: 0
      }

      Image {
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        source: wallpaperSource
        visible: wallpaperSource !== ""
        cache: true
        smooth: true
        mipmap: false
      }
    }
  }
}

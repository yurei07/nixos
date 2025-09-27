import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Modules.Settings
import qs.Services
import qs.Widgets

// Utilities: record & wallpaper
NBox {

  property real spacing: 0

  RowLayout {
    id: utilRow
    anchors.fill: parent
    anchors.margins: Style.marginS * scaling
    spacing: spacing
    Item {
      Layout.fillWidth: true
    }
    // Screen Recorder
    NIconButton {
      icon: "camera-video"
      enabled: ScreenRecorderService.isAvailable
      tooltipText: ScreenRecorderService.isAvailable ? (ScreenRecorderService.isRecording ? I18n.tr("tooltips.stop-screen-recording") : I18n.tr("tooltips.start-screen-recording")) : I18n.tr("tooltips.screen-recorder-not-installed")
      colorBg: ScreenRecorderService.isRecording ? Color.mPrimary : Color.mSurfaceVariant
      colorFg: ScreenRecorderService.isRecording ? Color.mOnPrimary : Color.mPrimary
      onClicked: {
        if (!ScreenRecorderService.isAvailable)
          return
        ScreenRecorderService.toggleRecording()
        // If we were not recording and we just initiated a start, close the panel
        if (!ScreenRecorderService.isRecording) {
          var panel = PanelService.getPanel("controlCenterPanel")
          panel?.close()
        }
      }
    }

    // Idle Inhibitor
    NIconButton {
      icon: IdleInhibitorService.isInhibited ? "keep-awake-on" : "keep-awake-off"
      tooltipText: IdleInhibitorService.isInhibited ? I18n.tr("tooltips.disable-keep-awake") : I18n.tr("tooltips.enable-keep-awake")
      colorBg: IdleInhibitorService.isInhibited ? Color.mPrimary : Color.mSurfaceVariant
      colorFg: IdleInhibitorService.isInhibited ? Color.mOnPrimary : Color.mPrimary
      onClicked: {
        IdleInhibitorService.manualToggle()
      }
    }

    // Wallpaper
    NIconButton {
      visible: Settings.data.wallpaper.enabled
      icon: "wallpaper-selector"
      tooltipText: I18n.tr("tooltips.wallpaper-selector")
      onClicked: PanelService.getPanel("wallpaperPanel")?.toggle(this)
      onRightClicked: WallpaperService.setRandomWallpaper()
    }

    Item {
      Layout.fillWidth: true
    }
  }
}

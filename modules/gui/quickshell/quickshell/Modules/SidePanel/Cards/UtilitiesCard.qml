import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Modules.SettingsPanel
import qs.Services
import qs.Widgets

// Utilities: record & wallpaper
NBox {

  property real spacing: 0

  Layout.fillWidth: true
  Layout.preferredWidth: 1
  implicitHeight: utilRow.implicitHeight + Style.marginM * 2 * scaling
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
      tooltipText: ScreenRecorderService.isAvailable ? (ScreenRecorderService.isRecording ? "Stop screen recording." : "Start screen recording.") : "Screen recorder not installed."
      colorBg: ScreenRecorderService.isRecording ? Color.mPrimary : Color.mSurfaceVariant
      colorFg: ScreenRecorderService.isRecording ? Color.mOnPrimary : Color.mPrimary
      onClicked: {
        if (!ScreenRecorderService.isAvailable)
          return
        ScreenRecorderService.toggleRecording()
        // If we were not recording and we just initiated a start, close the panel
        if (!ScreenRecorderService.isRecording) {
          var panel = PanelService.getPanel("sidePanel")
          panel && panel.close()
        }
      }
    }

    // Idle Inhibitor
    NIconButton {
      icon: IdleInhibitorService.isInhibited ? "keep-awake-on" : "keep-awake-off"
      tooltipText: IdleInhibitorService.isInhibited ? "Disable keep awake." : "Enable keep awake."
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
      tooltipText: "Left click: Open wallpaper selector.\nRight click: Set random wallpaper."
      onClicked: {
        var settingsPanel = PanelService.getPanel("settingsPanel")
        settingsPanel.requestedTab = SettingsPanel.Tab.WallpaperSelector
        settingsPanel.open()
      }
      onRightClicked: {
        WallpaperService.setRandomWallpaper()
      }
    }

    Item {
      Layout.fillWidth: true
    }
  }
}

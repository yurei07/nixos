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
  Layout.fillWidth: true
  Layout.preferredWidth: 1
  implicitHeight: utilRow.implicitHeight + Style.marginM * 2 * scaling
  RowLayout {
    id: utilRow
    anchors.fill: parent
    anchors.margins: Style.marginS * scaling
    spacing: sidePanel.cardSpacing
    Item {
      Layout.fillWidth: true
    }
    // Screen Recorder
    NIconButton {
      icon: "videocam"
      tooltipText: ScreenRecorderService.isRecording ? "Stop Screen Recording" : "Start Screen Recording"
      colorBg: ScreenRecorderService.isRecording ? Color.mPrimary : Color.mSurfaceVariant
      colorFg: ScreenRecorderService.isRecording ? Color.mOnPrimary : Color.mPrimary
      onClicked: {
        ScreenRecorderService.toggleRecording()
      }
    }

    // Wallpaper
    NIconButton {
      icon: "image"
      tooltipText: "Open Wallpaper Selector"
      onClicked: {
        settingsPanel.requestedTab = SettingsPanel.Tab.WallpaperSelector
        settingsPanel.isLoaded = true
      }
    }

    Item {
      Layout.fillWidth: true
    }
  }
}

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
  implicitHeight: utilRow.implicitHeight + Style.marginMedium * 2 * scaling
  RowLayout {
    id: utilRow
    anchors.fill: parent
    anchors.margins: Style.marginSmall * scaling
    spacing: sidePanel.cardSpacing
    Item {
      Layout.fillWidth: true
    }
    // Screen Recorder
    NIconButton {
      icon: "videocam"
      tooltipText: ScreenRecorderService.isRecording ? "Stop Screen Recording" : "Start Screen Recording"
      showFilled: ScreenRecorderService.isRecording
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

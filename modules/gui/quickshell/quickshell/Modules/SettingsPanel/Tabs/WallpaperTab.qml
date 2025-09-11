import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services
import qs.Widgets

ColumnLayout {
  id: root

  NToggle {
    label: "Enable Wallpaper Management"
    description: "Manage wallpapers with Noctalia. (Uncheck if you prefer using another application)."
    checked: Settings.data.wallpaper.enabled
    onToggled: checked => Settings.data.wallpaper.enabled = checked
    Layout.bottomMargin: Style.marginL * scaling
  }

  ColumnLayout {
    visible: Settings.data.wallpaper.enabled
    spacing: Style.marginL * scaling
    Layout.fillWidth: true
    NTextInput {
      label: "Wallpaper Directory"
      description: "Path to your common wallpaper directory."
      text: Settings.data.wallpaper.directory
      onEditingFinished: {
        Settings.data.wallpaper.directory = text
      }
      Layout.maximumWidth: 420 * scaling
    }

    // Monitor-specific directories
    NToggle {
      label: "Monitor-specific directories"
      description: "Enable multi-monitor wallpaper directory management."
      checked: Settings.data.wallpaper.enableMultiMonitorDirectories
      onToggled: checked => Settings.data.wallpaper.enableMultiMonitorDirectories = checked
    }

    NBox {
      visible: Settings.data.wallpaper.enableMultiMonitorDirectories

      Layout.fillWidth: true
      Layout.minimumWidth: 550 * scaling
      radius: Style.radiusM * scaling
      color: Color.mSurfaceVariant
      border.color: Color.mOutline
      border.width: Math.max(1, Style.borderS * scaling)
      implicitHeight: contentCol.implicitHeight + Style.marginXL * 2 * scaling

      ColumnLayout {
        id: contentCol
        anchors.fill: parent
        anchors.margins: Style.marginXL * scaling
        spacing: Style.marginM * scaling
        Repeater {
          model: Quickshell.screens || []
          delegate: RowLayout {
            NText {
              text: (modelData.name || "Unknown")
              color: Color.mSecondary
              font.weight: Style.fontWeightBold
              Layout.preferredWidth: 90 * scaling
            }
            NTextInput {
              Layout.fillWidth: true
              text: WallpaperService.getMonitorDirectory(modelData.name)
              onEditingFinished: WallpaperService.setMonitorDirectory(modelData.name, text)
              Layout.maximumWidth: 420 * scaling
            }
          }
        }
      }
    }
  }

  NDivider {
    visible: Settings.data.wallpaper.enabled
    Layout.fillWidth: true
    Layout.topMargin: Style.marginXL * scaling
    Layout.bottomMargin: Style.marginXL * scaling
  }

  ColumnLayout {
    visible: Settings.data.wallpaper.enabled
    spacing: Style.marginL * scaling
    Layout.fillWidth: true

    NText {
      text: "Look & Feel"
      font.pointSize: Style.fontSizeXXL * scaling
      font.weight: Style.fontWeightBold
      color: Color.mSecondary
    }

    // Fill Mode
    NComboBox {
      label: "Fill Mode"
      description: "Select how the image should scale to match your monitor's resolution."
      model: WallpaperService.fillModeModel
      currentKey: Settings.data.wallpaper.fillMode
      onSelected: key => Settings.data.wallpaper.fillMode = key
    }

    RowLayout {
      NLabel {
        label: "Fill Color"
        description: "Choose a fill color that may appear behind the wallpaper."
        Layout.alignment: Qt.AlignTop
      }

      NColorPicker {
        selectedColor: Settings.data.wallpaper.fillColor
        onColorSelected: color => Settings.data.wallpaper.fillColor = color
      }
    }

    // Transition Type
    NComboBox {
      label: "Transition Type"
      description: "Animation type when switching between wallpapers."
      model: WallpaperService.transitionsModel
      currentKey: Settings.data.wallpaper.transitionType
      onSelected: key => Settings.data.wallpaper.transitionType = key
    }

    // Transition Duration
    ColumnLayout {
      NLabel {
        label: "Transition Duration"
        description: "Duration of transition animations in seconds."
      }

      RowLayout {
        spacing: Style.marginL * scaling
        NSlider {
          Layout.fillWidth: true
          from: 500
          to: 10000
          stepSize: 100
          value: Settings.data.wallpaper.transitionDuration
          onMoved: Settings.data.wallpaper.transitionDuration = value
          cutoutColor: Color.mSurface
        }
        NText {
          text: (Settings.data.wallpaper.transitionDuration / 1000).toFixed(2) + "s"
          Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
        }
      }
    }

    // Edge Smoothness
    ColumnLayout {
      NLabel {
        label: "Transition Edge Smoothness"
        description: "Duration of transition animations in seconds."
      }

      RowLayout {
        spacing: Style.marginL * scaling
        NSlider {
          Layout.fillWidth: true
          from: 0.0
          to: 1.0
          value: Settings.data.wallpaper.transitionEdgeSmoothness
          onMoved: Settings.data.wallpaper.transitionEdgeSmoothness = value
          cutoutColor: Color.mSurface
        }
        NText {
          text: Math.round(Settings.data.wallpaper.transitionEdgeSmoothness * 100) + "%"
          Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
        }
      }
    }
  }

  NDivider {
    visible: Settings.data.wallpaper.enabled
    Layout.fillWidth: true
    Layout.topMargin: Style.marginXL * scaling
    Layout.bottomMargin: Style.marginXL * scaling
  }

  ColumnLayout {
    visible: Settings.data.wallpaper.enabled
    spacing: Style.marginL * scaling
    Layout.fillWidth: true

    NText {
      text: "Automation"
      font.pointSize: Style.fontSizeXXL * scaling
      font.weight: Style.fontWeightBold
      color: Color.mSecondary
    }

    // Random Wallpaper
    NToggle {
      label: "Random Wallpaper"
      description: "Schedule random wallpaper changes at regular intervals."
      checked: Settings.data.wallpaper.randomEnabled
      onToggled: checked => Settings.data.wallpaper.randomEnabled = checked
    }

    // Interval
    ColumnLayout {
      visible: Settings.data.wallpaper.randomEnabled
      RowLayout {
        NLabel {
          label: "Wallpaper Interval"
          description: "How often to change wallpapers automatically."
          Layout.fillWidth: true
        }

        NText {
          // Show friendly H:MM format from current settings
          text: Time.formatVagueHumanReadableDuration(Settings.data.wallpaper.randomIntervalSec)
          Layout.alignment: Qt.AlignBottom | Qt.AlignRight
        }
      }

      // Preset chips using Repeater
      RowLayout {
        id: presetRow
        spacing: Style.marginS * scaling

        // Factorized presets data
        property var intervalPresets: [5 * 60, 10 * 60, 15 * 60, 30 * 60, 45 * 60, 60 * 60, 90 * 60, 120 * 60]

        // Whether current interval equals one of the presets
        property bool isCurrentPreset: {
          return intervalPresets.some(seconds => seconds === Settings.data.wallpaper.randomIntervalSec)
        }
        // Allow user to force open the custom input; otherwise it's auto-open when not a preset
        property bool customForcedVisible: false

        function setIntervalSeconds(sec) {
          Settings.data.wallpaper.randomIntervalSec = sec
          WallpaperService.restartRandomWallpaperTimer()
          // Hide custom when selecting a preset
          customForcedVisible = false
        }

        // Helper to color selected chip
        function isSelected(sec) {
          return Settings.data.wallpaper.randomIntervalSec === sec
        }

        // Repeater for preset chips
        Repeater {
          model: presetRow.intervalPresets
          delegate: IntervalPresetChip {
            seconds: modelData
            label: Time.formatVagueHumanReadableDuration(modelData)
            selected: presetRow.isSelected(modelData)
            onClicked: presetRow.setIntervalSeconds(modelData)
          }
        }

        // Custom… opens inline input
        IntervalPresetChip {
          label: customRow.visible ? "Custom" : "Custom…"
          selected: customRow.visible
          onClicked: presetRow.customForcedVisible = !presetRow.customForcedVisible
        }
      }

      // Custom HH:MM inline input
      RowLayout {
        id: customRow
        visible: presetRow.customForcedVisible || !presetRow.isCurrentPreset
        spacing: Style.marginS * scaling
        Layout.topMargin: Style.marginS * scaling

        NTextInput {
          label: "Custom Interval"
          description: "Enter time as HH:MM (e.g., 01:30)."
          text: {
            const s = Settings.data.wallpaper.randomIntervalSec
            const h = Math.floor(s / 3600)
            const m = Math.floor((s % 3600) / 60)
            return h + ":" + (m < 10 ? ("0" + m) : m)
          }
          onEditingFinished: {
            const m = text.trim().match(/^(\d{1,2}):(\d{2})$/)
            if (m) {
              let h = parseInt(m[1])
              let min = parseInt(m[2])
              if (isNaN(h) || isNaN(min))
                return
              h = Math.max(0, Math.min(24, h))
              min = Math.max(0, Math.min(59, min))
              Settings.data.wallpaper.randomIntervalSec = (h * 3600) + (min * 60)
              WallpaperService.restartRandomWallpaperTimer()
              // Keep custom visible after manual entry
              presetRow.customForcedVisible = true
            }
          }
        }
      }
    }
  }

  // Reusable component for interval preset chips
  component IntervalPresetChip: Rectangle {
    property int seconds: 0
    property string label: ""
    property bool selected: false
    signal clicked

    radius: height * 0.5
    color: selected ? Color.mPrimary : Color.mSurfaceVariant
    implicitHeight: Math.max(Style.baseWidgetSize * 0.55 * scaling, 24 * scaling)
    implicitWidth: chipLabel.implicitWidth + Style.marginM * 1.5 * scaling
    border.width: 1
    border.color: selected ? Color.transparent : Color.mOutline

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: parent.clicked()
    }

    NText {
      id: chipLabel
      anchors.centerIn: parent
      text: parent.label
      font.pointSize: Style.fontSizeS * scaling
      color: parent.selected ? Color.mOnPrimary : Color.mOnSurface
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginXL * scaling
    Layout.bottomMargin: Style.marginXL * scaling
  }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

ColumnLayout {
  id: root

  spacing: Style.marginL * scaling

  // Output Directory
  ColumnLayout {
    spacing: Style.marginS * scaling
    Layout.fillWidth: true
    Layout.topMargin: Style.marginS * scaling

    NTextInput {
      label: "Output Directory"
      description: "Directory where screen recordings will be saved."
      placeholderText: "/home/xxx/Videos"
      text: Settings.data.screenRecorder.directory
      onEditingFinished: {
        Settings.data.screenRecorder.directory = text
      }

      Layout.maximumWidth: 420 * scaling
    }

    ColumnLayout {
      spacing: Style.marginS * scaling
      Layout.fillWidth: true
      Layout.topMargin: Style.marginM * scaling
      // Show Cursor
      NToggle {
        label: "Show Cursor"
        description: "Record mouse cursor in the video."
        checked: Settings.data.screenRecorder.showCursor
        onToggled: checked => Settings.data.screenRecorder.showCursor = checked
      }
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginXL * scaling
    Layout.bottomMargin: Style.marginXL * scaling
  }

  // Video Settings
  ColumnLayout {
    spacing: Style.marginL * scaling
    Layout.fillWidth: true

    NText {
      text: "Video Settings"
      font.pointSize: Style.fontSizeXXL * scaling
      font.weight: Style.fontWeightBold
      color: Color.mSecondary
      Layout.bottomMargin: Style.marginS * scaling
    }

    // Source
    NComboBox {
      label: "Video Source"
      description: "Portal is recommend, if you get artifacts try Screen."
      model: ListModel {
        ListElement {
          key: "portal"
          name: "Portal"
        }
        ListElement {
          key: "screen"
          name: "Screen"
        }
      }
      currentKey: Settings.data.screenRecorder.videoSource
      onSelected: key => Settings.data.screenRecorder.videoSource = key
    }

    // Frame Rate
    NComboBox {
      label: "Frame Rate"
      description: "Target frame rate for screen recordings."
      model: ListModel {
        ListElement {
          key: "30"
          name: "30 FPS"
        }
        ListElement {
          key: "60"
          name: "60 FPS"
        }
        ListElement {
          key: "100"
          name: "100 FPS"
        }
        ListElement {
          key: "120"
          name: "120 FPS"
        }
        ListElement {
          key: "144"
          name: "144 FPS"
        }
        ListElement {
          key: "165"
          name: "165 FPS"
        }
        ListElement {
          key: "240"
          name: "240 FPS"
        }
      }
      currentKey: Settings.data.screenRecorder.frameRate
      onSelected: key => Settings.data.screenRecorder.frameRate = key
    }

    // Video Quality
    NComboBox {
      label: "Video Quality"
      description: "Higher quality results in larger file sizes."
      model: ListModel {
        ListElement {
          key: "medium"
          name: "Medium"
        }
        ListElement {
          key: "high"
          name: "High"
        }
        ListElement {
          key: "very_high"
          name: "Very High"
        }
        ListElement {
          key: "ultra"
          name: "Ultra"
        }
      }
      currentKey: Settings.data.screenRecorder.quality
      onSelected: key => Settings.data.screenRecorder.quality = key
    }

    // Video Codec
    NComboBox {
      label: "Video Codec"
      description: "h264 is the most common codec."
      model: ListModel {
        ListElement {
          key: "h264"
          name: "H264"
        }
        ListElement {
          key: "hevc"
          name: "HEVC"
        }
        ListElement {
          key: "av1"
          name: "AV1"
        }
        ListElement {
          key: "vp8"
          name: "VP8"
        }
        ListElement {
          key: "vp9"
          name: "VP9"
        }
      }
      currentKey: Settings.data.screenRecorder.videoCodec
      onSelected: key => Settings.data.screenRecorder.videoCodec = key
    }

    // Color Range
    NComboBox {
      label: "Color Range"
      description: "Limited is recommended for better compatibility."
      model: ListModel {
        ListElement {
          key: "limited"
          name: "Limited"
        }
        ListElement {
          key: "full"
          name: "Full"
        }
      }
      currentKey: Settings.data.screenRecorder.colorRange
      onSelected: key => Settings.data.screenRecorder.colorRange = key
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginL * 2 * scaling
    Layout.bottomMargin: Style.marginL * scaling
  }

  // Audio Settings
  ColumnLayout {
    spacing: Style.marginL * scaling
    Layout.fillWidth: true

    NText {
      text: "Audio Settings"
      font.pointSize: Style.fontSizeXXL * scaling
      font.weight: Style.fontWeightBold
      color: Color.mSecondary
      Layout.bottomMargin: Style.marginS * scaling
    }

    // Audio Source
    NComboBox {
      label: "Audio Source"
      description: "Audio source to capture during recording."
      model: ListModel {
        ListElement {
          key: "default_output"
          name: "System Output"
        }
        ListElement {
          key: "default_input"
          name: "Microphone Input"
        }
        ListElement {
          key: "both"
          name: "System Output + Microphone Input"
        }
      }
      currentKey: Settings.data.screenRecorder.audioSource
      onSelected: key => Settings.data.screenRecorder.audioSource = key
    }

    // Audio Codec
    NComboBox {
      label: "Audio Codec"
      description: "Opus is recommended for best performance and smallest audio size."
      model: ListModel {
        ListElement {
          key: "opus"
          name: "Opus"
        }
        ListElement {
          key: "aac"
          name: "AAC"
        }
      }
      currentKey: Settings.data.screenRecorder.audioCodec
      onSelected: key => Settings.data.screenRecorder.audioCodec = key
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginXL * scaling
    Layout.bottomMargin: Style.marginXL * scaling
  }
}

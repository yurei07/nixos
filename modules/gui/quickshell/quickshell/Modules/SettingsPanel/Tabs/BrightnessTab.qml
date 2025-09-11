import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services
import qs.Widgets

ColumnLayout {
  id: root

  // Time dropdown options (00:00 .. 23:30)
  ListModel {
    id: timeOptions
  }
  Component.onCompleted: {
    for (var h = 0; h < 24; h++) {
      for (var m = 0; m < 60; m += 30) {
        var hh = ("0" + h).slice(-2)
        var mm = ("0" + m).slice(-2)
        var key = hh + ":" + mm
        timeOptions.append({
                             "key": key,
                             "name": key
                           })
      }
    }
  }

  // Check for wlsunset availability when enabling Night Light
  Process {
    id: wlsunsetCheck
    command: ["which", "wlsunset"]
    running: false

    onExited: function (exitCode) {
      if (exitCode === 0) {
        Settings.data.nightLight.enabled = true
        NightLightService.apply()
        ToastService.showNotice("Night Light", "Enabled")
      } else {
        Settings.data.nightLight.enabled = false
        ToastService.showWarning("Night Light", "wlsunset not installed")
      }
    }

    stdout: StdioCollector {}
    stderr: StdioCollector {}
  }

  spacing: Style.marginL * scaling

  // Brightness Step Section
  ColumnLayout {
    spacing: Style.marginS * scaling
    Layout.fillWidth: true

    NSpinBox {
      Layout.fillWidth: true
      label: "Brightness Step Size"
      description: "Adjust the step size for brightness changes (scroll wheel, keyboard shortcuts)."
      minimum: 1
      maximum: 50
      value: Settings.data.brightness.brightnessStep
      stepSize: 1
      suffix: "%"
      onValueChanged: {
        Settings.data.brightness.brightnessStep = value
      }
    }
  }

  // Monitor Overview Section
  ColumnLayout {
    spacing: Style.marginL * scaling

    NLabel {
      label: "Monitors Brightness Control"
      description: "Current brightness levels for all detected monitors."
    }

    // Single monitor display using the same data source as the bar icon
    Repeater {
      model: BrightnessService.monitors
      Rectangle {
        Layout.fillWidth: true
        radius: Style.radiusM * scaling
        color: Color.mSurface
        border.color: Color.mOutline
        border.width: Math.max(1, Style.borderS * scaling)
        implicitHeight: contentCol.implicitHeight + Style.marginXL * 2 * scaling

        ColumnLayout {
          id: contentCol
          anchors.fill: parent
          anchors.margins: Style.marginL * scaling
          spacing: Style.marginM * scaling

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginM * scaling

            NText {
              text: `${model.modelData.name} [${model.modelData.model}]`
              font.pointSize: Style.fontSizeL * scaling
              font.weight: Style.fontWeightBold
              color: Color.mSecondary
            }

            Item {
              Layout.fillWidth: true
            }

            NText {
              text: model.method
              font.pointSize: Style.fontSizeXS * scaling
              color: Color.mOnSurfaceVariant
              Layout.alignment: Qt.AlignRight
            }
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginM * scaling

            NText {
              text: "Brightness:"
              font.pointSize: Style.fontSizeM * scaling
              color: Color.mOnSurface
            }

            NSlider {
              Layout.fillWidth: true
              from: 0
              to: 1
              value: model.brightness
              stepSize: 0.05
              onPressedChanged: {
                if (!pressed) {
                  var monitor = BrightnessService.getMonitorForScreen(model.modelData)
                  monitor.setBrightness(value)
                }
              }
            }

            NText {
              text: Math.round(model.brightness * 100) + "%"
              font.pointSize: Style.fontSizeM * scaling
              font.weight: Style.fontWeightBold
              color: Color.mPrimary
              Layout.alignment: Qt.AlignRight
            }
          }
        }
      }
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginXL * scaling
    Layout.bottomMargin: Style.marginXL * scaling
  }

  // Night Light Section
  ColumnLayout {
    spacing: Style.marginXS * scaling
    Layout.fillWidth: true

    NText {
      text: "Night Light"
      font.pointSize: Style.fontSizeXXL * scaling
      font.weight: Style.fontWeightBold
      color: Color.mSecondary
    }

    NText {
      text: "Reduce blue light emission to help you sleep better and reduce eye strain."
      font.pointSize: Style.fontSizeM * scaling
      color: Color.mOnSurfaceVariant
      wrapMode: Text.WordWrap
      Layout.fillWidth: true
    }
  }

  NToggle {
    label: "Enable Night Light"
    description: "Apply a warm color filter to reduce blue light emission."
    checked: Settings.data.nightLight.enabled
    onToggled: checked => {
                 if (checked) {
                   // Verify wlsunset exists before enabling
                   wlsunsetCheck.running = true
                 } else {
                   Settings.data.nightLight.enabled = false
                   Settings.data.nightLight.forced = false
                   NightLightService.apply()
                   ToastService.showNotice("Night Light", "Disabled")
                 }
               }
  }

  // Temperature
  ColumnLayout {
    spacing: Style.marginXS * scaling
    Layout.alignment: Qt.AlignVCenter

    NLabel {
      label: "Color temperature"
      description: "Choose two temperatures in Kelvin."
    }

    RowLayout {
      visible: Settings.data.nightLight.enabled
      spacing: Style.marginM * scaling
      Layout.fillWidth: false
      Layout.fillHeight: true
      Layout.alignment: Qt.AlignVCenter

      NText {
        text: "Night"
        font.pointSize: Style.fontSizeM * scaling
        color: Color.mOnSurfaceVariant
        Layout.alignment: Qt.AlignVCenter
      }

      NTextInput {
        text: Settings.data.nightLight.nightTemp
        inputMethodHints: Qt.ImhDigitsOnly
        Layout.alignment: Qt.AlignVCenter
        onEditingFinished: {
          var nightTemp = parseInt(text)
          var dayTemp = parseInt(Settings.data.nightLight.dayTemp)
          if (!isNaN(nightTemp) && !isNaN(dayTemp)) {
            // Clamp value between [1000 .. (dayTemp-500)]
            var clampedValue = Math.min(dayTemp - 500, Math.max(1000, nightTemp))
            text = Settings.data.nightLight.nightTemp = clampedValue.toString()
          }
        }
      }

      Item {}

      NText {
        text: "Day"
        font.pointSize: Style.fontSizeM * scaling
        color: Color.mOnSurfaceVariant
        Layout.alignment: Qt.AlignVCenter
      }
      NTextInput {
        text: Settings.data.nightLight.dayTemp
        inputMethodHints: Qt.ImhDigitsOnly
        Layout.alignment: Qt.AlignVCenter
        onEditingFinished: {
          var dayTemp = parseInt(text)
          var nightTemp = parseInt(Settings.data.nightLight.nightTemp)
          if (!isNaN(nightTemp) && !isNaN(dayTemp)) {
            // Clamp value between [(nightTemp+500) .. 6500]
            var clampedValue = Math.max(nightTemp + 500, Math.min(6500, dayTemp))
            text = Settings.data.nightLight.dayTemp = clampedValue.toString()
          }
        }
      }
    }
  }

  NToggle {
    label: "Automatic Scheduling"
    description: `Based on the sunset and sunrise time in <i>${LocationService.stableName}</i> - recommended.`
    checked: Settings.data.nightLight.autoSchedule
    onToggled: checked => Settings.data.nightLight.autoSchedule = checked
    visible: Settings.data.nightLight.enabled
  }

  // Schedule settings
  ColumnLayout {
    spacing: Style.marginXS * scaling
    visible: Settings.data.nightLight.enabled && !Settings.data.nightLight.autoSchedule
             && !Settings.data.nightLight.forced

    RowLayout {
      Layout.fillWidth: false
      spacing: Style.marginM * scaling

      NLabel {
        label: "Manual Scheduling"
      }

      Item {// add a little more spacing
      }

      NText {
        text: "Sunrise Time"
        font.pointSize: Style.fontSizeM * scaling
        color: Color.mOnSurfaceVariant
      }

      NComboBox {
        model: timeOptions
        currentKey: Settings.data.nightLight.manualSunrise
        placeholder: "Select start time"
        onSelected: key => Settings.data.nightLight.manualSunrise = key
        minimumWidth: 120 * scaling
      }

      Item {// add a little more spacing
      }

      NText {
        text: "Sunset Time"
        font.pointSize: Style.fontSizeM * scaling
        color: Color.mOnSurfaceVariant
      }
      NComboBox {
        model: timeOptions
        currentKey: Settings.data.nightLight.manualSunset
        placeholder: "Select stop time"
        onSelected: key => Settings.data.nightLight.manualSunset = key
        minimumWidth: 120 * scaling
      }
    }
  }

  // Force activation toggle
  NToggle {
    label: "Force activation"
    description: "Immediately apply night temperature without scheduling or fade."
    checked: Settings.data.nightLight.forced
    onToggled: checked => {
                 Settings.data.nightLight.forced = checked
                 if (checked && !Settings.data.nightLight.enabled) {
                   // Ensure enabled when forcing
                   wlsunsetCheck.running = true
                 } else {
                   NightLightService.apply()
                 }
               }
    visible: Settings.data.nightLight.enabled
  }
}

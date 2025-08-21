import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.Widgets
import qs.Commons
import qs.Services

ColumnLayout {
  id: root

  property real localVolume: AudioService.volume

  // Connection used to open the pill when volume changes
  Connections {
    target: AudioService.sink?.audio ? AudioService.sink?.audio : null
    function onVolumeChanged() {
      localVolume = AudioService.volume
    }
  }

  spacing: 0

  ScrollView {
    id: scrollView

    Layout.fillWidth: true
    Layout.fillHeight: true
    padding: Style.marginM * scaling
    clip: true
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
    ScrollBar.vertical.policy: ScrollBar.AsNeeded

    ColumnLayout {
      width: scrollView.availableWidth
      spacing: 0

      Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 0
      }

      ColumnLayout {
        spacing: Style.marginXS * scaling
        Layout.fillWidth: true

        NText {
          text: "Audio Output Volume"
          font.pointSize: Style.fontSizeXXL * scaling
          font.weight: Style.fontWeightBold
          color: Color.mOnSurface
          Layout.bottomMargin: Style.marginS * scaling
        }

        // Volume Controls
        ColumnLayout {
          spacing: Style.marginS * scaling
          Layout.fillWidth: true
          Layout.topMargin: Style.marginS * scaling

          // Master Volume
          ColumnLayout {
            spacing: Style.marginS * scaling
            Layout.fillWidth: true

            NLabel {
              label: "Master Volume"
              description: "System-wide volume level."
            }

            RowLayout {
              // Pipewire seems a bit finicky, if we spam too many volume changes it breaks easily
              // Probably because they have some quick fades in and out to avoid clipping
              // We use a timer to space out the updates, to avoid lock up
              Timer {
                interval: Style.animationFast
                running: true
                repeat: true
                onTriggered: {
                  if (Math.abs(localVolume - AudioService.volume) >= 0.01) {
                    AudioService.setVolume(localVolume)
                  }
                }
              }

              NSlider {
                Layout.fillWidth: true
                from: 0
                to: Settings.data.audio.volumeOverdrive ? 2.0 : 1.0
                value: localVolume
                stepSize: 0.01
                onMoved: {
                  localVolume = value
                }
              }

              NText {
                text: Math.floor(AudioService.volume * 100) + "%"
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: Style.marginS * scaling
                color: Color.mOnSurface
              }
            }
          }

          // Mute Toggle
          ColumnLayout {
            spacing: Style.marginS * scaling
            Layout.fillWidth: true
            Layout.topMargin: Style.marginM * scaling

            NToggle {
              label: "Mute Audio Output"
              description: "Mute or unmute the default audio output."
              checked: AudioService.muted
              onToggled: checked => {
                           if (AudioService.sink && AudioService.sink.audio) {
                             AudioService.sink.audio.muted = checked
                           }
                         }
            }
          }

          // Volume Step Size
          ColumnLayout {
            spacing: Style.marginS * scaling
            Layout.fillWidth: true
            Layout.topMargin: Style.marginM * scaling

            NSpinBox {
              Layout.fillWidth: true
              label: "Volume Step Size"
              description: "Adjust the step size for volume changes (scroll wheel, keyboard shortcuts)."
              minimum: 1
              maximum: 25
              value: Settings.data.audio.volumeStep
              stepSize: 1
              suffix: "%"
              onValueChanged: {
                Settings.data.audio.volumeStep = value
              }
            }
          }
        }

        NDivider {
          Layout.fillWidth: true
          Layout.topMargin: Style.marginL * 2 * scaling
          Layout.bottomMargin: Style.marginL * scaling
        }

        // AudioService Devices
        ColumnLayout {
          spacing: Style.marginL * scaling
          Layout.fillWidth: true

          NText {
            text: "Audio Devices"
            font.pointSize: Style.fontSizeXXL * scaling
            font.weight: Style.fontWeightBold
            color: Color.mOnSurface
            Layout.bottomMargin: Style.marginS * scaling
          }

          // -------------------------------
          // Output Devices
          ButtonGroup {
            id: sinks
          }

          ColumnLayout {
            spacing: Style.marginXS * scaling
            Layout.fillWidth: true
            Layout.bottomMargin: Style.marginL * scaling

            NLabel {
              label: "Output Device"
              description: "Select the desired audio output device."
            }

            Repeater {
              model: AudioService.sinks
              NRadioButton {
                required property PwNode modelData
                ButtonGroup.group: sinks
                checked: AudioService.sink?.id === modelData.id
                onClicked: AudioService.setAudioSink(modelData)
                text: modelData.description
              }
            }
          }
        }

        // -------------------------------
        // Input Devices
        ButtonGroup {
          id: sources
        }

        ColumnLayout {
          spacing: Style.marginXS * scaling
          Layout.fillWidth: true
          Layout.bottomMargin: Style.marginL * scaling

          NLabel {
            label: "Input Device"
            description: "Select the desired audio input device."
          }

          Repeater {
            model: AudioService.sources
            NRadioButton {
              required property PwNode modelData
              ButtonGroup.group: sources
              checked: AudioService.source?.id === modelData.id
              onClicked: AudioService.setAudioSource(modelData)
              text: modelData.description
            }
          }
        }
      }

      // Divider
      NDivider {
        Layout.fillWidth: true
        Layout.topMargin: Style.marginL * scaling
        Layout.bottomMargin: Style.marginXL * scaling
      }

      // Bar Mini Media player
      ColumnLayout {
        spacing: Style.marginL * scaling
        Layout.fillWidth: true

        NText {
          text: "Bar Media Player"
          font.pointSize: Style.fontSizeXXL * scaling
          font.weight: Style.fontWeightBold
          color: Color.mOnSurface
          Layout.bottomMargin: Style.marginS * scaling
        }

        // Miniplayer section
        NToggle {
          label: "Show Album Art In Bar Media Player"
          description: "Show the album art of the currently playing song next to the title."
          checked: Settings.data.audio.showMiniplayerAlbumArt
          onToggled: checked => {
                       Settings.data.audio.showMiniplayerAlbumArt = checked
                     }
        }

        NToggle {
          label: "Show Audio Visualizer In Bar Media Player"
          description: "Shows an audio visualizer in the background of the miniplayer."
          checked: Settings.data.audio.showMiniplayerCava
          onToggled: checked => {
                       Settings.data.audio.showMiniplayerCava = checked
                     }
        }
      }

      // Divider
      NDivider {
        Layout.fillWidth: true
        Layout.topMargin: Style.marginXL * scaling
        Layout.bottomMargin: Style.marginXL * scaling
      }

      // AudioService Visualizer Category
      ColumnLayout {
        spacing: Style.marginS * scaling
        Layout.fillWidth: true

        NText {
          text: "Audio Visualizer"
          font.pointSize: Style.fontSizeXXL * scaling
          font.weight: Style.fontWeightBold
          color: Color.mOnSurface
          Layout.bottomMargin: Style.marginS * scaling
        }

        // AudioService Visualizer section
        NComboBox {
          id: audioVisualizerCombo
          label: "Visualization Type"
          description: "Choose a visualization type for media playback"
          model: ListModel {
            ListElement {
              key: "none"
              name: "None"
            }
            ListElement {
              key: "linear"
              name: "Linear"
            }
            ListElement {
              key: "mirrored"
              name: "Mirrored"
            }
            ListElement {
              key: "wave"
              name: "Wave"
            }
          }
          currentKey: Settings.data.audio.visualizerType
          onSelected: key => {
            Settings.data.audio.visualizerType = key
          }
        }
      }
    }
  }
}

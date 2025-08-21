import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import qs.Commons
import qs.Services
import qs.Widgets

ColumnLayout {
  id: root

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
        spacing: Style.marginL * scaling
        Layout.fillWidth: true

        NText {
          text: "Directory"
          font.pointSize: Style.fontSizeXXL * scaling
          font.weight: Style.fontWeightBold
          color: Color.mOnSurface
          Layout.bottomMargin: Style.marginS * scaling
        }

        // Wallpaper Settings Category
        ColumnLayout {
          spacing: Style.marginS * scaling
          Layout.fillWidth: true
          Layout.topMargin: Style.marginS * scaling

          // Wallpaper Folder
          ColumnLayout {
            spacing: Style.marginS * scaling
            Layout.fillWidth: true

            NTextInput {
              label: "Wallpaper Directory"
              description: "Path to your wallpaper directory."
              text: Settings.data.wallpaper.directory
              Layout.fillWidth: true
              onEditingFinished: {
                Settings.data.wallpaper.directory = text
              }
            }
          }
        }
      }

      NDivider {
        Layout.fillWidth: true
        Layout.topMargin: Style.marginL * 2 * scaling
        Layout.bottomMargin: Style.marginL * scaling
      }

      ColumnLayout {
        spacing: Style.marginL * scaling
        Layout.fillWidth: true

        NText {
          text: "Automation"
          font.pointSize: Style.fontSizeXXL * scaling
          font.weight: Style.fontWeightBold
          color: Color.mOnSurface
          Layout.bottomMargin: Style.marginS * scaling
        }

        // Random Wallpaper
        NToggle {
          label: "Random Wallpaper"
          description: "Automatically select random wallpapers from the folder."
          checked: Settings.data.wallpaper.isRandom
          onToggled: checked => {
                       Settings.data.wallpaper.isRandom = checked
                     }
        }

        // Interval
        ColumnLayout {
          RowLayout {
            NLabel {
              label: "Wallpaper Interval"
              description: "How often to change wallpapers automatically (in seconds)."
              Layout.fillWidth: true
            }

            NText {
              text: sliderWpInterval.value + " seconds"
              Layout.alignment: Qt.AlignBottom | Qt.AlignRight
            }
          }

          NSlider {
            id: sliderWpInterval
            Layout.fillWidth: true
            from: 10
            to: 900
            stepSize: 10
            value: Settings.data.wallpaper.randomInterval
            onPressedChanged: Settings.data.wallpaper.randomInterval = Math.round(value)
            cutoutColor: Color.mSurface
          }
        }
      }

      NDivider {
        Layout.fillWidth: true
        Layout.topMargin: Style.marginL * 2 * scaling
        Layout.bottomMargin: Style.marginL * scaling
      }

      // -------------------------------
      // SWWW
      ColumnLayout {
        spacing: Style.marginL * scaling
        Layout.fillWidth: true

        NText {
          text: "SWWW"
          font.pointSize: Style.fontSizeXXL * scaling
          font.weight: Style.fontWeightBold
          color: Color.mOnSurface
          Layout.bottomMargin: Style.marginS * scaling
        }

        // Use SWWW
        NToggle {
          label: "Use SWWW"
          description: "Use SWWW daemon for advanced wallpaper management."
          checked: Settings.data.wallpaper.swww.enabled
          onToggled: checked => {
                       if (checked) {
                         // Check if swww is installed
                         swwwCheck.running = true
                       } else {
                         Settings.data.wallpaper.swww.enabled = false
                         ToastService.showNotice("SWWW", "Disabled")
                       }
                     }
        }

        // SWWW Settings (only visible when useSWWW is enabled)
        ColumnLayout {
          spacing: Style.marginS * scaling
          Layout.fillWidth: true
          Layout.topMargin: Style.marginS * scaling
          visible: Settings.data.wallpaper.swww.enabled

          // Resize Mode
          NComboBox {
            label: "Resize Mode"
            description: "How SWWW should resize wallpapers to fit the screen."
            model: ListModel {
              ListElement {
                key: "no"
                name: "No"
              }
              ListElement {
                key: "crop"
                name: "Crop"
              }
              ListElement {
                key: "fit"
                name: "Fit"
              }
              ListElement {
                key: "stretch"
                name: "Stretch"
              }
            }
            currentKey: Settings.data.wallpaper.swww.resizeMethod
            onSelected: key => {
              Settings.data.wallpaper.swww.resizeMethod = key
            }
          }

          // Transition Type
          NComboBox {
            label: "Transition Type"
            description: "Animation type when switching between wallpapers."
            model: ListModel {
              ListElement {
                key: "none"
                name: "None"
              }
              ListElement {
                key: "simple"
                name: "Simple"
              }
              ListElement {
                key: "fade"
                name: "Fade"
              }
              ListElement {
                key: "left"
                name: "Left"
              }
              ListElement {
                key: "right"
                name: "Right"
              }
              ListElement {
                key: "top"
                name: "Top"
              }
              ListElement {
                key: "bottom"
                name: "Bottom"
              }
              ListElement {
                key: "wipe"
                name: "Wipe"
              }
              ListElement {
                key: "wave"
                name: "Wave"
              }
              ListElement {
                key: "grow"
                name: "Grow"
              }
              ListElement {
                key: "center"
                name: "Center"
              }
              ListElement {
                key: "any"
                name: "Any"
              }
              ListElement {
                key: "outer"
                name: "Outer"
              }
              ListElement {
                key: "random"
                name: "Random"
              }
            }
            currentKey: Settings.data.wallpaper.swww.transitionType
            onSelected: key => {
              Settings.data.wallpaper.swww.transitionType = key
            }
          }

          // Transition FPS
          ColumnLayout {
            RowLayout {
              Layout.fillWidth: true

              ColumnLayout {
                NText {
                  text: "Transition FPS"
                  font.weight: Style.fontWeightBold
                  color: Color.mOnSurface
                }

                NText {
                  text: "Frames per second for transition animations."
                  font.pointSize: Style.fontSizeXS * scaling
                  color: Color.mOnSurface
                  wrapMode: Text.WordWrap
                  Layout.fillWidth: true
                }
              }

              NText {
                text: sliderWpTransitionFps.value + " FPS"
                Layout.alignment: Qt.AlignBottom | Qt.AlignRight
              }
            }

            NSlider {
              id: sliderWpTransitionFps
              Layout.fillWidth: true
              from: 30
              to: 500
              stepSize: 5
              value: Settings.data.wallpaper.swww.transitionFps
              onPressedChanged: Settings.data.wallpaper.swww.transitionFps = Math.round(value)
              cutoutColor: Color.mSurface
            }
          }

          // Transition Duration
          ColumnLayout {
            RowLayout {
              Layout.fillWidth: true

              ColumnLayout {
                NText {
                  text: "Transition Duration"
                  font.weight: Style.fontWeightBold
                  color: Color.mOnSurface
                }

                NText {
                  text: "Duration of transition animations in seconds."
                  font.pointSize: Style.fontSizeXS * scaling
                  color: Color.mOnSurface
                  wrapMode: Text.WordWrap
                  Layout.fillWidth: true
                }
              }

              NText {
                text: sliderWpTransitionDuration.value.toFixed(2) + "s"
                Layout.alignment: Qt.AlignBottom | Qt.AlignRight
              }
            }

            NSlider {
              id: sliderWpTransitionDuration
              Layout.fillWidth: true
              from: 0.25
              to: 10
              stepSize: 0.05
              value: Settings.data.wallpaper.swww.transitionDuration
              onPressedChanged: Settings.data.wallpaper.swww.transitionDuration = value
              cutoutColor: Color.mSurface
            }
          }
        }
      }
    }
  }

  // Process to check if swww is installed
  Process {
    id: swwwCheck
    command: ["which", "swww"]
    running: false

    onExited: function (exitCode) {
      if (exitCode === 0) {
        // SWWW exists, enable it
        Settings.data.wallpaper.swww.enabled = true
        WallpaperService.startSWWWDaemon()
        ToastService.showNotice("SWWW", "Enabled!")
      } else {
        // SWWW not found
        ToastService.showWarning("SWWW", "Not installed!")
      }
    }

    stdout: StdioCollector {}
    stderr: StdioCollector {}
  }
}

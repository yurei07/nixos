import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Modules.Audio
import qs.Commons
import qs.Services
import qs.Widgets

Row {
  id: root

  property ShellScreen screen
  property real scaling: 1.0
  readonly property real minWidth: 160
  readonly property real maxWidth: 400

  anchors.verticalCenter: parent.verticalCenter
  spacing: Style.marginS * scaling
  visible: MediaService.currentPlayer !== null && MediaService.canPlay
  width: MediaService.currentPlayer !== null && MediaService.canPlay ? implicitWidth : 0

  function getTitle() {
    return MediaService.trackTitle + (MediaService.trackArtist !== "" ? ` - ${MediaService.trackArtist}` : "")
  }

  //  A hidden text element to safely measure the full title width
  NText {
    id: fullTitleMetrics
    visible: false
    text: titleText.text
    font: titleText.font
  }

  Rectangle {
    id: mediaMini

    // Let the Rectangle size itself based on its content (the Row)
    width: row.width + Style.marginM * 2 * scaling

    height: Math.round(Style.capsuleHeight * scaling)
    radius: Math.round(Style.radiusM * scaling)
    color: Color.mSurfaceVariant

    anchors.verticalCenter: parent.verticalCenter

    // Used to anchor the tooltip, so the tooltip does not move when the content expands
    Item {
      id: anchor
      height: parent.height
      width: 200 * scaling
    }

    Item {
      id: mainContainer
      anchors.fill: parent
      anchors.leftMargin: Style.marginS * scaling
      anchors.rightMargin: Style.marginS * scaling

      Loader {
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        active: Settings.data.audio.showMiniplayerCava && Settings.data.audio.visualizerType == "linear"
                && MediaService.isPlaying && MediaService.trackLength > 0
        z: 0

        sourceComponent: LinearSpectrum {
          width: mainContainer.width - Style.marginS * scaling
          height: 20 * scaling
          values: CavaService.values
          fillColor: Color.mOnSurfaceVariant
          opacity: 0.4
        }

        Loader {
          anchors.verticalCenter: parent.verticalCenter
          anchors.horizontalCenter: parent.horizontalCenter
          active: Settings.data.audio.showMiniplayerCava && Settings.data.audio.visualizerType == "mirrored"
                  && MediaService.isPlaying && MediaService.trackLength > 0
          z: 0

          sourceComponent: MirroredSpectrum {
            width: mainContainer.width - Style.marginS * scaling
            height: mainContainer.height - Style.marginS * scaling
            values: CavaService.values
            fillColor: Color.mOnSurfaceVariant
            opacity: 0.4
          }
        }

        Loader {
          anchors.verticalCenter: parent.verticalCenter
          anchors.horizontalCenter: parent.horizontalCenter
          active: Settings.data.audio.showMiniplayerCava && Settings.data.audio.visualizerType == "wave"
                  && MediaService.isPlaying && MediaService.trackLength > 0
          z: 0

          sourceComponent: WaveSpectrum {
            width: mainContainer.width - Style.marginS * scaling
            height: mainContainer.height - Style.marginS * scaling
            values: CavaService.values
            fillColor: Color.mOnSurfaceVariant
            opacity: 0.4
          }
        }
      }

      Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.marginS * scaling
        z: 1 // Above the visualizer

        NIcon {
          id: windowIcon
          text: MediaService.isPlaying ? "pause" : "play_arrow"
          font.pointSize: Style.fontSizeL * scaling
          verticalAlignment: Text.AlignVCenter
          anchors.verticalCenter: parent.verticalCenter
          visible: !Settings.data.audio.showMiniplayerAlbumArt && getTitle() !== "" && !trackArt.visible
        }

        Column {
          anchors.verticalCenter: parent.verticalCenter
          visible: Settings.data.audio.showMiniplayerAlbumArt

          Item {
            width: Math.round(18 * scaling)
            height: Math.round(18 * scaling)

            NImageCircled {
              id: trackArt
              anchors.fill: parent
              imagePath: MediaService.trackArtUrl
              fallbackIcon: MediaService.isPlaying ? "pause" : "play_arrow"
              borderWidth: 0
              border.color: Color.transparent
            }
          }
        }

        NText {
          id: titleText

          // For short titles, show full. For long titles, truncate and expand on hover
          width: {
            if (mouseArea.containsMouse) {
              return Math.round(Math.min(fullTitleMetrics.contentWidth, root.maxWidth * scaling))
            } else {
              return Math.round(Math.min(fullTitleMetrics.contentWidth, root.minWidth * scaling))
            }
          }
          text: getTitle()
          font.pointSize: Style.fontSizeS * scaling
          font.weight: Style.fontWeightMedium
          elide: Text.ElideRight
          anchors.verticalCenter: parent.verticalCenter
          verticalAlignment: Text.AlignVCenter
          color: Color.mTertiary

          Behavior on width {
            NumberAnimation {
              duration: Style.animationSlow
              easing.type: Easing.InOutCubic
            }
          }
        }
      }

      // Mouse area for hover detection
      MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: mouse => {
                     if (mouse.button === Qt.LeftButton) {
                       MediaService.playPause()
                     } else if (mouse.button == Qt.RightButton) {
                       MediaService.next()
                       // Need to hide the tooltip instantly
                       tooltip.visible = false
                     } else if (mouse.button == Qt.MiddleButton) {
                       MediaService.previous()
                       // Need to hide the tooltip instantly
                       tooltip.visible = false
                     }
                   }

        onEntered: {
          if (tooltip.text !== "") {
            tooltip.show()
          }
        }
        onExited: {
          tooltip.hide()
        }
      }
    }
  }

  NTooltip {
    id: tooltip
    text: {
      var str = ""
      if (MediaService.canGoNext) {
        str += "Right click for next\n"
      }
      if (MediaService.canGoPrevious) {
        str += "Middle click for previous\n"
      }
      return str
    }
    target: anchor
    positionAbove: Settings.data.bar.position === "bottom"
  }
}

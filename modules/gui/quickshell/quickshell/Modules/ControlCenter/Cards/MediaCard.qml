import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Modules.Audio
import qs.Commons
import qs.Services
import qs.Widgets

NBox {
  id: root

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: Style.marginL * scaling

    // No media player detected
    ColumnLayout {
      id: fallback

      visible: !main.visible
      spacing: Style.marginS * scaling

      Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
      }

      NIcon {
        icon: "disc"
        font.pointSize: Style.fontSizeXXXL * 3 * scaling
        color: Color.mPrimary
        Layout.alignment: Qt.AlignHCenter
      }

      // NText {
      //   text: I18n.tr("system.no-media-player-detected")
      //   color: Color.mOnSurfaceVariant
      //   Layout.alignment: Qt.AlignHCenter
      // }
      Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
      }
    }

    // MediaPlayer Main Content
    ColumnLayout {
      id: main

      visible: MediaService.currentPlayer && MediaService.canPlay
      spacing: Style.marginM * scaling

      // Player selector using NContextMenu
      Rectangle {
        id: playerSelectorButton
        Layout.fillWidth: true
        Layout.preferredHeight: Style.barHeight * scaling
        visible: MediaService.getAvailablePlayers().length > 1
        radius: Style.radiusM * scaling
        color: Color.transparent

        property var currentPlayer: MediaService.getAvailablePlayers()[MediaService.selectedPlayerIndex]

        RowLayout {
          anchors.fill: parent
          spacing: Style.marginS * scaling

          NIcon {
            icon: "caret-down"
            font.pointSize: Style.fontSizeXXL * scaling
            color: Color.mOnSurfaceVariant
          }

          NText {
            text: playerSelectorButton.currentPlayer ? playerSelectorButton.currentPlayer.identity : ""
            font.pointSize: Style.fontSizeXS * scaling
            color: Color.mOnSurfaceVariant
            Layout.fillWidth: true
          }
        }

        MouseArea {
          id: playerSelectorMouseArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor

          onClicked: {
            // Create menu items from available players
            var menuItems = []
            var players = MediaService.getAvailablePlayers()
            for (var i = 0; i < players.length; i++) {
              menuItems.push({
                               "label": players[i].identity,
                               "action": i.toString(),
                               "icon": "disc",
                               "enabled": true,
                               "visible": true
                             })
            }
            playerContextMenu.model = menuItems
            playerContextMenu.openAtItem(playerSelectorButton, playerSelectorButton.width - playerContextMenu.width, playerSelectorButton.height)
          }
        }

        NContextMenu {
          id: playerContextMenu
          parent: root
          width: 200 * scaling

          onTriggered: function (action) {
            var index = parseInt(action)
            if (!isNaN(index)) {
              MediaService.selectedPlayerIndex = index
              MediaService.updateCurrentPlayer()
            }
          }
        }
      }

      RowLayout {
        spacing: Style.marginM * scaling

        // -------------------------
        // Rounded thumbnail image
        Rectangle {

          width: 90 * scaling
          height: 90 * scaling
          radius: width * 0.5
          color: trackArt.visible ? Color.mPrimary : Color.transparent
          clip: true

          // Can't use fallback icon here, as we have a big disc behind
          NImageCircled {
            id: trackArt
            visible: MediaService.trackArtUrl !== ""
            anchors.fill: parent
            anchors.margins: Style.marginXS * scaling
            imagePath: MediaService.trackArtUrl
            borderColor: Color.mOutline
            borderWidth: Math.max(1, Style.borderS * scaling)
          }

          // Fallback icon when no album art available
          NIcon {
            icon: "disc"
            color: Color.mPrimary
            font.pointSize: Style.fontSizeXXXL * 3 * scaling
            visible: !trackArt.visible
            anchors.centerIn: parent
          }
        }

        // -------------------------
        // Track metadata
        ColumnLayout {
          Layout.fillWidth: true
          spacing: Style.marginXS * scaling

          NText {
            visible: MediaService.trackTitle !== ""
            text: MediaService.trackTitle
            font.pointSize: Style.fontSizeM * scaling
            font.weight: Style.fontWeightBold
            elide: Text.ElideRight
            wrapMode: Text.Wrap
            maximumLineCount: 2
            Layout.fillWidth: true
          }

          NText {
            visible: MediaService.trackArtist !== ""
            text: MediaService.trackArtist
            color: Color.mPrimary
            font.pointSize: Style.fontSizeXS * scaling
            elide: Text.ElideRight
            Layout.fillWidth: true
          }

          NText {
            visible: MediaService.trackAlbum !== ""
            text: MediaService.trackAlbum
            color: Color.mOnSurface
            font.pointSize: Style.fontSizeXS * scaling
            elide: Text.ElideRight
            Layout.fillWidth: true
          }
        }
      }

      // -------------------------
      // Progress slider (uses shared NSlider behavior like BarTab)
      Item {
        id: progressWrapper
        visible: (MediaService.currentPlayer && MediaService.trackLength > 0)
        Layout.fillWidth: true
        height: Style.baseWidgetSize * 0.5 * scaling

        // Local preview while dragging
        property real localSeekRatio: -1
        // Track the last ratio we actually sent to the backend to avoid redundant seeks
        property real lastSentSeekRatio: -1
        // Minimum change required to issue a new seek during drag
        property real seekEpsilon: 0.01
        property real progressRatio: {
          if (!MediaService.currentPlayer || MediaService.trackLength <= 0)
            return 0
          const r = MediaService.currentPosition / MediaService.trackLength
          if (isNaN(r) || !isFinite(r))
            return 0
          return Math.max(0, Math.min(1, r))
        }
        property real effectiveRatio: (MediaService.isSeeking && localSeekRatio >= 0) ? Math.max(0, Math.min(1, localSeekRatio)) : progressRatio

        // Debounced backend seek during drag
        Timer {
          id: seekDebounce
          interval: 75
          repeat: false
          onTriggered: {
            if (MediaService.isSeeking && progressWrapper.localSeekRatio >= 0) {
              const next = Math.max(0, Math.min(1, progressWrapper.localSeekRatio))
              if (progressWrapper.lastSentSeekRatio < 0 || Math.abs(next - progressWrapper.lastSentSeekRatio) >= progressWrapper.seekEpsilon) {
                MediaService.seekByRatio(next)
                progressWrapper.lastSentSeekRatio = next
              }
            }
          }
        }

        NSlider {
          id: progressSlider
          anchors.fill: parent
          from: 0
          to: 1
          stepSize: 0
          snapAlways: false
          enabled: MediaService.trackLength > 0 && MediaService.canSeek
          heightRatio: 0.65

          onMoved: {
            progressWrapper.localSeekRatio = value
            seekDebounce.restart()
          }
          onPressedChanged: {
            if (pressed) {
              MediaService.isSeeking = true
              progressWrapper.localSeekRatio = value
              MediaService.seekByRatio(value)
              progressWrapper.lastSentSeekRatio = value
            } else {
              seekDebounce.stop()
              MediaService.seekByRatio(value)
              MediaService.isSeeking = false
              progressWrapper.localSeekRatio = -1
              progressWrapper.lastSentSeekRatio = -1
            }
          }
        }

        // While not dragging, bind slider to live progress
        // during drag, let the slider manage its own value
        Binding {
          target: progressSlider
          property: "value"
          value: progressWrapper.progressRatio
          when: !MediaService.isSeeking
        }
      }

      // -------------------------
      // Media controls
      RowLayout {
        spacing: Style.marginM * scaling
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignHCenter

        // Previous button
        NIconButton {
          icon: "media-prev"
          tooltipText: I18n.tr("tooltips.previous-media")
          visible: MediaService.canGoPrevious
          onClicked: MediaService.canGoPrevious ? MediaService.previous() : {}
        }

        // Play/Pause button
        NIconButton {
          icon: MediaService.isPlaying ? "media-pause" : "media-play"
          tooltipText: MediaService.isPlaying ? I18n.tr("tooltips.pause") : I18n.tr("tooltips.play")
          visible: (MediaService.canPlay || MediaService.canPause)
          onClicked: (MediaService.canPlay || MediaService.canPause) ? MediaService.playPause() : {}
        }

        // Next button
        NIconButton {
          icon: "media-next"
          tooltipText: I18n.tr("tooltips.next-media")
          visible: MediaService.canGoNext
          onClicked: MediaService.canGoNext ? MediaService.next() : {}
        }
      }
    }

    Loader {
      active: Settings.data.audio.visualizerType == "linear"
      Layout.alignment: Qt.AlignHCenter

      sourceComponent: LinearSpectrum {
        width: 300 * scaling
        height: 80 * scaling
        values: CavaService.values
        fillColor: Color.mPrimary
        Layout.alignment: Qt.AlignHCenter
      }
    }

    Loader {
      active: Settings.data.audio.visualizerType == "mirrored"
      Layout.alignment: Qt.AlignHCenter

      sourceComponent: MirroredSpectrum {
        width: 300 * scaling
        height: 80 * scaling
        values: CavaService.values
        fillColor: Color.mPrimary
        Layout.alignment: Qt.AlignHCenter
      }
    }

    Loader {
      active: Settings.data.audio.visualizerType == "wave"
      Layout.alignment: Qt.AlignHCenter

      sourceComponent: WaveSpectrum {
        width: 300 * scaling
        height: 80 * scaling
        values: CavaService.values
        fillColor: Color.mPrimary
        Layout.alignment: Qt.AlignHCenter
      }
    }
  }
}

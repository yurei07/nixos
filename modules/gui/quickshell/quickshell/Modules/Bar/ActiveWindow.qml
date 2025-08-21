import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.Commons
import qs.Services
import qs.Widgets

Row {
  id: root
  anchors.verticalCenter: parent.verticalCenter
  spacing: Style.marginS * scaling
  visible: (Settings.data.bar.showActiveWindow && getTitle() !== "")

  property bool showingFullTitle: false
  property int lastWindowIndex: -1

  // Timer to hide full title after window switch
  Timer {
    id: fullTitleTimer
    interval: Style.animationSlow * 4 // Show full title for 2 seconds
    repeat: false
    onTriggered: {
      showingFullTitle = false
    }
  }

  // Update text when window changes
  Connections {
    target: CompositorService
    function onActiveWindowChanged() {
      // Check if window actually changed
      if (CompositorService.focusedWindowIndex !== lastWindowIndex) {
        lastWindowIndex = CompositorService.focusedWindowIndex
        showingFullTitle = true
        fullTitleTimer.restart()
      }
    }
  }

  function getTitle() {
    const focusedWindow = CompositorService.getFocusedWindow()
    return focusedWindow ? (focusedWindow.title || focusedWindow.appId || "") : ""
  }

  function getAppIcon() {
    const focusedWindow = CompositorService.getFocusedWindow()
    if (!focusedWindow || !focusedWindow.appId)
      return ""

    return Icons.iconForAppId(focusedWindow.appId)
  }

  //  A hidden text element to safely measure the full title width
  NText {
    id: fullTitleMetrics
    visible: false
    text: titleText.text
    font: titleText.font
  }

  Rectangle {
    // Let the Rectangle size itself based on its content (the Row)
    width: row.width + Style.marginM * scaling * 2
    height: Math.round(Style.capsuleHeight * scaling)
    radius: Math.round(Style.radiusM * scaling)
    color: Color.mSurfaceVariant

    anchors.verticalCenter: parent.verticalCenter

    Item {
      id: mainContainer
      anchors.fill: parent
      anchors.leftMargin: Style.marginS * scaling
      anchors.rightMargin: Style.marginS * scaling

      Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.marginXS * scaling

        // Window icon
        Item {
          width: Style.fontSizeL * scaling * 1.2
          height: Style.fontSizeL * scaling * 1.2
          anchors.verticalCenter: parent.verticalCenter
          visible: getTitle() !== "" && Settings.data.bar.showActiveWindowIcon

          IconImage {
            id: windowIcon
            anchors.fill: parent
            source: getAppIcon()
            asynchronous: true
            smooth: true
            visible: source !== ""
          }
        }

        NText {
          id: titleText

          // If hovered or just switched window, show up to 300 pixels
          // If not hovered show up to 150 pixels
          width: (showingFullTitle || mouseArea.containsMouse) ? Math.min(fullTitleMetrics.contentWidth,
                                                                          300 * scaling) : Math.min(
                                                                   fullTitleMetrics.contentWidth, 150 * scaling)
          text: getTitle()
          font.pointSize: Style.fontSizeS * scaling
          font.weight: Style.fontWeightMedium
          elide: Text.ElideRight
          anchors.verticalCenter: parent.verticalCenter
          verticalAlignment: Text.AlignVCenter
          color: Color.mSecondary

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
      }
    }
  }
}

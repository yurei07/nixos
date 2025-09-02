import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Wayland
import qs.Commons
import qs.Services
import qs.Widgets

NPanel {
  id: root

  panelWidth: 440 * scaling
  panelHeight: 380 * scaling
  panelAnchorHorizontalCenter: true
  panelAnchorVerticalCenter: true

  // Timer properties
  property int timerDuration: 9000 // 9 seconds
  property string pendingAction: ""
  property bool timerActive: false
  property int timeRemaining: 0

  // Cancel timer when panel is closing
  onClosed: {
    cancelTimer()
  }

  // Timer management
  function startTimer(action) {
    if (timerActive && pendingAction === action) {
      // Second click - execute immediately
      executeAction(action)
      return
    }

    pendingAction = action
    timeRemaining = timerDuration
    timerActive = true
    countdownTimer.start()
  }

  function cancelTimer() {
    timerActive = false
    pendingAction = ""
    timeRemaining = 0
    countdownTimer.stop()
  }

  function executeAction(action) {
    // Stop timer but don't reset other properties yet
    countdownTimer.stop()

    switch (action) {
    case "lock":
      // Access lockScreen directly like IPCManager does
      if (!lockScreen.active) {
        lockScreen.active = true
      }
      break
    case "suspend":
      CompositorService.suspend()
      break
    case "reboot":
      CompositorService.reboot()
      break
    case "logout":
      CompositorService.logout()
      break
    case "shutdown":
      CompositorService.shutdown()
      break
    }

    // Reset timer state and close panel
    cancelTimer()
    root.close()
  }

  // Countdown timer
  Timer {
    id: countdownTimer
    interval: 100
    repeat: true
    onTriggered: {
      timeRemaining -= interval
      if (timeRemaining <= 0) {
        executeAction(pendingAction)
      }
    }
  }

  panelContent: Rectangle {
    color: Color.transparent

    ColumnLayout {
      anchors.fill: parent
      anchors.topMargin: Style.marginL * scaling
      anchors.leftMargin: Style.marginL * scaling
      anchors.rightMargin: Style.marginL * scaling
      anchors.bottomMargin: Style.marginM * scaling
      spacing: Style.marginS * scaling

      // Header with title and close button
      RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: Style.baseWidgetSize * 0.8 * scaling

        NText {
          text: timerActive ? `${pendingAction.charAt(0).toUpperCase() + pendingAction.slice(1)} in ${Math.ceil(
                                timeRemaining / 1000)} seconds...` : "Power Options"
          font.weight: Style.fontWeightBold
          font.pointSize: Style.fontSizeL * scaling
          color: timerActive ? Color.mPrimary : Color.mOnSurface
          Layout.alignment: Qt.AlignVCenter
          verticalAlignment: Text.AlignVCenter
        }

        Item {
          Layout.fillWidth: true
        }

        NIconButton {
          icon: timerActive ? "back_hand" : "close"
          tooltipText: timerActive ? "Cancel Timer" : "Close"
          Layout.alignment: Qt.AlignVCenter
          colorBg: timerActive ? Color.applyOpacity(Color.mError, "20") : Color.transparent
          colorFg: timerActive ? Color.mError : Color.mOnSurface
          onClicked: {
            if (timerActive) {
              cancelTimer()
            } else {
              cancelTimer()
              root.close()
            }
          }
        }
      }

      // Power options
      ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginM * scaling

        // Lock Screen
        PowerButton {
          Layout.fillWidth: true
          icon: "lock_outline"
          title: "Lock"
          subtitle: "Lock your session"
          onClicked: startTimer("lock")
          pending: timerActive && pendingAction === "lock"
        }

        // Suspend
        PowerButton {
          Layout.fillWidth: true
          icon: "bedtime"
          title: "Suspend"
          subtitle: "Put the system to sleep"
          onClicked: startTimer("suspend")
          pending: timerActive && pendingAction === "suspend"
        }

        // Reboot
        PowerButton {
          Layout.fillWidth: true
          icon: "refresh"
          title: "Reboot"
          subtitle: "Restart the system"
          onClicked: startTimer("reboot")
          pending: timerActive && pendingAction === "reboot"
        }

        // Logout
        PowerButton {
          Layout.fillWidth: true
          icon: "exit_to_app"
          title: "Logout"
          subtitle: "End your session"
          onClicked: startTimer("logout")
          pending: timerActive && pendingAction === "logout"
        }

        // Shutdown
        PowerButton {
          Layout.fillWidth: true
          icon: "power_settings_new"
          title: "Shutdown"
          subtitle: "Turn off the system"
          onClicked: startTimer("shutdown")
          pending: timerActive && pendingAction === "shutdown"
          isShutdown: true
        }
      }
    }
  }

  // Custom power button component
  component PowerButton: Rectangle {
    id: buttonRoot

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool pending: false
    property bool isShutdown: false

    signal clicked

    height: Style.baseWidgetSize * 1.6 * scaling
    radius: Style.radiusS * scaling
    color: {
      if (pending)
        return Color.applyOpacity(Color.mPrimary, "20")
      if (mouseArea.containsMouse)
        return Color.mSecondary
      return Color.transparent
    }

    border.width: pending ? Math.max(Style.borderM * scaling) : 0
    border.color: pending ? Color.mPrimary : Color.mOutline

    Behavior on color {
      ColorAnimation {
        duration: Style.animationFast
      }
    }

    Item {
      anchors.fill: parent
      anchors.margins: Style.marginL * scaling

      // Icon on the left
      NIcon {
        id: iconElement
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: buttonRoot.icon
        color: {

          if (buttonRoot.pending)
            return Color.mPrimary
          if (buttonRoot.isShutdown && !mouseArea.containsMouse)
            return Color.mError
          if (mouseArea.containsMouse)
            return Color.mOnTertiary
          return Color.mOnSurface
        }
        font.pointSize: Style.fontSizeXXXL * scaling
        width: Style.baseWidgetSize * 0.6 * scaling
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter

        Behavior on color {
          ColorAnimation {
            duration: Style.animationFast
          }
        }
      }

      // Text content in the middle
      Column {
        anchors.left: iconElement.right
        anchors.right: pendingIndicator.visible ? pendingIndicator.left : parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Style.marginXL * scaling
        anchors.rightMargin: pendingIndicator.visible ? Style.marginM * scaling : 0
        spacing: 0

        NText {
          text: buttonRoot.title
          font.weight: Style.fontWeightMedium
          font.pointSize: Style.fontSizeM * scaling
          color: {
            if (buttonRoot.pending)
              return Color.mPrimary
            if (buttonRoot.isShutdown && !mouseArea.containsMouse)
              return Color.mError
            if (mouseArea.containsMouse)
              return Color.mOnTertiary
            return Color.mOnSurface
          }

          Behavior on color {
            ColorAnimation {
              duration: Style.animationFast
            }
          }
        }

        NText {
          text: {
            if (buttonRoot.pending) {
              return "Click again to execute immediately"
            }
            return buttonRoot.subtitle
          }
          font.pointSize: Style.fontSizeXS * scaling
          color: {
            if (buttonRoot.pending)
              return Color.mPrimary
            if (buttonRoot.isShutdown && !mouseArea.containsMouse)
              return Color.mError
            if (mouseArea.containsMouse)
              return Color.mOnTertiary
            return Color.mOnSurfaceVariant
          }
          opacity: Style.opacityHeavy
          wrapMode: Text.NoWrap
          elide: Text.ElideRight
        }
      }

      // Pending indicator on the right
      Rectangle {
        id: pendingIndicator
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 24 * scaling
        height: 24 * scaling
        radius: width * 0.5
        color: Color.mPrimary
        visible: buttonRoot.pending

        NText {
          anchors.centerIn: parent
          text: Math.ceil(timeRemaining / 1000)
          font.pointSize: Style.fontSizeS * scaling
          font.weight: Style.fontWeightBold
          color: Color.mOnPrimary
        }
      }
    }

    MouseArea {
      id: mouseArea
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor

      onClicked: buttonRoot.clicked()
    }
  }
}

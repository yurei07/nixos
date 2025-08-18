import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Services.Notifications
import qs.Commons
import qs.Services
import qs.Widgets

// Simple notification popup - displays multiple notifications
Variants {
  model: Quickshell.screens

  PanelWindow {
    id: root

    required property ShellScreen modelData
    readonly property real scaling: ScalingService.scale(screen)
    screen: modelData

    // Access the notification model from the service
    property ListModel notificationModel: NotificationService.notificationModel

    // Track notifications being removed for animation
    property var removingNotifications: ({})

    color: Color.transparent

    // If no notification display activated in settings, then show them all
    visible: modelData ? (Settings.data.notifications.monitors.includes(modelData.name)
                          || (Settings.data.notifications.monitors.length === 0))
                         && (NotificationService.notificationModel.count > 0) : false

    anchors.top: true
    anchors.right: true
    margins.top: (Style.barHeight + Style.marginMedium) * scaling
    margins.right: Style.marginMedium * scaling
    implicitWidth: 360 * scaling
    implicitHeight: Math.min(notificationStack.implicitHeight, (NotificationService.maxVisible * 120) * scaling)
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    // Connect to animation signal from service
    Component.onCompleted: {
      NotificationService.animateAndRemove.connect(function (notification, index) {
        // Find the delegate and trigger its animation
        if (notificationStack.children && notificationStack.children[index]) {
          let delegate = notificationStack.children[index]
          if (delegate && delegate.animateOut) {
            delegate.animateOut()
          }
        }
      })
    }

    // Main notification container
    Column {
      id: notificationStack
      anchors.top: parent.top
      anchors.right: parent.right
      spacing: Style.marginSmall * scaling
      width: 360 * scaling
      visible: true

      // Multiple notifications display
      Repeater {
        model: notificationModel
        delegate: Rectangle {
          width: 360 * scaling
          height: Math.max(80 * scaling, contentColumn.implicitHeight + (Style.marginMedium * 2 * scaling))
          clip: true
          radius: Style.radiusMedium * scaling
          border.color: Color.mPrimary
          border.width: Math.max(1, Style.borderThin * scaling)
          color: Color.mSurface

          // Animation properties
          property real scaleValue: 0.8
          property real opacityValue: 0.0
          property bool isRemoving: false

          // Scale and fade-in animation
          scale: scaleValue
          opacity: opacityValue

          // Animate in when the item is created
          Component.onCompleted: {
            scaleValue = 1.0
            opacityValue = 1.0
          }

          // Animate out when being removed
          function animateOut() {
            isRemoving = true
            scaleValue = 0.8
            opacityValue = 0.0
          }

          // Timer for delayed removal after animation
          Timer {
            id: removalTimer
            interval: Style.animationSlow
            repeat: false
            onTriggered: {
              NotificationService.forceRemoveNotification(model.rawNotification)
            }
          }

          // Check if this notification is being removed
          onIsRemovingChanged: {
            if (isRemoving) {
              // Remove from model after animation completes
              removalTimer.start()
            }
          }

          // Animation behaviors
          Behavior on scale {
            NumberAnimation {
              duration: Style.animationSlow
              easing.type: Easing.OutExpo
              //easing.type: Easing.OutBack   looks better but notification get clipped on all sides
            }
          }

          Behavior on opacity {
            NumberAnimation {
              duration: Style.animationNormal
              easing.type: Easing.OutQuad
            }
          }

          Column {
            id: contentColumn
            anchors.fill: parent
            anchors.margins: Style.marginMedium * scaling
            spacing: Style.marginSmall * scaling

            RowLayout {
              spacing: Style.marginSmall * scaling
              NText {
                text: (model.appName || model.desktopEntry) || "Unknown App"
                color: Color.mSecondary
                font.pointSize: Style.fontSizeSmall * scaling
              }
              Rectangle {
                width: 6 * scaling
                height: 6 * scaling
                radius: Style.radiusTiny * scaling
                color: (model.urgency === NotificationUrgency.Critical) ? Color.mError : (model.urgency === NotificationUrgency.Low) ? Color.mOnSurface : Color.mPrimary
                Layout.alignment: Qt.AlignVCenter
              }
              Item {
                Layout.fillWidth: true
              }
              NText {
                text: NotificationService.formatTimestamp(model.timestamp)
                color: Color.mOnSurface
                font.pointSize: Style.fontSizeSmall * scaling
              }
            }

            NText {
              text: model.summary || "No summary"
              font.pointSize: Style.fontSizeLarge * scaling
              font.weight: Style.fontWeightBold
              color: Color.mOnSurface
              wrapMode: Text.Wrap
              width: 300 * scaling
              maximumLineCount: 3
              elide: Text.ElideRight
            }

            NText {
              text: model.body || ""
              font.pointSize: Style.fontSizeSmall * scaling
              color: Color.mOnSurface
              wrapMode: Text.Wrap
              width: 300 * scaling
              maximumLineCount: 5
              elide: Text.ElideRight
            }
          }

          NIconButton {
            icon: "close"
            tooltipText: "Close"
            sizeMultiplier: 0.8
            showBorder: false
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: Style.marginSmall * scaling

            onClicked: {
              animateOut()
            }
          }
        }
      }
    }
  }
}

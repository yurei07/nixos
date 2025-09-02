import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import qs.Commons
import qs.Services
import qs.Widgets

// Notification History panel
NPanel {
  id: root

  panelWidth: 380 * scaling
  panelHeight: 500 * scaling
  panelAnchorRight: true

  panelContent: Rectangle {
    id: notificationRect
    color: Color.transparent

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Style.marginL * scaling
      spacing: Style.marginM * scaling

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM * scaling

        NIcon {
          text: "notifications"
          font.pointSize: Style.fontSizeXXL * scaling
          color: Color.mPrimary
        }

        NText {
          text: "Notification History"
          font.pointSize: Style.fontSizeL * scaling
          font.weight: Style.fontWeightBold
          color: Color.mOnSurface
          Layout.fillWidth: true
        }

        NIconButton {
          icon: "delete"
          tooltipText: "Clear history"
          sizeRatio: 0.8
          onClicked: NotificationService.clearHistory()
        }

        NIconButton {
          icon: "close"
          tooltipText: "Close"
          sizeRatio: 0.8
          onClicked: {
            root.close()
          }
        }
      }

      NDivider {
        Layout.fillWidth: true
      }

      // Empty state when no notifications
      Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: NotificationService.historyModel.count === 0

        ColumnLayout {
          anchors.centerIn: parent
          spacing: Style.marginM * scaling

          NIcon {
            text: "notifications_off"
            font.pointSize: Style.fontSizeXXXL * scaling
            color: Color.mOnSurface
            Layout.alignment: Qt.AlignHCenter
          }

          NText {
            text: "No notifications"
            font.pointSize: Style.fontSizeL * scaling
            color: Color.mOnSurface
            Layout.alignment: Qt.AlignHCenter
          }

          NText {
            text: "Your notifications will show up here as they arrive."
            font.pointSize: Style.fontSizeNormal * scaling
            color: Color.mOnSurfaceVariant
            Layout.alignment: Qt.AlignHCenter
          }
        }
      }

      ListView {
        id: notificationList
        Layout.fillWidth: true
        Layout.fillHeight: true
        model: NotificationService.historyModel
        spacing: Style.marginM * scaling
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        visible: NotificationService.historyModel.count > 0

        delegate: Rectangle {
          width: notificationList ? notificationList.width : 380 * scaling
          height: Math.max(80, notificationContent.height + 30)
          radius: Style.radiusM * scaling
          color: notificationMouseArea.containsMouse ? Color.mSecondary : Color.mSurfaceVariant

          RowLayout {
            anchors {
              fill: parent
              margins: Style.marginM * scaling
            }
            spacing: Style.marginM * scaling

            // Notification content
            Column {
              id: notificationContent
              Layout.fillWidth: true
              Layout.alignment: Qt.AlignVCenter
              spacing: Style.marginXXS * scaling

              NText {
                text: (summary || "No summary").substring(0, 100)
                font.pointSize: Style.fontSizeM * scaling
                font.weight: Font.Medium
                color: notificationMouseArea.containsMouse ? Color.mSurface : Color.mPrimary
                wrapMode: Text.Wrap
                width: parent.width - 60
                maximumLineCount: 2
                elide: Text.ElideRight
              }

              NText {
                text: (body || "").substring(0, 150)
                font.pointSize: Style.fontSizeXS * scaling
                color: notificationMouseArea.containsMouse ? Color.mSurface : Color.mOnSurface
                wrapMode: Text.Wrap
                width: parent.width - 60
                maximumLineCount: 3
                elide: Text.ElideRight
              }

              NText {
                text: NotificationService.formatTimestamp(timestamp)
                font.pointSize: Style.fontSizeXS * scaling
                color: notificationMouseArea.containsMouse ? Color.mSurface : Color.mOnSurface
              }
            }

            // Trash icon button
            NIconButton {
              icon: "delete"
              tooltipText: "Delete notification"
              sizeRatio: 0.7

              onClicked: {
                Logger.log("NotificationHistory", "Removing notification:", summary)
                NotificationService.historyModel.remove(index)
                NotificationService.saveHistory()
              }
            }
          }

          MouseArea {
            id: notificationMouseArea
            anchors.fill: parent
            anchors.rightMargin: Style.marginL * 3 * scaling
            hoverEnabled: true
          }
        }
      }
    }
  }
}

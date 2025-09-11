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

  preferredWidth: 380
  preferredHeight: 500
  panelAnchorRight: true

  panelContent: Rectangle {
    id: notificationRect
    color: Color.transparent

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Style.marginL * scaling
      spacing: Style.marginM * scaling

      // Header section
      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM * scaling

        NIcon {
          icon: "bell"
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
          icon: Settings.data.notifications.doNotDisturb ? "bell-off" : "bell"
          tooltipText: Settings.data.notifications.doNotDisturb ? "'Do Not Disturb' is enabled." : "'Do Not Disturb' is disabled."
          sizeRatio: 0.8
          onClicked: Settings.data.notifications.doNotDisturb = !Settings.data.notifications.doNotDisturb
          onRightClicked: Settings.data.notifications.doNotDisturb = !Settings.data.notifications.doNotDisturb
        }

        NIconButton {
          icon: "trash"
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
      ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.alignment: Qt.AlignHCenter
        visible: NotificationService.historyModel.count === 0
        spacing: Style.marginL * scaling

        Item {
          Layout.fillHeight: true
        }

        NIcon {
          icon: "bell-off"
          font.pointSize: 64 * scaling
          color: Color.mOnSurfaceVariant
          Layout.alignment: Qt.AlignHCenter
        }

        NText {
          text: "No notifications"
          font.pointSize: Style.fontSizeL * scaling
          color: Color.mOnSurfaceVariant
          Layout.alignment: Qt.AlignHCenter
        }

        NText {
          text: "Your notifications will show up here as they arrive."
          font.pointSize: Style.fontSizeS * scaling
          color: Color.mOnSurfaceVariant
          Layout.alignment: Qt.AlignHCenter
          Layout.fillWidth: true
          wrapMode: Text.Wrap
          horizontalAlignment: Text.AlignHCenter
        }

        Item {
          Layout.fillHeight: true
        }
      }

      // Notification list
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
          width: notificationList.width
          height: notificationLayout.implicitHeight + (Style.marginM * scaling * 2)
          radius: Style.radiusM * scaling
          color: notificationMouseArea.containsMouse ? Color.mSecondary : Color.mSurfaceVariant
          border.color: Qt.alpha(Color.mOutline, Style.opacityMedium)
          border.width: Math.max(1, Style.borderS * scaling)

          RowLayout {
            id: notificationLayout
            anchors.fill: parent
            anchors.margins: Style.marginM * scaling
            spacing: Style.marginM * scaling

            // App icon (same style as popup)
            NImageCircled {
              Layout.preferredWidth: 28 * scaling
              Layout.preferredHeight: 28 * scaling
              Layout.alignment: Qt.AlignVCenter
              // Prefer stable themed icons over transient image paths
              imagePath: (appIcon
                          && appIcon !== "") ? (AppIcons.iconFromName(appIcon, "application-x-executable")
                                                || appIcon) : ((AppIcons.iconForAppId(desktopEntry
                                                                                      || appName, "application-x-executable")
                                                                || (image && image
                                                                    !== "" ? image : AppIcons.iconFromName("application-x-executable",
                                                                                                           "application-x-executable"))))
              borderColor: Color.transparent
              borderWidth: 0
              visible: true
            }

            // Notification content column
            ColumnLayout {
              Layout.fillWidth: true
              Layout.alignment: Qt.AlignVCenter
              Layout.maximumWidth: notificationList.width - (Style.marginM * scaling * 4) // Account for margins and delete button
              spacing: Style.marginXXS * scaling

              NText {
                text: (summary || "No summary").substring(0, 100)
                font.pointSize: Style.fontSizeM * scaling
                font.weight: Font.Medium
                color: notificationMouseArea.containsMouse ? Color.mSurface : Color.mPrimary
                wrapMode: Text.Wrap
                Layout.fillWidth: true
                maximumLineCount: 2
                elide: Text.ElideRight
              }

              NText {
                text: (body || "").substring(0, 150)
                font.pointSize: Style.fontSizeXS * scaling
                color: notificationMouseArea.containsMouse ? Color.mSurface : Color.mOnSurface
                wrapMode: Text.Wrap
                Layout.fillWidth: true
                maximumLineCount: 3
                elide: Text.ElideRight
                visible: text.length > 0
              }

              NText {
                text: NotificationService.formatTimestamp(timestamp)
                font.pointSize: Style.fontSizeXS * scaling
                color: notificationMouseArea.containsMouse ? Color.mSurface : Color.mOnSurface
                Layout.fillWidth: true
              }
            }

            // Delete button
            NIconButton {
              icon: "trash"
              tooltipText: "Delete notification"
              sizeRatio: 0.7
              Layout.alignment: Qt.AlignTop

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
            anchors.rightMargin: Style.marginXL * scaling
            hoverEnabled: true
          }
        }
      }
    }
  }
}

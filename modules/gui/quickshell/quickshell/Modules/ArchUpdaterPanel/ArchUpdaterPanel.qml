import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services
import qs.Widgets

NPanel {
  id: root
  panelWidth: 380 * scaling
  panelHeight: 500 * scaling
  panelAnchorRight: true

  panelContent: Rectangle {
    color: Color.mSurface
    radius: Style.radiusL * scaling

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Style.marginL * scaling
      spacing: Style.marginM * scaling

      // Header
      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM * scaling

        NIcon {
          text: "system_update_alt"
          font.pointSize: Style.fontSizeXXL * scaling
          color: Color.mPrimary
        }

        NText {
          text: "System Updates"
          font.pointSize: Style.fontSizeL * scaling
          font.weight: Style.fontWeightBold
          color: Color.mOnSurface
          Layout.fillWidth: true
        }

        // Reset button (only show if update failed)
        NIconButton {
          visible: ArchUpdaterService.updateFailed
          icon: "refresh"
          tooltipText: "Reset update state"
          sizeRatio: 0.8
          colorBg: Color.mError
          colorFg: Color.mOnError
          onClicked: {
            ArchUpdaterService.resetUpdateState()
          }
        }

        NIconButton {
          icon: "close"
          tooltipText: "Close"
          sizeRatio: 0.8
          onClicked: root.close()
        }
      }

      NDivider {
        Layout.fillWidth: true
      }

      // Update summary (only show when packages are available and terminal is configured)
      NText {
        visible: !ArchUpdaterService.updateInProgress && !ArchUpdaterService.updateFailed
                 && !ArchUpdaterService.checkFailed && !ArchUpdaterService.aurBusy
                 && ArchUpdaterService.totalUpdates > 0 && ArchUpdaterService.terminalAvailable
                 && ArchUpdaterService.aurHelperAvailable
        text: ArchUpdaterService.totalUpdates + " package" + (ArchUpdaterService.totalUpdates !== 1 ? "s" : "") + " can be updated"
        font.pointSize: Style.fontSizeL * scaling
        font.weight: Style.fontWeightMedium
        color: Color.mOnSurface
        Layout.fillWidth: true
      }

      // Package selection info (only show when not updating and have packages and terminal is configured)
      NText {
        visible: !ArchUpdaterService.updateInProgress && !ArchUpdaterService.updateFailed
                 && !ArchUpdaterService.checkFailed && !ArchUpdaterService.aurBusy
                 && ArchUpdaterService.totalUpdates > 0 && ArchUpdaterService.terminalAvailable
                 && ArchUpdaterService.aurHelperAvailable
        text: ArchUpdaterService.selectedPackagesCount + " of " + ArchUpdaterService.totalUpdates + " packages selected"
        font.pointSize: Style.fontSizeS * scaling
        color: Color.mOnSurfaceVariant
        Layout.fillWidth: true
      }

      // Update in progress state
      ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: ArchUpdaterService.updateInProgress
        spacing: Style.marginM * scaling

        Item {
          Layout.fillHeight: true
        } // Spacer

        NIcon {
          text: "hourglass_empty"
          font.pointSize: Style.fontSizeXXXL * scaling
          color: Color.mPrimary
          Layout.alignment: Qt.AlignHCenter
        }

        NText {
          text: "Update in progress"
          font.pointSize: Style.fontSizeL * scaling
          color: Color.mOnSurface
          Layout.alignment: Qt.AlignHCenter
        }

        NText {
          text: "Please check your terminal window for update progress and prompts."
          font.pointSize: Style.fontSizeNormal * scaling
          color: Color.mOnSurfaceVariant
          Layout.alignment: Qt.AlignHCenter
          horizontalAlignment: Text.AlignHCenter
          wrapMode: Text.Wrap
          Layout.maximumWidth: 280 * scaling
        }

        Item {
          Layout.fillHeight: true
        } // Spacer
      }

      // Terminal not available state
      Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: !ArchUpdaterService.terminalAvailable && !ArchUpdaterService.updateInProgress
                 && !ArchUpdaterService.updateFailed

        ColumnLayout {
          anchors.centerIn: parent
          spacing: Style.marginM * scaling

          NIcon {
            text: "terminal"
            font.pointSize: Style.fontSizeXXXL * scaling
            color: Color.mError
            Layout.alignment: Qt.AlignHCenter
          }

          NText {
            text: "Terminal not configured"
            font.pointSize: Style.fontSizeL * scaling
            color: Color.mOnSurface
            Layout.alignment: Qt.AlignHCenter
          }

          NText {
            text: "The TERMINAL environment variable is not set. Please set it to your preferred terminal (e.g., kitty, alacritty, foot) in your shell configuration."
            font.pointSize: Style.fontSizeNormal * scaling
            color: Color.mOnSurfaceVariant
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            Layout.maximumWidth: 280 * scaling
          }
        }
      }

      // AUR helper not available state
      Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: ArchUpdaterService.terminalAvailable && !ArchUpdaterService.aurHelperAvailable
                 && !ArchUpdaterService.updateInProgress && !ArchUpdaterService.updateFailed
                 && !ArchUpdaterService.checkFailed && !ArchUpdaterService.aurBusy

        ColumnLayout {
          anchors.centerIn: parent
          spacing: Style.marginM * scaling

          NIcon {
            text: "package"
            font.pointSize: Style.fontSizeXXXL * scaling
            color: Color.mError
            Layout.alignment: Qt.AlignHCenter
          }

          NText {
            text: "AUR helper not found"
            font.pointSize: Style.fontSizeL * scaling
            color: Color.mOnSurface
            Layout.alignment: Qt.AlignHCenter
          }

          NText {
            text: "No AUR helper (yay or paru) is installed. Please install either yay or paru to manage AUR packages. yay is recommended."
            font.pointSize: Style.fontSizeNormal * scaling
            color: Color.mOnSurfaceVariant
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            Layout.maximumWidth: 280 * scaling
          }
        }
      }

      // Check failed state (AUR down, network issues, etc.)
      Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: ArchUpdaterService.checkFailed && !ArchUpdaterService.updateInProgress
                 && !ArchUpdaterService.updateFailed && ArchUpdaterService.terminalAvailable
                 && ArchUpdaterService.aurHelperAvailable

        ColumnLayout {
          anchors.centerIn: parent
          spacing: Style.marginM * scaling

          NIcon {
            text: "error"
            font.pointSize: Style.fontSizeXXXL * scaling
            color: Color.mError
            Layout.alignment: Qt.AlignHCenter
          }

          NText {
            text: "Cannot check for updates"
            font.pointSize: Style.fontSizeL * scaling
            color: Color.mOnSurface
            Layout.alignment: Qt.AlignHCenter
          }

          NText {
            text: ArchUpdaterService.lastCheckError
                  || "AUR helper is unavailable or network connection failed. This could be due to AUR being down, network issues, or missing AUR helper (yay/paru)."
            font.pointSize: Style.fontSizeNormal * scaling
            color: Color.mOnSurfaceVariant
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            Layout.maximumWidth: 280 * scaling
          }

          // Prominent refresh button
          NIconButton {
            icon: "refresh"
            tooltipText: "Try checking again"
            sizeRatio: 1.2
            colorBg: Color.mPrimary
            colorFg: Color.mOnPrimary
            onClicked: {
              ArchUpdaterService.forceRefresh()
            }
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Style.marginL * scaling
          }
        }
      }

      // Update failed state
      Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: ArchUpdaterService.updateFailed

        ColumnLayout {
          anchors.centerIn: parent
          spacing: Style.marginM * scaling

          NIcon {
            text: "error_outline"
            font.pointSize: Style.fontSizeXXXL * scaling
            color: Color.mError
            Layout.alignment: Qt.AlignHCenter
          }

          NText {
            text: "Update failed"
            font.pointSize: Style.fontSizeL * scaling
            color: Color.mOnSurface
            Layout.alignment: Qt.AlignHCenter
          }

          NText {
            text: "Check your terminal for error details and try again."
            font.pointSize: Style.fontSizeNormal * scaling
            color: Color.mOnSurfaceVariant
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            Layout.maximumWidth: 280 * scaling
          }

          // Prominent refresh button
          NIconButton {
            icon: "refresh"
            tooltipText: "Refresh and try again"
            sizeRatio: 1.2
            colorBg: Color.mPrimary
            colorFg: Color.mOnPrimary
            onClicked: {
              ArchUpdaterService.resetUpdateState()
            }
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Style.marginL * scaling
          }
        }
      }

      // No updates available state
      Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: !ArchUpdaterService.updateInProgress && !ArchUpdaterService.updateFailed
                 && !ArchUpdaterService.checkFailed && !ArchUpdaterService.aurBusy
                 && ArchUpdaterService.totalUpdates === 0 && ArchUpdaterService.terminalAvailable
                 && ArchUpdaterService.aurHelperAvailable

        ColumnLayout {
          anchors.centerIn: parent
          spacing: Style.marginM * scaling

          NIcon {
            text: "check_circle"
            font.pointSize: Style.fontSizeXXXL * scaling
            color: Color.mPrimary
            Layout.alignment: Qt.AlignHCenter
          }

          NText {
            text: "System is up to date"
            font.pointSize: Style.fontSizeL * scaling
            color: Color.mOnSurface
            Layout.alignment: Qt.AlignHCenter
          }

          NText {
            text: "All packages are current. Check back later for updates."
            font.pointSize: Style.fontSizeNormal * scaling
            color: Color.mOnSurfaceVariant
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            Layout.maximumWidth: 280 * scaling
          }
        }
      }

      // Checking for updates state
      Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: ArchUpdaterService.aurBusy && !ArchUpdaterService.updateInProgress && !ArchUpdaterService.updateFailed
                 && ArchUpdaterService.terminalAvailable && ArchUpdaterService.aurHelperAvailable

        ColumnLayout {
          anchors.centerIn: parent
          spacing: Style.marginM * scaling

          NBusyIndicator {
            Layout.alignment: Qt.AlignHCenter
            size: Style.fontSizeXXXL * scaling
            color: Color.mPrimary
          }

          NText {
            text: "Checking for updates"
            font.pointSize: Style.fontSizeL * scaling
            color: Color.mOnSurface
            Layout.alignment: Qt.AlignHCenter
          }

          NText {
            text: "Scanning package databases for available updates..."
            font.pointSize: Style.fontSizeNormal * scaling
            color: Color.mOnSurfaceVariant
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            Layout.maximumWidth: 280 * scaling
          }
        }
      }

      // Package list (only show when not in any special state)
      NBox {
        visible: !ArchUpdaterService.updateInProgress && !ArchUpdaterService.updateFailed
                 && !ArchUpdaterService.checkFailed && !ArchUpdaterService.aurBusy
                 && ArchUpdaterService.totalUpdates > 0 && ArchUpdaterService.terminalAvailable
                 && ArchUpdaterService.aurHelperAvailable
        Layout.fillWidth: true
        Layout.fillHeight: true

        // Combine repo and AUR lists in order: repos first, then AUR
        property var items: (ArchUpdaterService.repoPackages || []).concat(ArchUpdaterService.aurPackages || [])

        ListView {
          id: unifiedList
          anchors.fill: parent
          anchors.margins: Style.marginM * scaling
          cacheBuffer: Math.round(300 * scaling)
          clip: true

          model: parent.items
          delegate: Rectangle {
            width: unifiedList.width
            height: 44 * scaling
            color: Color.transparent
            radius: Style.radiusS * scaling

            RowLayout {
              anchors.fill: parent
              spacing: Style.marginS * scaling

              // Checkbox for selection
              NCheckbox {
                id: checkbox
                label: ""
                description: ""
                checked: ArchUpdaterService.isPackageSelected(modelData.name)
                baseSize: Math.max(Style.baseWidgetSize * 0.7, 14)
                onToggled: function (checked) {
                  ArchUpdaterService.togglePackageSelection(modelData.name)
                  // Force refresh of the checked property
                  checkbox.checked = ArchUpdaterService.isPackageSelected(modelData.name)
                }
              }

              // Package info
              ColumnLayout {
                Layout.fillWidth: true
                spacing: Style.marginXXS * scaling

                NText {
                  text: modelData.name
                  font.pointSize: Style.fontSizeS * scaling
                  font.weight: Style.fontWeightBold
                  color: Color.mOnSurface
                  Layout.fillWidth: true
                  Layout.alignment: Qt.AlignVCenter
                }

                NText {
                  text: modelData.oldVersion + " → " + modelData.newVersion
                  font.pointSize: Style.fontSizeXXS * scaling
                  color: Color.mOnSurfaceVariant
                  Layout.fillWidth: true
                }
              }

              // Source tag (AUR vs PAC)
              Rectangle {
                visible: !!modelData.source
                radius: width * 0.5
                color: modelData.source === "aur" ? Color.mTertiary : Color.mSecondary
                Layout.alignment: Qt.AlignVCenter
                implicitHeight: Style.fontSizeS * 1.8 * scaling
                // Width based on label content + horizontal padding
                implicitWidth: badgeText.implicitWidth + Math.max(12 * scaling, Style.marginS * scaling)

                NText {
                  id: badgeText
                  anchors.centerIn: parent
                  text: modelData.source === "aur" ? "AUR" : "PAC"
                  font.pointSize: Style.fontSizeXXS * scaling
                  font.weight: Style.fontWeightBold
                  color: modelData.source === "aur" ? Color.mOnTertiary : Color.mOnSecondary
                }
              }
            }
          }
        }
      }

      // Action buttons (only show when not updating)
      RowLayout {
        visible: !ArchUpdaterService.updateInProgress && !ArchUpdaterService.updateFailed
                 && !ArchUpdaterService.checkFailed && ArchUpdaterService.terminalAvailable
                 && ArchUpdaterService.aurHelperAvailable
        Layout.fillWidth: true
        spacing: Style.marginL * scaling

        NIconButton {
          icon: "refresh"
          tooltipText: ArchUpdaterService.aurBusy ? "Checking for updates..." : (!ArchUpdaterService.canPoll ? "Refresh available soon" : "Refresh package lists")
          onClicked: {
            ArchUpdaterService.forceRefresh()
          }
          colorBg: Color.mSurfaceVariant
          colorFg: Color.mOnSurface
          Layout.fillWidth: true
          enabled: !ArchUpdaterService.aurBusy
        }

        NIconButton {
          icon: "system_update_alt"
          tooltipText: "Update all packages"
          enabled: ArchUpdaterService.totalUpdates > 0
          onClicked: {
            ArchUpdaterService.runUpdate()
            root.close()
          }
          colorBg: ArchUpdaterService.totalUpdates > 0 ? Color.mPrimary : Color.mSurfaceVariant
          colorFg: ArchUpdaterService.totalUpdates > 0 ? Color.mOnPrimary : Color.mOnSurfaceVariant
          Layout.fillWidth: true
        }

        NIconButton {
          icon: "check_box"
          tooltipText: "Update selected packages"
          enabled: ArchUpdaterService.selectedPackagesCount > 0
          onClicked: {
            if (ArchUpdaterService.selectedPackagesCount > 0) {
              ArchUpdaterService.runSelectiveUpdate()
              root.close()
            }
          }
          colorBg: ArchUpdaterService.selectedPackagesCount > 0 ? Color.mPrimary : Color.mSurfaceVariant
          colorFg: ArchUpdaterService.selectedPackagesCount > 0 ? Color.mOnPrimary : Color.mOnSurfaceVariant
          Layout.fillWidth: true
        }
      }
    }
  }
}

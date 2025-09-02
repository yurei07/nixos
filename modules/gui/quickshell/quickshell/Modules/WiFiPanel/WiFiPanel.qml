import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
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

  // Enable keyboard focus for WiFi panel (needed for password input)
  panelKeyboardFocus: true

  property string passwordPromptSsid: ""
  property string passwordInput: ""
  property bool showPasswordPrompt: false

  onOpened: {
    if (Settings.data.network.wifiEnabled && wifiPanel.visible) {
      NetworkService.refreshNetworks()
    }
  }

  panelContent: Rectangle {
    color: Color.transparent
    anchors.fill: parent
    anchors.margins: Style.marginL * scaling

    ColumnLayout {
      anchors.fill: parent

      // Header
      RowLayout {
        NIcon {
          text: "wifi"
          font.pointSize: Style.fontSizeXXL * scaling
          color: Color.mPrimary
        }

        NText {
          text: "WiFi"
          font.pointSize: Style.fontSizeL * scaling
          font.weight: Style.fontWeightBold
          color: Color.mOnSurface
          Layout.fillWidth: true
          Layout.leftMargin: Style.marginS * scaling
        }

        NIconButton {
          icon: "refresh"
          tooltipText: "Refresh networks"
          sizeRatio: 0.8
          enabled: Settings.data.network.wifiEnabled && !NetworkService.isLoading
          onClicked: {
            NetworkService.refreshNetworks()
          }
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

      // Show errors at the very top
      NText {
        visible: NetworkService.connectStatus === "error" && NetworkService.connectError.length > 0
        text: NetworkService.connectError
        color: Color.mError
        font.pointSize: Style.fontSizeXS * scaling
        wrapMode: Text.Wrap
        Layout.fillWidth: true
      }

      Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        // Loading indicator
        ColumnLayout {
          anchors.centerIn: parent
          visible: Settings.data.network.wifiEnabled && NetworkService.isLoading
          spacing: Style.marginM * scaling

          NBusyIndicator {
            running: NetworkService.isLoading
            color: Color.mPrimary
            size: Style.baseWidgetSize * scaling
            Layout.alignment: Qt.AlignHCenter
          }

          NText {
            text: "Scanning for networks..."
            font.pointSize: Style.fontSizeNormal * scaling
            color: Color.mOnSurfaceVariant
            Layout.alignment: Qt.AlignHCenter
          }
        }

        // WiFi disabled message
        ColumnLayout {
          anchors.centerIn: parent
          visible: !Settings.data.network.wifiEnabled
          spacing: Style.marginM * scaling

          NIcon {
            text: "wifi_off"
            font.pointSize: Style.fontSizeXXXL * scaling
            color: Color.mOnSurfaceVariant
            Layout.alignment: Qt.AlignHCenter
          }

          NText {
            text: "WiFi is disabled"
            font.pointSize: Style.fontSizeL * scaling
            color: Color.mOnSurfaceVariant
            Layout.alignment: Qt.AlignHCenter
          }

          NText {
            text: "Enable WiFi to see available networks"
            font.pointSize: Style.fontSizeNormal * scaling
            color: Color.mOnSurfaceVariant
            Layout.alignment: Qt.AlignHCenter
          }
        }

        // Network list
        ListView {
          anchors.fill: parent
          visible: Settings.data.network.wifiEnabled && !NetworkService.isLoading
          model: Object.values(NetworkService.networks)
          spacing: Style.marginS * scaling
          clip: true

          delegate: Item {
            width: parent ? parent.width : 0
            height: modelData.ssid === passwordPromptSsid
                    && showPasswordPrompt ? 130 * scaling : Style.baseWidgetSize * 1.75 * scaling

            ColumnLayout {
              anchors.fill: parent
              spacing: 0

              Rectangle {
                id: rect
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Style.radiusS * scaling
                color: networkMouseArea.containsMouse ? Color.mTertiary : Color.transparent
                border.color: modelData.connected ? Color.mPrimary : Color.transparent
                border.width: Math.max(1, Style.borderM * scaling)

                RowLayout {
                  anchors {
                    fill: parent
                    leftMargin: Style.marginL * scaling
                    rightMargin: Style.marginL * scaling
                  }
                  spacing: Style.marginS * scaling

                  NIcon {
                    text: NetworkService.signalIcon(modelData.signal)
                    font.pointSize: Style.fontSizeXXL * scaling
                    color: networkMouseArea.containsMouse ? Color.mSurface : Color.mOnSurface
                  }

                  ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 0

                    // SSID
                    NText {
                      Layout.fillWidth: true
                      text: modelData.ssid || "Unknown Network"
                      font.pointSize: Style.fontSizeNormal * scaling
                      elide: Text.ElideRight
                      color: networkMouseArea.containsMouse ? Color.mSurface : Color.mOnSurface
                    }

                    // Security Protocol
                    NText {
                      text: modelData.security && modelData.security !== "--" ? modelData.security : "Open"
                      font.pointSize: Style.fontSizeXXS * scaling
                      elide: Text.ElideRight
                      Layout.fillWidth: true
                      color: networkMouseArea.containsMouse ? Color.mSurface : Color.mOnSurface
                    }
                  }

                  Item {
                    Layout.preferredWidth: Style.baseWidgetSize * 0.7 * scaling
                    Layout.preferredHeight: Style.baseWidgetSize * 0.7 * scaling
                    visible: NetworkService.connectStatusSsid === modelData.ssid
                             && (NetworkService.connectStatus !== ""
                                 || NetworkService.connectingSsid === modelData.ssid)

                    NBusyIndicator {
                      visible: NetworkService.connectingSsid === modelData.ssid
                      running: NetworkService.connectingSsid === modelData.ssid
                      color: networkMouseArea.containsMouse ? Color.mSurface : Color.mOnSurface
                      anchors.centerIn: parent
                      size: Style.baseWidgetSize * 0.7 * scaling
                    }
                  }

                  RowLayout {
                    visible: modelData.connected
                    NText {
                      text: "Connected"
                      font.pointSize: Style.fontSizeXS * scaling
                      color: networkMouseArea.containsMouse ? Color.mSurface : Color.mOnSurface
                      Layout.alignment: Qt.AlignVCenter
                    }
                    NIcon {
                      text: "check"
                      font.pointSize: Style.fontSizeXXL * scaling
                      color: networkMouseArea.containsMouse ? Color.mSurface : Color.mOnSurface
                    }
                  }
                }

                MouseArea {
                  id: networkMouseArea
                  anchors.fill: parent
                  hoverEnabled: true
                  onClicked: {
                    if (modelData.connected) {
                      NetworkService.disconnectNetwork(modelData.ssid)
                      showPasswordPrompt = false
                    } else if (NetworkService.isSecured(modelData.security) && !modelData.existing) {
                      passwordPromptSsid = modelData.ssid
                      showPasswordPrompt = true
                      passwordInput = "" // Clear previous input
                      Qt.callLater(function () {
                        passwordInputField.forceActiveFocus()
                      })
                    } else {
                      NetworkService.connectNetwork(modelData.ssid, modelData.security)
                    }
                  }
                }
              }

              // Password prompt section
              Rectangle {
                visible: modelData.ssid === passwordPromptSsid && showPasswordPrompt
                Layout.fillWidth: true
                Layout.preferredHeight: modelData.ssid === passwordPromptSsid && showPasswordPrompt ? 60 : 0
                Layout.margins: Style.marginS * scaling

                color: Color.mSurfaceVariant
                radius: Style.radiusS * scaling

                RowLayout {
                  anchors.fill: parent
                  anchors.margins: Style.marginS * scaling
                  spacing: Style.marginS * scaling

                  Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.round(Style.barHeight * scaling)

                    Rectangle {
                      anchors.fill: parent
                      radius: Style.radiusXS * scaling
                      color: Color.transparent
                      border.color: passwordInputField.activeFocus ? Color.mPrimary : Color.mOutline
                      border.width: Math.max(1, Style.borderS * scaling)

                      TextInput {
                        id: passwordInputField
                        anchors.fill: parent
                        anchors.margins: Style.marginM * scaling
                        text: passwordInput
                        font.pointSize: Style.fontSizeM * scaling
                        color: Color.mOnSurface
                        verticalAlignment: TextInput.AlignVCenter
                        clip: true
                        focus: true
                        selectByMouse: true
                        activeFocusOnTab: true
                        inputMethodHints: Qt.ImhNone
                        echoMode: TextInput.Password
                        onTextChanged: passwordInput = text
                        onAccepted: {
                          if (passwordInput !== "") {
                            NetworkService.submitPassword(passwordPromptSsid, passwordInput)
                            showPasswordPrompt = false
                          }
                        }

                        MouseArea {
                          id: passwordInputMouseArea
                          anchors.fill: parent
                          onClicked: passwordInputField.forceActiveFocus()
                        }
                      }
                    }
                  }

                  Rectangle {
                    Layout.preferredWidth: Style.baseWidgetSize * 2.5 * scaling
                    Layout.preferredHeight: Math.round(Style.barHeight * scaling)
                    radius: Style.radiusM * scaling
                    color: Color.mPrimary

                    Behavior on color {
                      ColorAnimation {
                        duration: Style.animationFast
                      }
                    }

                    NText {
                      anchors.centerIn: parent
                      text: "Connect"
                      color: Color.mSurface
                      font.pointSize: Style.fontSizeXS * scaling
                    }

                    MouseArea {
                      anchors.fill: parent
                      onClicked: {
                        if (passwordInput !== "") {
                          NetworkService.submitPassword(passwordPromptSsid, passwordInput)
                          showPasswordPrompt = false
                        }
                      }
                      cursorShape: Qt.PointingHandCursor
                      hoverEnabled: true
                      onEntered: parent.color = Qt.darker(Color.mPrimary, 1.1)
                      onExited: parent.color = Color.mPrimary
                    }
                  }

                  NIconButton {
                    icon: "close"
                    onClicked: {
                      showPasswordPrompt = false
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}

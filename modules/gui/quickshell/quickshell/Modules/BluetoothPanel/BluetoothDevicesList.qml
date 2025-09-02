import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Wayland
import qs.Commons
import qs.Services
import qs.Widgets

ColumnLayout {
  id: root

  property string label: ""
  property string tooltipText: ""
  property var model: {

  }

  Layout.fillWidth: true
  spacing: Style.marginM * scaling

  NText {
    text: root.label
    font.pointSize: Style.fontSizeL * scaling
    color: Color.mSecondary
    font.weight: Style.fontWeightMedium
    Layout.fillWidth: true
    visible: root.model.length > 0
  }

  Repeater {
    id: deviceList
    Layout.fillWidth: true
    model: root.model
    visible: BluetoothService.adapter && BluetoothService.adapter.enabled

    Rectangle {
      id: bluetoothDeviceRectangle
      property bool canConnect: BluetoothService.canConnect(modelData)
      property bool canDisconnect: BluetoothService.canDisconnect(modelData)
      property bool isBusy: BluetoothService.isDeviceBusy(modelData)

      Layout.fillWidth: true
      Layout.preferredHeight: 64 * scaling + (10 * scaling * modelData.batteryAvailable)
      radius: Style.radiusM * scaling

      color: {
        if (availableDeviceArea.containsMouse) {
          if (canDisconnect && !isBusy)
            return Color.mError

          if (!isBusy)
            return Color.mTertiary
          return Color.mPrimary
        }

        if (modelData.pairing || modelData.state === BluetoothDeviceState.Connecting)
          return Color.mPrimary

        if (modelData.blocked)
          return Color.mError

        return Color.mSurfaceVariant
      }
      border.color: Color.mOutline
      border.width: Math.max(1, Style.borderS * scaling)

      NTooltip {
        id: tooltip
        target: bluetoothDeviceRectangle
        positionAbove: Settings.data.bar.position === "bottom"
        text: root.tooltipText
      }

      RowLayout {
        anchors.fill: parent
        anchors.margins: Style.marginM * scaling
        spacing: Style.marginS * scaling
        Layout.alignment: Qt.AlignVCenter

        // One device BT icon
        NIcon {
          text: BluetoothService.getDeviceIcon(modelData)
          font.pointSize: Style.fontSizeXXL * scaling
          color: {
            if (availableDeviceArea.containsMouse)
              return Color.mOnTertiary

            if (modelData.pairing || modelData.state === BluetoothDeviceState.Connecting)
              return Color.mOnPrimary

            if (modelData.blocked)
              return Color.mOnError

            return Color.mOnSurface
          }
          Layout.alignment: Qt.AlignVCenter
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: Style.marginXXS * scaling

          // Device name
          NText {
            text: modelData.name || modelData.deviceName
            font.pointSize: Style.fontSizeM * scaling
            elide: Text.ElideRight
            color: {
              if (availableDeviceArea.containsMouse)
                return Color.mOnTertiary

              if (modelData.pairing || modelData.state === BluetoothDeviceState.Connecting)
                return Color.mOnPrimary

              if (modelData.blocked)
                return Color.mOnError

              return Color.mOnSurface
            }
            font.weight: Style.fontWeightMedium
            Layout.fillWidth: true
          }

          // Signal Strength
          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginXS * scaling

            // Device signal strength - "Unknown" when not connected
            NText {
              text: BluetoothService.getSignalStrength(modelData)
              font.pointSize: Style.fontSizeXS * scaling
              color: {
                if (availableDeviceArea.containsMouse)
                  return Color.mOnTertiary

                if (modelData.pairing || modelData.state === BluetoothDeviceState.Connecting)
                  return Color.mOnPrimary

                if (modelData.blocked)
                  return Color.mOnError

                return Color.mOnSurfaceVariant
              }
            }

            NIcon {
              text: BluetoothService.getSignalIcon(modelData)
              font.pointSize: Style.fontSizeXS * scaling
              color: {
                if (availableDeviceArea.containsMouse)
                  return Color.mOnTertiary

                if (modelData.pairing || modelData.state === BluetoothDeviceState.Connecting)
                  return Color.mOnPrimary

                if (modelData.blocked)
                  return Color.mOnError

                return Color.mOnSurface
              }
              visible: modelData.signalStrength !== undefined && modelData.signalStrength > 0 && !modelData.pairing
                       && !modelData.blocked
            }

            NText {
              text: (modelData.signalStrength !== undefined
                     && modelData.signalStrength > 0) ? modelData.signalStrength + "%" : ""
              font.pointSize: Style.fontSizeXS * scaling
              color: {
                if (availableDeviceArea.containsMouse)
                  return Color.mOnTertiary

                if (modelData.pairing || modelData.state === BluetoothDeviceState.Connecting)
                  return Color.mOnPrimary

                if (modelData.blocked)
                  return Color.mOnError

                return Color.mOnSurface
              }
              visible: modelData.signalStrength !== undefined && modelData.signalStrength > 0 && !modelData.pairing
                       && !modelData.blocked
            }
          }

          NText {
            visible: modelData.batteryAvailable
            text: BluetoothService.getBattery(modelData)
            font.pointSize: Style.fontSizeXS * scaling
            color: {
              if (availableDeviceArea.containsMouse)
                return Color.mOnTertiary

              if (modelData.pairing || modelData.state === BluetoothDeviceState.Connecting)
                return Color.mOnPrimary

              if (modelData.blocked)
                return Color.mOnError

              return Color.mOnSurfaceVariant
            }
          }
        }

        // Spacer to push connect button to the right
        Item {
          Layout.fillWidth: true
        }

        // Call to action
        Rectangle {
          Layout.preferredWidth: 80 * scaling
          Layout.preferredHeight: 28 * scaling
          radius: Style.radiusM * scaling
          visible: (modelData.state !== BluetoothDeviceState.Connecting)
          color: Color.transparent

          border.color: {
            if (availableDeviceArea.containsMouse) {
              return Color.mOnTertiary
            }
            if (bluetoothDeviceRectangle.canDisconnect && !isBusy) {
              return Color.mError
            }
            return Color.mPrimary
          }
          border.width: Math.max(1, Style.borderS * scaling)
          opacity: canConnect || isBusy || canDisconnect ? 1 : 0.5

          NText {
            anchors.centerIn: parent
            text: {
              if (modelData.pairing) {
                return "Pairing..."
              }
              if (modelData.blocked) {
                return "Blocked"
              }
              if (modelData.connected) {
                return "Disconnect"
              }
              return "Connect"
            }
            font.pointSize: Style.fontSizeXS * scaling
            font.weight: Style.fontWeightMedium
            color: {

              if (availableDeviceArea.containsMouse) {
                return Color.mOnTertiary
              }

              if (bluetoothDeviceRectangle.canDisconnect && !isBusy) {
                return Color.mError
              } else {
                return Color.mPrimary
              }
            }
          }
        }
      }

      MouseArea {

        id: availableDeviceArea
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: (canConnect || canDisconnect)
                     && !isBusy ? Qt.PointingHandCursor : (isBusy ? Qt.BusyCursor : Qt.ArrowCursor)
        onEntered: {
          if (root.tooltipText && !isBusy) {
            tooltip.show()
          }
        }
        onExited: {
          if (root.tooltipText && !isBusy) {
            tooltip.hide()
          }
        }
        onClicked: function (mouse) {

          if (!modelData || modelData.pairing) {
            return
          }

          if (root.tooltipText && !isBusy) {
            tooltip.hide()
          }

          if (mouse.button === Qt.LeftButton) {
            if (modelData.connected) {
              BluetoothService.disconnectDevice(modelData)
            } else {
              BluetoothService.connectDeviceWithTrust(modelData)
            }
          } else if (mouse.button === Qt.RightButton) {
            BluetoothService.forgetDevice(modelData)
          }
        }
      }
    }
  }
}

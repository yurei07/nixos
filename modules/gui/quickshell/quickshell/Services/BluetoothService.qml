pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs.Commons

Singleton {
  id: root

  readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
  readonly property bool available: adapter !== null
  readonly property bool enabled: (adapter && adapter.enabled) ?? false
  readonly property bool discovering: (adapter && adapter.discovering) ?? false
  readonly property var devices: adapter ? adapter.devices : null
  readonly property var pairedDevices: {
    if (!adapter || !adapter.devices) {
      return []
    }
    return adapter.devices.values.filter(dev => {
                                           return dev && (dev.paired || dev.trusted)
                                         })
  }
  readonly property var allDevicesWithBattery: {
    if (!adapter || !adapter.devices) {
      return []
    }
    return adapter.devices.values.filter(dev => {
                                           return dev && dev.batteryAvailable && dev.battery > 0
                                         })
  }

  function init() {
    Logger.log("Bluetooth", "Service initialized")
    delaySyncState.running = true
  }

  Timer {
    id: delaySyncState
    interval: 1000
    repeat: false
    onTriggered: {
      Settings.data.network.bluetoothEnabled = adapter.enabled
    }
  }

  Timer {
    id: delayDiscovery
    interval: 1000
    repeat: false
    onTriggered: adapter.discovering = true
  }

  Connections {
    target: adapter
    function onEnabledChanged() {
      Settings.data.network.bluetoothEnabled = adapter.enabled
      if (adapter.enabled) {
        ToastService.showNotice("Bluetooth", "Enabled")
        // Using a timer to give a little time so the adapter is really enabled
        delayDiscovery.running = true
      } else {
        ToastService.showNotice("Bluetooth", "Disabled")
      }
    }
  }

  function sortDevices(devices) {
    return devices.sort((a, b) => {
                          var aName = a.name || a.deviceName || ""
                          var bName = b.name || b.deviceName || ""

                          var aHasRealName = aName.includes(" ") && aName.length > 3
                          var bHasRealName = bName.includes(" ") && bName.length > 3

                          if (aHasRealName && !bHasRealName)
                          return -1
                          if (!aHasRealName && bHasRealName)
                          return 1

                          var aSignal = (a.signalStrength !== undefined && a.signalStrength > 0) ? a.signalStrength : 0
                          var bSignal = (b.signalStrength !== undefined && b.signalStrength > 0) ? b.signalStrength : 0
                          return bSignal - aSignal
                        })
  }

  function getDeviceIcon(device) {
    if (!device) {
      return "bt-device-generic"
    }

    var name = (device.name || device.deviceName || "").toLowerCase()
    var icon = (device.icon || "").toLowerCase()
    if (icon.includes("headset") || icon.includes("audio") || name.includes("headphone") || name.includes("airpod") || name.includes("headset") || name.includes("arctis")) {
      return "bt-device-headphones"
    }

    if (icon.includes("mouse") || name.includes("mouse")) {
      return "bt-device-mouse"
    }
    if (icon.includes("keyboard") || name.includes("keyboard")) {
      return "bt-device-keyboard"
    }
    if (icon.includes("phone") || name.includes("phone") || name.includes("iphone") || name.includes("android") || name.includes("samsung")) {
      return "bt-device-phone"
    }
    if (icon.includes("watch") || name.includes("watch")) {
      return "bt-device-watch"
    }
    if (icon.includes("speaker") || name.includes("speaker")) {
      return "bt-device-speaker"
    }
    if (icon.includes("display") || name.includes("tv")) {
      return "bt-device-tv"
    }
    return "bt-device-generic"
  }

  function canConnect(device) {
    if (!device)
      return false


    /*
      Paired

      Means you’ve successfully exchanged keys with the device.

      The devices remember each other and can authenticate without repeating the pairing process.

      Example: once your headphones are paired, you don’t need to type a PIN every time.
      Hence, instead of !device.paired, should be device.connected
    */
    return !device.connected && !device.pairing && !device.blocked
  }

  function canDisconnect(device) {
    if (!device)
      return false
    return device.connected && !device.pairing && !device.blocked
  }

  function getStatusString(device) {
    if (device.state === BluetoothDeviceState.Connecting) {
      return "Connecting..."
    }
    if (device.pairing) {
      return "Pairing..."
    }
    if (device.blocked) {
      return "Blocked"
    }
    return ""
  }

  function getSignalStrength(device) {
    if (!device || device.signalStrength === undefined || device.signalStrength <= 0) {
      return "Signal: Unknown"
    }
    var signal = device.signalStrength
    if (signal >= 80) {
      return "Signal: Excellent"
    }
    if (signal >= 60) {
      return "Signal: Good"
    }
    if (signal >= 40) {
      return "Signal: Fair"
    }
    if (signal >= 20) {
      return "Signal: Poor"
    }
    return "Signal: Very Poor"
  }

  function getBattery(device) {
    return `Battery: ${Math.round(device.battery * 100)}%`
  }

  function getSignalIcon(device) {
    if (!device || device.signalStrength === undefined || device.signalStrength <= 0) {
      return "signal_cellular_null"
    }
    var signal = device.signalStrength
    if (signal >= 80) {
      return "signal_cellular_4_bar"
    }
    if (signal >= 60) {
      return "signal_cellular_3_bar"
    }
    if (signal >= 40) {
      return "signal_cellular_2_bar"
    }
    if (signal >= 20) {
      return "signal_cellular_1_bar"
    }
    return "signal_cellular_0_bar"
  }

  function isDeviceBusy(device) {
    if (!device) {
      return false
    }

    return device.pairing || device.state === BluetoothDeviceState.Disconnecting || device.state === BluetoothDeviceState.Connecting
  }

  function connectDeviceWithTrust(device) {
    if (!device) {
      return
    }

    device.trusted = true
    device.connect()
  }

  function disconnectDevice(device) {
    if (!device) {
      return
    }

    device.disconnect()
  }

  function forgetDevice(device) {
    if (!device) {
      return
    }

    device.trusted = false
    device.forget()
  }

  function setBluetoothEnabled(enabled) {
    if (!adapter) {
      Logger.warn("Bluetooth", "No adapter available")
      return
    }

    adapter.enabled = enabled
  }
}

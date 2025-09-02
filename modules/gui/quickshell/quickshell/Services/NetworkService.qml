pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Singleton {
  id: root

  property var networks: ({})
  property string connectingSsid: ""
  property string connectStatus: ""
  property string connectStatusSsid: ""
  property string connectError: ""
  property string detectedInterface: ""
  property string lastConnectedNetwork: ""
  property bool isLoading: false
  property bool ethernet: false

  Component.onCompleted: {
    Logger.log("Network", "Service started")
    // Only refresh networks if WiFi is enabled
    if (Settings.data.network.wifiEnabled) {
      refreshNetworks()
    }
  }

  function signalIcon(signal) {
    if (signal >= 80)
      return "network_wifi"
    if (signal >= 60)
      return "network_wifi_3_bar"
    if (signal >= 40)
      return "network_wifi_2_bar"
    if (signal >= 20)
      return "network_wifi_1_bar"
    return "signal_wifi_0_bar"
  }

  function isSecured(security) {
    return security && security.trim() !== "" && security.trim() !== "--"
  }

  function refreshNetworks() {
    isLoading = true
    checkEthernet.running = true
    existingNetwork.running = true
  }

  function setWifiEnabled(enabled) {
    if (enabled) {
      // Enable WiFi radio
      isLoading = true
      enableWifiProcess.running = true
    } else {
      // Disconnect from current network and store it for reconnection
      for (const ssid in networks) {
        if (networks[ssid].connected) {
          lastConnectedNetwork = ssid
          // Disconnect from the current network before disabling WiFi
          disconnectNetwork(ssid)
          break
        }
      }

      // Disable WiFi radio
      disableWifiProcess.running = true
    }
  }

  function connectNetwork(ssid, security) {
    pendingConnect = {
      "ssid": ssid,
      "security": security,
      "password": ""
    }
    doConnect()
  }

  function submitPassword(ssid, password) {
    pendingConnect = {
      "ssid": ssid,
      "security": networks[ssid].security,
      "password": password
    }
    doConnect()
  }

  function disconnectNetwork(ssid) {
    disconnectProfileProcess.connectionName = ssid
    disconnectProfileProcess.running = true
  }

  property var pendingConnect: null

  function doConnect() {
    const params = pendingConnect
    if (!params)
      return

    connectingSsid = params.ssid
    connectStatus = ""
    connectStatusSsid = params.ssid

    const targetNetwork = networks[params.ssid]

    if (targetNetwork && targetNetwork.existing) {
      upConnectionProcess.profileName = params.ssid
      upConnectionProcess.running = true
      pendingConnect = null
      return
    }

    if (params.security && params.security !== "--") {
      getInterfaceProcess.running = true
      return
    }
    connectProcess.security = params.security
    connectProcess.ssid = params.ssid
    connectProcess.password = params.password
    connectProcess.running = true
    pendingConnect = null
  }

  property int refreshInterval: 25000

  // Only refresh when we have an active connection and WiFi is enabled
  property bool hasActiveConnection: {
    for (const net in networks) {
      if (networks[net].connected) {
        return true
      }
    }
    return false
  }

  property Timer refreshTimer: Timer {
    interval: root.refreshInterval
    // Only run timer when we're connected to a network and WiFi is enabled
    running: root.hasActiveConnection && Settings.data.network.wifiEnabled
    repeat: true
    onTriggered: root.refreshNetworks()
  }

  // Force a refresh when menu is opened
  function onMenuOpened() {
    if (Settings.data.network.wifiEnabled) {
      refreshNetworks()
    }
  }

  function onMenuClosed() {// No need to do anything special on close
  }

  // Process to enable WiFi radio
  property Process enableWifiProcess: Process {
    id: enableWifiProcess
    running: false
    command: ["nmcli", "radio", "wifi", "on"]
    onRunningChanged: {
      if (!running) {
        // Wait a moment for the radio to be enabled, then refresh networks
        enableWifiDelayTimer.start()
      }
    }
    stderr: StdioCollector {
      onStreamFinished: {
        if (text.trim() !== "") {
          Logger.warn("Network", "Error enabling WiFi:", text)
        }
      }
    }
  }

  // Timer to delay network refresh after enabling WiFi
  property Timer enableWifiDelayTimer: Timer {
    id: enableWifiDelayTimer
    interval: 2000 // Wait 2 seconds for radio to be ready
    repeat: false
    onTriggered: {
      // Force refresh networks multiple times to ensure UI updates
      root.refreshNetworks()

      // Try to auto-reconnect to the last connected network if it exists
      if (lastConnectedNetwork) {
        autoReconnectTimer.start()
      }

      // Set up additional refresh to ensure UI is populated
      postEnableRefreshTimer.start()
    }
  }

  // Additional timer to ensure networks are populated after enabling
  property Timer postEnableRefreshTimer: Timer {
    id: postEnableRefreshTimer
    interval: 1000
    repeat: false
    onTriggered: {
      root.refreshNetworks()
    }
  }

  // Timer to attempt auto-reconnection to the last connected network
  property Timer autoReconnectTimer: Timer {
    id: autoReconnectTimer
    interval: 3000 // Wait 3 seconds after scan for networks to be available
    repeat: false
    onTriggered: {
      if (lastConnectedNetwork && networks[lastConnectedNetwork]) {
        const network = networks[lastConnectedNetwork]
        if (network.existing && !network.connected) {
          upConnectionProcess.profileName = lastConnectedNetwork
          upConnectionProcess.running = true
        }
      }
    }
  }

  // Process to disable WiFi radio
  property Process disableWifiProcess: Process {
    id: disableWifiProcess
    running: false
    command: ["nmcli", "radio", "wifi", "off"]
    onRunningChanged: {
      if (!running) {
        // Clear networks when WiFi is disabled
        root.networks = ({})
        root.connectingSsid = ""
        root.connectStatus = ""
        root.connectStatusSsid = ""
        root.connectError = ""
        root.isLoading = false
      }
    }
    stderr: StdioCollector {
      onStreamFinished: {
        if (text.trim() !== "") {
          Logger.warn("Network", "Error disabling WiFi:", text)
        }
      }
    }
  }

  property Process disconnectProfileProcess: Process {
    id: disconnectProfileProcess
    property string connectionName: ""
    running: false
    command: ["nmcli", "connection", "down", connectionName]
    onRunningChanged: {
      if (!running) {
        // Clear connection status when disconnecting
        root.connectingSsid = ""
        root.connectStatus = ""
        root.connectStatusSsid = ""
        root.connectError = ""
        root.refreshNetworks()
      }
    }
  }

  property Process existingNetwork: Process {
    id: existingNetwork
    running: false
    command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"]
    stdout: StdioCollector {
      onStreamFinished: {
        const lines = text.split("\n")
        const networksMap = {}

        for (var i = 0; i < lines.length; ++i) {
          const line = lines[i].trim()
          if (!line)
          continue

          const parts = line.split(":")
          if (parts.length < 2) {
            Logger.warn("Network", "Malformed nmcli output line:", line)
            continue
          }

          const ssid = parts[0]
          const type = parts[1]

          if (ssid) {
            networksMap[ssid] = {
              "ssid": ssid,
              "type": type
            }
          }
        }
        scanProcess.existingNetwork = networksMap
        scanProcess.running = true
      }
    }
  }

  property Process scanProcess: Process {
    id: scanProcess
    running: false
    command: ["nmcli", "-t", "-f", "SSID,SECURITY,SIGNAL,IN-USE", "device", "wifi", "list"]

    property var existingNetwork

    stdout: StdioCollector {
      onStreamFinished: {
        const lines = text.split("\n")
        const networksMap = {}

        for (var i = 0; i < lines.length; ++i) {
          const line = lines[i].trim()
          if (!line)
          continue

          const parts = line.split(":")
          if (parts.length < 4) {
            Logger.warn("Network", "Malformed nmcli output line:", line)
            continue
          }
          const ssid = parts[0]
          const security = parts[1]
          const signal = parseInt(parts[2])
          const inUse = parts[3] === "*"

          if (ssid) {
            if (!networksMap[ssid]) {
              networksMap[ssid] = {
                "ssid": ssid,
                "security": security,
                "signal": signal,
                "connected": inUse,
                "existing": ssid in scanProcess.existingNetwork
              }
            } else {
              const existingNet = networksMap[ssid]
              if (inUse) {
                existingNet.connected = true
              }
              if (signal > existingNet.signal) {
                existingNet.signal = signal
                existingNet.security = security
              }
            }
          }
        }

        root.networks = networksMap
        root.isLoading = false
        scanProcess.existingNetwork = {}
      }
    }
  }

  property Process connectProcess: Process {
    id: connectProcess
    property string ssid: ""
    property string password: ""
    property string security: ""
    running: false
    command: {
      if (password) {
        return ["nmcli", "device", "wifi", "connect", `'${ssid}'`, "password", password]
      } else {
        return ["nmcli", "device", "wifi", "connect", `'${ssid}'`]
      }
    }
    stdout: StdioCollector {
      onStreamFinished: {
        root.connectingSsid = ""
        root.connectStatus = "success"
        root.connectStatusSsid = connectProcess.ssid
        root.connectError = ""
        root.lastConnectedNetwork = connectProcess.ssid
        root.refreshNetworks()
      }
    }
    stderr: StdioCollector {
      onStreamFinished: {
        root.connectingSsid = ""
        root.connectStatus = "error"
        root.connectStatusSsid = connectProcess.ssid
        root.connectError = text
      }
    }
  }

  property Process getInterfaceProcess: Process {
    id: getInterfaceProcess
    running: false
    command: ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE", "device"]
    stdout: StdioCollector {
      onStreamFinished: {
        var lines = text.split("\n")
        for (var i = 0; i < lines.length; ++i) {
          var parts = lines[i].split(":")
          if (parts[1] === "wifi" && parts[2] !== "unavailable") {
            root.detectedInterface = parts[0]
            break
          }
        }
        if (root.detectedInterface) {
          var params = root.pendingConnect
          addConnectionProcess.ifname = root.detectedInterface
          addConnectionProcess.ssid = params.ssid
          addConnectionProcess.password = params.password
          addConnectionProcess.profileName = params.ssid
          addConnectionProcess.security = params.security
          addConnectionProcess.running = true
        } else {
          root.connectStatus = "error"
          root.connectStatusSsid = root.pendingConnect.ssid
          root.connectError = "No Wi-Fi interface found."
          root.connectingSsid = ""
          root.pendingConnect = null
        }
      }
    }
  }

  property Process checkEthernet: Process {
    id: checkEthernet
    running: false
    command: ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE", "device"]
    stdout: StdioCollector {
      onStreamFinished: {
        var lines = text.split("\n")
        for (var i = 0; i < lines.length; ++i) {
          var parts = lines[i].split(":")
          if (parts[1] === "ethernet" && parts[2] === "connected") {
            root.ethernet = true
            break
          }
        }
      }
    }
  }

  property Process addConnectionProcess: Process {
    id: addConnectionProcess
    property string ifname: ""
    property string ssid: ""
    property string password: ""
    property string profileName: ""
    property string security: ""
    running: false
    command: {
      var cmd = ["nmcli", "connection", "add", "type", "wifi", "ifname", ifname, "con-name", profileName, "ssid", ssid]
      if (security && security !== "--") {
        cmd.push("wifi-sec.key-mgmt")
        cmd.push("wpa-psk")
        cmd.push("wifi-sec.psk")
        cmd.push(password)
      }
      return cmd
    }
    stdout: StdioCollector {
      onStreamFinished: {
        upConnectionProcess.profileName = addConnectionProcess.profileName
        upConnectionProcess.running = true
      }
    }
    stderr: StdioCollector {
      onStreamFinished: {
        upConnectionProcess.profileName = addConnectionProcess.profileName
        upConnectionProcess.running = true
      }
    }
  }

  property Process upConnectionProcess: Process {
    id: upConnectionProcess
    property string profileName: ""
    running: false
    command: ["nmcli", "connection", "up", "id", profileName]
    stdout: StdioCollector {
      onStreamFinished: {
        root.connectingSsid = ""
        root.connectStatus = "success"
        root.connectStatusSsid = root.pendingConnect ? root.pendingConnect.ssid : upConnectionProcess.profileName
        root.connectError = ""
        root.lastConnectedNetwork = upConnectionProcess.profileName
        root.pendingConnect = null
        root.refreshNetworks()
      }
    }
    stderr: StdioCollector {
      onStreamFinished: {
        root.connectingSsid = ""
        root.connectStatus = "error"
        root.connectStatusSsid = root.pendingConnect ? root.pendingConnect.ssid : upConnectionProcess.profileName
        root.connectError = text
        root.pendingConnect = null
      }
    }
  }
}

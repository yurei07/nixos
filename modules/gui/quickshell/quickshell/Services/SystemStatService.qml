pragma Singleton

import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  // Public values
  property real cpuUsage: 0
  property real cpuTemp: 0
  property real memoryUsageGb: 0
  property real memoryUsagePer: 0
  property real diskUsage: 0
  property real rxSpeed: 0
  property real txSpeed: 0

  // Helper function to format network speeds
  function formatSpeed(bytesPerSecond) {
    if (bytesPerSecond < 1024) {
      return bytesPerSecond.toFixed(0) + "B/s"
    } else if (bytesPerSecond < 1024 * 1024) {
      return (bytesPerSecond / 1024).toFixed(1) + "KB/s"
    } else if (bytesPerSecond < 1024 * 1024 * 1024) {
      return (bytesPerSecond / (1024 * 1024)).toFixed(1) + "MB/s"
    } else {
      return (bytesPerSecond / (1024 * 1024 * 1024)).toFixed(1) + "GB/s"
    }
  }

  // Background process emitting one JSON line per sample
  Process {
    id: reader
    running: true
    command: ["sh", "-c", Quickshell.shellDir + "/Bin/system-stats.sh"]
    stdout: SplitParser {
      onRead: function (line) {
        try {
          const data = JSON.parse(line)
          root.cpuUsage = data.cpu
          root.cpuTemp = data.cputemp
          root.memoryUsageGb = data.memgb
          root.memoryUsagePer = data.memper
          root.diskUsage = data.diskper
          root.rxSpeed = parseFloat(data.rx_speed) || 0
          root.txSpeed = parseFloat(data.tx_speed) || 0
        } catch (e) {

          // ignore malformed lines
        }
      }
    }
  }
}

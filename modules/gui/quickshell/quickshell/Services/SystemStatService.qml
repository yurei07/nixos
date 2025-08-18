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
        } catch (e) {

          // ignore malformed lines
        }
      }
    }
  }
}

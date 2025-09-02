pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services

Singleton {
  id: root

  // Night Light properties - directly bound to settings
  readonly property var params: Settings.data.nightLight
  property var lastCommand: []

  function apply() {
    // If using LocationService, wait for it to be ready
    if (params.autoSchedule && !LocationService.coordinatesReady) {
      return
    }

    var command = buildCommand()

    // Compare with previous command to avoid unecessary restart
    if (JSON.stringify(command) !== JSON.stringify(lastCommand)) {
      lastCommand = command
      runner.command = command

      // Set running to false so it may restarts below if still enabled
      runner.running = false
    }
    runner.running = params.enabled
  }

  function buildCommand() {
    var cmd = ["wlsunset"]
    cmd.push("-t", `${params.nightTemp}`, "-T", `${params.dayTemp}`)
    if (params.autoSchedule) {
      cmd.push("-l", `${LocationService.stableLatitude}`, "-L", `${LocationService.stableLongitude}`)
    } else {
      cmd.push("-S", params.manualSunrise)
      cmd.push("-s", params.manualSunset)
    }
    cmd.push("-d", 60 * 15) // 15min progressive fade at sunset/sunrise
    return cmd
  }

  // Observe setting changes and location readiness
  Connections {
    target: Settings.data.nightLight
    function onEnabledChanged() {
      apply()
    }
    function onNightTempChanged() {
      apply()
    }
    function onDayTempChanged() {
      apply()
    }
  }

  Connections {
    target: LocationService
    function onCoordinatesReadyChanged() {
      if (LocationService.coordinatesReady) {
        apply()
      }
    }
  }

  // Foreground process runner
  Process {
    id: runner
    running: false
    onStarted: {
      Logger.log("NightLight", "Wlsunset started:", runner.command)
    }
    onExited: function (code, status) {
      Logger.log("NightLight", "Wlsunset exited:", code, status)
    }
  }
}

pragma Singleton

import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import qs.Commons

Singleton {
  id: root

  Component.onCompleted: {
    Logger.log("Wallpapers", "Service started")
    listWallpapers()

    // Wallpaper is set when the settings are loaded.
    // Don't start random wallpaper during initialization
  }

  property var wallpaperList: []
  property string currentWallpaper: Settings.data.wallpaper.current
  property bool scanning: false

  // SWWW
  property string transitionType: Settings.data.wallpaper.swww.transitionType
  property var randomChoices: ["simple", "fade", "left", "right", "top", "bottom", "wipe", "wave", "grow", "center", "any", "outer"]

  function listWallpapers() {
    Logger.log("Wallpapers", "Listing wallpapers")
    scanning = true
    wallpaperList = []
    // Unsetting, then setting the folder will re-trigger the parsing!
    folderModel.folder = ""
    folderModel.folder = "file://" + (Settings.data.wallpaper.directory !== undefined ? Settings.data.wallpaper.directory : "")
  }

  function changeWallpaper(path) {
    Logger.log("Wallpapers", "Changing to:", path)
    setCurrentWallpaper(path, false)
  }

  function setCurrentWallpaper(path, isInitial) {
    // Only regenerate colors if the wallpaper actually changed
    var wallpaperChanged = currentWallpaper !== path

    currentWallpaper = path
    if (!isInitial) {
      Settings.data.wallpaper.current = path
    }
    if (Settings.data.wallpaper.swww.enabled) {
      if (Settings.data.wallpaper.swww.transitionType === "random") {
        transitionType = randomChoices[Math.floor(Math.random() * randomChoices.length)]
      } else {
        transitionType = Settings.data.wallpaper.swww.transitionType
      }

      changeWallpaperProcess.running = true
    } else {

      // Fallback: update the settings directly for non-SWWW mode
      //Logger.log("Wallpapers", "Not using Swww, setting wallpaper directly")
    }

    if (randomWallpaperTimer.running) {
      randomWallpaperTimer.restart()
    }

    // Only notify ColorScheme service if the wallpaper actually changed
    if (wallpaperChanged) {
      ColorSchemeService.changedWallpaper()
    }
  }

  function setRandomWallpaper() {
    var randomIndex = Math.floor(Math.random() * wallpaperList.length)
    var randomPath = wallpaperList[randomIndex]
    if (!randomPath) {
      return
    }
    setCurrentWallpaper(randomPath, false)
  }

  function toggleRandomWallpaper() {
    if (Settings.data.wallpaper.isRandom && !randomWallpaperTimer.running) {
      randomWallpaperTimer.start()
      setRandomWallpaper()
    } else if (!Settings.data.randomWallpaper && randomWallpaperTimer.running) {
      randomWallpaperTimer.stop()
    }
  }

  function restartRandomWallpaperTimer() {
    if (Settings.data.wallpaper.isRandom) {
      randomWallpaperTimer.stop()
      randomWallpaperTimer.start()
    }
  }

  function startSWWWDaemon() {
    if (Settings.data.wallpaper.swww.enabled) {
      Logger.log("Swww", "Requesting swww-daemon")
      startDaemonProcess.running = true
    }
  }

  Timer {
    id: randomWallpaperTimer
    interval: Settings.data.wallpaper.randomInterval * 1000
    running: false
    repeat: true
    onTriggered: setRandomWallpaper()
    triggeredOnStart: false
  }

  FolderListModel {
    id: folderModel
    // Swww supports many images format but Quickshell only support a subset of those.
    nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.gif", "*.pnm", "*.bmp"]
    showDirs: false
    sortField: FolderListModel.Name
    onStatusChanged: {
      if (status === FolderListModel.Ready) {
        var files = []
        for (var i = 0; i < count; i++) {
          var directory = (Settings.data.wallpaper.directory !== undefined ? Settings.data.wallpaper.directory : "")
          var filepath = directory + "/" + get(i, "fileName")
          files.push(filepath)
        }
        wallpaperList = files
        scanning = false
        Logger.log("Wallpapers", "List refreshed, count:", wallpaperList.length)
      }
    }
  }

  Process {
    id: changeWallpaperProcess
    command: ["swww", "img", "--resize", Settings.data.wallpaper.swww.resizeMethod, "--transition-fps", Settings.data.wallpaper.swww.transitionFps.toString(
        ), "--transition-type", transitionType, "--transition-duration", Settings.data.wallpaper.swww.transitionDuration.toString(
        ), currentWallpaper]
    running: false

    onStarted: {

    }

    onExited: function (exitCode, exitStatus) {
      Logger.log("Swww", "Process finished with exit code:", exitCode, "status:", exitStatus)
      if (exitCode !== 0) {
        Logger.log("Swww", "Process failed. Make sure swww-daemon is running with: swww-daemon")
        Logger.log("Swww", "You can start it with: swww-daemon --format xrgb")
      }
    }
  }

  Process {
    id: startDaemonProcess
    command: ["swww-daemon", "--format", "xrgb"]
    running: false

    onStarted: {
      Logger.log("Swww", "Daemon start process initiated")
    }

    onExited: function (exitCode, exitStatus) {
      Logger.log("Swww", "Daemon start process finished with exit code:", exitCode)
      if (exitCode === 0) {
        Logger.log("Swww", "Daemon started successfully")
      } else {
        Logger.log("Swww", "Failed to start daemon, may already be running")
      }
    }
  }
}

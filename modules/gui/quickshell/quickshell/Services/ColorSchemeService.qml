pragma Singleton

import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import qs.Commons

Singleton {
  id: root

  Component.onCompleted: {
    Logger.log("ColorScheme", "Service started")
    loadColorSchemes()
  }

  property var schemes: []
  property bool scanning: false
  property string schemesDirectory: Quickshell.shellDir + "/Assets/ColorScheme"
  property string colorsJsonFilePath: Settings.configDir + "colors.json"

  function loadColorSchemes() {
    Logger.log("ColorScheme", "Load ColorScheme")
    scanning = true
    schemes = []
    // Unsetting, then setting the folder will re-trigger the parsing!
    folderModel.folder = ""
    folderModel.folder = "file://" + schemesDirectory
  }

  function applyScheme(filePath) {
    Quickshell.execDetached(["cp", filePath, colorsJsonFilePath])
  }

  function changedWallpaper() {
    if (Settings.data.colorSchemes.useWallpaperColors) {
      Logger.log("ColorScheme", "Starting color generation from wallpaper")
      generateColorsProcess.running = true
      // Invalidate potential predefined scheme
      Settings.data.colorSchemes.predefinedScheme = ""
    }
  }

  FolderListModel {
    id: folderModel
    nameFilters: ["*.json"]
    showDirs: false
    sortField: FolderListModel.Name
    onStatusChanged: {
      if (status === FolderListModel.Ready) {
        var files = []
        for (var i = 0; i < count; i++) {
          var filepath = schemesDirectory + "/" + get(i, "fileName")
          files.push(filepath)
        }
        schemes = files
        scanning = false
        Logger.log("ColorScheme", "Listed", schemes.length, "schemes")
      }
    }
  }

  Process {
    id: generateColorsProcess
    command: {
      var cmd = ["matugen", "image", WallpaperService.currentWallpaper, "--config", Quickshell.shellDir + "/Assets/Matugen/matugen.toml"]
      if (!Settings.data.colorSchemes.darkMode) {
        cmd.push("--mode", "light")
      } else {
        cmd.push("--mode", "dark")
      }
      return cmd
    }
    workingDirectory: Quickshell.shellDir
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        Logger.log("ColorScheme", "Completed colors generation")
      }
    }
    stderr: StdioCollector {
      onStreamFinished: {
        if (this.text !== "") {
          Logger.error(this.text)
        }
      }
    }
  }
}

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
  // Internal: remember last path if needed
  property string pendingApplyPath: ""

  function loadColorSchemes() {
    Logger.log("ColorScheme", "Load ColorScheme")
    scanning = true
    schemes = []
    // Unsetting, then setting the folder will re-trigger the parsing!
    folderModel.folder = ""
    folderModel.folder = "file://" + schemesDirectory
  }

  function applyScheme(filePath) {
    // Read the scheme JSON and write the effective variant to colors.json
    pendingApplyPath = filePath
    // Force reload by bouncing the path
    schemeReader.path = ""
    schemeReader.path = filePath
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

  // Internal loader to read a scheme file
  FileView {
    id: schemeReader
    onLoaded: {
      try {
        var data = JSON.parse(text())
        var variant = data
        // If scheme provides dark/light variants, pick based on settings
        if (data && (data.dark || data.light)) {
          if (Settings.data.colorSchemes.darkMode) {
            variant = data.dark || data.light
          } else {
            variant = data.light || data.dark
          }
        }
        writeColorsToDisk(variant)
      } catch (e) {
        Logger.error("ColorScheme", "Failed to parse scheme JSON:", e)
      }
    }
  }

  // Writer to colors.json using a JsonAdapter for safety
  FileView {
    id: colorsWriter
    path: colorsJsonFilePath
    JsonAdapter {
      id: out
      property color mPrimary: "#000000"
      property color mOnPrimary: "#000000"
      property color mSecondary: "#000000"
      property color mOnSecondary: "#000000"
      property color mTertiary: "#000000"
      property color mOnTertiary: "#000000"
      property color mError: "#ff0000"
      property color mOnError: "#000000"
      property color mSurface: "#ffffff"
      property color mOnSurface: "#000000"
      property color mSurfaceVariant: "#cccccc"
      property color mOnSurfaceVariant: "#333333"
      property color mOutline: "#444444"
      property color mShadow: "#000000"
    }
  }

  function writeColorsToDisk(obj) {
    function pick(o, a, b, fallback) {
      return (o && (o[a] || o[b])) || fallback
    }
    out.mPrimary = pick(obj, "mPrimary", "primary", out.mPrimary)
    out.mOnPrimary = pick(obj, "mOnPrimary", "onPrimary", out.mOnPrimary)
    out.mSecondary = pick(obj, "mSecondary", "secondary", out.mSecondary)
    out.mOnSecondary = pick(obj, "mOnSecondary", "onSecondary", out.mOnSecondary)
    out.mTertiary = pick(obj, "mTertiary", "tertiary", out.mTertiary)
    out.mOnTertiary = pick(obj, "mOnTertiary", "onTertiary", out.mOnTertiary)
    out.mError = pick(obj, "mError", "error", out.mError)
    out.mOnError = pick(obj, "mOnError", "onError", out.mOnError)
    out.mSurface = pick(obj, "mSurface", "surface", out.mSurface)
    out.mOnSurface = pick(obj, "mOnSurface", "onSurface", out.mOnSurface)
    out.mSurfaceVariant = pick(obj, "mSurfaceVariant", "surfaceVariant", out.mSurfaceVariant)
    out.mOnSurfaceVariant = pick(obj, "mOnSurfaceVariant", "onSurfaceVariant", out.mOnSurfaceVariant)
    out.mOutline = pick(obj, "mOutline", "outline", out.mOutline)
    out.mShadow = pick(obj, "mShadow", "shadow", out.mShadow)
    colorsWriter.writeAdapter()
  }

  Process {
    id: generateColorsProcess
    command: {
      // Choose config based on external theming toggles
      var cfg = Quickshell.shellDir + "/Assets/Matugen/matugen.toml"
      if (!Settings.data.colorSchemes.themeApps) {
        cfg = Quickshell.shellDir + "/Assets/Matugen/matugen.base.toml"
      }
      var cmd = ["matugen", "image", WallpaperService.currentWallpaper, "--config", cfg]
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

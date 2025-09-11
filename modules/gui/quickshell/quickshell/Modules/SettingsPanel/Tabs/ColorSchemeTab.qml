import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import qs.Commons
import qs.Services
import qs.Widgets

ColumnLayout {
  id: root
  spacing: 0

  // Cache for scheme JSON (can be flat or {dark, light})
  property var schemeColorsCache: ({})

  // Scale properties for card animations
  property real cardScaleLow: 0.95
  property real cardScaleHigh: 1.0

  // Helper function to get color from scheme file (supports dark/light variants)
  function getSchemeColor(schemePath, colorKey) {
    // Extract scheme name from path
    var schemeName = schemePath.split("/").pop().replace(".json", "")

    // Try to get from cached data first
    if (schemeColorsCache[schemeName]) {
      var entry = schemeColorsCache[schemeName]
      var variant = entry
      if (entry.dark || entry.light) {
        variant = Settings.data.colorSchemes.darkMode ? (entry.dark || entry.light) : (entry.light || entry.dark)
      }
      if (variant && variant[colorKey])
        return variant[colorKey]
    }

    // Return a default color if not cached yet
    return "#000000"
  }

  // This function is called by the FileView Repeater when a scheme file is loaded
  function schemeLoaded(schemeName, jsonData) {
    var value = jsonData || {}
    var newCache = schemeColorsCache
    newCache[schemeName] = value
    schemeColorsCache = newCache
  }

  // When the list of available schemes changes, clear the cache.
  // The Repeater below will automatically re-create the FileViews.
  Connections {
    target: ColorSchemeService
    function onSchemesChanged() {
      schemeColorsCache = {}
    }
  }

  // Simple process to check if matugen exists
  Process {
    id: matugenCheck
    command: ["which", "matugen"]
    running: false

    onExited: function (exitCode) {
      if (exitCode === 0) {
        // Matugen exists, enable it
        Settings.data.colorSchemes.useWallpaperColors = true
        MatugenService.generateFromWallpaper()
        ToastService.showNotice("Matugen", "Enabled")
      } else {
        // Matugen not found
        ToastService.showWarning("Matugen", "Not installed")
      }
    }

    stdout: StdioCollector {}
    stderr: StdioCollector {}
  }

  // A non-visual Item to host the Repeater that loads the color scheme files.
  Item {
    visible: false
    id: fileLoaders

    Repeater {
      model: ColorSchemeService.schemes

      // The delegate is a Component, which correctly wraps the non-visual FileView
      delegate: Item {
        FileView {
          path: modelData
          blockLoading: true
          onLoaded: {
            var schemeName = path.split("/").pop().replace(".json", "")
            try {
              var jsonData = JSON.parse(text())
              root.schemeLoaded(schemeName, jsonData)
            } catch (e) {
              Logger.warn("ColorSchemeTab", "Failed to parse JSON for scheme:", schemeName, e)
              root.schemeLoaded(schemeName, null) // Load defaults on parse error
            }
          }
        }
      }
    }
  }

  // Main Toggles - Dark Mode / Matugen
  ColumnLayout {
    spacing: Style.marginL * scaling
    Layout.fillWidth: true

    // Dark Mode Toggle (affects both Matugen and predefined schemes that provide variants)
    NToggle {
      label: "Dark Mode"
      description: Settings.data.colorSchemes.useWallpaperColors ? "Generate dark theme colors when using Matugen." : "Use a dark variant if available."
      checked: Settings.data.colorSchemes.darkMode
      enabled: true
      onToggled: checked => Settings.data.colorSchemes.darkMode = checked
    }

    // Use Matugen
    NToggle {
      label: "Enable Matugen"
      description: "Automatically generate colors based on your active wallpaper."
      checked: Settings.data.colorSchemes.useWallpaperColors
      onToggled: checked => {
                   if (checked) {
                     // Check if matugen is installed
                     matugenCheck.running = true
                   } else {
                     Settings.data.colorSchemes.useWallpaperColors = false
                     ToastService.showNotice("Matugen", "Disabled")

                     if (Settings.data.colorSchemes.predefinedScheme) {

                       ColorSchemeService.applyScheme(Settings.data.colorSchemes.predefinedScheme)
                     }
                   }
                 }
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginXL * scaling
    Layout.bottomMargin: Style.marginXL * scaling
  }

  // Predefined Color Schemes
  ColumnLayout {
    spacing: Style.marginM * scaling
    Layout.fillWidth: true

    NText {
      text: "Predefined Color Schemes"
      font.pointSize: Style.fontSizeXXL * scaling
      font.weight: Style.fontWeightBold
      color: Color.mSecondary
    }

    NText {
      text: "To use these color schemes, you must turn off Matugen. With Matugen enabled, colors are automatically generated from your wallpaper."
      font.pointSize: Style.fontSizeM * scaling
      color: Color.mOnSurfaceVariant
      Layout.fillWidth: true
      wrapMode: Text.WordWrap
    }

    // Color Schemes Grid
    GridLayout {
      columns: 3
      rowSpacing: Style.marginM * scaling
      columnSpacing: Style.marginM * scaling
      Layout.fillWidth: true

      Repeater {
        model: ColorSchemeService.schemes

        Rectangle {
          id: schemeCard

          property string schemePath: modelData

          Layout.fillWidth: true
          Layout.preferredHeight: 120 * scaling
          radius: Style.radiusM * scaling
          color: getSchemeColor(modelData, "mSurface")
          border.width: Math.max(1, Style.borderL * scaling)
          border.color: (!Settings.data.colorSchemes.useWallpaperColors
                         && (Settings.data.colorSchemes.predefinedScheme === modelData.split("/").pop().replace(
                               ".json", ""))) ? Color.mPrimary : Color.mOutline
          scale: root.cardScaleLow

          // Mouse area for selection
          MouseArea {
            anchors.fill: parent
            onClicked: {
              // Disable useWallpaperColors when picking a predefined color scheme
              Settings.data.colorSchemes.useWallpaperColors = false
              Logger.log("ColorSchemeTab", "Disabled matugen setting")

              Settings.data.colorSchemes.predefinedScheme = schemePath.split("/").pop().replace(".json", "")
              ColorSchemeService.applyScheme(Settings.data.colorSchemes.predefinedScheme)
            }
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onEntered: {
              schemeCard.scale = root.cardScaleHigh
            }

            onExited: {
              schemeCard.scale = root.cardScaleLow
            }
          }

          // Card content
          ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.marginXL * scaling
            spacing: Style.marginS * scaling

            // Scheme name
            NText {
              text: {
                // Remove json and the full path
                var chunks = schemePath.replace(".json", "").split("/")
                return chunks[chunks.length - 1]
              }
              font.pointSize: Style.fontSizeM * scaling
              font.weight: Style.fontWeightBold
              color: getSchemeColor(modelData, "mOnSurface")
              Layout.fillWidth: true
              elide: Text.ElideRight
              horizontalAlignment: Text.AlignHCenter
            }

            // Color swatches
            RowLayout {
              id: swatches

              spacing: Style.marginS * scaling
              Layout.fillWidth: true
              Layout.alignment: Qt.AlignHCenter

              readonly property int swatchSize: 20 * scaling

              // Primary color swatch
              Rectangle {
                width: swatches.swatchSize
                height: swatches.swatchSize
                radius: width * 0.5
                color: getSchemeColor(modelData, "mPrimary")
              }

              // Secondary color swatch
              Rectangle {
                width: swatches.swatchSize
                height: swatches.swatchSize
                radius: width * 0.5
                color: getSchemeColor(modelData, "mSecondary")
              }

              // Tertiary color swatch
              Rectangle {
                width: swatches.swatchSize
                height: swatches.swatchSize
                radius: width * 0.5
                color: getSchemeColor(modelData, "mTertiary")
              }

              // Error color swatch
              Rectangle {
                width: swatches.swatchSize
                height: swatches.swatchSize
                radius: width * 0.5
                color: getSchemeColor(modelData, "mError")
              }
            }
          }

          // Selection indicator (Checkmark)
          Rectangle {
            visible: !Settings.data.colorSchemes.useWallpaperColors
                     && (Settings.data.colorSchemes.predefinedScheme === schemePath.split("/").pop().replace(".json",
                                                                                                             ""))
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Style.marginS * scaling
            width: 24 * scaling
            height: 24 * scaling
            radius: width * 0.5
            color: Color.mPrimary

            NText {
              anchors.centerIn: parent
              text: "✓"
              font.pointSize: Style.fontSizeXS * scaling
              font.weight: Style.fontWeightBold
              color: Color.mOnPrimary
            }
          }

          // Smooth animations
          Behavior on scale {
            NumberAnimation {
              duration: Style.animationNormal
              easing.type: Easing.OutCubic
            }
          }

          Behavior on border.color {
            ColorAnimation {
              duration: Style.animationNormal
            }
          }

          Behavior on border.width {
            NumberAnimation {
              duration: Style.animationFast
            }
          }
        }
      }
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginXL * scaling
    Layout.bottomMargin: Style.marginXL * scaling
    visible: Settings.data.colorSchemes.useWallpaperColors
  }

  // Matugen template toggles (moved from MatugenTab)
  ColumnLayout {
    spacing: Style.marginL * scaling
    Layout.fillWidth: true
    visible: Settings.data.colorSchemes.useWallpaperColors

    ColumnLayout {
      spacing: Style.marginS * scaling
      Layout.fillWidth: true

      NText {
        text: "Matugen Templates"
        font.pointSize: Style.fontSizeXXL * scaling
        font.weight: Style.fontWeightBold
        color: Color.mSecondary
      }

      NText {
        text: "Select which external components Matugen should apply theming to."
        font.pointSize: Style.fontSizeM * scaling
        color: Color.mOnSurfaceVariant
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
      }
    }

    NCheckbox {
      label: "GTK 4 (libadwaita)"
      description: "Write ~/.config/gtk-4.0/gtk.css"
      checked: Settings.data.matugen.gtk4
      onToggled: checked => {
                   Settings.data.matugen.gtk4 = checked
                   if (Settings.data.colorSchemes.useWallpaperColors)
                   MatugenService.generateFromWallpaper()
                 }
    }

    NCheckbox {
      label: "GTK 3"
      description: "Write ~/.config/gtk-3.0/gtk.css"
      checked: Settings.data.matugen.gtk3
      onToggled: checked => {
                   Settings.data.matugen.gtk3 = checked
                   if (Settings.data.colorSchemes.useWallpaperColors)
                   MatugenService.generateFromWallpaper()
                 }
    }

    NCheckbox {
      label: "Qt6ct"
      description: "Write ~/.config/qt6ct/colors/noctalia.conf"
      checked: Settings.data.matugen.qt6
      onToggled: checked => {
                   Settings.data.matugen.qt6 = checked
                   if (Settings.data.colorSchemes.useWallpaperColors)
                   MatugenService.generateFromWallpaper()
                 }
    }

    NCheckbox {
      label: "Qt5ct"
      description: "Write ~/.config/qt5ct/colors/noctalia.conf"
      checked: Settings.data.matugen.qt5
      onToggled: checked => {
                   Settings.data.matugen.qt5 = checked
                   if (Settings.data.colorSchemes.useWallpaperColors)
                   MatugenService.generateFromWallpaper()
                 }
    }

    NCheckbox {
      label: "Kitty"
      description: "Write ~/.config/kitty/themes/noctalia.conf and reload"
      checked: Settings.data.matugen.kitty
      onToggled: checked => {
                   Settings.data.matugen.kitty = checked
                   if (Settings.data.colorSchemes.useWallpaperColors)
                   MatugenService.generateFromWallpaper()
                 }
    }

    NCheckbox {
      label: "Ghostty"
      description: "Write ~/.config/ghostty/themes/noctalia and reload"
      checked: Settings.data.matugen.ghostty
      onToggled: checked => {
                   Settings.data.matugen.ghostty = checked
                   if (Settings.data.colorSchemes.useWallpaperColors)
                   MatugenService.generateFromWallpaper()
                 }
    }

    NCheckbox {
      label: "Foot"
      description: "Write ~/.config/foot/themes/noctalia and reload"
      checked: Settings.data.matugen.foot
      onToggled: checked => {
                   Settings.data.matugen.foot = checked
                   if (Settings.data.colorSchemes.useWallpaperColors)
                   MatugenService.generateFromWallpaper()
                 }
    }

    NCheckbox {
      label: "Fuzzel"
      description: "Write ~/.config/fuzzel/themes/noctalia and reload"
      checked: Settings.data.matugen.fuzzel
      onToggled: checked => {
                   Settings.data.matugen.fuzzel = checked
                   if (Settings.data.colorSchemes.useWallpaperColors)
                   MatugenService.generateFromWallpaper()
                 }
    }

    NCheckbox {
      label: "Vesktop"
      description: "Write ~/.config/vesktop/themes/noctalia.theme.css"
      checked: Settings.data.matugen.vesktop
      onToggled: checked => {
                   Settings.data.matugen.vesktop = checked
                   if (Settings.data.colorSchemes.useWallpaperColors)
                   MatugenService.generateFromWallpaper()
                 }
    }

    NDivider {
      Layout.fillWidth: true
      Layout.topMargin: Style.marginM * scaling
      Layout.bottomMargin: Style.marginM * scaling
    }

    NCheckbox {
      label: "User Templates"
      description: "Enable user-defined Matugen config from ~/.config/matugen/config.toml"
      checked: Settings.data.matugen.enableUserTemplates
      onToggled: checked => {
                   Settings.data.matugen.enableUserTemplates = checked
                   if (Settings.data.colorSchemes.useWallpaperColors)
                   MatugenService.generateFromWallpaper()
                 }
    }
  }
}

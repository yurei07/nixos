import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets
import Quickshell.Io

ColumnLayout {
  id: root

  spacing: 0

  // Helper function to get color from scheme file
  function getSchemeColor(schemePath, colorKey) {
    // Extract scheme name from path
    var schemeName = schemePath.split("/").pop().replace(".json", "")

    // Try to get from cached data first
    if (schemeColorsCache[schemeName] && schemeColorsCache[schemeName][colorKey]) {
      return schemeColorsCache[schemeName][colorKey]
    }

    // Return a default color if not cached yet
    return "#000000"
  }

  // Cache for scheme colors
  property var schemeColorsCache: ({})

  // Scale properties for card animations
  property real cardScaleLow: 0.95
  property real cardScaleHigh: 1.0

  // This function is called by the FileView Repeater when a scheme file is loaded
  function schemeLoaded(schemeName, jsonData) {
    var colors = {}

    // Extract colors from JSON data
    if (jsonData && typeof jsonData === 'object') {
      colors.mPrimary = jsonData.mPrimary || jsonData.primary || "#000000"
      colors.mSecondary = jsonData.mSecondary || jsonData.secondary || "#000000"
      colors.mTertiary = jsonData.mTertiary || jsonData.tertiary || "#000000"
      colors.mError = jsonData.mError || jsonData.error || "#ff0000"
      colors.mSurface = jsonData.mSurface || jsonData.surface || "#ffffff"
      colors.mOnSurface = jsonData.mOnSurface || jsonData.onSurface || "#000000"
      colors.mOutline = jsonData.mOutline || jsonData.outline || "#666666"
    } else {
      // Default colors on failure
      colors = {
        "mPrimary": "#000000",
        "mSecondary": "#000000",
        "mTertiary": "#000000",
        "mError": "#ff0000",
        "mSurface": "#ffffff",
        "mOnSurface": "#000000",
        "mOutline": "#666666"
      }
    }

    // Update the cache. This must be done by re-assigning the whole object to trigger updates.
    var newCache = schemeColorsCache
    newCache[schemeName] = colors
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

  // UI Code
  ScrollView {
    id: scrollView

    Layout.fillWidth: true
    Layout.fillHeight: true
    padding: Style.marginMedium * scaling
    clip: true
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
    ScrollBar.vertical.policy: ScrollBar.AsNeeded

    ColumnLayout {
      width: scrollView.availableWidth
      spacing: 0

      Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 0
      }

      ColumnLayout {
        spacing: Style.marginLarge * scaling
        Layout.fillWidth: true

        // Use Matugen
        NToggle {
          label: "Use Matugen"
          description: "Automatically generate colors based on your active wallpaper using Matugen"
          checked: Settings.data.colorSchemes.useWallpaperColors
          onToggled: checked => {
                       Settings.data.colorSchemes.useWallpaperColors = checked
                       if (Settings.data.colorSchemes.useWallpaperColors) {
                         ColorSchemeService.changedWallpaper()
                       }
                     }
        }

        // Dark Mode Toggle
        NToggle {
          label: "Dark Mode"
          description: "Generate dark theme colors when using Matugen. Disable for light theme."
          checked: Settings.data.colorSchemes.darkMode
          enabled: Settings.data.colorSchemes.useWallpaperColors
          onToggled: checked => {
                       Settings.data.colorSchemes.darkMode = checked
                       if (Settings.data.colorSchemes.useWallpaperColors) {
                         ColorSchemeService.changedWallpaper()
                       }
                     }
        }

        NDivider {
          Layout.fillWidth: true
          Layout.topMargin: Style.marginLarge * scaling
          Layout.bottomMargin: Style.marginLarge * scaling
        }

        ColumnLayout {
          spacing: Style.marginTiniest * scaling
          Layout.fillWidth: true

          NText {
            text: "Predefined Color Schemes"
            font.pointSize: Style.fontSizeLarge * scaling
            font.weight: Style.fontWeightBold
            color: Color.mOnSurface
            Layout.fillWidth: true
          }

          NText {
            text: "These color schemes only apply when 'Use Matugen' is disabled. When enabled, Matugen will generate colors based on your wallpaper instead. You can toggle between light and dark themes when using Matugen."
            font.pointSize: Style.fontSizeSmall * scaling
            color: Color.mOnSurface
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
          }
        }

        ColumnLayout {
          spacing: Style.marginTiny * scaling
          Layout.fillWidth: true
          Layout.topMargin: Style.marginLarge * scaling

          // Color Schemes Grid
          GridLayout {
            columns: 4
            rowSpacing: Style.marginLarge * scaling
            columnSpacing: Style.marginLarge * scaling
            Layout.fillWidth: true

            Repeater {
              model: ColorSchemeService.schemes

              Rectangle {
                id: schemeCard

                property string schemePath: modelData

                Layout.fillWidth: true
                Layout.preferredHeight: 120 * scaling
                radius: Style.radiusMedium * scaling
                color: getSchemeColor(modelData, "mSurface")
                border.width: Math.max(1, Style.borderThick * scaling)
                border.color: Settings.data.colorSchemes.predefinedScheme === modelData ? Color.mPrimary : Color.mOutline
                scale: root.cardScaleLow

                // Mouse area for selection
                MouseArea {
                  anchors.fill: parent
                  onClicked: {
                    // Disable useWallpaperColors when picking a predefined color scheme
                    Settings.data.colorSchemes.useWallpaperColors = false
                    Settings.data.colorSchemes.predefinedScheme = schemePath
                    ColorSchemeService.applyScheme(schemePath)
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
                  spacing: Style.marginSmall * scaling

                  // Scheme name
                  NText {
                    text: {
                      // Remove json and the full path
                      var chunks = schemePath.replace(".json", "").split("/")
                      return chunks[chunks.length - 1]
                    }
                    font.pointSize: Style.fontSizeMedium * scaling
                    font.weight: Style.fontWeightBold
                    color: getSchemeColor(modelData, "mOnSurface")
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                  }

                  // Color swatches
                  RowLayout {
                    spacing: Style.marginSmall * scaling
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter

                    // Primary color swatch
                    Rectangle {
                      width: 28 * scaling
                      height: 28 * scaling
                      radius: width * 0.5
                      color: getSchemeColor(modelData, "mPrimary")
                    }

                    // Secondary color swatch
                    Rectangle {
                      width: 28 * scaling
                      height: 28 * scaling
                      radius: width * 0.5
                      color: getSchemeColor(modelData, "mSecondary")
                    }

                    // Tertiary color swatch
                    Rectangle {
                      width: 28 * scaling
                      height: 28 * scaling
                      radius: width * 0.5
                      color: getSchemeColor(modelData, "mTertiary")
                    }

                    // Error color swatch
                    Rectangle {
                      width: 28 * scaling
                      height: 28 * scaling
                      radius: width * 0.5
                      color: getSchemeColor(modelData, "mError")
                    }
                  }
                }

                // Selection indicator
                Rectangle {
                  visible: Settings.data.colorSchemes.predefinedScheme === schemePath
                  anchors.right: parent.right
                  anchors.top: parent.top
                  anchors.margins: Style.marginSmall * scaling
                  width: 24 * scaling
                  height: 24 * scaling
                  radius: width * 0.5
                  color: Color.mPrimary

                  NText {
                    anchors.centerIn: parent
                    text: "✓"
                    font.pointSize: Style.fontSizeSmall * scaling
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
      }
    }
  }
}

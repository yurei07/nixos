pragma Singleton

import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Commons

Singleton {
  id: root

  property ListModel availableFonts: ListModel {}
  property ListModel monospaceFonts: ListModel {}
  property ListModel displayFonts: ListModel {}
  property bool fontsLoaded: false

  // -------------------------------------------
  function init() {
    Logger.log("Font", "Service started")
    loadSystemFonts()
  }

  function loadSystemFonts() {
    Logger.log("Font", "Loading system fonts...")

    var fontFamilies = Qt.fontFamilies()

    availableFonts.clear()
    monospaceFonts.clear()
    displayFonts.clear()

    for (var i = 0; i < fontFamilies.length; i++) {
      var fontName = fontFamilies[i]
      if (fontName && fontName.trim() !== "") {
        availableFonts.append({
                                "key": fontName,
                                "name": fontName
                              })

        if (isMonospaceFont(fontName)) {
          monospaceFonts.append({
                                  "key": fontName,
                                  "name": fontName
                                })
        }

        if (isDisplayFont(fontName)) {
          displayFonts.append({
                                "key": fontName,
                                "name": fontName
                              })
        }
      }
    }

    sortModel(availableFonts)
    sortModel(monospaceFonts)
    sortModel(displayFonts)

    if (monospaceFonts.count === 0) {
      Logger.log("Font", "No monospace fonts detected, adding fallbacks")
      addFallbackFonts(
            monospaceFonts,
            ["DejaVu Sans Mono", "Liberation Mono", "Courier New", "Courier", "Monaco", "Consolas", "Lucida Console", "Monaco", "Andale Mono"])
    }

    if (displayFonts.count === 0) {
      Logger.log("Font", "No display fonts detected, adding fallbacks")
      addFallbackFonts(
            displayFonts,
            ["Inter", "Roboto", "Open Sans", "Arial", "Helvetica", "Verdana", "Segoe UI", "SF Pro Display", "Ubuntu", "Noto Sans"])
    }

    fontsLoaded = true
    Logger.log("Font", "Loaded", availableFonts.count, "fonts:", monospaceFonts.count, "monospace,",
               displayFonts.count, "display")
  }

  function isMonospaceFont(fontName) {
    var patterns = ["mono", "monospace", "fixed", "console", "terminal", "typewriter", "courier", "dejavu", "liberation", "source code", "fira code", "jetbrains", "cascadia", "hack", "inconsolata", "roboto mono", "ubuntu mono", "menlo", "consolas", "monaco", "andale mono"]
    var lowerFontName = fontName.toLowerCase()

    for (var i = 0; i < patterns.length; i++) {
      if (lowerFontName.includes(patterns[i]))
        return true
    }

    var commonFonts = ["DejaVu Sans Mono", "Liberation Mono", "Source Code Pro", "Fira Code", "JetBrains Mono", "Cascadia Code", "Hack", "Inconsolata", "Roboto Mono", "Ubuntu Mono", "Menlo", "Consolas", "Monaco", "Andale Mono", "Courier New", "Courier", "Lucida Console", "Monaco", "MS Gothic", "MS Mincho"]
    return commonFonts.includes(fontName)
  }

  function isDisplayFont(fontName) {
    var patterns = ["display", "headline", "title", "hero", "showcase", "brand", "inter", "roboto", "open sans", "lato", "montserrat", "poppins", "raleway", "nunito", "source sans", "ubuntu", "noto sans", "work sans", "dm sans", "manrope", "plus jakarta", "figtree"]
    var lowerFontName = fontName.toLowerCase()

    for (var i = 0; i < patterns.length; i++) {
      if (lowerFontName.includes(patterns[i]))
        return true
    }

    var commonFonts = ["Inter", "Roboto", "Open Sans", "Lato", "Montserrat", "Poppins", "Raleway", "Nunito", "Source Sans Pro", "Ubuntu", "Noto Sans", "Work Sans", "DM Sans", "Manrope", "Plus Jakarta Sans", "Figtree", "SF Pro Display", "Segoe UI", "Arial", "Helvetica", "Verdana"]
    return commonFonts.includes(fontName)
  }

  function sortModel(model) {
    var fontsArray = []
    for (var i = 0; i < model.count; i++) {
      fontsArray.push({
                        "key": model.get(i).key,
                        "name": model.get(i).name
                      })
    }

    fontsArray.sort(function (a, b) {
      return a.name.localeCompare(b.name)
    })

    model.clear()
    for (var j = 0; j < fontsArray.length; j++) {
      model.append(fontsArray[j])
    }
  }

  function addFallbackFonts(model, fallbackFonts) {
    for (var i = 0; i < fallbackFonts.length; i++) {
      var fontName = fallbackFonts[i]
      var exists = false
      for (var j = 0; j < model.count; j++) {
        if (model.get(j).name === fontName) {
          exists = true
          break
        }
      }

      if (!exists) {
        model.append({
                       "key": fontName,
                       "name": fontName
                     })
      }
    }

    sortModel(model)
  }

  function searchFonts(query) {
    if (!query || query.trim() === "")
      return availableFonts

    var results = []
    var lowerQuery = query.toLowerCase()

    for (var i = 0; i < availableFonts.count; i++) {
      var font = availableFonts.get(i)
      if (font.name.toLowerCase().includes(lowerQuery)) {
        results.push(font)
      }
    }

    return results
  }
}

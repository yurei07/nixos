import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Commons
import qs.Services
import qs.Widgets

import "../../Helpers/FuzzySort.js" as Fuzzysort

NPanel {
  id: root
  panelWidth: Math.min(700 * scaling, screen?.width * 0.75)
  panelHeight: Math.min(550 * scaling, screen?.height * 0.8)
  // Positioning derives from Settings.data.bar.position for vertical (top/bottom)
  // and from Settings.data.appLauncher.position for horizontal vs center.
  // Options: center, top_left, top_right, bottom_left, bottom_right, bottom_center, top_center
  readonly property string launcherPosition: Settings.data.appLauncher.position

  panelAnchorHorizontalCenter: launcherPosition === "center" || (launcherPosition.endsWith("_center"))
  panelAnchorVerticalCenter: launcherPosition === "center"
  panelAnchorLeft: launcherPosition !== "center" && (launcherPosition.endsWith("_left"))
  panelAnchorRight: launcherPosition !== "center" && (launcherPosition.endsWith("_right"))
  panelAnchorBottom: launcherPosition.startsWith("bottom_")
  panelAnchorTop: launcherPosition.startsWith("top_")

  // Enable keyboard focus for launcher (needed for search)
  panelKeyboardFocus: true

  // Background opacity following bar's approach
  panelBackgroundColor: Qt.rgba(Color.mSurface.r, Color.mSurface.g, Color.mSurface.b,
                                Settings.data.appLauncher.backgroundOpacity)

  // Properties
  property string searchText: ""
  property bool shouldResetCursor: false

  // Add function to set search text programmatically
  function setSearchText(text) {
    searchText = text
    // The searchInput will automatically update via the text binding
    // Focus and cursor position will be handled by the TextField's Component.onCompleted
  }

  onOpened: {
    // Reset state when panel opens to avoid sticky modes
    if (searchText === "") {
      searchText = ""
      selectedIndex = 0
    }
    // Focus search input on open and place cursor at end
    Qt.callLater(() => {
                   if (searchInputBox && searchInputBox.inputItem) {
                     searchInputBox.inputItem.forceActiveFocus()
                     if (searchText && searchText.length > 0) {
                       searchInputBox.inputItem.cursorPosition = searchText.length
                     } else {
                       searchInputBox.inputItem.cursorPosition = 0
                     }
                   }
                 })
  }

  onClosed: {
    // Reset search bar when launcher is closed
    searchText = ""
    selectedIndex = 0
    shouldResetCursor = true
  }

  // Import modular components
  Calculator {
    id: calculator
  }

  ClipboardHistory {
    id: clipboardHistory
  }

  // Poll cliphist while in clipboard mode to keep entries fresh
  Timer {
    id: clipRefreshTimer
    interval: 2000
    repeat: true
    running: Settings.data.appLauncher.enableClipboardHistory && searchText.startsWith(">clip")
    onTriggered: clipboardHistory.refresh()
  }

  // Properties
  property var desktopEntries: DesktopEntries.applications.values
  property int selectedIndex: 0

  // Refresh clipboard when user starts typing clipboard commands
  onSearchTextChanged: {
    if (Settings.data.appLauncher.enableClipboardHistory && searchText.startsWith(">clip")) {
      clipboardHistory.refresh()
    }
  }

  // Main filtering logic
  property var filteredEntries: {
    // Explicit dependency so changes to items/decoded images retrigger this binding
    const _clipItems = Settings.data.appLauncher.enableClipboardHistory ? CliphistService.items : []
    const _clipRev = Settings.data.appLauncher.enableClipboardHistory ? CliphistService.revision : 0

    var query = searchText ? searchText.toLowerCase() : ""
    if (Settings.data.appLauncher.enableClipboardHistory && query.startsWith(">clip")) {
      return clipboardHistory.processQuery(query, _clipItems)
    }

    if (!desktopEntries || desktopEntries.length === 0) {
      return []
    }

    // Filter out entries that shouldn't be displayed
    var visibleEntries = desktopEntries.filter(entry => {
                                                 if (!entry || entry.noDisplay) {
                                                   return false
                                                 }
                                                 return true
                                               })

    var results = []

    // Handle special commands
    if (query === ">") {
      results.push({
                     "isCommand": true,
                     "name": ">calc",
                     "content": "Calculator - evaluate mathematical expressions",
                     "icon": "calculate",
                     "execute": executeCalcCommand
                   })
      if (Settings.data.appLauncher.enableClipboardHistory) {
        results.push({
                       "isCommand": true,
                       "name": ">clip",
                       "content": "Clipboard history - browse and restore clipboard items",
                       "icon": "content_paste",
                       "execute": executeClipCommand
                     })
      }

      return results
    }

    // Handle calculator
    if (query.startsWith(">calc")) {
      return calculator.processQuery(query, "calc")
    }

    // Handle direct math expressions after ">"
    if (query.startsWith(">") && query.length > 1 && (!Settings.data.appLauncher.enableClipboardHistory
                                                      || !query.startsWith(">clip")) && !query.startsWith(">calc")) {
      const mathResults = calculator.processQuery(query, "direct")
      if (mathResults.length > 0) {
        return mathResults
      }
      // If math evaluation fails, fall through to regular search
    }

    // Regular app search
    if (!query) {
      results = results.concat(visibleEntries.sort(function (a, b) {
        return a.name.toLowerCase().localeCompare(b.name.toLowerCase())
      }))
    } else {
      var fuzzyResults = Fuzzysort.go(query, visibleEntries, {
                                        "keys": ["name", "comment", "genericName"]
                                      })
      results = results.concat(fuzzyResults.map(function (r) {
        return r.obj
      }))
    }

    return results
  }

  // Command execution functions
  function executeCalcCommand() {
    setSearchText(">calc ")
  }

  function executeClipCommand() {
    setSearchText(">clip ")
  }

  // Navigation functions
  function selectNext() {
    if (filteredEntries.length > 0) {
      selectedIndex = Math.min(selectedIndex + 1, filteredEntries.length - 1)
    }
  }

  function selectPrev() {
    if (filteredEntries.length > 0) {
      selectedIndex = Math.max(selectedIndex - 1, 0)
    }
  }

  function selectNextPage() {
    if (filteredEntries.length > 0) {
      const delegateHeight = 65 * scaling + (Style.marginXXS * scaling)
      const page = Math.max(1, Math.floor(appsList.height / delegateHeight))
      selectedIndex = Math.min(selectedIndex + page, filteredEntries.length - 1)
    }
  }
  function selectPrevPage() {
    if (filteredEntries.length > 0) {
      const delegateHeight = 65 * scaling + (Style.marginXXS * scaling)
      const page = Math.max(1, Math.floor(appsList.height / delegateHeight))
      selectedIndex = Math.max(selectedIndex - page, 0)
    }
  }

  function activateSelected() {
    if (filteredEntries.length === 0)
      return

    var modelData = filteredEntries[selectedIndex]
    if (modelData && modelData.execute) {
      if (modelData.isCommand) {
        modelData.execute()
        return
      } else {
        modelData.execute()
      }
      root.close()
    }
  }

  Component.onCompleted: {
    Logger.log("Launcher", "Component completed")
    Logger.log("Launcher", "DesktopEntries available:", typeof DesktopEntries !== 'undefined')
    if (typeof DesktopEntries !== 'undefined') {
      Logger.log("Launcher", "DesktopEntries.entries:",
                 DesktopEntries.entries ? DesktopEntries.entries.length : 'undefined')
    }
    // Start clipboard refresh immediately on open if enabled
    if (Settings.data.appLauncher.enableClipboardHistory) {
      clipboardHistory.refresh()
    }
  }

  // Main content container
  panelContent: Rectangle {
    color: Color.transparent

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Style.marginL * scaling
      spacing: Style.marginM * scaling

      RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.round(Style.barHeight * scaling)
        Layout.bottomMargin: Style.marginM * scaling

        // Wrapper ensures the input stretches to full width under RowLayout
        Item {
          id: searchInputWrap
          Layout.fillWidth: true
          Layout.preferredHeight: Math.round(Style.barHeight * scaling)

          NTextInput {
            id: searchInputBox
            anchors.fill: parent
            placeholderText: "Search applications... (use > to view commands)"
            text: searchText
            inputMaxWidth: 100000
            // Tune vertical centering on inner input
            Component.onCompleted: {
              searchInputBox.inputItem.font.pointSize = Style.fontSizeL * scaling
              searchInputBox.inputItem.verticalAlignment = TextInput.AlignVCenter
              // Ensure focus when launcher first appears
              Qt.callLater(() => {
                             searchInputBox.inputItem.forceActiveFocus()
                             if (searchText && searchText.length > 0) {
                               searchInputBox.inputItem.cursorPosition = searchText.length
                             } else {
                               searchInputBox.inputItem.cursorPosition = 0
                             }
                           })
            }
            onTextChanged: {
              if (searchText !== text) {
                searchText = text
              }
              Qt.callLater(() => selectedIndex = 0)
              if (shouldResetCursor && text === "") {
                searchInputBox.inputItem.cursorPosition = 0
                shouldResetCursor = false
              }
            }
            // Forward key navigation to behave like before
            Keys.onDownPressed: selectNext()
            Keys.onUpPressed: selectPrev()
            Keys.onEnterPressed: activateSelected()
            Keys.onReturnPressed: activateSelected()
            Keys.onEscapePressed: root.close()
            Keys.onPressed: event => {
                              if (event.key === Qt.Key_PageDown) {
                                appsList.cancelFlick()
                                root.selectNextPage()
                                event.accepted = true
                              } else if (event.key === Qt.Key_PageUp) {
                                appsList.cancelFlick()
                                root.selectPrevPage()
                                event.accepted = true
                              } else if (event.key === Qt.Key_Home) {
                                appsList.cancelFlick()
                                selectedIndex = 0
                                event.accepted = true
                              } else if (event.key === Qt.Key_End) {
                                appsList.cancelFlick()
                                if (filteredEntries.length > 0) {
                                  selectedIndex = filteredEntries.length - 1
                                }
                                event.accepted = true
                              }
                              if (event.modifiers & Qt.ControlModifier) {
                                switch (event.key) {
                                  case Qt.Key_J:
                                  appsList.cancelFlick()
                                  root.selectNext()
                                  event.accepted = true
                                  break
                                  case Qt.Key_K:
                                  appsList.cancelFlick()
                                  root.selectPrev()
                                  event.accepted = true
                                  break
                                }
                              }
                            }
          }
        }

        // Clear-all action to the right of the input
        NIconButton {
          Layout.alignment: Qt.AlignVCenter
          visible: searchText.startsWith(">clip")
          icon: "delete_sweep"
          tooltipText: "Clear clipboard history"
          onClicked: CliphistService.wipeAll()
        }
      }

      // Applications list
      ListView {
        id: appsList
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: Style.marginXXS * scaling
        model: filteredEntries
        currentIndex: selectedIndex
        boundsBehavior: Flickable.StopAtBounds
        maximumFlickVelocity: 2500
        flickDeceleration: 2000
        onCurrentIndexChanged: {
          cancelFlick()
          if (currentIndex >= 0) {
            positionViewAtIndex(currentIndex, ListView.Contain)
          }
        }
        ScrollBar.vertical: ScrollBar {
          policy: ScrollBar.AsNeeded
        }

        // Keep viewport anchored to the selected item when the clipboard model refreshes
        Connections {
          target: CliphistService
          function onRevisionChanged() {
            if (Settings.data.appLauncher.enableClipboardHistory && searchText.startsWith(">clip")) {
              // Clamp selection in case the list shrank
              if (selectedIndex >= filteredEntries.length) {
                selectedIndex = Math.max(0, filteredEntries.length - 1)
              }
              Qt.callLater(() => {
                             appsList.positionViewAtIndex(selectedIndex, ListView.Contain)
                           })
            }
          }
        }

        delegate: Rectangle {
          width: appsList.width - Style.marginS * scaling
          height: 65 * scaling
          radius: Style.radiusM * scaling
          property bool isSelected: index === selectedIndex
          color: (appCardArea.containsMouse || isSelected) ? Color.mSecondary : Color.mSurface

          Behavior on color {
            ColorAnimation {
              duration: Style.animationFast
            }
          }

          Behavior on border.color {
            ColorAnimation {
              duration: Style.animationFast
            }
          }

          Behavior on border.width {
            NumberAnimation {
              duration: Style.animationFast
            }
          }

          RowLayout {
            anchors.fill: parent
            anchors.margins: Style.marginM * scaling
            spacing: Style.marginM * scaling

            // App/clipboard icon with background
            Rectangle {
              Layout.preferredWidth: Style.baseWidgetSize * 1.25 * scaling
              Layout.preferredHeight: Style.baseWidgetSize * 1.25 * scaling
              radius: Style.radiusS * scaling
              color: appCardArea.containsMouse ? Qt.darker(Color.mPrimary, 1.1) : Color.mSurfaceVariant
              property bool iconLoaded: (modelData.isCalculator || modelData.isClipboard || modelData.isCommand)
                                        || (iconImg.status === Image.Ready && iconImg.source !== ""
                                            && iconImg.status !== Image.Error && iconImg.source !== "")
              visible: !searchText.startsWith(">calc")

              // Decode image thumbnails on demand
              Component.onCompleted: {
                if (modelData && modelData.type === 'image' && !CliphistService.imageDataById[modelData.id]) {
                  CliphistService.decodeToDataUrl(modelData.id, modelData.mime || "image/*", function () {})
                }
              }
              onVisibleChanged: {
                if (visible && modelData && modelData.type === 'image'
                    && !CliphistService.imageDataById[modelData.id]) {
                  CliphistService.decodeToDataUrl(modelData.id, modelData.mime || "image/*", function () {})
                }
              }

              // Clipboard image display (pull from cache)
              Image {
                id: clipboardImage
                anchors.fill: parent
                anchors.margins: Style.marginXS * scaling
                visible: modelData.type === 'image'
                source: modelData.type === 'image' ? (CliphistService.imageDataById[modelData.id] || "") : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
              }

              IconImage {
                id: iconImg
                anchors.fill: parent
                anchors.margins: Style.marginXS * scaling
                asynchronous: true
                source: modelData.isCalculator ? "" : modelData.isClipboard ? "" : modelData.isCommand ? modelData.icon : Icons.iconFromName(
                                                                                                           modelData.icon,
                                                                                                           "application-x-executable")
                visible: (modelData.isCalculator || modelData.isClipboard || modelData.isCommand || parent.iconLoaded)
                         && modelData.type !== 'image'
              }

              Rectangle {
                anchors.fill: parent
                anchors.margins: Style.marginXS * scaling
                radius: Style.radiusXS * scaling
                color: Color.mPrimary
                opacity: Style.opacityMedium
                visible: !parent.iconLoaded
              }

              NText {
                anchors.centerIn: parent
                visible: !parent.iconLoaded && !(modelData.isCalculator || modelData.isClipboard || modelData.isCommand)
                text: modelData.name ? modelData.name.charAt(0).toUpperCase() : "?"
                font.pointSize: Style.fontSizeXXL * scaling
                font.weight: Style.fontWeightBold
                color: Color.mPrimary
              }

              Behavior on color {
                ColorAnimation {
                  duration: Style.animationFast
                }
              }
            }

            // App info
            ColumnLayout {
              Layout.fillWidth: true
              spacing: Style.marginXXS * scaling

              NText {
                text: modelData.name || "Unknown"
                font.pointSize: Style.fontSizeL * scaling
                font.weight: Style.fontWeightBold
                color: (appCardArea.containsMouse || isSelected) ? Color.mOnPrimary : Color.mOnSurface
                elide: Text.ElideRight
                Layout.fillWidth: true
              }

              NText {
                text: modelData.isCalculator ? (modelData.expr + " = " + modelData.result) : modelData.isClipboard ? modelData.content : modelData.isCommand ? modelData.content : (modelData.genericName || modelData.comment || "")
                font.pointSize: Style.fontSizeM * scaling
                color: (appCardArea.containsMouse || isSelected) ? Color.mOnPrimary : Color.mOnSurface
                elide: Text.ElideRight
                Layout.fillWidth: true
                visible: text !== ""
              }
            }
          }

          MouseArea {
            id: appCardArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onClicked: {
              selectedIndex = index
              activateSelected()
            }
          }
        }
      }

      // No results message
      NText {
        text: searchText.trim() !== "" ? "No applications found" : "No applications available"
        font.pointSize: Style.fontSizeL * scaling
        color: Color.mOnSurface
        horizontalAlignment: Text.AlignHCenter
        Layout.fillWidth: true
        visible: filteredEntries.length === 0
      }

      // Results count
      NText {
        text: searchText.startsWith(
                ">clip") ? (Settings.data.appLauncher.enableClipboardHistory ? `${filteredEntries.length} clipboard item${filteredEntries.length !== 1 ? 's' : ''}` : `Clipboard history is disabled`) : searchText.startsWith(
                             ">calc") ? `${filteredEntries.length} result${filteredEntries.length
                                        !== 1 ? 's' : ''}` : `${filteredEntries.length} application${filteredEntries.length
                                                !== 1 ? 's' : ''}`
        font.pointSize: Style.fontSizeXS * scaling
        color: Color.mOnSurface
        horizontalAlignment: Text.AlignHCenter
        Layout.fillWidth: true
        visible: searchText.trim() !== ""
      }
    }
  }
}

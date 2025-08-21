pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services

Singleton {
  id: root

  property var history: []
  property bool initialized: false
  property int maxHistory: 50 // Limit clipboard history entries

  // Internal state
  property bool _enabled: true

  // Cached history file path
  property string historyFile: Quickshell.env("NOCTALIA_CLIPBOARD_HISTORY_FILE")
                               || (Settings.cacheDir + "clipboard.json")

  // Persisted storage for clipboard history
  property FileView historyFileView: FileView {
    id: historyFileView
    objectName: "clipboardHistoryFileView"
    path: historyFile
    watchChanges: false // We don't need to watch changes for clipboard
    onAdapterUpdated: writeAdapter()
    Component.onCompleted: reload()
    onLoaded: loadFromHistory()
    onLoadFailed: function (error) {
      // Create file on first use
      if (error.toString().includes("No such file") || error === 2) {
        writeAdapter()
      }
    }

    JsonAdapter {
      id: historyAdapter
      property var history: []
      property double timestamp: 0
    }
  }

  Timer {
    interval: 2000
    repeat: true
    running: root._enabled
    onTriggered: root.refresh()
  }

  // Detect current clipboard types (text/image)
  Process {
    id: typeProcess
    property bool isLoading: false
    property var currentTypes: []

    onExited: (exitCode, exitStatus) => {
      if (exitCode === 0) {
        currentTypes = String(stdout.text).trim().split('\n').filter(t => t)

        // Always check for text first
        textProcess.command = ["wl-paste", "-n", "--type", "text/plain"]
        textProcess.isLoading = true
        textProcess.running = true

        // Also check for images if available
        const imageType = currentTypes.find(t => t.startsWith('image/'))
        if (imageType) {
          imageProcess.mimeType = imageType
          imageProcess.command = ["sh", "-c", `wl-paste -n -t "${imageType}" | base64 -w 0`]
          imageProcess.running = true
        }
      } else {
        typeProcess.isLoading = false
      }
    }

    stdout: StdioCollector {}
  }

  // Read image data
  Process {
    id: imageProcess
    property string mimeType: ""

    onExited: (exitCode, exitStatus) => {
      if (exitCode === 0) {
        const base64 = stdout.text.trim()
        if (base64) {
          const entry = {
            "type": 'image',
            "mimeType": mimeType,
            "data": `data:${mimeType};base64,${base64}`,
            "timestamp": new Date().getTime()
          }

          // Check if this exact image already exists
          const exists = root.history.find(item => item.type === 'image' && item.data === entry.data)
          if (!exists) {
            // Normalize existing history and add the new image
            const normalizedHistory = root.history.map(item => {
                                                         if (typeof item === 'string') {
                                                           return {
                                                             "type": 'text',
                                                             "content": item,
                                                             "timestamp": new Date().getTime(
                                                                            ) - 1000 // Make it slightly older
                                                           }
                                                         }
                                                         return item
                                                       })
            root.history = [entry, ...normalizedHistory].slice(0, maxHistory)
            saveHistory()
          }
        }
      }

      // Always mark as initialized when done
      if (!textProcess.isLoading) {
        root.initialized = true
        typeProcess.isLoading = false
      }
    }

    stdout: StdioCollector {}
  }

  // Read text data
  Process {
    id: textProcess
    property bool isLoading: false

    onExited: (exitCode, exitStatus) => {
      textProcess.isLoading = false

      if (exitCode === 0) {
        const content = String(stdout.text).trim()
        if (content && content.length > 0) {
          const entry = {
            "type": 'text',
            "content": content,
            "timestamp": new Date().getTime()
          }

          // Check if this exact text content already exists
          const exists = root.history.find(item => {
                                             if (item.type === 'text') {
                                               return item.content === content
                                             }
                                             return item === content
                                           })

          if (!exists) {
            // Normalize existing history entries
            const normalizedHistory = root.history.map(item => {
                                                         if (typeof item === 'string') {
                                                           return {
                                                             "type": 'text',
                                                             "content": item,
                                                             "timestamp": new Date().getTime(
                                                                            ) - 1000 // Make it slightly older
                                                           }
                                                         }
                                                         return item
                                                       })

            root.history = [entry, ...normalizedHistory].slice(0, maxHistory)
            saveHistory()
          }
        }
      }

      // Mark as initialized and clean up loading states
      root.initialized = true
      if (!imageProcess.running) {
        typeProcess.isLoading = false
      }
    }

    stdout: StdioCollector {}
  }

  function refresh() {
    if (!typeProcess.isLoading && !textProcess.isLoading && !imageProcess.running) {
      typeProcess.isLoading = true
      typeProcess.command = ["wl-paste", "-l"]
      typeProcess.running = true
    }
  }

  function loadFromHistory() {
    // Populate in-memory history from cached file
    try {
      const items = historyAdapter.history || []
      root.history = items.slice(0, maxHistory) // Apply limit when loading
      Logger.log("Clipboard", "Loaded", root.history.length, "entries from cache")
    } catch (e) {
      Logger.error("Clipboard", "Failed to load history:", e)
      root.history = []
    }
  }

  function saveHistory() {
    try {
      // Ensure we don't exceed the maximum history limit
      const limitedHistory = root.history.slice(0, maxHistory)

      historyAdapter.history = limitedHistory
      historyAdapter.timestamp = Time.timestamp

      // Ensure cache directory exists
      Quickshell.execDetached(["mkdir", "-p", Settings.cacheDir])

      Qt.callLater(function () {
        historyFileView.writeAdapter()
      })
    } catch (e) {
      Logger.error("Clipboard", "Failed to save history:", e)
    }
  }

  function clearHistory() {
    root.history = []
    saveHistory()
  }
}

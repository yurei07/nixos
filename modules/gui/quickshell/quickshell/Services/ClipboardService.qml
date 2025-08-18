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

  // Internal state
  property bool _enabled: true

  Timer {
    interval: 1000
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

        const imageType = currentTypes.find(t => t.startsWith('image/'))
        if (imageType) {
          imageProcess.mimeType = imageType
          imageProcess.command = ["sh", "-c", `wl-paste -n -t "${imageType}" | base64 -w 0`]
          imageProcess.running = true
        } else {
          textProcess.command = ["wl-paste", "-n", "--type", "text/plain"]
          textProcess.running = true
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

          const exists = root.history.find(item => item.type === 'image' && item.data === entry.data)
          if (!exists) {
            root.history = [entry, ...root.history].slice(0, 20)
          }
        }
      }

      if (!textProcess.isLoading) {
        root.initialized = true
      }
      typeProcess.isLoading = false
    }

    stdout: StdioCollector {}
  }

  // Read text data
  Process {
    id: textProcess
    property bool isLoading: false

    onExited: (exitCode, exitStatus) => {
      if (exitCode === 0) {
        const content = String(stdout.text).trim()
        if (content) {
          const entry = {
            "type": 'text',
            "content": content,
            "timestamp": new Date().getTime()
          }

          const exists = root.history.find(item => {
                                             if (item.type === 'text') {
                                               return item.content === content
                                             }
                                             return item === content
                                           })

          if (!exists) {
            const newHistory = root.history.map(item => {
                                                  if (typeof item === 'string') {
                                                    return {
                                                      "type": 'text',
                                                      "content": item,
                                                      "timestamp": new Date().getTime()
                                                    }
                                                  }
                                                  return item
                                                })

            root.history = [entry, ...newHistory].slice(0, 20)
          }
        }
      } else {
        textProcess.isLoading = false
      }

      root.initialized = true
      typeProcess.isLoading = false
    }

    stdout: StdioCollector {}
  }

  function refresh() {
    if (!typeProcess.isLoading && !textProcess.isLoading) {
      typeProcess.isLoading = true
      typeProcess.command = ["wl-paste", "-l"]
      typeProcess.running = true
    }
  }
}

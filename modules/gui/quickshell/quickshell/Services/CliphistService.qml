pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// Thin wrapper around the cliphist CLI
Singleton {
  id: root

  // Public API
  property var items: [] // [{id, preview, mime, isImage}]
  property bool loading: false
  // Active only when feature is enabled and settings have finished initial load
  property bool active: Settings.data.appLauncher.enableClipboardHistory && !Settings.isInitialLoad

  // Optional automatic watchers to feed cliphist DB
  property bool autoWatch: true
  property bool watchersStarted: false

  // Expose decoded thumbnails by id and a revision to notify bindings
  property var imageDataById: ({})
  property int revision: 0

  // Internal: store callback for decode
  property var _decodeCallback: null

  // Queue for base64 decodes
  property var _b64Queue: []
  property var _b64CurrentCb: null
  property string _b64CurrentMime: ""
  property string _b64CurrentId: ""

  // Start/stop watchers when enabled changes
  Component.onCompleted: {
    if (root.active) startWatchers()
  }
  onActiveChanged: {
    if (root.active) {
      startWatchers()
    } else {
      stopWatchers()
      loading = false
      // Optional: clear items to avoid stale UI
      items = []
    }
  }

  // Fallback: periodically refresh list so UI updates even if not in clip mode
  Timer {
    interval: 5000
    repeat: true
    running: root.active
    onTriggered: list()
  }

  // Internal process objects
  Process {
    id: listProc
    stdout: StdioCollector {}
    onExited: (exitCode, exitStatus) => {
      const out = String(stdout.text)
      const lines = out.split('\n').filter(l => l.length > 0)
      // cliphist list default format: "<id> <preview>" or "<id>\t<preview>"
      const parsed = lines.map(l => {
        let id = ""
        let preview = ""
        const m = l.match(/^(\d+)\s+(.+)$/)
        if (m) {
          id = m[1]
          preview = m[2]
        } else {
          const tab = l.indexOf('\t')
          id = tab > -1 ? l.slice(0, tab) : l
          preview = tab > -1 ? l.slice(tab + 1) : ""
        }
        const lower = preview.toLowerCase()
        const isImage = lower.startsWith("[image]") || lower.includes(" binary data ")
        // Best-effort mime guess from preview
        var mime = "text/plain"
        if (isImage) {
          if (lower.includes(" png")) mime = "image/png"
          else if (lower.includes(" jpg") || lower.includes(" jpeg")) mime = "image/jpeg"
          else if (lower.includes(" webp")) mime = "image/webp"
          else if (lower.includes(" gif")) mime = "image/gif"
          else mime = "image/*"
        }
        return { id, preview, isImage, mime }
      })
      items = parsed
      loading = false
    }
  }

  Process {
    id: decodeProc
    stdout: StdioCollector {}
    onExited: (exitCode, exitStatus) => {
      const out = String(stdout.text)
      if (root._decodeCallback) {
        try { root._decodeCallback(out) } finally { root._decodeCallback = null }
      }
    }
  }

  Process {
    id: copyProc
    stdout: StdioCollector {}
  }

  // Base64 decode pipeline (queued)
  Process {
    id: decodeB64Proc
    stdout: StdioCollector {}
    onExited: (exitCode, exitStatus) => {
      const b64 = String(stdout.text).trim()
      if (root._b64CurrentCb) {
        const url = `data:${root._b64CurrentMime};base64,${b64}`
        try { root._b64CurrentCb(url) } finally { /* noop */ }
      }
      if (root._b64CurrentId !== "") {
        root.imageDataById[root._b64CurrentId] = `data:${root._b64CurrentMime};base64,${b64}`
        root.revision += 1
      }
      root._b64CurrentCb = null
      root._b64CurrentMime = ""
      root._b64CurrentId = ""
      Qt.callLater(root._startNextB64)
    }
  }

  // Long-running watchers to store new clipboard contents
  Process {
    id: watchText
    stdout: StdioCollector {}
    onExited: (exitCode, exitStatus) => {
      // Auto-restart if watcher dies
      if (root.autoWatch) Qt.callLater(() => { running = true })
    }
  }
  Process {
    id: watchImage
    stdout: StdioCollector {}
    onExited: (exitCode, exitStatus) => {
      if (root.autoWatch) Qt.callLater(() => { running = true })
    }
  }

  function startWatchers() {
    if (!root.active || !autoWatch || watchersStarted) return
    watchersStarted = true
    // Start text watcher
    watchText.command = ["wl-paste", "--type", "text", "--watch", "cliphist", "store"]
    watchText.running = true
    // Start image watcher
    watchImage.command = ["wl-paste", "--type", "image", "--watch", "cliphist", "store"]
    watchImage.running = true
  }

  function stopWatchers() {
    if (!watchersStarted) return
    watchText.running = false
    watchImage.running = false
    watchersStarted = false
  }

  function list(maxPreviewWidth) {
    if (!root.active) { return }
    if (listProc.running) return
    loading = true
    const width = maxPreviewWidth || 100
    listProc.command = ["cliphist", "list", "-preview-width", String(width)]
    listProc.running = true
  }

  function decode(id, cb) {
    root._decodeCallback = cb
    decodeProc.command = ["cliphist", "decode", id]
    decodeProc.running = true
  }

  function decodeToDataUrl(id, mime, cb) {
    // If cached, return immediately
    if (root.imageDataById[id]) {
      if (cb) cb(root.imageDataById[id])
      return
    }
    // Queue request; ensures single process handles sequentially
    root._b64Queue.push({ id, mime: mime || "image/*", cb })
    if (!decodeB64Proc.running && root._b64CurrentCb === null) {
      _startNextB64()
    }
  }

  function _startNextB64() {
    if (root._b64Queue.length === 0) return
    const job = root._b64Queue.shift()
    root._b64CurrentCb = job.cb
    root._b64CurrentMime = job.mime
    root._b64CurrentId = job.id
    decodeB64Proc.command = ["sh", "-lc", `cliphist decode ${job.id} | base64 -w 0`]
    decodeB64Proc.running = true
  }

  function copyToClipboard(id) {
    // decode and pipe to wl-copy; implement via shell to preserve binary
    copyProc.command = ["sh", "-lc", `cliphist decode ${id} | wl-copy`]
    copyProc.running = true
  }

  function deleteById(id) {
    Quickshell.execDetached(["cliphist", "delete", id])
    Qt.callLater(() => list())
  }

  function wipeAll() {
    Quickshell.execDetached(["cliphist", "wipe"])
    Qt.callLater(() => list())
  }
}



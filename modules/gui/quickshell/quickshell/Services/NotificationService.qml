pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services
import Quickshell.Services.Notifications

Singleton {
  id: root

  // Notification server instance
  property NotificationServer server: NotificationServer {
    id: notificationServer

    // Server capabilities
    keepOnReload: false
    imageSupported: true
    actionsSupported: true
    actionIconsSupported: true
    bodyMarkupSupported: true
    bodySupported: true
    persistenceSupported: true
    inlineReplySupported: true
    bodyHyperlinksSupported: true
    bodyImagesSupported: true

    // Signal when notification is received
    onNotification: function (notification) {
      // Always add notification to history
      root.addToHistory(notification)

      // Check if do-not-disturb is enabled
      if (Settings.data.notifications && Settings.data.notifications.doNotDisturb) {
        return
      }

      // Track the notification
      notification.tracked = true

      // Connect to closed signal for cleanup
      notification.closed.connect(function () {
        root.removeNotification(notification)
      })

      // Add to our model
      root.addNotification(notification)
    }
  }

  // List model to hold notifications
  property ListModel notificationModel: ListModel {}

  // Persistent history of notifications (most recent first)
  property ListModel historyModel: ListModel {}
  property int maxHistory: 100

  // Cached history file path
  property string historyFile: Quickshell.env("NOCTALIA_NOTIF_HISTORY_FILE")
                               || (Settings.cacheDir + "notifications.json")

  // Persisted storage for history
  property FileView historyFileView: FileView {
    id: historyFileView
    objectName: "notificationHistoryFileView"
    path: historyFile
    printErrors: false
    watchChanges: true
    onFileChanged: reload()
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
      property real timestamp: 0
    }
  }

  // Maximum visible notifications
  property int maxVisible: 5

  // Auto-hide timer
  property Timer hideTimer: Timer {
    interval: 8000 // 8 seconds - longer display time
    repeat: true
    running: notificationModel.count > 0

    onTriggered: {
      if (notificationModel.count === 0) {
        return
      }

      // Remove the oldest notification (last in the list)
      let oldestNotification = notificationModel.get(notificationModel.count - 1).rawNotification
      if (oldestNotification) {
        // Trigger animation signal instead of direct dismiss
        animateAndRemove(oldestNotification, notificationModel.count - 1)
      }
    }
  }

  Connections {
    target: Settings.data.notifications
    function onDoNotDisturbChanged() {
      const label = Settings.data.notifications.doNotDisturb ? "'Do Not Disturb' enabled" : "'Do Not Disturb' disabled"
      const description = Settings.data.notifications.doNotDisturb ? "You'll find these notifications in your history." : "Showing all notifications."
      ToastService.showNotice(label, description)
    }
  }

  // Function to resolve app name from notification
  function resolveAppName(notification) {
    try {
      const appName = notification.appName || ""

      // If it's already a clean name (no dots or reverse domain notation), use it
      if (!appName.includes(".") || appName.length < 10) {
        return appName
      }

      // Try to find a desktop entry for this app ID
      const desktopEntries = DesktopEntries.byId(appName)
      if (desktopEntries && desktopEntries.length > 0) {
        const entry = desktopEntries[0]
        // Prefer name over genericName, fallback to original appName
        return entry.name || entry.genericName || appName
      }

      // If no desktop entry found, try to clean up the app ID
      // Convert "org.gnome.Nautilus" to "Nautilus"
      const parts = appName.split(".")
      if (parts.length > 1) {
        // Take the last part and capitalize it
        const lastPart = parts[parts.length - 1]
        return lastPart.charAt(0).toUpperCase() + lastPart.slice(1)
      }

      return appName
    } catch (e) {
      // Fallback to original app name on any error
      return notification.appName || ""
    }
  }

  // Function to add notification to model
  function addNotification(notification) {
    const resolvedImage = resolveNotificationImage(notification)
    const resolvedAppName = resolveAppName(notification)

    notificationModel.insert(0, {
                               "rawNotification": notification,
                               "summary": notification.summary,
                               "body": notification.body,
                               "appName": resolvedAppName,
                               "desktopEntry": notification.desktopEntry,
                               "image": resolvedImage,
                               "appIcon": notification.appIcon,
                               "urgency": notification.urgency,
                               "timestamp": new Date()
                             })

    // Remove oldest notifications if we exceed maxVisible
    while (notificationModel.count > maxVisible) {
      let oldestNotification = notificationModel.get(notificationModel.count - 1).rawNotification
      if (oldestNotification) {
        oldestNotification.dismiss()
      }
      notificationModel.remove(notificationModel.count - 1)
    }
  }

  // Resolve an image path for a notification, supporting icon names and absolute paths
  function resolveNotificationImage(notification) {
    try {
      // If an explicit image is already provided, prefer it
      if (notification && notification.image && notification.image !== "") {
        return notification.image
      }

      // Fallback to appIcon which may be a name or a path (notify-send -i)
      const icon = notification ? (notification.appIcon || "") : ""
      if (!icon)
        return ""

      // Accept absolute file paths or file URLs directly
      if (icon.startsWith("/")) {
        return icon
      }
      if (icon.startsWith("file://")) {
        // Strip the scheme for QML image source compatibility
        return icon.substring("file://".length)
      }

      // Resolve themed icon names to absolute paths
      try {
        const p = AppIcons.iconFromName(icon, "")
        return p || ""
      } catch (e2) {
        return ""
      }
    } catch (e) {
      return ""
    }
  }

  function addToHistory(notification) {
    const resolvedAppName = resolveAppName(notification)
    const resolvedImage = resolveNotificationImage(notification)

    historyModel.insert(0, {
                          "summary": notification.summary,
                          "body": notification.body,
                          "appName": resolvedAppName,
                          "desktopEntry": notification.desktopEntry || "",
                          "image": resolvedImage,
                          "appIcon": notification.appIcon || "",
                          "urgency": notification.urgency,
                          "timestamp": new Date()
                        })
    while (historyModel.count > maxHistory) {
      historyModel.remove(historyModel.count - 1)
    }
    saveHistory()
  }

  function clearHistory() {
    historyModel.clear()
    saveHistory()
  }

  function loadFromHistory() {
    // Populate in-memory model from adapter
    try {
      historyModel.clear()
      const items = historyAdapter.history || []
      for (var i = 0; i < items.length; i++) {
        const it = items[i]
        // Coerce legacy second-based timestamps to milliseconds
        var ts = it.timestamp
        if (typeof ts === "number" && ts < 1e12) {
          ts = ts * 1000
        }
        historyModel.append({
                              "summary": it.summary || "",
                              "body": it.body || "",
                              "appName": it.appName || "",
                              "desktopEntry": it.desktopEntry || "",
                              "image": it.image || "",
                              "appIcon": it.appIcon || "",
                              "urgency": it.urgency,
                              "timestamp": ts ? new Date(ts) : new Date()
                            })
      }
    } catch (e) {
      Logger.error("Notifications", "Failed to load history:", e)
    }
  }

  function saveHistory() {
    try {
      // Serialize model back to adapter
      var arr = []
      for (var i = 0; i < historyModel.count; i++) {
        const n = historyModel.get(i)
        arr.push({
                   "summary": n.summary,
                   "body": n.body,
                   "appName": n.appName,
                   "desktopEntry": n.desktopEntry,
                   "image": n.image,
                   "appIcon": n.appIcon,
                   "urgency": n.urgency,
                   "timestamp"// Always persist in milliseconds
                   : (n.timestamp instanceof Date) ? n.timestamp.getTime(
                                                       ) : (typeof n.timestamp === "number"
                                                            && n.timestamp < 1e12 ? n.timestamp * 1000 : n.timestamp)
                 })
      }
      historyAdapter.history = arr
      historyAdapter.timestamp = Time.timestamp

      Qt.callLater(function () {
        historyFileView.writeAdapter()
      })
    } catch (e) {
      Logger.error("Notifications", "Failed to save history:", e)
    }
  }

  // Signal to trigger animation before removal
  signal animateAndRemove(var notification, int index)

  // Function to remove notification from model
  function removeNotification(notification) {
    for (var i = 0; i < notificationModel.count; i++) {
      if (notificationModel.get(i).rawNotification === notification) {
        // Emit signal to trigger animation first
        animateAndRemove(notification, i)
        break
      }
    }
  }

  // Function to actually remove notification after animation
  function forceRemoveNotification(notification) {
    for (var i = 0; i < notificationModel.count; i++) {
      if (notificationModel.get(i).rawNotification === notification) {
        notificationModel.remove(i)
        break
      }
    }
  }

  // Function to format timestamp
  function formatTimestamp(timestamp) {
    if (!timestamp)
      return ""

    const now = new Date()
    const diff = now - timestamp

    // Less than 1 minute
    if (diff < 60000) {
      return "now"
    } // Less than 1 hour
    else if (diff < 3600000) {
      const minutes = Math.floor(diff / 60000)
      return `${minutes}m ago`
    } // Less than 24 hours
    else if (diff < 86400000) {
      const hours = Math.floor(diff / 3600000)
      return `${hours}h ago`
    } // More than 24 hours
    else {
      const days = Math.floor(diff / 86400000)
      return `${days}d ago`
    }
  }
}

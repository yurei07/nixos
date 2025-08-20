pragma Singleton

import QtQuick
import Quickshell.Io
import qs.Commons

QtObject {
  id: root

  // Queue of pending toast messages
  property var messageQueue: []
  property bool isShowingToast: false

  // Reference to the current toast instance (set by ToastManager)
  property var currentToast: null

  // Methods to show different types of messages
  function showNotice(label, description = "", persistent = false, duration = 3000) {
    showToast(label, description, "notice", persistent, duration)
  }

  function showWarning(label, description = "", persistent = false, duration = 4000) {
    showToast(label, description, "warning", persistent, duration)
  }

  // Utility function to check if a command exists and show appropriate toast
  function checkCommandAndToast(command, successMessage, failMessage, onSuccess = null) {
    var checkProcess = Qt.createQmlObject(`
                                          import QtQuick
                                          import Quickshell.Io
                                          Process {
                                          id: checkProc
                                          command: ["which", "${command}"]
                                          running: true

                                          property var onSuccessCallback: null
                                          property bool hasFinished: false

                                          onExited: {
                                          if (!hasFinished) {
                                          hasFinished = true
                                          if (exitCode === 0) {
                                          ToastService.showNotice("${successMessage}")
                                          if (onSuccessCallback) onSuccessCallback()
                                          } else {
                                          ToastService.showWarning("${failMessage}")
                                          }
                                          checkProc.destroy()
                                          }
                                          }

                                          // Fallback collectors to prevent issues
                                          stdout: StdioCollector {}
                                          stderr: StdioCollector {}
                                          }
                                          `, root)

    checkProcess.onSuccessCallback = onSuccess
  }

  // Simple function to show a random toast (useful for testing or fun messages)
  function showRandomToast() {
    var messages = [{
                      "type": "notice",
                      "text": "Everything is working smoothly!"
                    }, {
                      "type": "notice",
                      "text": "Noctalia is looking great today!"
                    }, {
                      "type": "notice",
                      "text": "Your desktop setup is amazing!"
                    }, {
                      "type": "warning",
                      "text": "Don't forget to take a break!"
                    }, {
                      "type": "notice",
                      "text": "Configuration saved successfully!"
                    }, {
                      "type": "warning",
                      "text": "Remember to backup your settings!"
                    }]

    var randomMessage = messages[Math.floor(Math.random() * messages.length)]
    showToast(randomMessage.text, randomMessage.type)
  }

  // Convenience function for quick notifications
  function quickNotice(message) {
    showNotice(message, false, 2000) // Short duration
  }

  function quickWarning(message) {
    showWarning(message, false, 3000) // Medium duration
  }

  // Generic command runner with toast feedback
  function runCommandWithToast(command, args, successMessage, failMessage, onSuccess = null) {
    var fullCommand = [command].concat(args || [])
    var runProcess = Qt.createQmlObject(`
                                        import QtQuick
                                        import Quickshell.Io
                                        Process {
                                        id: runProc
                                        command: ${JSON.stringify(fullCommand)}
                                        running: true

                                        property var onSuccessCallback: null
                                        property bool hasFinished: false

                                        onExited: {
                                        if (!hasFinished) {
                                        hasFinished = true
                                        if (exitCode === 0) {
                                        ToastService.showNotice("${successMessage}")
                                        if (onSuccessCallback) onSuccessCallback()
                                        } else {
                                        ToastService.showWarning("${failMessage}")
                                        }
                                        runProc.destroy()
                                        }
                                        }

                                        stdout: StdioCollector {}
                                        stderr: StdioCollector {}
                                        }
                                        `, root)

    runProcess.onSuccessCallback = onSuccess
  }

  // Check if a file/directory exists
  function checkPathAndToast(path, successMessage, failMessage, onSuccess = null) {
    runCommandWithToast("test", ["-e", path], successMessage, failMessage, onSuccess)
  }

  // Show toast after a delay (useful for delayed feedback)
  function delayedToast(message, type = "notice", delayMs = 1000) {
    var timer = Qt.createQmlObject(`
                                   import QtQuick
                                   Timer {
                                   interval: ${delayMs}
                                   repeat: false
                                   running: true
                                   onTriggered: {
                                   ToastService.showToast("${message}", "${type}")
                                   destroy()
                                   }
                                   }
                                   `, root)
  }

  // Generic method to show a toast
  function showToast(label, description = "", type = "notice", persistent = false, duration = 3000) {
    var toastData = {
      "label": label,
      "description": description,
      "type": type,
      "persistent": persistent,
      "duration": duration,
      "timestamp": Date.now()
    }

    // Add to queue
    messageQueue.push(toastData)

    // Process queue if not currently showing a toast
    if (!isShowingToast) {
      processQueue()
    }
  }

  // Process the message queue
  function processQueue() {
    if (messageQueue.length === 0 || !currentToast) {
      isShowingToast = false
      return
    }

    if (isShowingToast) {
      // Wait for current toast to finish
      return
    }

    var toastData = messageQueue.shift()
    isShowingToast = true

    // Configure and show toast
    currentToast.label = toastData.label
    currentToast.description = toastData.description
    currentToast.type = toastData.type
    currentToast.persistent = toastData.persistent
    currentToast.duration = toastData.duration
    currentToast.show()
  }

  // Called when a toast is dismissed
  function onToastDismissed() {

    isShowingToast = false

    // Small delay before showing next toast
    Qt.callLater(function () {
      processQueue()
    })
  }

  // Clear all pending messages
  function clearQueue() {

    messageQueue = []
  }

  // Hide current toast
  function hideCurrentToast() {
    if (currentToast && isShowingToast) {
      currentToast.hide()
    }
  }

  Component.onCompleted: {

  }
}

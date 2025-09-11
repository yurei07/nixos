import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services
import "../../../Helpers/FuzzySort.js" as Fuzzysort

Item {
  property var launcher: null
  property string name: "Applications"
  property bool handleSearch: true
  property var entries: []

  function init() {
    loadApplications()
  }

  function onOpened() {
    // Refresh apps when launcher opens
    loadApplications()
  }

  function loadApplications() {
    if (typeof DesktopEntries === 'undefined') {
      Logger.warn("ApplicationsPlugin", "DesktopEntries service not available")
      return
    }

    const allApps = DesktopEntries.applications.values || []
    entries = allApps.filter(app => app && !app.noDisplay)
    Logger.log("ApplicationsPlugin", `Loaded ${entries.length} applications`)
  }

  function getResults(query) {
    if (!entries || entries.length === 0)
      return []

    if (!query || query.trim() === "") {
      // Return all apps alphabetically
      return entries.sort((a, b) => a.name.toLowerCase().localeCompare(b.name.toLowerCase())).map(
            app => createResultEntry(app))
    }

    // Use fuzzy search if available, fallback to simple search
    if (typeof Fuzzysort !== 'undefined') {
      const fuzzyResults = Fuzzysort.go(query, entries, {
                                          "keys": ["name", "comment", "genericName"],
                                          "threshold": -1000,
                                          "limit": 20
                                        })

      return fuzzyResults.map(result => createResultEntry(result.obj))
    } else {
      // Fallback to simple search
      const searchTerm = query.toLowerCase()
      return entries.filter(app => {
                              const name = (app.name || "").toLowerCase()
                              const comment = (app.comment || "").toLowerCase()
                              const generic = (app.genericName || "").toLowerCase()
                              return name.includes(searchTerm) || comment.includes(searchTerm) || generic.includes(
                                searchTerm)
                            }).sort((a, b) => {
                                      // Prioritize name matches
                                      const aName = a.name.toLowerCase()
                                      const bName = b.name.toLowerCase()
                                      const aStarts = aName.startsWith(searchTerm)
                                      const bStarts = bName.startsWith(searchTerm)
                                      if (aStarts && !bStarts)
                                      return -1
                                      if (!aStarts && bStarts)
                                      return 1
                                      return aName.localeCompare(bName)
                                    }).slice(0, 20).map(app => createResultEntry(app))
    }
  }

  function createResultEntry(app) {
    return {
      "name": app.name || "Unknown",
      "description": app.genericName || app.comment || "",
      "icon": app.icon || "application-x-executable",
      "isImage": false,
      "onActivate": function () {
        Logger.log("ApplicationsPlugin", `Launching: ${app.name}`)

        if (Settings.data.appLauncher.useApp2Unit && app.id) {
          Logger.log("ApplicationsPlugin", `Using app2unit for: ${app.id}`)
          Quickshell.execDetached(["app2unit", "--", app.id + ".desktop"])
        } else if (app.execute) {
          app.execute()
        } else if (app.exec) {
          // Fallback to manual execution
          Process.execute(app.exec)
        }
        launcher.close()
      }
    }
  }
}

pragma Singleton

import QtQuick
import Quickshell
import qs.Commons
import qs.Services

Singleton {
  id: root

  // Delegate to CompositorService for all workspace operations
  property ListModel workspaces: ListModel {}
  property bool isHyprland: false
  property bool isNiri: false

  Component.onCompleted: {
    // Connect to CompositorService workspace changes
    CompositorService.workspaceChanged.connect(updateWorkspaces)
    // Initial sync
    updateWorkspaces()
  }

  // Listen to compositor detection changes
  Connections {
    target: CompositorService
    function onIsHyprlandChanged() {
      isHyprland = CompositorService.isHyprland
    }
    function onIsNiriChanged() {
      isNiri = CompositorService.isNiri
    }
  }

  function updateWorkspaces() {
    workspaces.clear()
    for (var i = 0; i < CompositorService.workspaces.count; i++) {
      const ws = CompositorService.workspaces.get(i)
      workspaces.append(ws)
    }
    // Explicitly trigger the signal to ensure the Workspace module gets notified
    workspacesChanged()
  }

  function switchToWorkspace(workspaceId) {
    CompositorService.switchToWorkspace(workspaceId)
  }
}

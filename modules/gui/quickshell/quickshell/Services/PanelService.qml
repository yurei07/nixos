pragma Singleton

import Quickshell

Singleton {
  id: root

  // A ref. to the sidePanel, so it's accessible from other services
  property var sidePanel: null

  // Currently opened panel
  property var openedPanel: null

  function registerOpen(panel) {
    if (openedPanel && openedPanel != panel) {
      openedPanel.close()
    }
    openedPanel = panel
  }
}

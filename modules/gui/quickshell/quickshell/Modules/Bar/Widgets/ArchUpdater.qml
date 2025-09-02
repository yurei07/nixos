import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

NIconButton {
  id: root

  property ShellScreen screen
  property real scaling: 1.0

  sizeRatio: 0.8
  colorBg: Color.mSurfaceVariant
  colorBorder: Color.transparent
  colorBorderHover: Color.transparent
  colorFg: {
    if (!ArchUpdaterService.terminalAvailable || !ArchUpdaterService.aurHelperAvailable) {
      return Color.mError
    }
    return (ArchUpdaterService.totalUpdates === 0) ? Color.mOnSurface : Color.mPrimary
  }

  // Icon states
  icon: {
    if (!ArchUpdaterService.terminalAvailable) {
      return "terminal"
    }
    if (!ArchUpdaterService.aurHelperAvailable) {
      return "package"
    }
    if (ArchUpdaterService.aurBusy) {
      return "sync"
    }
    if (ArchUpdaterService.totalUpdates > 0) {
      return "system_update_alt"
    }
    return "task_alt"
  }

  // Tooltip with repo vs AUR breakdown and sample lists
  tooltipText: {
    if (!ArchUpdaterService.terminalAvailable) {
      return "Terminal not configured\nSet TERMINAL environment variable"
    }
    if (!ArchUpdaterService.aurHelperAvailable) {
      return "AUR helper not found\nInstall yay or paru"
    }
    if (ArchUpdaterService.aurBusy) {
      return "Checking for updates…"
    }

    const total = ArchUpdaterService.totalUpdates
    if (total === 0) {
      return "System is up to date ✓"
    }
    let header = (total === 1) ? "1 package can be updated" : (total + " packages can be updated")

    const pacCount = ArchUpdaterService.updates
    const aurCount = ArchUpdaterService.aurUpdates
    const pacmanTooltip = (pacCount > 0) ? ((pacCount === 1) ? "1 system package" : pacCount + " system packages") : ""
    const aurTooltip = (aurCount > 0) ? ((aurCount === 1) ? "1 AUR package" : aurCount + " AUR packages") : ""

    let tooltip = header
    if (pacmanTooltip !== "") {
      tooltip += "\n" + pacmanTooltip
    }
    if (aurTooltip !== "") {
      tooltip += "\n" + aurTooltip
    }
    return tooltip
  }

  onClicked: {
    // Always allow panel to open, never block
    PanelService.getPanel("archUpdaterPanel").toggle(screen, this)
  }
}

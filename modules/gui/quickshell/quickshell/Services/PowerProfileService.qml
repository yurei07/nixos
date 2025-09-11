pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs.Commons
import qs.Services

Singleton {
  id: root

  readonly property var powerProfiles: PowerProfiles
  readonly property bool available: powerProfiles && powerProfiles.hasPerformanceProfile
  property int profile: powerProfiles ? powerProfiles.profile : PowerProfile.Balanced

  function profileName(p) {
    const prof = (p !== undefined) ? p : profile
    if (!available)
      return "Unknown"
    if (prof === PowerProfile.Performance)
      return "Performance"
    if (prof === PowerProfile.Balanced)
      return "Balanced"
    if (prof === PowerProfile.PowerSaver)
      return "Power Saver"
    return "Unknown"
  }

  function setProfile(p) {
    if (!available)
      return
    try {
      powerProfiles.profile = p
    } catch (e) {
      Logger.error("PowerProfileService", "Failed to set profile:", e)
    }
  }

  function cycleProfile() {
    if (!available)
      return
    const current = powerProfiles.profile
    if (current === PowerProfile.Performance)
      setProfile(PowerProfile.PowerSaver)
    else if (current === PowerProfile.Balanced)
      setProfile(PowerProfile.Performance)
    else if (current === PowerProfile.PowerSaver)
      setProfile(PowerProfile.Balanced)
  }

  Connections {
    target: powerProfiles
    function onProfileChanged() {
      root.profile = powerProfiles.profile
      // Only show toast if we have a valid profile name (not "Unknown")
      const profileName = root.profileName()
      if (profileName !== "Unknown") {
        ToastService.showNotice("Power Profile", profileName)
      }
    }
  }
}

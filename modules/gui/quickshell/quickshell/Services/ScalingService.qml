pragma Singleton

import Quickshell
import qs.Commons

Singleton {
  id: root

  // -------------------------------------------
  // Manual scaling via Settings
  function scale(aScreen) {
    return scaleByName(aScreen.name)
  }

  function scaleByName(aScreenName) {
    try {
      if (Settings.data.monitorsScaling !== undefined) {
        if (Settings.data.monitorsScaling[aScreenName] !== undefined) {
          return Settings.data.monitorsScaling[aScreenName]
        }
      }
    } catch (e) {

      //Logger.warn(e)
    }

    return 1.0
  }

  // -------------------------------------------
  // Dynamic scaling based on resolution

  // Design reference resolution (for scale = 1.0)
  readonly property int designScreenWidth: 2560
  readonly property int designScreenHeight: 1440

  function dynamicScale(aScreen) {
    var ratioW = aScreen.width / designScreenWidth
    var ratioH = aScreen.height / designScreenHeight
    return Math.min(ratioW, ratioH)
  }
}

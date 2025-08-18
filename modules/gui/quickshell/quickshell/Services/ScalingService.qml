pragma Singleton

import Quickshell

Singleton {
  id: root

  // Manual override for testing UI scale across the whole shell
  // Enable this from the DemoPanel slider
  property bool overrideEnabled: false
  property real overrideScale: 1.0

  // Design reference resolution (for scale = 1.0)
  readonly property int designScreenWidth: 2560
  readonly property int designScreenHeight: 1440

  // Automatic, orientation-agnostic scaling
  function scale(aScreen) {
    // 0) Manual override (for development/testing)
    try {
      if (overrideEnabled && isFinite(overrideScale)) {
        // Clamp to keep UI usable
        const clamped = Math.max(0.6, Math.min(1.8, overrideScale))
        return clamped
      }
    } catch (e) {

    }

    if (typeof aScreen !== 'undefined' & aScreen) {

      // // 1) Per-monitor override wins
      // try {
      //     const overrides = Settings.data.ui.monitorsScale || {};
      //     if (currentScreen && currentScreen.name && overrides[currentScreen.name] !== undefined) {
      //         const overrideValue = overrides[currentScreen.name]
      //         if (isFinite(overrideValue)) return overrideValue
      //     }
      // } catch (e) {
      //     // ignore
      // }

      // // 2) Fallback: scale by diagonal pixel count relative to design resolution
      // try {
      //     const w = Math.max(1, currentScreen ? (currentScreen.width || 0) : 0)
      //     const h = Math.max(1, currentScreen ? (currentScreen.height || 0) : 0)
      //     if (w > 1 && h > 1) {
      //         const diag = Math.sqrt(w * w + h * h)
      //         const baseDiag = Math.sqrt(designScreenWidth * designScreenWidth + designScreenHeight * designScreenHeight)
      //         const ratio = diag / baseDiag
      //         // Clamp to a reasonable range for UI legibility
      //         return Math.max(0.9, Math.min(1.6, ratio))
      //     }
      // } catch (e) {
      //     // ignore and fall through
      // }
    }

    // 3) Safe default
    return 1.0
  }
}

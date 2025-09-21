import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

// Screen Recording Indicator
NIconButton {
  id: root

  property ShellScreen screen
  property real scaling: 1.0

  visible: ScreenRecorderService.isRecording
  icon: "camera-video"
  tooltipText: "Screen recording is active.\nClick to stop recording."
  compact: (Settings.data.bar.density === "compact")
  baseSize: Style.capsuleHeight
  colorBg: Color.mPrimary
  colorFg: Color.mOnPrimary
  onClicked: ScreenRecorderService.toggleRecording()
}

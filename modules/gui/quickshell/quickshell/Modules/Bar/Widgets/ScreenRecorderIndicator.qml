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
  icon: "videocam"
  tooltipText: "Screen recording is active\nClick to stop recording"
  sizeRatio: 0.8
  colorBg: Color.mPrimary
  colorFg: Color.mOnPrimary
  anchors.verticalCenter: parent.verticalCenter
  onClicked: ScreenRecorderService.toggleRecording()
}

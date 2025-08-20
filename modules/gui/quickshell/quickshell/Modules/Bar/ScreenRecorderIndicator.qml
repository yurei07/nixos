import qs.Commons
import qs.Services
import qs.Widgets

// Screen Recording Indicator
NIconButton {
  id: screenRecordingIndicator
  icon: "videocam"
  tooltipText: "Screen Recording Active\nClick To Stop Recording"
  sizeMultiplier: 0.8
  colorBg: Color.mPrimary
  colorFg: Color.mOnPrimary
  visible: ScreenRecorderService.isRecording
  anchors.verticalCenter: parent.verticalCenter
  onClicked: {
    ScreenRecorderService.toggleRecording()
  }
}

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services
import qs.Widgets

NIconButton {
  id: root

  readonly property bool wifiEnabled: Settings.data.network.wifiEnabled

  sizeMultiplier: 0.8
  visible: wifiEnabled

  colorBg: Color.mSurfaceVariant
  colorFg: Color.mOnSurface
  colorBorder: Color.transparent
  colorBorderHover: Color.transparent

  icon: {
    let connected = false
    let signalStrength = 0
    for (const net in NetworkService.networks) {
      if (NetworkService.networks[net].connected) {
        connected = true
        signalStrength = NetworkService.networks[net].signal
        break
      }
    }
    return connected ? NetworkService.signalIcon(signalStrength) : "wifi"
  }
  tooltipText: "WiFi Networks"
  onClicked: {
    wifiPanel.toggle(screen)
  }

  WiFiPanel {
    id: wifiPanel
  }
}

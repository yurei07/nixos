pragma Singleton

import QtQuick
import Quickshell
import qs.Commons
import qs.Modules.Bar.Widgets

Singleton {
  id: root

  // Widget registry object mapping widget names to components
  property var widgets: ({
                           "ActiveWindow": activeWindowComponent,
                           "Battery": batteryComponent,
                           "Bluetooth": bluetoothComponent,
                           "Brightness": brightnessComponent,
                           "Clock": clockComponent,
                           "CustomButton": customButtonComponent,
                           "DarkModeToggle": darkModeToggle,
                           "KeepAwake": keepAwakeComponent,
                           "KeyboardLayout": keyboardLayoutComponent,
                           "MediaMini": mediaMiniComponent,
                           "Microphone": microphoneComponent,
                           "NightLight": nightLightComponent,
                           "NotificationHistory": notificationHistoryComponent,
                           "PowerProfile": powerProfileComponent,
                           "PowerToggle": powerToggleComponent,
                           "ScreenRecorderIndicator": screenRecorderIndicatorComponent,
                           "SidePanelToggle": sidePanelToggleComponent,
                           "Spacer": spacerComponent,
                           "SystemMonitor": systemMonitorComponent,
                           "Taskbar": taskbarComponent,
                           "Tray": trayComponent,
                           "Volume": volumeComponent,
                           "WiFi": wiFiComponent,
                           "Workspace": workspaceComponent
                         })

  property var widgetMetadata: ({
                                  "ActiveWindow": {
                                    "allowUserSettings": true,
                                    "showIcon": true
                                  },
                                  "Battery": {
                                    "allowUserSettings": true,
                                    "alwaysShowPercentage": false,
                                    "warningThreshold": 30
                                  },
                                  "Brightness": {
                                    "allowUserSettings": true,
                                    "alwaysShowPercentage": false
                                  },
                                  "Clock": {
                                    "allowUserSettings": true,
                                    "showDate": false,
                                    "use12HourClock": false,
                                    "showSeconds": false,
                                    "reverseDayMonth": true,
                                    "compactMode": false
                                  },
                                  "CustomButton": {
                                    "allowUserSettings": true,
                                    "icon": "heart",
                                    "leftClickExec": "",
                                    "rightClickExec": "",
                                    "middleClickExec": ""
                                  },
                                  "Microphone": {
                                    "allowUserSettings": true,
                                    "alwaysShowPercentage": false
                                  },
                                  "NotificationHistory": {
                                    "allowUserSettings": true,
                                    "showUnreadBadge": true,
                                    "hideWhenZero": true
                                  },
                                  "Spacer": {
                                    "allowUserSettings": true,
                                    "width": 20
                                  },
                                  "SystemMonitor": {
                                    "allowUserSettings": true,
                                    "showCpuUsage": true,
                                    "showCpuTemp": true,
                                    "showMemoryUsage": true,
                                    "showMemoryAsPercent": false,
                                    "showNetworkStats": false,
                                    "showDiskUsage": false
                                  },
                                  "Workspace": {
                                    "allowUserSettings": true,
                                    "labelMode": "index"
                                  },
                                  "MediaMini": {
                                    "allowUserSettings": true,
                                    "showAlbumArt": false,
                                    "showVisualizer": false,
                                    "visualizerType": "linear"
                                  },
                                  "SidePanelToggle": {
                                    "allowUserSettings": true,
                                    "useDistroLogo": false
                                  },
                                  "Volume": {
                                    "allowUserSettings": true,
                                    "alwaysShowPercentage": false
                                  },
                                  "KeyboardLayout": {
                                    "allowUserSettings": true,
                                    "forceOpen": false
                                  }
                                })

  // Component definitions - these are loaded once at startup
  property Component activeWindowComponent: Component {
    ActiveWindow {}
  }
  property Component batteryComponent: Component {
    Battery {}
  }
  property Component bluetoothComponent: Component {
    Bluetooth {}
  }
  property Component brightnessComponent: Component {
    Brightness {}
  }
  property Component clockComponent: Component {
    Clock {}
  }
  property Component customButtonComponent: Component {
    CustomButton {}
  }
  property Component darkModeToggle: Component {
    DarkModeToggle {}
  }
  property Component keyboardLayoutComponent: Component {
    KeyboardLayout {}
  }
  property Component keepAwakeComponent: Component {
    KeepAwake {}
  }
  property Component mediaMiniComponent: Component {
    MediaMini {}
  }
  property Component microphoneComponent: Component {
    Microphone {}
  }
  property Component nightLightComponent: Component {
    NightLight {}
  }
  property Component notificationHistoryComponent: Component {
    NotificationHistory {}
  }
  property Component powerProfileComponent: Component {
    PowerProfile {}
  }
  property Component powerToggleComponent: Component {
    PowerToggle {}
  }
  property Component screenRecorderIndicatorComponent: Component {
    ScreenRecorderIndicator {}
  }
  property Component sidePanelToggleComponent: Component {
    SidePanelToggle {}
  }
  property Component spacerComponent: Component {
    Spacer {}
  }
  property Component systemMonitorComponent: Component {
    SystemMonitor {}
  }
  property Component trayComponent: Component {
    Tray {}
  }
  property Component volumeComponent: Component {
    Volume {}
  }
  property Component wiFiComponent: Component {
    WiFi {}
  }
  property Component workspaceComponent: Component {
    Workspace {}
  }
  property Component taskbarComponent: Component {
    Taskbar {}
  }

  // ------------------------------
  // Helper function to get widget component by name
  function getWidget(id) {
    return widgets[id] || null
  }

  // Helper function to check if widget exists
  function hasWidget(id) {
    return id in widgets
  }

  // Get list of available widget id
  function getAvailableWidgets() {
    return Object.keys(widgets)
  }

  // Helper function to check if widget has user settings
  function widgetHasUserSettings(id) {
    return (widgetMetadata[id] !== undefined) && (widgetMetadata[id].allowUserSettings === true)
  }

  function getNPillDirection(widget) {
    try {
      if (widget.barSection === "leftSection") {
        return true
      } else if (widget.barSection === "rightSection") {
        return false
      } else {
        // middle section
        if (widget.sectionWidgetIndex < widget.sectionWidgetsCount / 2) {
          return false
        } else {
          return true
        }
      }
    } catch (e) {
      Logger.error(e)
    }
    return false
  }
}

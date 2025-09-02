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
                           "ArchUpdater": archUpdaterComponent,
                           "Battery": batteryComponent,
                           "Bluetooth": bluetoothComponent,
                           "Brightness": brightnessComponent,
                           "Clock": clockComponent,
                           "DarkModeToggle": darkModeToggle,
                           "KeyboardLayout": keyboardLayoutComponent,
                           "MediaMini": mediaMiniComponent,
                           "Microphone": microphoneComponent,
                           "NightLight": nightLightComponent,
                           "NotificationHistory": notificationHistoryComponent,
                           "PowerProfile": powerProfileComponent,
                           "ScreenRecorderIndicator": screenRecorderIndicatorComponent,
                           "SidePanelToggle": sidePanelToggleComponent,
                           "SystemMonitor": systemMonitorComponent,
                           "Taskbar": taskbarComponent,
                           "Tray": trayComponent,
                           "Volume": volumeComponent,
                           "WiFi": wiFiComponent,
                           "Workspace": workspaceComponent
                         })

  // Component definitions - these are loaded once at startup
  property Component activeWindowComponent: Component {
    ActiveWindow {}
  }
  property Component archUpdaterComponent: Component {
    ArchUpdater {}
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
  property Component darkModeToggle: Component {
    DarkModeToggle {}
  }
  property Component keyboardLayoutComponent: Component {
    KeyboardLayout {}
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
  property Component screenRecorderIndicatorComponent: Component {
    ScreenRecorderIndicator {}
  }
  property Component sidePanelToggleComponent: Component {
    SidePanelToggle {}
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
  function getWidget(name) {
    return widgets[name] || null
  }

  // Helper function to check if widget exists
  function hasWidget(name) {
    return name in widgets
  }

  // Get list of available widget names
  function getAvailableWidgets() {
    return Object.keys(widgets)
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

import QtQuick
import Quickshell
import qs.Services
import qs.Commons

Item {
  id: root

  property string widgetName: ""
  property var widgetProps: ({})
  property bool enabled: true

  Connections {
    target: ScalingService
    function onScaleChanged(screenName, scale) {
      if (loader.item && loader.item.screen && screenName === loader.item.screen.name) {
        loader.item['scaling'] = scale
      }
    }
  }

  // Don't reserve space unless the loaded widget is really visible
  implicitWidth: loader.item ? loader.item.visible ? loader.item.implicitWidth : 0 : 0
  implicitHeight: loader.item ? loader.item.visible ? loader.item.implicitHeight : 0 : 0

  Loader {
    id: loader

    anchors.fill: parent
    active: Settings.isLoaded && enabled && widgetName !== ""
    sourceComponent: {
      if (!active) {
        return null
      }
      return BarWidgetRegistry.getWidget(widgetName)
    }

    onLoaded: {
      if (item && widgetProps) {
        // Apply properties to loaded widget
        for (var prop in widgetProps) {
          if (item.hasOwnProperty(prop)) {
            item[prop] = widgetProps[prop]
          }
        }
      }

      if (item.hasOwnProperty("onLoaded")) {
        item.onLoaded()
      }

      //Logger.log("NWidgetLoader", "Loaded", widgetName, "on screen", item.screen.name)
    }
  }

  // Error handling
  onWidgetNameChanged: {
    if (widgetName && !BarWidgetRegistry.hasWidget(widgetName)) {
      Logger.warn("WidgetLoader", "Widget not found in registry:", widgetName)
    }
  }
}

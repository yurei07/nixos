import QtQuick
import Quickshell
import qs.Services
import qs.Commons

Item {
  id: root

  property string widgetId: ""
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
    active: Settings.isLoaded && enabled && widgetId !== ""
    sourceComponent: {
      if (!active) {
        return null
      }
      return BarWidgetRegistry.getWidget(widgetId)
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

      //Logger.log("NWidgetLoader", "Loaded", widgetId, "on screen", item.screen.name)
    }
  }

  // Error handling
  onWidgetIdChanged: {
    if (widgetId && !BarWidgetRegistry.hasWidget(widgetId)) {
      Logger.warn("WidgetLoader", "Widget not found in registry:", widgetId)
    }
  }
}

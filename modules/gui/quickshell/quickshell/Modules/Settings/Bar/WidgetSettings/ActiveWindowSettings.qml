import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import qs.Services

ColumnLayout {
  id: root
  spacing: Style.marginM * scaling

  // Properties to receive data from parent
  property var widgetData: null
  property var widgetMetadata: null

  // Local state
  property bool valueShowIcon: widgetData.showIcon !== undefined ? widgetData.showIcon : widgetMetadata.showIcon
  property bool valueAutoHide: widgetData.autoHide !== undefined ? widgetData.autoHide : widgetMetadata.autoHide
  property string valueScrollingMode: widgetData.scrollingMode || widgetMetadata.scrollingMode

  function saveSettings() {
    var settings = Object.assign({}, widgetData || {})
    settings.autoHide = valueAutoHide
    settings.showIcon = valueShowIcon
    settings.scrollingMode = valueScrollingMode
    console.log(JSON.stringify(settings))
    return settings
  }

  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("bar.widget-settings.active-window.auto-hide")
    checked: root.valueAutoHide
    onToggled: checked => root.valueAutoHide = checked
  }

  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("bar.widget-settings.active-window.show-app-icon")
    checked: root.valueShowIcon
    onToggled: checked => root.valueShowIcon = checked
  }

  NComboBox {
    label: I18n.tr("bar.widget-settings.active-window.scrolling-mode")
    model: [{
        "key": "always",
        "name": I18n.tr("options.scrolling-modes.always")
      }, {
        "key": "hover",
        "name": I18n.tr("options.scrolling-modes.hover")
      }, {
        "key": "never",
        "name": I18n.tr("options.scrolling-modes.never")
      }]
    currentKey: valueScrollingMode
    onSelected: key => valueScrollingMode = key
    minimumWidth: 200 * scaling
  }
}

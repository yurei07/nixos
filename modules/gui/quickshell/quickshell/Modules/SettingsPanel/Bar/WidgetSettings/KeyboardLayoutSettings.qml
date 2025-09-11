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
  property bool valueForceOpen: widgetData.forceOpen !== undefined ? widgetData.forceOpen : widgetMetadata.forceOpen

  function saveSettings() {
    var settings = Object.assign({}, widgetData || {})
    settings.forceOpen = valueForceOpen
    return settings
  }

  NToggle {
    label: "Force open"
    description: "Keep the keyboard layout widget always expanded."
    checked: valueForceOpen
    onToggled: checked => valueForceOpen = checked
  }
}

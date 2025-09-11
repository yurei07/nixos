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
  property bool valueAlwaysShowPercentage: widgetData.alwaysShowPercentage
                                           !== undefined ? widgetData.alwaysShowPercentage : widgetMetadata.alwaysShowPercentage

  function saveSettings() {
    var settings = Object.assign({}, widgetData || {})
    settings.alwaysShowPercentage = valueAlwaysShowPercentage
    return settings
  }

  NToggle {
    label: "Always show percentage"
    checked: valueAlwaysShowPercentage
    onToggled: checked => valueAlwaysShowPercentage = checked
  }
}

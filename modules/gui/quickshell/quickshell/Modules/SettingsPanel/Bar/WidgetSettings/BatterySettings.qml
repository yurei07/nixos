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
  property int valueWarningThreshold: widgetData.warningThreshold
                                      !== undefined ? widgetData.warningThreshold : widgetMetadata.warningThreshold

  function saveSettings() {
    var settings = Object.assign({}, widgetData || {})
    settings.alwaysShowPercentage = valueAlwaysShowPercentage
    settings.warningThreshold = valueWarningThreshold
    return settings
  }

  NToggle {
    label: "Always show percentage"
    checked: root.valueAlwaysShowPercentage
    onToggled: checked => root.valueAlwaysShowPercentage = checked
  }

  NSpinBox {
    label: "Low battery warning threshold"
    description: "Show a warning when battery falls below this percentage."
    value: valueWarningThreshold
    suffix: "%"
    minimum: 5
    maximum: 50
    onValueChanged: valueWarningThreshold = value
  }
}

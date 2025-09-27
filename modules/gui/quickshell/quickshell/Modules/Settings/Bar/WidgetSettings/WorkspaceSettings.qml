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

  function saveSettings() {
    var settings = Object.assign({}, widgetData || {})
    settings.labelMode = labelModeCombo.currentKey
    settings.hideUnoccupied = hideUnoccupiedToggle.checked
    return settings
  }

  NComboBox {
    id: labelModeCombo

    label: I18n.tr("bar.widget-settings.workspace.label-mode")
    model: [{
        "key": "none",
        "name": I18n.tr("options.workspace-labels.none")
      }, {
        "key": "index",
        "name": I18n.tr("options.workspace-labels.index")
      }, {
        "key": "name",
        "name": I18n.tr("options.workspace-labels.name")
      }]
    currentKey: widgetData.labelMode || widgetMetadata.labelMode
    onSelected: key => labelModeCombo.currentKey = key
    minimumWidth: 200 * scaling
  }

  NToggle {
    id: hideUnoccupiedToggle
    label: I18n.tr("bar.widget-settings.workspace.hide-unoccupied.label")
    description: I18n.tr("bar.widget-settings.workspace.hide-unoccupied.description")
    checked: widgetData.hideUnoccupied
    onToggled: checked => hideUnoccupiedToggle.checked = checked
  }
}

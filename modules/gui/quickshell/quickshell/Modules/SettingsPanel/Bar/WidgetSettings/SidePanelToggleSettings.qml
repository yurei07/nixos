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
  property bool valueUseDistroLogo: widgetData.useDistroLogo !== undefined ? widgetData.useDistroLogo : widgetMetadata.useDistroLogo

  function saveSettings() {
    var settings = Object.assign({}, widgetData || {})
    settings.useDistroLogo = valueUseDistroLogo
    return settings
  }

  NToggle {
    label: "Use distro logo instead of icon"
    checked: valueUseDistroLogo
    onToggled: checked => valueUseDistroLogo = checked
  }
}

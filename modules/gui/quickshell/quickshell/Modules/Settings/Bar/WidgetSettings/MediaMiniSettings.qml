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
  property bool valueAutoHide: widgetData.autoHide !== undefined ? widgetData.autoHide : widgetMetadata.autoHide
  property bool valueShowAlbumArt: widgetData.showAlbumArt !== undefined ? widgetData.showAlbumArt : widgetMetadata.showAlbumArt
  property bool valueShowVisualizer: widgetData.showVisualizer !== undefined ? widgetData.showVisualizer : widgetMetadata.showVisualizer
  property string valueVisualizerType: widgetData.visualizerType || widgetMetadata.visualizerType
  property string valueScrollingMode: widgetData.scrollingMode || widgetMetadata.scrollingMode

  function saveSettings() {
    var settings = Object.assign({}, widgetData || {})
    settings.autoHide = valueAutoHide
    settings.showAlbumArt = valueShowAlbumArt
    settings.showVisualizer = valueShowVisualizer
    settings.visualizerType = valueVisualizerType
    settings.scrollingMode = valueScrollingMode
    return settings
  }

  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("bar.widget-settings.media-mini.auto-hide")
    checked: root.valueAutoHide
    onToggled: checked => root.valueAutoHide = checked
  }

  NToggle {
    label: I18n.tr("bar.widget-settings.media-mini.show-album-art")
    checked: valueShowAlbumArt
    onToggled: checked => valueShowAlbumArt = checked
  }

  NToggle {
    label: I18n.tr("bar.widget-settings.media-mini.show-visualizer")
    checked: valueShowVisualizer
    onToggled: checked => valueShowVisualizer = checked
  }

  NComboBox {
    visible: valueShowVisualizer
    label: I18n.tr("bar.widget-settings.media-mini.visualizer-type")
    model: [{
        "key": "linear",
        "name": I18n.tr("options.visualizer-types.linear")
      }, {
        "key": "mirrored",
        "name": I18n.tr("options.visualizer-types.mirrored")
      }, {
        "key": "wave",
        "name": I18n.tr("options.visualizer-types.wave")
      }]
    currentKey: valueVisualizerType
    onSelected: key => valueVisualizerType = key
    minimumWidth: 200 * scaling
  }

  NComboBox {
    label: I18n.tr("bar.widget-settings.media-mini.scrolling-mode")
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

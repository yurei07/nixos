import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets
import qs.Modules.SettingsPanel.Bar

ColumnLayout {
  id: root

  // Handler for drag start - disables panel background clicks
  function handleDragStart() {
    var panel = PanelService.getPanel("settingsPanel")
    if (panel && panel.disableBackgroundClick) {
      panel.disableBackgroundClick()
    }
  }

  // Handler for drag end - re-enables panel background clicks
  function handleDragEnd() {
    var panel = PanelService.getPanel("settingsPanel")
    if (panel && panel.enableBackgroundClick) {
      panel.enableBackgroundClick()
    }
  }

  ColumnLayout {
    spacing: Style.marginL * scaling

    RowLayout {
      NComboBox {
        Layout.fillWidth: true
        label: "Bar Position"
        description: "Choose where to place the bar on the screen."
        model: ListModel {
          ListElement {
            key: "top"
            name: "Top"
          }
          ListElement {
            key: "bottom"
            name: "Bottom"
          }
        }
        currentKey: Settings.data.bar.position
        onSelected: key => Settings.data.bar.position = key
      }
    }

    ColumnLayout {
      spacing: Style.marginXXS * scaling
      Layout.fillWidth: true

      NText {
        text: "Background Opacity"
        font.pointSize: Style.fontSizeL * scaling
        font.weight: Style.fontWeightBold
        color: Color.mOnSurface
      }

      NText {
        text: "Adjust the background opacity of the bar."
        font.pointSize: Style.fontSizeXS * scaling
        color: Color.mOnSurfaceVariant
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
      }

      RowLayout {
        NSlider {
          Layout.fillWidth: true
          from: 0
          to: 1
          stepSize: 0.01
          value: Settings.data.bar.backgroundOpacity
          onMoved: Settings.data.bar.backgroundOpacity = value
          cutoutColor: Color.mSurface
        }

        NText {
          text: Math.floor(Settings.data.bar.backgroundOpacity * 100) + "%"
          Layout.alignment: Qt.AlignVCenter
          Layout.leftMargin: Style.marginS * scaling
          color: Color.mOnSurface
        }
      }
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginXL * scaling
    Layout.bottomMargin: Style.marginXL * scaling
  }

  // Widgets Management Section
  ColumnLayout {
    spacing: Style.marginXXS * scaling
    Layout.fillWidth: true

    NText {
      text: "Widgets Positioning"
      font.pointSize: Style.fontSizeXXL * scaling
      font.weight: Style.fontWeightBold
      color: Color.mSecondary
      Layout.bottomMargin: Style.marginS * scaling
    }

    NText {
      text: "Drag and drop widgets to reorder them within each section, or use the add/remove buttons to manage widgets."
      font.pointSize: Style.fontSizeM * scaling
      color: Color.mOnSurfaceVariant
      wrapMode: Text.WordWrap
      Layout.fillWidth: true
    }

    // Bar Sections
    ColumnLayout {
      Layout.fillWidth: true
      Layout.fillHeight: true
      Layout.topMargin: Style.marginM * scaling
      spacing: Style.marginM * scaling

      // Left Section
      BarSectionEditor {
        sectionName: "Left"
        sectionId: "left"
        widgetModel: Settings.data.bar.widgets.left
        availableWidgets: availableWidgets
        onAddWidget: (widgetId, section) => _addWidgetToSection(widgetId, section)
        onRemoveWidget: (section, index) => _removeWidgetFromSection(section, index)
        onReorderWidget: (section, fromIndex, toIndex) => _reorderWidgetInSection(section, fromIndex, toIndex)
        onUpdateWidgetSettings: (section, index, settings) => _updateWidgetSettingsInSection(section, index, settings)
        onDragPotentialStarted: root.handleDragStart()
        onDragPotentialEnded: root.handleDragEnd()
      }

      // Center Section
      BarSectionEditor {
        sectionName: "Center"
        sectionId: "center"
        widgetModel: Settings.data.bar.widgets.center
        availableWidgets: availableWidgets
        onAddWidget: (widgetId, section) => _addWidgetToSection(widgetId, section)
        onRemoveWidget: (section, index) => _removeWidgetFromSection(section, index)
        onReorderWidget: (section, fromIndex, toIndex) => _reorderWidgetInSection(section, fromIndex, toIndex)
        onUpdateWidgetSettings: (section, index, settings) => _updateWidgetSettingsInSection(section, index, settings)
        onDragPotentialStarted: root.handleDragStart()
        onDragPotentialEnded: root.handleDragEnd()
      }

      // Right Section
      BarSectionEditor {
        sectionName: "Right"
        sectionId: "right"
        widgetModel: Settings.data.bar.widgets.right
        availableWidgets: availableWidgets
        onAddWidget: (widgetId, section) => _addWidgetToSection(widgetId, section)
        onRemoveWidget: (section, index) => _removeWidgetFromSection(section, index)
        onReorderWidget: (section, fromIndex, toIndex) => _reorderWidgetInSection(section, fromIndex, toIndex)
        onUpdateWidgetSettings: (section, index, settings) => _updateWidgetSettingsInSection(section, index, settings)
        onDragPotentialStarted: root.handleDragStart()
        onDragPotentialEnded: root.handleDragEnd()
      }
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginXL * scaling
    Layout.bottomMargin: Style.marginXL * scaling
  }

  // ---------------------------------
  // Signal functions
  // ---------------------------------
  function _addWidgetToSection(widgetId, section) {
    var newWidget = {
      "id": widgetId
    }
    if (BarWidgetRegistry.widgetHasUserSettings(widgetId)) {
      var metadata = BarWidgetRegistry.widgetMetadata[widgetId]
      if (metadata) {
        Object.keys(metadata).forEach(function (key) {
          if (key !== "allowUserSettings") {
            newWidget[key] = metadata[key]
          }
        })
      }
    }
    Settings.data.bar.widgets[section].push(newWidget)
  }

  function _removeWidgetFromSection(section, index) {
    if (index >= 0 && index < Settings.data.bar.widgets[section].length) {
      var newArray = Settings.data.bar.widgets[section].slice()
      newArray.splice(index, 1)
      Settings.data.bar.widgets[section] = newArray
    }
  }

  function _reorderWidgetInSection(section, fromIndex, toIndex) {
    if (fromIndex >= 0 && fromIndex < Settings.data.bar.widgets[section].length && toIndex >= 0
        && toIndex < Settings.data.bar.widgets[section].length) {

      // Create a new array to avoid modifying the original
      var newArray = Settings.data.bar.widgets[section].slice()
      var item = newArray[fromIndex]
      newArray.splice(fromIndex, 1)
      newArray.splice(toIndex, 0, item)

      Settings.data.bar.widgets[section] = newArray
      //Logger.log("BarTab", "Widget reordered. New array:", JSON.stringify(newArray))
    }
  }

  function _updateWidgetSettingsInSection(section, index, settings) {
    // Update the widget settings in the Settings data
    Settings.data.bar.widgets[section][index] = settings
    //Logger.log("BarTab", `Updated widget settings for ${settings.id} in ${section} section`)
  }

  // Base list model for all combo boxes
  ListModel {
    id: availableWidgets
  }

  Component.onCompleted: {
    // Fill out availableWidgets ListModel
    availableWidgets.clear()
    BarWidgetRegistry.getAvailableWidgets().forEach(entry => {
                                                      availableWidgets.append({
                                                                                "key": entry,
                                                                                "name": entry
                                                                              })
                                                    })
  }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

ColumnLayout {
  id: root

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

    NToggle {
      label: "Show Active Window's Icon"
      description: "Display the app icon next to the title of the currently focused window."
      checked: Settings.data.bar.showActiveWindowIcon
      onToggled: checked => Settings.data.bar.showActiveWindowIcon = checked
    }

    NToggle {
      label: "Show Battery Percentage"
      description: "Display battery percentage at all times."
      checked: Settings.data.bar.alwaysShowBatteryPercentage
      onToggled: checked => Settings.data.bar.alwaysShowBatteryPercentage = checked
    }

    NToggle {
      label: "Show Network Statistics"
      description: "Display network upload and download speeds in the system monitor."
      checked: Settings.data.bar.showNetworkStats
      onToggled: checked => Settings.data.bar.showNetworkStats = checked
    }

    NToggle {
      label: "Replace SidePanel toggle with distro logo"
      description: "Show distro logo instead of the SidePanel toggle button in the bar."
      checked: Settings.data.bar.useDistroLogo
      onToggled: checked => {
                   Settings.data.bar.useDistroLogo = checked
                 }
    }

    NComboBox {
      label: "Show Workspaces Labels"
      description: "Show the workspace name or index within the workspace indicator."
      model: ListModel {
        ListElement {
          key: "none"
          name: "None"
        }
        ListElement {
          key: "index"
          name: "Index"
        }
        ListElement {
          key: "name"
          name: "Name"
        }
      }
      currentKey: Settings.data.bar.showWorkspaceLabel
      onSelected: key => Settings.data.bar.showWorkspaceLabel = key
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
      color: Color.mOnSurface
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
      NSectionEditor {
        sectionName: "Left"
        sectionId: "left"
        widgetModel: Settings.data.bar.widgets.left
        availableWidgets: availableWidgets
        onAddWidget: (widgetName, section) => addWidgetToSection(widgetName, section)
        onRemoveWidget: (section, index) => removeWidgetFromSection(section, index)
        onReorderWidget: (section, fromIndex, toIndex) => reorderWidgetInSection(section, fromIndex, toIndex)
      }

      // Center Section
      NSectionEditor {
        sectionName: "Center"
        sectionId: "center"
        widgetModel: Settings.data.bar.widgets.center
        availableWidgets: availableWidgets
        onAddWidget: (widgetName, section) => addWidgetToSection(widgetName, section)
        onRemoveWidget: (section, index) => removeWidgetFromSection(section, index)
        onReorderWidget: (section, fromIndex, toIndex) => reorderWidgetInSection(section, fromIndex, toIndex)
      }

      // Right Section
      NSectionEditor {
        sectionName: "Right"
        sectionId: "right"
        widgetModel: Settings.data.bar.widgets.right
        availableWidgets: availableWidgets
        onAddWidget: (widgetName, section) => addWidgetToSection(widgetName, section)
        onRemoveWidget: (section, index) => removeWidgetFromSection(section, index)
        onReorderWidget: (section, fromIndex, toIndex) => reorderWidgetInSection(section, fromIndex, toIndex)
      }
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginXL * scaling
    Layout.bottomMargin: Style.marginXL * scaling
  }

  // Helper functions
  function addWidgetToSection(widgetName, section) {
    //Logger.log("BarTab", "Adding widget", widgetName, "to section", section)
    var sectionArray = Settings.data.bar.widgets[section]

    if (sectionArray) {
      // Create a new array to avoid modifying the original
      var newArray = sectionArray.slice()
      newArray.push(widgetName)
      //Logger.log("BarTab", "Widget added. New array:", JSON.stringify(newArray))

      // Assign the new array
      Settings.data.bar.widgets[section] = newArray
    }
  }

  function removeWidgetFromSection(section, index) {
    // Logger.log("BarTab", "Removing widget from section", section, "at index", index)
    var sectionArray = Settings.data.bar.widgets[section]

    //Logger.log("BarTab", "Current section array:", JSON.stringify(sectionArray))
    if (sectionArray && index >= 0 && index < sectionArray.length) {
      // Create a new array to avoid modifying the original
      var newArray = sectionArray.slice()
      newArray.splice(index, 1)
      //Logger.log("BarTab", "Widget removed. New array:", JSON.stringify(newArray))

      // Assign the new array
      Settings.data.bar.widgets[section] = newArray
    } else {

      //Logger.log("BarTab", "Invalid section or index:", section, index, "array length:",
      //            sectionArray ? sectionArray.length : "null")
    }
  }

  function reorderWidgetInSection(section, fromIndex, toIndex) {
    //Logger.log("BarTab", "Reordering widget in section", section, "from", fromIndex, "to", toIndex)
    var sectionArray = Settings.data.bar.widgets[section]
    if (sectionArray && fromIndex >= 0 && fromIndex < sectionArray.length && toIndex >= 0
        && toIndex < sectionArray.length) {

      // Create a new array to avoid modifying the original
      var newArray = sectionArray.slice()
      var item = newArray[fromIndex]
      newArray.splice(fromIndex, 1)
      newArray.splice(toIndex, 0, item)
      Logger.log("BarTab", "Widget reordered. New array:", JSON.stringify(newArray))

      // Assign the new array
      Settings.data.bar.widgets[section] = newArray
    }
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

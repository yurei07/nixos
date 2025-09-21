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
  property string valueDisplayFormat: widgetData.displayFormat !== undefined ? widgetData.displayFormat : widgetMetadata.displayFormat
  property bool valueUse12h: widgetData.use12HourClock !== undefined ? widgetData.use12HourClock : widgetMetadata.use12HourClock
  property bool valueReverseDayMonth: widgetData.reverseDayMonth !== undefined ? widgetData.reverseDayMonth : widgetMetadata.reverseDayMonth

  function saveSettings() {
    var settings = Object.assign({}, widgetData || {})
    settings.displayFormat = valueDisplayFormat
    settings.use12HourClock = valueUse12h
    settings.reverseDayMonth = valueReverseDayMonth
    return settings
  }

  NComboBox {
    label: "Display Format"
    model: ListModel {
      ListElement {
        key: "time"
        name: "HH:mm"
      }
      ListElement {
        key: "time-seconds"
        name: "HH:mm:ss"
      }
      ListElement {
        key: "time-date"
        name: "HH:mm - Date"
      }
      ListElement {
        key: "time-date-short"
        name: "HH:mm - Short Date"
      }
    }
    currentKey: valueDisplayFormat
    onSelected: key => valueDisplayFormat = key
    minimumWidth: 230 * scaling
  }

  NToggle {
    label: "Use 12-hour clock"
    checked: valueUse12h
    onToggled: checked => valueUse12h = checked
  }

  NToggle {
    label: "Reverse day and month"
    checked: valueReverseDayMonth
    onToggled: checked => valueReverseDayMonth = checked
  }
}

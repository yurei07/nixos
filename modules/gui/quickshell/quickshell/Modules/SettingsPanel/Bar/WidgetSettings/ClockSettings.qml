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
  property bool valueShowDate: widgetData.showDate !== undefined ? widgetData.showDate : widgetMetadata.showDate
  property bool valueUse12h: widgetData.use12HourClock !== undefined ? widgetData.use12HourClock : widgetMetadata.use12HourClock
  property bool valueShowSeconds: widgetData.showSeconds !== undefined ? widgetData.showSeconds : widgetMetadata.showSeconds
  property bool valueReverseDayMonth: widgetData.reverseDayMonth !== undefined ? widgetData.reverseDayMonth : widgetMetadata.reverseDayMonth
  property bool valueCompactMode: widgetData.compactMode !== undefined ? widgetData.compactMode : widgetMetadata.compactMode

  function saveSettings() {
    var settings = Object.assign({}, widgetData || {})
    settings.showDate = valueShowDate
    settings.use12HourClock = valueUse12h
    settings.showSeconds = valueShowSeconds
    settings.reverseDayMonth = valueReverseDayMonth
    settings.compactMode = valueCompactMode
    return settings
  }

  NToggle {
    label: "Show date"
    checked: valueShowDate
    onToggled: checked => valueShowDate = checked
  }

  NToggle {
    label: "Compact Mode"
    checked: valueCompactMode
    onToggled: checked => valueCompactMode = checked
  }

  NToggle {
    label: "Use 12-hour clock"
    checked: valueUse12h
    onToggled: checked => valueUse12h = checked
  }

  NToggle {
    label: "Show seconds"
    checked: valueShowSeconds
    onToggled: checked => valueShowSeconds = checked
  }

  NToggle {
    label: "Reverse day and month"
    checked: valueReverseDayMonth
    onToggled: checked => valueReverseDayMonth = checked
  }
}

import QtQuick
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

Rectangle {
  id: root

  property ShellScreen screen
  property real scaling: 1.0

  // Widget properties passed from Bar.qml for per-instance settings
  property string widgetId: ""
  property string barSection: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0

  property var widgetMetadata: BarWidgetRegistry.widgetMetadata[widgetId]
  property var widgetSettings: {
    var section = barSection.replace("Section", "").toLowerCase()
    if (section && sectionWidgetIndex >= 0) {
      var widgets = Settings.data.bar.widgets[section]
      if (widgets && sectionWidgetIndex < widgets.length) {
        return widgets[sectionWidgetIndex]
      }
    }
    return {}
  }

  // Resolve settings: try user settings or defaults from BarWidgetRegistry
  readonly property bool showDate: widgetSettings.showDate !== undefined ? widgetSettings.showDate : widgetMetadata.showDate
  readonly property bool use12h: widgetSettings.use12HourClock !== undefined ? widgetSettings.use12HourClock : widgetMetadata.use12HourClock
  readonly property bool showSeconds: widgetSettings.showSeconds !== undefined ? widgetSettings.showSeconds : widgetMetadata.showSeconds
  readonly property bool reverseDayMonth: widgetSettings.reverseDayMonth
                                          !== undefined ? widgetSettings.reverseDayMonth : widgetMetadata.reverseDayMonth
  readonly property bool compactMode: widgetSettings.compactMode !== undefined ? widgetSettings.compactMode : widgetMetadata.compactMode

  implicitWidth: (compactMode ? Math.max(timeText.implicitWidth,
                                         dateText.implicitWidth) : clock.width) + Style.marginM * 2 * scaling
  implicitHeight: compactMode ? (timeText.implicitHeight + dateText.implicitHeight + Math.round(
                                   Style.marginXS * scaling) + Math.round(Style.marginM * 2 * scaling)) : Math.round(
                                  Style.capsuleHeight * scaling)
  radius: Math.round(implicitHeight / 2)
  color: Color.mSurfaceVariant

  // Clock with optional compact layout & attached calendar
  Item {
    id: clockContainer
    anchors.fill: parent
    anchors.margins: 0

    Column {
      id: compactColumn
      anchors.centerIn: parent
      spacing: compactMode ? 0 : Math.round(Style.marginXXS * scaling)
      visible: compactMode

      NText {
        id: timeText
        text: {
          const now = Time.date
          const timeFormat = use12h ? (showSeconds ? "h:mm:ss AP" : "h:mm AP") : (showSeconds ? "HH:mm:ss" : "HH:mm")
          return Qt.formatDateTime(now, timeFormat)
        }
        font.pointSize: Style.fontSizeS * scaling
        font.weight: Style.fontWeightBold
        color: Color.mPrimary
        horizontalAlignment: Text.AlignHCenter
        anchors.horizontalCenter: parent.horizontalCenter
      }

      NText {
        id: dateText
        visible: compactMode || showDate
        text: {
          const now = Time.date
          const day = now.getDate()
          const month = now.getMonth() + 1
          const dd = (day < 10 ? "0" + day : "" + day)
          const mm = (month < 10 ? "0" + month : "" + month)
          return reverseDayMonth ? `${mm}/${dd}` : `${dd}/${mm}`
        }
        font.pointSize: Math.max(Style.fontSizeXXS, Style.fontSizeXXS * scaling)
        font.weight: Style.fontWeightRegular
        color: Color.mPrimary
        horizontalAlignment: Text.AlignHCenter
        anchors.horizontalCenter: parent.horizontalCenter
      }
    }

    // Non-compact single-line text
    NText {
      id: clock
      visible: !compactMode
      text: {
        const now = Time.date
        const timeFormat = use12h ? (showSeconds ? "h:mm:ss AP" : "h:mm AP") : (showSeconds ? "HH:mm:ss" : "HH:mm")
        const timeString = Qt.formatDateTime(now, timeFormat)

        if (showDate) {
          let dayName = now.toLocaleDateString(Qt.locale(), "ddd")
          dayName = dayName.charAt(0).toUpperCase() + dayName.slice(1)
          let day = now.getDate()
          let month = now.toLocaleDateString(Qt.locale(), "MMM")
          return timeString + " - " + (reverseDayMonth ? `${dayName}, ${month} ${day}` : `${dayName}, ${day} ${month}`)
        }
        return timeString
      }
      anchors.centerIn: parent
      font.pointSize: Style.fontSizeS * scaling
      font.weight: Style.fontWeightBold
      color: Color.mPrimary
    }
  }

  NTooltip {
    id: tooltip
    text: `${Time.formatDate(reverseDayMonth)}.`
    target: clock
    positionAbove: Settings.data.bar.position === "bottom"
  }

  MouseArea {
    id: clockMouseArea
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    hoverEnabled: true
    onEntered: {
      if (!PanelService.getPanel("calendarPanel")?.active) {
        tooltip.show()
      }
    }
    onExited: {
      tooltip.hide()
    }
    onClicked: {
      tooltip.hide()
      PanelService.getPanel("calendarPanel")?.toggle(this)
    }
  }
}

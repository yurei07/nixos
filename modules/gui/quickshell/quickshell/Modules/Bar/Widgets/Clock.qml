import QtQuick
import QtQuick.Layouts
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
  property string section: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0

  property var widgetMetadata: BarWidgetRegistry.widgetMetadata[widgetId]
  property var widgetSettings: {
    if (section && sectionWidgetIndex >= 0) {
      var widgets = Settings.data.bar.widgets[section]
      if (widgets && sectionWidgetIndex < widgets.length) {
        return widgets[sectionWidgetIndex]
      }
    }
    return {}
  }

  readonly property string barPosition: Settings.data.bar.position
  readonly property bool compact: (Settings.data.bar.density === "compact")

  // Resolve settings: try user settings or defaults from BarWidgetRegistry
  readonly property bool use12h: widgetSettings.use12HourClock !== undefined ? widgetSettings.use12HourClock : widgetMetadata.use12HourClock
  readonly property bool reverseDayMonth: widgetSettings.reverseDayMonth !== undefined ? widgetSettings.reverseDayMonth : widgetMetadata.reverseDayMonth
  readonly property string displayFormat: widgetSettings.displayFormat !== undefined ? widgetSettings.displayFormat : widgetMetadata.displayFormat

  // Use compact mode for vertical bars
  readonly property bool verticalMode: barPosition === "left" || barPosition === "right"

  implicitWidth: verticalMode ? Math.round(Style.capsuleHeight * scaling) : Math.round(layout.implicitWidth + Style.marginM * 2 * scaling)
  implicitHeight: verticalMode ? Math.round(Style.capsuleHeight * 2.5 * scaling) : Math.round(Style.capsuleHeight * scaling) // Match BarPill

  radius: Math.round(Style.radiusS * scaling)
  color: Settings.data.bar.showCapsule ? Color.mSurfaceVariant : Color.transparent

  Item {
    id: clockContainer
    anchors.fill: parent
    anchors.margins: compact ? 0 : Style.marginXS * scaling

    ColumnLayout {
      id: layout
      anchors.centerIn: parent
      spacing: verticalMode ? -2 * scaling : -3 * scaling

      // Compact mode for vertical bars - Time section (HH, MM)
      Repeater {
        model: verticalMode ? 2 : 1
        NText {
          readonly property bool showSeconds: (displayFormat === "time-seconds")
          readonly property bool inlineDate: (displayFormat === "time-date")
          readonly property var now: Time.date

          text: {
            if (verticalMode) {
              // Compact mode: time section (first 2 lines)
              switch (index) {
              case 0:
                // Hours
                if (use12h) {
                  const hours = now.getHours()
                  const displayHours = hours === 0 ? 12 : (hours > 12 ? hours - 12 : hours)
                  return displayHours.toString().padStart(2, '0')
                } else {
                  return now.getHours().toString().padStart(2, '0')
                }
              case 1:
                // Minutes
                return now.getMinutes().toString().padStart(2, '0')
              default:
                return ""
              }
            } else {
              // Normal mode: single line with time
              let timeStr = ""

              if (use12h) {
                // 12-hour format with proper padding and consistent spacing
                const hours = now.getHours()
                const displayHours = hours === 0 ? 12 : (hours > 12 ? hours - 12 : hours)
                const paddedHours = displayHours.toString().padStart(2, '0')
                const minutes = now.getMinutes().toString().padStart(2, '0')
                const ampm = hours < 12 ? 'AM' : 'PM'

                if (showSeconds) {
                  const seconds = now.getSeconds().toString().padStart(2, '0')
                  timeStr = `${paddedHours}:${minutes}:${seconds} ${ampm}`
                } else {
                  timeStr = `${paddedHours}:${minutes} ${ampm}`
                }
              } else {
                // 24-hour format with padding
                const hours = now.getHours().toString().padStart(2, '0')
                const minutes = now.getMinutes().toString().padStart(2, '0')

                if (showSeconds) {
                  const seconds = now.getSeconds().toString().padStart(2, '0')
                  timeStr = `${hours}:${minutes}:${seconds}`
                } else {
                  timeStr = `${hours}:${minutes}`
                }
              }

              // Add inline date if needed
              if (inlineDate) {
                let dayName = now.toLocaleDateString(Qt.locale(), "ddd")
                dayName = dayName.charAt(0).toUpperCase() + dayName.slice(1)
                const day = now.getDate().toString().padStart(2, '0')
                let month = now.toLocaleDateString(Qt.locale(), "MMM")
                timeStr += " - " + (reverseDayMonth ? `${dayName}, ${month} ${day}` : `${dayName}, ${day} ${month}`)
              }

              return timeStr
            }
          }

          font.family: Settings.data.ui.fontFixed
          font.pointSize: verticalMode ? Style.fontSizeXXS * scaling : Style.fontSizeXS * scaling
          font.weight: Style.fontWeightBold
          color: Color.mPrimary
          Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        }
      }

      // Separator line for compact mode (between time and date)
      Rectangle {
        visible: verticalMode
        Layout.preferredWidth: 20 * scaling
        Layout.preferredHeight: 2 * scaling
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 3 * scaling
        Layout.bottomMargin: 3 * scaling
        color: Color.mPrimary
        opacity: 0.3
        radius: 1 * scaling
      }

      // Compact mode for vertical bars - Date section (DD, MM)
      Repeater {
        model: verticalMode ? 2 : 0
        NText {
          readonly property var now: Time.date

          text: {
            if (verticalMode) {
              // Compact mode: date section (last 2 lines)
              switch (index) {
              case 0:
                // Day
                return now.getDate().toString().padStart(2, '0')
              case 1:
                // Month
                return (now.getMonth() + 1).toString().padStart(2, '0')
              default:
                return ""
              }
            }
            return ""
          }

          font.pointSize: Style.fontSizeXXS * scaling
          font.weight: Style.fontWeightBold
          color: Color.mPrimary
          Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        }
      }

      // Second line for normal mode (date)
      NText {
        visible: !verticalMode && (displayFormat === "time-date-short")
        text: {
          const now = Time.date
          const day = now.getDate().toString().padStart(2, '0')
          const month = (now.getMonth() + 1).toString().padStart(2, '0')
          return reverseDayMonth ? `${month}/${day}` : `${day}/${month}`
        }

        // Enable fixed-width font for consistent spacing
        font.family: Settings.data.ui.fontFixed
        font.pointSize: Style.fontSizeXXS * scaling
        font.weight: Style.fontWeightRegular
        color: Color.mPrimary
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
      }
    }
  }

  NTooltip {
    id: tooltip
    text: `${Time.formatDate(reverseDayMonth)}.`
    target: clockContainer
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

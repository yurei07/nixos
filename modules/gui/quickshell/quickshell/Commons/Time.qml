pragma Singleton

import Quickshell
import QtQuick
import qs.Commons
import qs.Services

Singleton {
  id: root

  property var date: new Date()
  property string time: {
    let timeFormat = Settings.data.location.use12HourClock ? "h:mm AP" : "HH:mm"
    let timeString = Qt.formatDateTime(date, timeFormat)

    if (Settings.data.location.showDateWithClock) {
      let dayName = date.toLocaleDateString(Qt.locale(), "ddd")
      dayName = dayName.charAt(0).toUpperCase() + dayName.slice(1)
      let day = date.getDate()
      let month = date.toLocaleDateString(Qt.locale(), "MMM")

      return timeString + " - " + (Settings.data.location.reverseDayMonth ? `${dayName}, ${month} ${day}` : `${dayName}, ${day} ${month}`)
    }

    return timeString
  }
  readonly property string dateString: {
    let now = date
    let dayName = now.toLocaleDateString(Qt.locale(), "ddd")
    dayName = dayName.charAt(0).toUpperCase() + dayName.slice(1)
    let day = now.getDate()
    let suffix
    if (day > 3 && day < 21)
    suffix = 'th'
    else
    switch (day % 10) {
      case 1:
      suffix = "st"
      break
      case 2:
      suffix = "nd"
      break
      case 3:
      suffix = "rd"
      break
      default:
      suffix = "th"
    }
    let month = now.toLocaleDateString(Qt.locale(), "MMMM")
    let year = now.toLocaleDateString(Qt.locale(), "yyyy")
    return `${dayName}, `
    + (Settings.data.location.reverseDayMonth ? `${month} ${day}${suffix} ${year}` : `${day}${suffix} ${month} ${year}`)
  }

  // Returns a Unix Timestamp (in seconds)
  readonly property int timestamp: {
    return Math.floor(date / 1000)
  }


  /**
 * Formats a Date object into a YYYYMMDD-HHMMSS string.
 * @param {Date} [date=new Date()] - The date to format. Defaults to the current date and time.
 * @returns {string} The formatted date string.
 */
  function getFormattedTimestamp(date = new Date()) {
  const year = date.getFullYear()

  // getMonth() is zero-based, so we add 1
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')

  const hours = String(date.getHours()).padStart(2, '0')
  const minutes = String(date.getMinutes()).padStart(2, '0')
  const seconds = String(date.getSeconds()).padStart(2, '0')

  return `${year}${month}${day}-${hours}${minutes}${seconds}`
}

// Format an easy to read approximate duration ex: 4h32m
// Used to display the time remaining on the Battery widget
function formatVagueHumanReadableDuration(totalSeconds) {
  const hours = Math.floor(totalSeconds / 3600)
  const minutes = Math.floor((totalSeconds - (hours * 3600)) / 60)
  const seconds = totalSeconds - (hours * 3600) - (minutes * 60)

  var str = ""
  if (hours) {
    str += hours.toString() + "h"
  }
  if (minutes) {
    str += minutes.toString() + "m"
  }
  if (!hours && !minutes) {
    str += seconds.toString() + "s"
  }
  return str
}

Timer {
  interval: 1000
  repeat: true
  running: true

  onTriggered: root.date = new Date()
}
}

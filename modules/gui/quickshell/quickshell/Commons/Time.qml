pragma Singleton

import Quickshell
import QtQuick
import qs.Commons
import qs.Services

Singleton {
  id: root

  property var date: new Date()

  // Returns a Unix Timestamp (in seconds)
  readonly property int timestamp: {
    return Math.floor(date / 1000)
  }

  function formatDate(reverseDayMonth = true) {
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

    return `${dayName}, ` + (reverseDayMonth ? `${month} ${day}${suffix} ${year}` : `${day}${suffix} ${month} ${year}`)
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
// Used to display the time remaining on the Battery widget, computer uptime, etc..
function formatVagueHumanReadableDuration(totalSeconds) {
  if (typeof totalSeconds !== 'number' || totalSeconds < 0) {
    return '0s'
  }

  // Floor the input to handle decimal seconds
  totalSeconds = Math.floor(totalSeconds)

  const days = Math.floor(totalSeconds / 86400)
  const hours = Math.floor((totalSeconds % 86400) / 3600)
  const minutes = Math.floor((totalSeconds % 3600) / 60)
  const seconds = totalSeconds % 60

  const parts = []
  if (days)
    parts.push(`${days}d`)
  if (hours)
    parts.push(`${hours}h`)
  if (minutes)
    parts.push(`${minutes}m`)

  // Only show seconds if no hours and no minutes
  if (!hours && !minutes) {
    parts.push(`${seconds}s`)
  }

  return parts.join('')
}

Timer {
  interval: 1000
  repeat: true
  running: true

  onTriggered: root.date = new Date()
}
}

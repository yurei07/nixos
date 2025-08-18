import QtQuick
import qs.Commons
import qs.Services
import qs.Widgets

// Clock Icon with attached calendar
NClock {
  id: root

  NTooltip {
    id: tooltip
    text: Time.dateString
    target: root
  }

  onEntered: {
    if (!calendarPanel.isLoaded) {
      tooltip.show()
    }
  }
  onExited: {
    tooltip.hide()
  }
  onClicked: {
    tooltip.hide()
    calendarPanel.isLoaded = !calendarPanel.isLoaded
  }
}

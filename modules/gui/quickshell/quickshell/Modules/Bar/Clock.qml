import QtQuick
import qs.Commons
import qs.Services
import qs.Widgets

// Clock Icon with attached calendar
Rectangle {
  id: root
  width: clock.width + Style.marginM * 2 * scaling
  height: Math.round(Style.capsuleHeight * scaling)
  radius: Math.round(Style.radiusM * scaling)
  color: Color.mSurfaceVariant

  NClock {
    id: clock
    anchors.verticalCenter: parent.verticalCenter
    anchors.horizontalCenter: parent.horizontalCenter

    NTooltip {
      id: tooltip
      text: Time.dateString
      target: clock
      positionAbove: Settings.data.bar.position === "bottom"
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
}

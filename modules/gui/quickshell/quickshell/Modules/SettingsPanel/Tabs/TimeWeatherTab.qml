import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

ColumnLayout {
  id: root

  // Location section
  RowLayout {
    Layout.fillWidth: true
    spacing: Style.marginL * scaling

    NTextInput {
      label: "Location name"
      description: "Choose a known location near you."
      text: Settings.data.location.name
      placeholderText: "Enter the location name"
      onEditingFinished: {
        // Verify the location has really changed to avoid extra resets
        var newLocation = text.trim()
        if (newLocation != Settings.data.location.name) {
          Settings.data.location.name = newLocation
          LocationService.resetWeather()
        }
      }
      Layout.maximumWidth: 420 * scaling
    }

    NText {
      visible: LocationService.coordinatesReady
      text: `${LocationService.stableName} (${LocationService.displayCoordinates})`
      font.pointSize: Style.fontSizeS * scaling
      color: Color.mOnSurfaceVariant
      verticalAlignment: Text.AlignVCenter
      horizontalAlignment: Text.AlignRight
      Layout.alignment: Qt.AlignBottom
      Layout.bottomMargin: 12 * scaling
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginXL * scaling
    Layout.bottomMargin: Style.marginXL * scaling
  }

  // Time section
  ColumnLayout {
    spacing: Style.marginL * scaling
    Layout.fillWidth: true

    NText {
      text: "Time Format"
      font.pointSize: Style.fontSizeXXL * scaling
      font.weight: Style.fontWeightBold
      color: Color.mSecondary
    }

    NToggle {
      label: "Use 12-Hour Clock"
      description: "Display time in 12-hour format (AM/PM) instead of 24-hour."
      checked: Settings.data.location.use12HourClock
      onToggled: checked => Settings.data.location.use12HourClock = checked
    }

    NToggle {
      label: "Reverse Day/Month"
      description: "Display date as dd/mm instead of mm/dd."
      checked: Settings.data.location.reverseDayMonth
      onToggled: checked => Settings.data.location.reverseDayMonth = checked
    }

    NToggle {
      label: "Show Date with Clock"
      description: "Display date alongside time (e.g., 18:12 - Sat, 23 Aug)."
      checked: Settings.data.location.showDateWithClock
      onToggled: checked => Settings.data.location.showDateWithClock = checked
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginXL * scaling
    Layout.bottomMargin: Style.marginXL * scaling
  }

  // Weather section
  ColumnLayout {
    spacing: Style.marginM * scaling
    Layout.fillWidth: true

    NText {
      text: "Weather"
      font.pointSize: Style.fontSizeXXL * scaling
      font.weight: Style.fontWeightBold
      color: Color.mSecondary
    }

    NToggle {
      label: "Use Fahrenheit"
      description: "Display temperature in Fahrenheit instead of Celsius."
      checked: Settings.data.location.useFahrenheit
      onToggled: checked => Settings.data.location.useFahrenheit = checked
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginXL * scaling
    Layout.bottomMargin: Style.marginXL * scaling
  }
}

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
      text: Settings.data.location.name || Settings.defaultLocation
      placeholderText: "Enter the location name"
      onEditingFinished: {
        // Verify the location has really changed to avoid extra resets
        var newLocation = text.trim()
        // If empty, set to default location
        if (newLocation === "") {
          newLocation = Settings.defaultLocation
          text = Settings.defaultLocation // Update the input field to show the default
        }
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
}

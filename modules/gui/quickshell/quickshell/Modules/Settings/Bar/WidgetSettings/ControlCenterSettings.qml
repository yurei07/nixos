import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
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
  property string valueIcon: widgetData.icon !== undefined ? widgetData.icon : widgetMetadata.icon
  property bool valueUseDistroLogo: widgetData.useDistroLogo !== undefined ? widgetData.useDistroLogo : widgetMetadata.useDistroLogo
  property string valueCustomIconPath: widgetData.customIconPath !== undefined ? widgetData.customIconPath : ""

  function saveSettings() {
    var settings = Object.assign({}, widgetData || {})
    settings.icon = valueIcon
    settings.useDistroLogo = valueUseDistroLogo
    settings.customIconPath = valueCustomIconPath
    return settings
  }

  NToggle {
    label: I18n.tr("bar.widget-settings.control-center.use-distro-logo")
    checked: valueUseDistroLogo
    onToggled: {
      valueUseDistroLogo = checked
      if (checked) {
        valueCustomIconPath = ""
        valueIcon = ""
      }
    }
  }

  RowLayout {
    spacing: Style.marginM * scaling

    NLabel {
      label: I18n.tr("bar.widget-settings.control-center.icon.label")
      description: I18n.tr("bar.widget-settings.control-center.icon.description")
    }

    NImageCircled {
      Layout.alignment: Qt.AlignVCenter
      imagePath: valueCustomIconPath
      visible: valueCustomIconPath !== ""
      width: Style.fontSizeXL * 2 * scaling
      height: Style.fontSizeXL * 2 * scaling
    }

    NIcon {
      Layout.alignment: Qt.AlignVCenter
      icon: valueIcon
      font.pointSize: Style.fontSizeXXL * 1.5 * scaling
      visible: valueIcon !== "" && valueCustomIconPath === ""
    }
  }

  RowLayout {
    spacing: Style.marginM * scaling
    NButton {
      enabled: !valueUseDistroLogo
      text: I18n.tr("bar.widget-settings.control-center.browse-library")
      onClicked: iconPicker.open()
    }

    NButton {
      enabled: !valueUseDistroLogo
      text: I18n.tr("bar.widget-settings.control-center.browse-file")
      onClicked: imagePicker.openFilePicker()
    }
  }

  NIconPicker {
    id: iconPicker
    initialIcon: valueIcon
    onIconSelected: iconName => {
                      valueIcon = iconName
                      valueCustomIconPath = ""
                    }
  }

  NFilePicker {
    id: imagePicker
    title: I18n.tr("bar.widget-settings.control-center.select-custom-icon")
    selectionMode: "files"
    nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.gif", "*.pnm", "*.bmp"]
    initialPath: Quickshell.env("HOME")
    onAccepted: paths => {
                  if (paths.length > 0) {
                    valueCustomIconPath = paths[0] // Use first selected file
                  }
                }
  }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

ColumnLayout {
  id: root

  NHeader {
    label: I18n.tr("settings.general.profile.section.label")
    description: I18n.tr("settings.general.profile.section.description")
  }

  // Profile section
  RowLayout {
    Layout.fillWidth: true
    spacing: Style.marginL * scaling

    // Avatar preview
    NImageCircled {
      width: 108 * scaling
      height: 108 * scaling
      imagePath: Settings.data.general.avatarImage
      fallbackIcon: "person"
      borderColor: Color.mPrimary
      borderWidth: Math.max(1, Style.borderM * scaling)
      Layout.alignment: Qt.AlignTop
    }

    NTextInputButton {
      label: I18n.tr("settings.general.profile.picture.label", {
                       "user": Quickshell.env("USER" || "User")
                     })
      description: I18n.tr("settings.general.profile.picture.description")
      text: Settings.data.general.avatarImage
      placeholderText: I18n.tr("placeholders.profile-picture-path")
      buttonIcon: "photo"
      buttonTooltip: "Browse for avatar image"
      onInputEditingFinished: Settings.data.general.avatarImage = text
      onButtonClicked: {
        avatarPicker.openFilePicker()
      }
    }
  }

  NFilePicker {
    id: avatarPicker
    title: I18n.tr("settings.general.profile.select-avatar")
    selectionMode: "files"
    initialPath: Settings.data.general.avatarImage.substr(0, Settings.data.general.avatarImage.lastIndexOf("/")) || Quickshell.env("HOME")
    nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.gif", "*.pnm", "*.bmp"]
    onAccepted: paths => {
                  if (paths.length > 0) {
                    Settings.data.general.avatarImage = paths[0]
                  }
                }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginXL * scaling
    Layout.bottomMargin: Style.marginXL * scaling
  }

  // User Interface
  ColumnLayout {
    spacing: Style.marginL * scaling
    Layout.fillWidth: true

    NHeader {
      label: I18n.tr("settings.general.ui.section.label")
      description: I18n.tr("settings.general.ui.section.description")
    }

    NToggle {
      label: I18n.tr("settings.general.ui.dim-desktop.label")
      description: I18n.tr("settings.general.ui.dim-desktop.description")
      checked: Settings.data.general.dimDesktop
      onToggled: checked => Settings.data.general.dimDesktop = checked
    }

    ColumnLayout {
      spacing: Style.marginXXS * scaling
      Layout.fillWidth: true

      NLabel {
        label: I18n.tr("settings.general.ui.border-radius.label")
        description: I18n.tr("settings.general.ui.border-radius.description")
      }

      NValueSlider {
        Layout.fillWidth: true
        from: 0
        to: 1
        stepSize: 0.01
        value: Settings.data.general.radiusRatio
        onMoved: value => Settings.data.general.radiusRatio = value
        text: Math.floor(Settings.data.general.radiusRatio * 100) + "%"
      }
    }

    // Animation Speed
    ColumnLayout {
      spacing: Style.marginXXS * scaling
      Layout.fillWidth: true

      NLabel {
        label: I18n.tr("settings.general.ui.animation-speed.label")
        description: I18n.tr("settings.general.ui.animation-speed.description")
      }

      NValueSlider {
        Layout.fillWidth: true
        from: 0.1
        to: 2.0
        stepSize: 0.01
        value: Settings.data.general.animationSpeed
        onMoved: value => Settings.data.general.animationSpeed = value
        text: Math.round(Settings.data.general.animationSpeed * 100) + "%"
      }
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginXL * scaling
    Layout.bottomMargin: Style.marginXL * scaling
  }

  // Dock
  ColumnLayout {
    spacing: Style.marginL * scaling
    Layout.fillWidth: true

    NHeader {
      label: I18n.tr("settings.general.screen-corners.section.label")
      description: I18n.tr("settings.general.screen-corners.section.description")
    }

    NToggle {
      label: I18n.tr("settings.general.screen-corners.show-corners.label")
      description: I18n.tr("settings.general.screen-corners.show-corners.description")
      checked: Settings.data.general.showScreenCorners
      onToggled: checked => Settings.data.general.showScreenCorners = checked
    }

    NToggle {
      label: I18n.tr("settings.general.screen-corners.solid-black.label")
      description: I18n.tr("settings.general.screen-corners.solid-black.description")
      checked: Settings.data.general.forceBlackScreenCorners
      onToggled: checked => Settings.data.general.forceBlackScreenCorners = checked
    }

    ColumnLayout {
      spacing: Style.marginXXS * scaling
      Layout.fillWidth: true

      NLabel {
        label: I18n.tr("settings.general.screen-corners.radius.label")
        description: I18n.tr("settings.general.screen-corners.radius.description")
      }

      NValueSlider {
        Layout.fillWidth: true
        from: 0
        to: 2
        stepSize: 0.01
        value: Settings.data.general.screenRadiusRatio
        onMoved: value => Settings.data.general.screenRadiusRatio = value
        text: Math.floor(Settings.data.general.screenRadiusRatio * 100) + "%"
      }
    }
  }
  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginXL * scaling
    Layout.bottomMargin: Style.marginXL * scaling
  }

  // Fonts
  ColumnLayout {
    spacing: Style.marginL * scaling
    Layout.fillWidth: true

    NHeader {
      label: I18n.tr("settings.general.fonts.section.label")
      description: I18n.tr("settings.general.fonts.section.description")
    }

    // Font configuration section
    ColumnLayout {
      spacing: Style.marginL * scaling
      Layout.fillWidth: true

      NSearchableComboBox {
        label: I18n.tr("settings.general.fonts.default.label")
        description: I18n.tr("settings.general.fonts.default.description")
        model: FontService.availableFonts
        currentKey: Settings.data.ui.fontDefault
        placeholder: I18n.tr("settings.general.fonts.default.placeholder")
        searchPlaceholder: I18n.tr("settings.general.fonts.default.search-placeholder")
        popupHeight: 420 * scaling
        minimumWidth: 300 * scaling
        onSelected: function (key) {
          Settings.data.ui.fontDefault = key
        }
      }

      NSearchableComboBox {
        label: I18n.tr("settings.general.fonts.monospace.label")
        description: I18n.tr("settings.general.fonts.monospace.description")
        model: FontService.monospaceFonts
        currentKey: Settings.data.ui.fontFixed
        placeholder: I18n.tr("settings.general.fonts.monospace.placeholder")
        searchPlaceholder: I18n.tr("settings.general.fonts.monospace.search-placeholder")
        popupHeight: 320 * scaling
        minimumWidth: 300 * scaling
        onSelected: function (key) {
          Settings.data.ui.fontFixed = key
        }
      }

      NSearchableComboBox {
        label: I18n.tr("settings.general.fonts.accent.label")
        description: I18n.tr("settings.general.fonts.accent.description")
        model: FontService.displayFonts
        currentKey: Settings.data.ui.fontBillboard
        placeholder: I18n.tr("settings.general.fonts.accent.placeholder")
        searchPlaceholder: I18n.tr("settings.general.fonts.accent.search-placeholder")
        popupHeight: 320 * scaling
        minimumWidth: 300 * scaling
        onSelected: function (key) {
          Settings.data.ui.fontBillboard = key
        }
      }
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginXL * scaling
    Layout.bottomMargin: Style.marginXL * scaling
  }
}

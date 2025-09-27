import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import qs.Commons
import qs.Widgets
import qs.Services

ColumnLayout {
  id: root
  spacing: Style.marginM * scaling

  property var widgetData: null
  property var widgetMetadata: null

  property string valueIcon: widgetData.icon !== undefined ? widgetData.icon : widgetMetadata.icon

  function saveSettings() {
    var settings = Object.assign({}, widgetData || {})
    settings.icon = valueIcon
    settings.leftClickExec = leftClickExecInput.text
    settings.rightClickExec = rightClickExecInput.text
    settings.middleClickExec = middleClickExecInput.text
    settings.textCommand = textCommandInput.text
    settings.textIntervalMs = parseInt(textIntervalInput.text || textIntervalInput.placeholderText, 10)
    return settings
  }

  RowLayout {
    spacing: Style.marginM * scaling

    NLabel {
      label: I18n.tr("bar.widget-settings.custom-button.icon.label")
      description: I18n.tr("bar.widget-settings.custom-button.icon.description")
    }

    NIcon {
      Layout.alignment: Qt.AlignVCenter
      icon: valueIcon
      font.pointSize: Style.fontSizeXL * scaling
      visible: valueIcon !== ""
    }

    NButton {
      text: I18n.tr("bar.widget-settings.custom-button.browse")
      onClicked: iconPicker.open()
    }
  }

  NIconPicker {
    id: iconPicker
    initialIcon: valueIcon
    onIconSelected: function (iconName) {
      valueIcon = iconName
    }
  }

  NTextInput {
    id: leftClickExecInput
    Layout.fillWidth: true
    label: I18n.tr("bar.widget-settings.custom-button.left-click")
    placeholderText: I18n.tr("placeholders.enter-command")
    text: widgetData?.leftClickExec || widgetMetadata.leftClickExec
  }

  NTextInput {
    id: rightClickExecInput
    Layout.fillWidth: true
    label: I18n.tr("bar.widget-settings.custom-button.right-click")
    placeholderText: I18n.tr("placeholders.enter-command")
    text: widgetData?.rightClickExec || widgetMetadata.rightClickExec
  }

  NTextInput {
    id: middleClickExecInput
    Layout.fillWidth: true
    label: I18n.tr("bar.widget-settings.custom-button.middle-click")
    placeholderText: I18n.tr("placeholders.enter-command")
    text: widgetData.middleClickExec || widgetMetadata.middleClickExec
  }

  NDivider {
    Layout.fillWidth: true
  }

  NHeader {
    label: I18n.tr("bar.widget-settings.custom-button.dynamic-text")
  }

  NTextInput {
    id: textCommandInput
    Layout.fillWidth: true
    label: I18n.tr("bar.widget-settings.custom-button.display-command-output.label")
    description: I18n.tr("bar.widget-settings.custom-button.display-command-output.description")
    placeholderText: I18n.tr("placeholders.command-example")
    text: widgetData?.textCommand || widgetMetadata.textCommand
  }

  NTextInput {
    id: textIntervalInput
    Layout.fillWidth: true
    label: I18n.tr("bar.widget-settings.custom-button.refresh-interval.label")
    description: I18n.tr("bar.widget-settings.custom-button.refresh-interval.description")
    placeholderText: String(widgetMetadata.textIntervalMs || 3000)
    text: widgetData && widgetData.textIntervalMs !== undefined ? String(widgetData.textIntervalMs) : ""
  }
}

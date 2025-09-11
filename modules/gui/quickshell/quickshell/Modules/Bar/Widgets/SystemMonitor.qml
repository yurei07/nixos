import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

RowLayout {
  id: root

  property ShellScreen screen
  property real scaling: 1.0

  // Widget properties passed from Bar.qml for per-instance settings
  property string widgetId: ""
  property string barSection: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0

  property var widgetMetadata: BarWidgetRegistry.widgetMetadata[widgetId]
  property var widgetSettings: {
    var section = barSection.replace("Section", "").toLowerCase()
    if (section && sectionWidgetIndex >= 0) {
      var widgets = Settings.data.bar.widgets[section]
      if (widgets && sectionWidgetIndex < widgets.length) {
        return widgets[sectionWidgetIndex]
      }
    }
    return {}
  }

  readonly property bool showCpuUsage: (widgetSettings.showCpuUsage
                                        !== undefined) ? widgetSettings.showCpuUsage : widgetMetadata.showCpuUsage
  readonly property bool showCpuTemp: (widgetSettings.showCpuTemp !== undefined) ? widgetSettings.showCpuTemp : widgetMetadata.showCpuTemp
  readonly property bool showMemoryUsage: (widgetSettings.showMemoryUsage
                                           !== undefined) ? widgetSettings.showMemoryUsage : widgetMetadata.showMemoryUsage
  readonly property bool showMemoryAsPercent: (widgetSettings.showMemoryAsPercent
                                               !== undefined) ? widgetSettings.showMemoryAsPercent : widgetMetadata.showMemoryAsPercent
  readonly property bool showNetworkStats: (widgetSettings.showNetworkStats
                                            !== undefined) ? widgetSettings.showNetworkStats : widgetMetadata.showNetworkStats
  readonly property bool showDiskUsage: (widgetSettings.showDiskUsage
                                         !== undefined) ? widgetSettings.showDiskUsage : widgetMetadata.showDiskUsage

  Layout.alignment: Qt.AlignVCenter
  spacing: Style.marginS * scaling

  Rectangle {
    Layout.preferredHeight: Math.round(Style.capsuleHeight * scaling)
    Layout.preferredWidth: mainLayout.implicitWidth + Style.marginM * scaling * 2
    Layout.alignment: Qt.AlignVCenter

    radius: Math.round(Style.radiusM * scaling)
    color: Color.mSurfaceVariant

    RowLayout {
      id: mainLayout
      anchors.centerIn: parent // Better centering than margins
      width: parent.width - Style.marginM * scaling * 2
      spacing: Style.marginS * scaling

      // CPU Usage Component
      Item {
        Layout.preferredWidth: cpuUsageRow.implicitWidth
        Layout.preferredHeight: Math.round(Style.capsuleHeight * scaling)
        Layout.alignment: Qt.AlignVCenter
        visible: showCpuUsage

        RowLayout {
          id: cpuUsageRow
          anchors.centerIn: parent
          spacing: Style.marginXS * scaling

          NIcon {
            icon: "cpu-usage"
            font.pointSize: Style.fontSizeM * scaling
            Layout.alignment: Qt.AlignVCenter
          }

          NText {
            text: `${SystemStatService.cpuUsage}%`
            font.family: Settings.data.ui.fontFixed
            font.pointSize: Style.fontSizeXS * scaling
            font.weight: Style.fontWeightMedium
            Layout.alignment: Qt.AlignVCenter
            verticalAlignment: Text.AlignVCenter
            color: Color.mPrimary
          }
        }
      }

      // CPU Temperature Component
      Item {
        Layout.preferredWidth: cpuTempRow.implicitWidth
        Layout.preferredHeight: Math.round(Style.capsuleHeight * scaling)
        Layout.alignment: Qt.AlignVCenter
        visible: showCpuTemp

        RowLayout {
          id: cpuTempRow
          anchors.centerIn: parent
          spacing: Style.marginXS * scaling

          NIcon {
            icon: "cpu-temperature"
            // Fire is so tall, we need to make it smaller
            font.pointSize: Style.fontSizeS * scaling
            Layout.alignment: Qt.AlignVCenter
          }

          NText {
            text: `${SystemStatService.cpuTemp}°C`
            font.family: Settings.data.ui.fontFixed
            font.pointSize: Style.fontSizeXS * scaling
            font.weight: Style.fontWeightMedium
            Layout.alignment: Qt.AlignVCenter
            verticalAlignment: Text.AlignVCenter
            color: Color.mPrimary
          }
        }
      }

      // Memory Usage Component
      Item {
        Layout.preferredWidth: memoryUsageRow.implicitWidth
        Layout.preferredHeight: Math.round(Style.capsuleHeight * scaling)
        Layout.alignment: Qt.AlignVCenter
        visible: showMemoryUsage

        RowLayout {
          id: memoryUsageRow
          anchors.centerIn: parent
          spacing: Style.marginXS * scaling

          NIcon {
            icon: "memory"
            font.pointSize: Style.fontSizeM * scaling
            Layout.alignment: Qt.AlignVCenter
          }

          NText {
            text: showMemoryAsPercent ? `${SystemStatService.memPercent}%` : `${SystemStatService.memGb}G`
            font.family: Settings.data.ui.fontFixed
            font.pointSize: Style.fontSizeXS * scaling
            font.weight: Style.fontWeightMedium
            Layout.alignment: Qt.AlignVCenter
            verticalAlignment: Text.AlignVCenter
            color: Color.mPrimary
          }
        }
      }

      // Network Download Speed Component
      Item {
        Layout.preferredWidth: networkDownloadRow.implicitWidth
        Layout.preferredHeight: Math.round(Style.capsuleHeight * scaling)
        Layout.alignment: Qt.AlignVCenter
        visible: showNetworkStats

        RowLayout {
          id: networkDownloadRow
          anchors.centerIn: parent
          spacing: Style.marginXS * scaling

          NIcon {
            icon: "download-speed"
            font.pointSize: Style.fontSizeM * scaling
            Layout.alignment: Qt.AlignVCenter
          }

          NText {
            text: SystemStatService.formatSpeed(SystemStatService.rxSpeed)
            font.family: Settings.data.ui.fontFixed
            font.pointSize: Style.fontSizeXS * scaling
            font.weight: Style.fontWeightMedium
            Layout.alignment: Qt.AlignVCenter
            verticalAlignment: Text.AlignVCenter
            color: Color.mPrimary
          }
        }
      }

      // Network Upload Speed Component
      Item {
        Layout.preferredWidth: networkUploadRow.implicitWidth
        Layout.preferredHeight: Math.round(Style.capsuleHeight * scaling)
        Layout.alignment: Qt.AlignVCenter
        visible: showNetworkStats

        RowLayout {
          id: networkUploadRow
          anchors.centerIn: parent
          spacing: Style.marginXS * scaling

          NIcon {
            icon: "upload-speed"
            font.pointSize: Style.fontSizeM * scaling
            Layout.alignment: Qt.AlignVCenter
          }

          NText {
            text: SystemStatService.formatSpeed(SystemStatService.txSpeed)
            font.family: Settings.data.ui.fontFixed
            font.pointSize: Style.fontSizeXS * scaling
            font.weight: Style.fontWeightMedium
            Layout.alignment: Qt.AlignVCenter
            verticalAlignment: Text.AlignVCenter
            color: Color.mPrimary
          }
        }
      }

      // Disk Usage Component (primary drive)
      Item {
        Layout.preferredWidth: diskUsageRow.implicitWidth
        Layout.preferredHeight: Math.round(Style.capsuleHeight * scaling)
        Layout.alignment: Qt.AlignVCenter
        visible: showDiskUsage

        RowLayout {
          id: diskUsageRow
          anchors.centerIn: parent
          spacing: Style.marginXS * scaling

          NIcon {
            icon: "storage"
            font.pointSize: Style.fontSizeM * scaling
            Layout.alignment: Qt.AlignVCenter
          }

          NText {
            text: `${SystemStatService.diskPercent}%`
            font.family: Settings.data.ui.fontFixed
            font.pointSize: Style.fontSizeXS * scaling
            font.weight: Style.fontWeightMedium
            Layout.alignment: Qt.AlignVCenter
            verticalAlignment: Text.AlignVCenter
            color: Color.mPrimary
          }
        }
      }
    }
  }
}

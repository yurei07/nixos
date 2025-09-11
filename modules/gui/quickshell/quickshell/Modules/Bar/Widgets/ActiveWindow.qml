import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
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

  readonly property bool showIcon: (widgetSettings.showIcon !== undefined) ? widgetSettings.showIcon : widgetMetadata.showIcon

  // 6% of total width
  readonly property real minWidth: Math.max(1, screen.width * 0.06)
  readonly property real maxWidth: minWidth * 2

  function getTitle() {
    return CompositorService.focusedWindowTitle !== "(No active window)" ? CompositorService.focusedWindowTitle : ""
  }

  Layout.alignment: Qt.AlignVCenter
  spacing: Style.marginS * scaling
  visible: getTitle() !== ""

  function getAppIcon() {
    // Try CompositorService first
    const focusedWindow = CompositorService.getFocusedWindow()
    if (focusedWindow && focusedWindow.appId) {
      const idValue = focusedWindow.appId
      const normalizedId = (typeof idValue === 'string') ? idValue : String(idValue)
      return AppIcons.iconForAppId(normalizedId.toLowerCase())
    }

    // Fallback to ToplevelManager
    if (ToplevelManager && ToplevelManager.activeToplevel) {
      const activeToplevel = ToplevelManager.activeToplevel
      if (activeToplevel.appId) {
        const idValue2 = activeToplevel.appId
        const normalizedId2 = (typeof idValue2 === 'string') ? idValue2 : String(idValue2)
        return AppIcons.iconForAppId(normalizedId2.toLowerCase())
      }
    }

    return ""
  }

  // A hidden text element to safely measure the full title width
  NText {
    id: fullTitleMetrics
    visible: false
    text: getTitle()
    font.pointSize: Style.fontSizeS * scaling
    font.weight: Style.fontWeightMedium
  }

  Rectangle {
    id: windowTitleRect
    visible: root.visible
    Layout.preferredWidth: contentLayout.implicitWidth + Style.marginM * 2 * scaling
    Layout.preferredHeight: Math.round(Style.capsuleHeight * scaling)
    radius: Math.round(Style.radiusM * scaling)
    color: Color.mSurfaceVariant

    Item {
      id: mainContainer
      anchors.fill: parent
      anchors.leftMargin: Style.marginS * scaling
      anchors.rightMargin: Style.marginS * scaling
      clip: true

      RowLayout {
        id: contentLayout
        anchors.centerIn: parent
        spacing: Style.marginS * scaling

        // Window icon
        Item {
          Layout.preferredWidth: Style.fontSizeL * scaling * 1.2
          Layout.preferredHeight: Style.fontSizeL * scaling * 1.2
          Layout.alignment: Qt.AlignVCenter
          visible: getTitle() !== "" && showIcon

          IconImage {
            id: windowIcon
            anchors.fill: parent
            source: getAppIcon()
            asynchronous: true
            smooth: true
            visible: source !== ""
          }
        }

        NText {
          id: titleText
          Layout.preferredWidth: {
            if (mouseArea.containsMouse) {
              return Math.round(Math.min(fullTitleMetrics.contentWidth, root.maxWidth * scaling))
            } else {
              return Math.round(Math.min(fullTitleMetrics.contentWidth, root.minWidth * scaling))
            }
          }
          Layout.alignment: Qt.AlignVCenter
          horizontalAlignment: Text.AlignLeft
          text: getTitle()
          font.pointSize: Style.fontSizeS * scaling
          font.weight: Style.fontWeightMedium
          elide: mouseArea.containsMouse ? Text.ElideNone : Text.ElideRight
          verticalAlignment: Text.AlignVCenter
          color: Color.mPrimary
          clip: true

          Behavior on Layout.preferredWidth {
            NumberAnimation {
              duration: Style.animationSlow
              easing.type: Easing.InOutCubic
            }
          }
        }
      }

      // Mouse area for hover detection
      MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
      }
    }
  }

  Connections {
    target: CompositorService
    function onActiveWindowChanged() {
      windowIcon.source = Qt.binding(getAppIcon)
    }
    function onWindowListChanged() {
      windowIcon.source = Qt.binding(getAppIcon)
    }
  }
}

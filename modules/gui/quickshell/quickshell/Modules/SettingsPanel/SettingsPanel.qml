import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Modules.SettingsPanel.Tabs as Tabs
import qs.Commons
import qs.Services
import qs.Widgets

NPanel {
  id: root

  panelWidth: Math.max(screen?.width * 0.5, 1280) * scaling
  panelHeight: Math.max(screen?.height * 0.5, 720) * scaling
  panelAnchorCentered: true

  // Tabs enumeration, order is NOT relevant
  enum Tab {
    About,
    AudioService,
    Bar,
    Launcher,
    Brightness,
    ColorScheme,
    Display,
    General,
    Network,
    ScreenRecorder,
    TimeWeather,
    Wallpaper,
    WallpaperSelector
  }

  property int requestedTab: SettingsPanel.Tab.General
  property int currentTabIndex: 0

  Component {
    id: generalTab
    Tabs.GeneralTab {}
  }
  Component {
    id: launcherTab
    Tabs.LauncherTab {}
  }
  Component {
    id: barTab
    Tabs.BarTab {}
  }
  Component {
    id: audioTab
    Tabs.AudioTab {}
  }
  Component {
    id: brightnessTab
    Tabs.BrightnessTab {}
  }
  Component {
    id: displayTab
    Tabs.DisplayTab {}
  }
  Component {
    id: networkTab
    Tabs.NetworkTab {}
  }
  Component {
    id: timeWeatherTab
    Tabs.TimeWeatherTab {}
  }
  Component {
    id: colorSchemeTab
    Tabs.ColorSchemeTab {}
  }
  Component {
    id: wallpaperTab
    Tabs.WallpaperTab {}
  }
  Component {
    id: wallpaperSelectorTab
    Tabs.WallpaperSelectorTab {}
  }
  Component {
    id: screenRecorderTab
    Tabs.ScreenRecorderTab {}
  }
  Component {
    id: aboutTab
    Tabs.AboutTab {}
  }

  // Order *DOES* matter
  property var tabsModel: [{
      "id": SettingsPanel.Tab.General,
      "label": "General",
      "icon": "tune",
      "source": generalTab
    }, {
      "id": SettingsPanel.Tab.Bar,
      "label": "Bar",
      "icon": "web_asset",
      "source": barTab
    }, {
      "id": SettingsPanel.Tab.Launcher,
      "label": "Launcher",
      "icon": "apps",
      "source": launcherTab
    }, {
      "id": SettingsPanel.Tab.AudioService,
      "label": "Audio",
      "icon": "volume_up",
      "source": audioTab
    }, {
      "id": SettingsPanel.Tab.Display,
      "label": "Display",
      "icon": "monitor",
      "source": displayTab
    }, {
      "id": SettingsPanel.Tab.Network,
      "label": "Network",
      "icon": "lan",
      "source": networkTab
    }, {
      "id": SettingsPanel.Tab.Brightness,
      "label": "Brightness",
      "icon": "brightness_6",
      "source": brightnessTab
    }, {
      "id": SettingsPanel.Tab.TimeWeather,
      "label": "Time & Weather",
      "icon": "schedule",
      "source": timeWeatherTab
    }, {
      "id": SettingsPanel.Tab.ColorScheme,
      "label": "Color Scheme",
      "icon": "palette",
      "source": colorSchemeTab
    }, {
      "id": SettingsPanel.Tab.Wallpaper,
      "label": "Wallpaper",
      "icon": "image",
      "source": wallpaperTab
    }, {
      "id": SettingsPanel.Tab.WallpaperSelector,
      "label": "Wallpaper Selector",
      "icon": "wallpaper_slideshow",
      "source": wallpaperSelectorTab
    }, {
      "id": SettingsPanel.Tab.ScreenRecorder,
      "label": "Screen Recorder",
      "icon": "videocam",
      "source": screenRecorderTab
    }, {
      "id": SettingsPanel.Tab.About,
      "label": "About",
      "icon": "info",
      "source": aboutTab
    }]

  // When the panel opens, choose the appropriate tab
  onOpened: {
    var initialIndex = SettingsPanel.Tab.General
    if (root.requestedTab !== null) {
      for (var i = 0; i < root.tabsModel.length; i++) {
        if (root.tabsModel[i].id === root.requestedTab) {
          initialIndex = i
          break
        }
      }
    }
    // Now that the UI is settled, set the current tab index.
    root.currentTabIndex = initialIndex
  }

  panelContent: Rectangle {
    anchors.fill: parent
    anchors.margins: Style.marginL * scaling
    color: Color.transparent

    RowLayout {
      anchors.fill: parent
      spacing: Style.marginM * scaling

      Rectangle {
        id: sidebar
        Layout.preferredWidth: Style.sliderWidth * 1.3 * scaling
        Layout.fillHeight: true
        color: Color.mSurfaceVariant
        border.color: Color.mOutline
        border.width: Math.max(1, Style.borderS * scaling)
        radius: Style.radiusM * scaling

        Column {
          anchors.fill: parent
          anchors.margins: Style.marginS * scaling
          spacing: Style.marginXS * 1.5 * scaling

          Repeater {
            id: sections
            model: root.tabsModel
            delegate: Rectangle {
              id: tabItem
              width: parent.width
              height: 32 * scaling
              radius: Style.radiusS * scaling
              color: selected ? Color.mPrimary : (tabItem.hovering ? Color.mTertiary : Color.transparent)
              readonly property bool selected: index === currentTabIndex
              property bool hovering: false
              property color tabTextColor: selected ? Color.mOnPrimary : (tabItem.hovering ? Color.mOnTertiary : Color.mOnSurface)
              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Style.marginS * scaling
                anchors.rightMargin: Style.marginS * scaling
                spacing: Style.marginS * scaling
                // Tab icon on the left side
                NIcon {
                  text: modelData.icon
                  color: tabTextColor
                  font.pointSize: Style.fontSizeL * scaling
                }
                // Tab label on the left side
                NText {
                  text: modelData.label
                  color: tabTextColor
                  font.pointSize: Style.fontSizeM * scaling
                  font.weight: Style.fontWeightBold
                  Layout.fillWidth: true
                }
              }
              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton
                onEntered: tabItem.hovering = true
                onExited: tabItem.hovering = false
                onCanceled: tabItem.hovering = false
                onClicked: currentTabIndex = index
              }
            }
          }
        }
      }

      // Content
      Rectangle {
        id: contentPane
        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: Style.radiusM * scaling
        color: Color.mSurfaceVariant
        border.color: Color.mOutline
        border.width: Math.max(1, Style.borderS * scaling)
        clip: true

        ColumnLayout {
          id: contentLayout
          anchors.fill: parent
          anchors.margins: Style.marginL * scaling
          spacing: Style.marginS * scaling

          RowLayout {
            id: headerRow
            Layout.fillWidth: true
            spacing: Style.marginS * scaling

            // Tab label on the main right side
            NText {
              text: root.tabsModel[currentTabIndex].label
              font.pointSize: Style.fontSizeL * scaling
              font.weight: Style.fontWeightBold
              color: Color.mPrimary
              Layout.fillWidth: true
            }
            NIconButton {
              icon: "close"
              tooltipText: "Close"
              Layout.alignment: Qt.AlignVCenter
              onClicked: root.close()
            }
          }

          NDivider {
            Layout.fillWidth: true
          }

          Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            Repeater {
              model: root.tabsModel

              onItemAdded: function (index, item) {
                item.sourceComponent = root.tabsModel[index].source
              }

              delegate: Loader {
                // All loaders will occupy the same space, stacked on top of each other.
                anchors.fill: parent
                visible: index === root.currentTabIndex
                // The loader is only active (and uses memory) when its page is visible.
                active: visible
              }
            }
          }
        }
      }
    }
  }
}

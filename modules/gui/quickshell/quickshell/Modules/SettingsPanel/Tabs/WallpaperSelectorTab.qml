import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt.labs.folderlistmodel
import qs.Commons
import qs.Services
import qs.Widgets

ColumnLayout {
  id: root
  width: parent.width

  spacing: Style.marginL * scaling

  property list<string> wallpapersList: []
  property string currentWallpaper: ""

  Component.onCompleted: {
    wallpapersList = screen ? WallpaperService.getWallpapersList(screen.name) : []
    currentWallpaper = screen ? WallpaperService.getWallpaper(screen.name) : ""
  }

  Connections {
    target: WallpaperService
    function onWallpaperChanged(screenName, path) {
      if (screenName === screen.name) {
        currentWallpaper = WallpaperService.getWallpaper(screen.name)
      }
    }
    function onWallpaperDirectoryChanged(screenName, directory) {
      if (screenName === screen.name) {
        wallpapersList = WallpaperService.getWallpapersList(screen.name)
        currentWallpaper = WallpaperService.getWallpaper(screen.name)
      }
    }
    function onWallpaperListChanged(screenName, count) {
      if (screenName === screen.name) {
        wallpapersList = WallpaperService.getWallpapersList(screen.name)
        currentWallpaper = WallpaperService.getWallpaper(screen.name)
      }
    }
  }

  // Current wallpaper display
  NText {
    text: "Current Wallpaper"
    font.pointSize: Style.fontSizeXXL * scaling
    font.weight: Style.fontWeightBold
    color: Color.mSecondary
  }

  Rectangle {
    Layout.fillWidth: true
    Layout.preferredHeight: 140 * scaling
    radius: Style.radiusM * scaling
    color: Color.transparent

    NImageRounded {
      anchors.fill: parent
      anchors.margins: Style.marginXS * scaling
      imagePath: currentWallpaper
      fallbackIcon: "image"
      imageRadius: Style.radiusM * scaling
      borderColor: Color.mSecondary
      borderWidth: Style.borderL * 2 * scaling
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginXL * scaling
    Layout.bottomMargin: Style.marginXL * scaling
  }

  // Wallpaper selector
  RowLayout {
    Layout.fillWidth: true

    ColumnLayout {
      Layout.fillWidth: true

      // Wallpaper grid
      NText {
        text: "Wallpaper Selector"
        font.pointSize: Style.fontSizeXXL * scaling
        font.weight: Style.fontWeightBold
        color: Color.mSecondary
      }

      NText {
        text: "Click on a wallpaper to set it as your current wallpaper."
        color: Color.mOnSurfaceVariant
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
      }
    }

    NIconButton {
      icon: "refresh"
      tooltipText: "Refresh wallpaper list"
      onClicked: {
        WallpaperService.refreshWallpapersList()
      }
      Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
    }
  }

  NToggle {
    label: "Apply to all monitors"
    description: "Apply selected wallpaper to all monitors at once."
    checked: Settings.data.wallpaper.setWallpaperOnAllMonitors
    onToggled: checked => Settings.data.wallpaper.setWallpaperOnAllMonitors = checked
    visible: (wallpapersList.length > 0)
  }

  // Wallpaper grid container
  Item {
    visible: !WallpaperService.scanning
    Layout.fillWidth: true
    Layout.preferredHeight: {
      return Math.ceil(wallpapersList.length / wallpaperGridView.columns) * wallpaperGridView.cellHeight
    }

    GridView {
      id: wallpaperGridView
      anchors.fill: parent
      model: wallpapersList

      interactive: false
      clip: true

      property int columns: 4
      property int itemSize: Math.floor((width - leftMargin - rightMargin - (4 * Style.marginS * scaling)) / columns)

      cellWidth: Math.floor((width - leftMargin - rightMargin) / columns)
      cellHeight: Math.floor(itemSize * 0.67) + Style.marginS * scaling

      leftMargin: Style.marginS * scaling
      rightMargin: Style.marginS * scaling
      topMargin: Style.marginS * scaling
      bottomMargin: Style.marginS * scaling

      delegate: Rectangle {
        id: wallpaperItem

        property string wallpaperPath: modelData
        property bool isSelected: screen ? (wallpaperPath === currentWallpaper) : false

        width: wallpaperGridView.itemSize
        height: Math.round(wallpaperGridView.itemSize * 0.67)
        color: Color.transparent

        // NImageCached relies on the image being visible to work properly.
        // MultiEffect relies on the image being invisible to apply effects.
        // That's why we don't have rounded corners here, as we don't want to bring back qt5compat.
        NImageCached {
          id: img
          imagePath: wallpaperPath
          anchors.fill: parent
        }

        // Borders on top
        Rectangle {
          anchors.fill: parent
          color: Color.transparent
          border.color: isSelected ? Color.mSecondary : Color.mSurface
          border.width: Math.max(1, Style.borderL * 1.5 * scaling)
        }

        // Selection tick-mark
        Rectangle {
          anchors.top: parent.top
          anchors.right: parent.right
          anchors.margins: Style.marginS * scaling
          width: 28 * scaling
          height: 28 * scaling
          radius: width / 2
          color: Color.mSecondary
          border.color: Color.mOutline
          border.width: Math.max(1, Style.borderS * scaling)
          visible: isSelected

          NIcon {
            icon: "check"
            font.pointSize: Style.fontSizeM * scaling
            font.weight: Style.fontWeightBold
            color: Color.mOnSecondary
            anchors.centerIn: parent
          }
        }

        // Hover effect
        Rectangle {
          anchors.fill: parent
          color: Color.mSurface
          opacity: (mouseArea.containsMouse || isSelected) ? 0 : 0.3
          radius: parent.radius

          Behavior on opacity {
            NumberAnimation {
              duration: Style.animationFast
            }
          }
        }

        MouseArea {
          id: mouseArea
          anchors.fill: parent
          acceptedButtons: Qt.LeftButton
          hoverEnabled: true
          onPressed: {
            if (Settings.data.wallpaper.setWallpaperOnAllMonitors) {
              WallpaperService.changeWallpaper(wallpaperPath, undefined)
            } else if (screen) {
              WallpaperService.changeWallpaper(wallpaperPath, screen.name)
            }
          }
        }
      }
    }
  }

  // Empty state
  Rectangle {
    color: Color.mSurface
    radius: Style.radiusM * scaling
    border.color: Color.mOutline
    border.width: Math.max(1, Style.borderS * scaling)
    visible: wallpapersList.length === 0 || WallpaperService.scanning
    Layout.fillWidth: true
    Layout.preferredHeight: 130 * scaling

    ColumnLayout {
      anchors.fill: parent
      visible: WallpaperService.scanning
      NBusyIndicator {
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
      }
    }

    ColumnLayout {
      anchors.fill: parent
      visible: wallpapersList.length === 0 && !WallpaperService.scanning
      Item {
        Layout.fillHeight: true
      }

      NIcon {
        icon: "folder-open"
        font.pointSize: Style.fontSizeXXL * scaling
        color: Color.mOnSurface
        Layout.alignment: Qt.AlignHCenter
      }

      NText {
        text: "No wallpaper found."
        color: Color.mOnSurface
        font.weight: Style.fontWeightBold
        Layout.alignment: Qt.AlignHCenter
      }

      NText {
        text: "Make sure your wallpaper directory is configured and contains image files."
        color: Color.mOnSurfaceVariant
        wrapMode: Text.WordWrap
        Layout.alignment: Qt.AlignHCenter
      }

      Item {
        Layout.fillHeight: true
      }
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginXL * scaling
    Layout.bottomMargin: Style.marginXL * scaling
  }
}

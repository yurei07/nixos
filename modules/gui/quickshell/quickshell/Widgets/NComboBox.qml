import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

RowLayout {
  id: root

  property real minimumWidth: 280 * scaling
  property real popupHeight: 180 * scaling

  property string label: ""
  property string description: ""
  property var model
  property string currentKey: ""
  property string placeholder: ""

  readonly property real preferredHeight: Style.baseWidgetSize * 1.1 * scaling

  signal selected(string key)

  spacing: Style.marginL * scaling
  Layout.fillWidth: true

  function itemCount() {
    if (!root.model)
      return 0
    if (typeof root.model.count === 'number')
      return root.model.count
    if (Array.isArray(root.model))
      return root.model.length
    return 0
  }

  function getItem(index) {
    if (!root.model)
      return null
    if (typeof root.model.get === 'function')
      return root.model.get(index)
    if (Array.isArray(root.model))
      return root.model[index]
    return null
  }

  function findIndexByKey(key) {
    for (var i = 0; i < itemCount(); i++) {
      var item = getItem(i)
      if (item && item.key === key)
        return i
    }
    return -1
  }

  NLabel {
    label: root.label
    description: root.description
  }

  ComboBox {
    id: combo

    Layout.minimumWidth: root.minimumWidth
    Layout.preferredHeight: root.preferredHeight
    model: model
    currentIndex: findIndexByKey(currentKey)
    onActivated: {
      var item = getItem(combo.currentIndex)
      if (item && item.key !== undefined)
        root.selected(item.key)
    }

    background: Rectangle {
      implicitWidth: Style.baseWidgetSize * 3.75 * scaling
      implicitHeight: preferredHeight
      color: Color.mSurface
      border.color: combo.activeFocus ? Color.mSecondary : Color.mOutline
      border.width: Math.max(1, Style.borderS * scaling)
      radius: Style.radiusM * scaling

      Behavior on border.color {
        ColorAnimation {
          duration: Style.animationFast
        }
      }
    }

    contentItem: NText {
      leftPadding: Style.marginL * scaling
      rightPadding: combo.indicator.width + Style.marginL * scaling
      font.pointSize: Style.fontSizeM * scaling
      verticalAlignment: Text.AlignVCenter
      elide: Text.ElideRight
      color: (combo.currentIndex >= 0 && combo.currentIndex < itemCount()) ? Color.mOnSurface : Color.mOnSurfaceVariant
      text: (combo.currentIndex >= 0 && combo.currentIndex < itemCount()) ? (getItem(combo.currentIndex) ? getItem(combo.currentIndex).name : root.placeholder) : root.placeholder
    }

    indicator: NIcon {
      x: combo.width - width - Style.marginM * scaling
      y: combo.topPadding + (combo.availableHeight - height) / 2
      icon: "caret-down"
      font.pointSize: Style.fontSizeL * scaling
    }

    popup: Popup {
      y: combo.height
      implicitWidth: combo.width - Style.marginM * scaling
      implicitHeight: Math.min(root.popupHeight, contentItem.implicitHeight + Style.marginM * scaling * 2)
      padding: Style.marginM * scaling

      onOpened: {
        PanelService.willOpenPopup(root)
      }

      onClosed: {
        PanelService.willClosePopup(root)
      }

      contentItem: NListView {
        model: combo.popup.visible ? root.model : null
        implicitHeight: contentHeight
        horizontalPolicy: ScrollBar.AlwaysOff
        verticalPolicy: ScrollBar.AsNeeded

        delegate: ItemDelegate {
          width: combo.width
          hoverEnabled: true
          highlighted: ListView.view.currentIndex === index

          onHoveredChanged: {
            if (hovered) {
              ListView.view.currentIndex = index
            }
          }

          onClicked: {
            var item = root.getItem(index)
            if (item && item.key !== undefined) {
              root.selected(item.key)
              combo.currentIndex = index
              combo.popup.close()
            }
          }

          background: Rectangle {
            width: combo.width - Style.marginM * scaling * 3
            color: highlighted ? Color.mTertiary : Color.transparent
            radius: Style.radiusS * scaling
            Behavior on color {
              ColorAnimation {
                duration: Style.animationFast
              }
            }
          }

          contentItem: NText {
            text: {
              var item = root.getItem(index)
              return item && item.name ? item.name : ""
            }
            font.pointSize: Style.fontSizeM * scaling
            color: highlighted ? Color.mOnTertiary : Color.mOnSurface
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            Behavior on color {
              ColorAnimation {
                duration: Style.animationFast
              }
            }
          }
        }
      }

      background: Rectangle {
        color: Color.mSurfaceVariant
        border.color: Color.mOutline
        border.width: Math.max(1, Style.borderS * scaling)
        radius: Style.radiusM * scaling
      }
    }

    // Update the currentIndex if the currentKey is changed externalyu
    Connections {
      target: root
      function onCurrentKeyChanged() {
        combo.currentIndex = root.findIndexByKey(currentKey)
      }
    }
  }
}

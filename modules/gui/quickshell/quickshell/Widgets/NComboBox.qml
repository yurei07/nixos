import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

ColumnLayout {
  id: root

  readonly property real preferredHeight: Style.baseWidgetSize * 1.25 * scaling

  property string label: ""
  property string description: ""
  property ListModel model: {

  }
  property string currentKey: ''

  signal selected(string key)

  spacing: Style.marginS * scaling
  Layout.fillWidth: true

  NLabel {
    label: root.label
    description: root.description
  }

  function findIndexByKey(key) {
    for (var i = 0; i < root.model.count; i++) {
      if (root.model.get(i).key === key) {
        return i
      }
    }
    return -1
  }

  ComboBox {
    id: combo
    Layout.fillWidth: true
    Layout.preferredHeight: height
    model: model
    currentIndex: findIndexByKey(currentKey)
    onActivated: {
      root.selected(model.get(combo.currentIndex).key)
    }

    background: Rectangle {
      implicitWidth: Style.baseWidgetSize * 3.75 * scaling
      implicitHeight: preferredHeight
      color: Color.mSurface
      border.color: combo.activeFocus ? Color.mTertiary : Color.mOutline
      border.width: Math.max(1, Style.borderS * scaling)
      radius: Style.radiusM * scaling
    }

    contentItem: NText {
      leftPadding: Style.marginL * scaling
      rightPadding: combo.indicator.width + Style.marginL * scaling
      font.pointSize: Style.fontSizeM * scaling
      verticalAlignment: Text.AlignVCenter
      elide: Text.ElideRight
      text: (combo.currentIndex >= 0 && combo.currentIndex < root.model.count) ? root.model.get(
                                                                                   combo.currentIndex).name : ""
    }

    indicator: NIcon {
      x: combo.width - width - Style.marginM * scaling
      y: combo.topPadding + (combo.availableHeight - height) / 2
      text: "arrow_drop_down"
      font.pointSize: Style.fontSizeXXL * scaling
    }

    popup: Popup {
      y: combo.height
      width: combo.width
      implicitHeight: Math.min(160 * scaling, contentItem.implicitHeight + Style.marginM * scaling * 2)
      padding: Style.marginM * scaling

      contentItem: ListView {
        property var comboBoxRoot: root
        clip: true
        implicitHeight: contentHeight
        model: combo.popup.visible ? root.model : null
        ScrollIndicator.vertical: ScrollIndicator {}

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
            ListView.view.comboBoxRoot.selected(ListView.view.comboBoxRoot.model.get(index).key)
            combo.currentIndex = index
            combo.popup.close()
          }

          contentItem: NText {
            text: name
            font.pointSize: Style.fontSizeM * scaling
            color: highlighted ? Color.mSurface : Color.mOnSurface
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
          }

          background: Rectangle {
            width: combo.width - Style.marginM * scaling * 3
            color: highlighted ? Color.mTertiary : Color.transparent
            radius: Style.radiusS * scaling
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
  }
}

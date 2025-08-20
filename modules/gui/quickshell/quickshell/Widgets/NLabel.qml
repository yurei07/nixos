import QtQuick
import QtQuick.Layouts
import qs.Commons

ColumnLayout {
  property string label: ""
  property string description: ""

  spacing: Style.marginXXS * scaling
  Layout.fillWidth: true

  NText {
    text: label
    font.pointSize: Style.fontSizeM * scaling
    font.weight: Style.fontWeightBold
    color: Color.mOnSurface
    visible: label !== ""
  }

  NText {
    text: description
    font.pointSize: Style.fontSizeS * scaling
    color: Color.mOnSurfaceVariant
    wrapMode: Text.WordWrap
    visible: description !== ""
    Layout.fillWidth: true
  }
}

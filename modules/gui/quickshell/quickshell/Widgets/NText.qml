import QtQuick
import qs.Commons
import qs.Services
import qs.Widgets

Text {
  id: root

  font.family: Settings.data.ui.fontFamily
  font.pointSize: Style.fontSizeMedium * scaling
  font.weight: Style.fontWeightRegular
  color: Color.mOnSurface
}

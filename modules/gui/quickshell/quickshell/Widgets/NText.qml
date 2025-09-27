import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets

Text {
  id: root
  font.family: Settings.data.ui.fontDefault
  font.pointSize: Style.fontSizeM * scaling
  font.weight: Style.fontWeightMedium
  color: Color.mOnSurface
  elide: Text.ElideRight
  wrapMode: Text.NoWrap
  verticalAlignment: Text.AlignVCenter
}

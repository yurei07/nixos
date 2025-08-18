import QtQuick
import qs.Commons
import qs.Services

// Generic card container
Rectangle {
  id: root

  implicitWidth: childrenRect.width
  implicitHeight: childrenRect.height

  color: Color.mSurface
  radius: Style.radiusMedium * scaling
  border.color: Color.mOutline
  border.width: Math.max(1, Style.borderThin * scaling)
}

import QtQuick
import qs.theme

// Plain text unless a use asks for more: titles, names, networks and what Nilo shows come from
// outside, and as markup they could hide words or load a picture from anywhere.
Text {
    textFormat: Text.PlainText
    color: Tokens.ink
    font.family: Tokens.fontSans
    font.pixelSize: 14
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
}

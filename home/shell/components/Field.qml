import QtQuick
import QtQuick.Controls as QQC
import qs.theme

Surface {
    id: root

    property string value: ""
    property string placeholder: ""
    property bool password: false
    property bool invalid: false
    property bool catchEscape: false
    property alias text: input.text

    signal edited(string text)
    signal accepted()
    signal escaped()
    signal finished()

    function grab(): void { input.forceActiveFocus(); }
    function clear(): void { input.text = ""; }

    // A password doesn't stay in a field nobody sees.
    onVisibleChanged: if (!visible && root.password) clear()

    // What it last sent, typed: its value coming back as that leaves the field as it is, cursor and
    // all; any other value shows, the focus still in it or not (Discard, a choice beside it).
    property string typed: ""
    onValueChanged: {
        if (input.activeFocus && value === root.typed)
            return;
        if (input.text !== value)
            input.text = value;
    }
    Component.onCompleted: input.text = value

    implicitWidth: 300
    implicitHeight: 36
    radius: 8
    color: Tokens.surface
    border.width: 1
    border.color: invalid ? Tokens.interrupt : input.activeFocus ? Tokens.muted : Tokens.line

    QQC.TextField {
        id: input
        QQC.ContextMenu.menu: TextMenu {
            target: input
        }
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        background: null
        color: Tokens.ink
        placeholderText: root.placeholder
        placeholderTextColor: Tokens.muted
        font.family: Tokens.fontMono
        font.pixelSize: 13
        verticalAlignment: TextInput.AlignVCenter
        echoMode: root.password ? TextInput.Password : TextInput.Normal
        selectByMouse: true
        onTextEdited: {
            root.typed = text;
            root.edited(text);
        }
        onAccepted: root.accepted()
        onEditingFinished: root.finished()
        Keys.onEscapePressed: event => {
            root.escaped();
            event.accepted = root.catchEscape;
        }
    }
}

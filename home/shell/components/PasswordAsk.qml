import QtQuick
import QtQuick.Layouts
import qs.config

// The password that sudo asks for, the same wherever it is asked: a field, a button that cancels
// and one that goes on. Escape cancels as well, and what was typed is wiped on going on, on
// cancelling and when it hides.
RowLayout {
    id: root

    // The button that goes on; empty, and only Enter does.
    property string confirm: ""

    signal entered(string password)
    signal cancelled()

    function grab(): void { field.grab(); }

    function enter(): void {
        const typed = field.text;
        field.clear();
        root.entered(typed);
    }

    function cancel(): void {
        field.clear();
        root.cancelled();
    }

    spacing: 8
    onVisibleChanged: {
        if (visible)
            Qt.callLater(() => field.grab());
        else
            field.clear();
    }

    Field {
        id: field
        Layout.preferredWidth: 220
        password: true
        catchEscape: true
        placeholder: Lang.cfgApplyPassword
        onAccepted: root.enter()
        onEscaped: root.cancel()
    }

    KeyButton {
        text: Lang.cfgCancel
        onClicked: root.cancel()
    }

    KeyButton {
        visible: root.confirm !== ""
        accent: true
        text: root.confirm
        onClicked: root.enter()
    }
}

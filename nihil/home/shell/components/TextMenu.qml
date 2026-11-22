import QtQuick
import QtQuick.Controls as QQC
import qs.theme
import qs.config

// What a right click on a text field offers, in the shell's look rather than Qt's light one:
// undo, redo, cut, copy, paste and select all, those that can be done there and then.
QQC.Menu {
    id: root

    // The field it's for: a TextField or a TextArea.
    required property Item target
    readonly property bool hidden: (root.target.echoMode ?? TextInput.Normal) !== TextInput.Normal
    readonly property bool chosen: root.target.selectedText !== ""

    popupType: QQC.Popup.Item
    padding: 6

    background: Rectangle {
        implicitWidth: 200
        radius: 12
        color: Tokens.surface
        border.width: 1
        border.color: Tokens.line
    }

    delegate: QQC.MenuItem {
        id: item

        implicitHeight: 32
        padding: 0

        contentItem: Txt {
            leftPadding: 12
            rightPadding: 12
            text: item.text
            color: item.enabled ? Tokens.ink : Tokens.off
            font.pixelSize: 13
            verticalAlignment: Text.AlignVCenter
        }

        background: Rectangle {
            radius: 8
            color: item.highlighted && item.enabled ? Tokens.raised : "transparent"
        }
    }

    QQC.Action {
        text: Lang.textUndo
        enabled: !root.target.readOnly && root.target.canUndo
        onTriggered: root.target.undo()
    }

    QQC.Action {
        text: Lang.textRedo
        enabled: !root.target.readOnly && root.target.canRedo
        onTriggered: root.target.redo()
    }

    QQC.MenuSeparator {
        contentItem: Rectangle {
            implicitHeight: 1
            color: Tokens.line
        }
    }

    QQC.Action {
        text: Lang.textCut
        enabled: root.chosen && !root.hidden && !root.target.readOnly
        onTriggered: root.target.cut()
    }

    QQC.Action {
        text: Lang.textCopy
        enabled: root.chosen && !root.hidden
        onTriggered: root.target.copy()
    }

    QQC.Action {
        text: Lang.textPaste
        enabled: !root.target.readOnly && root.target.canPaste
        onTriggered: root.target.paste()
    }

    QQC.MenuSeparator {
        contentItem: Rectangle {
            implicitHeight: 1
            color: Tokens.line
        }
    }

    QQC.Action {
        text: Lang.textSelectAll
        enabled: root.target.length > 0
        onTriggered: root.target.selectAll()
    }
}

import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.config
import qs.services
import qs.components

Flickable {
    id: page

    readonly property bool matching: next.text === again.text
    readonly property bool ready: current.text !== "" && next.text !== "" && matching

    contentHeight: column.implicitHeight + 24
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    function change(): void {
        if (!page.ready)
            return;
        Machine.changePassword(current.text, next.text);
        current.clear();
        next.clear();
        again.clear();
    }

    ColumnLayout {
        id: column
        width: page.width
        spacing: 14

        Heading {
            title: Lang.cfgYou
        }

        Setting {
            title: Lang.cfgName

            Field {
                width: 280
                value: Machine.get("user.fullName", "")
                onEdited: text => Machine.set("user.fullName", text.trim())
            }
        }

        Setting {
            title: Lang.cfgAccount

            Txt {
                text: Machine.get("user.name", Config.user)
                color: Tokens.dim
                font.family: Tokens.fontMono
            }
        }

        Heading {
            Layout.topMargin: 14
            title: Lang.cfgPassword
        }

        Field {
            id: current
            Layout.preferredWidth: 300
            password: true
            placeholder: Lang.cfgCurrent
            onAccepted: next.grab()
        }

        Field {
            id: next
            Layout.preferredWidth: 300
            password: true
            placeholder: Lang.cfgNew
            onAccepted: again.grab()
        }

        Field {
            id: again
            Layout.preferredWidth: 300
            password: true
            placeholder: Lang.cfgRepeat
            invalid: again.text !== "" && !page.matching
            onAccepted: page.change()
        }

        RowLayout {
            spacing: 14

            KeyButton {
                text: Lang.cfgChange
                accent: page.ready
                onClicked: page.change()
            }

            Alert {
                text: !page.matching && again.text !== "" ? Lang.cfgPasswordMismatch
                    : Machine.passwordState === "busy" ? Lang.cfgChecking
                    : Machine.passwordState === "done" ? Lang.cfgPasswordDone
                    : Machine.passwordState === "wrong" ? Lang.cfgPasswordWrong
                    : Machine.passwordState === "invalid" ? Lang.cfgPasswordInvalid
                    : Machine.passwordState === "failed" ? Lang.cfgPasswordFailed : ""
                wrong: ["wrong", "invalid", "failed"].includes(Machine.passwordState) || (!page.matching && again.text !== "")
            }
        }
    }
}

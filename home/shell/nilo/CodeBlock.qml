import QtQuick
import qs.theme
import qs.config
import qs.services
import qs.components

Surface {
    id: root

    property string code: ""
    property string language: ""

    readonly property var languages: ({
        bash: "Bash", sh: "Shell", shell: "Shell", zsh: "Zsh", fish: "Fish", console: "Shell",
        python: "Python", py: "Python", nix: "Nix", qml: "QML", js: "JavaScript", javascript: "JavaScript",
        ts: "TypeScript", typescript: "TypeScript", json: "JSON", yaml: "YAML", yml: "YAML", toml: "TOML",
        ini: "INI", lua: "Lua", c: "C", cpp: "C++", "c++": "C++", rust: "Rust", rs: "Rust", go: "Go",
        java: "Java", kotlin: "Kotlin", kt: "Kotlin", html: "HTML", css: "CSS", sql: "SQL", diff: "Diff",
        markdown: "Markdown", md: "Markdown", xml: "XML", dockerfile: "Dockerfile", make: "Make", makefile: "Make"
    })
    readonly property string languageName: languages[language.toLowerCase()] ?? Case.sentence(language)

    implicitHeight: head.height + body.implicitHeight + 14
    height: implicitHeight
    radius: 12
    color: Tokens.surface
    border.width: 1
    border.color: Tokens.line

    Item {
        id: head
        x: 14
        width: parent.width - 24
        height: 34

        Label {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: root.language !== "" ? root.languageName : Lang.niloCode
        }

        CopyButton {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            wordFirst: true
            text: root.code
        }
    }

    TextEdit {
        id: body
        x: 14
        y: head.height
        width: parent.width - 28
        text: root.code
        readOnly: true
        selectByMouse: true
        textFormat: TextEdit.PlainText
        wrapMode: TextEdit.WrapAtWordBoundaryOrAnywhere
        color: "#E6E6E6"
        selectionColor: Tokens.ink
        selectedTextColor: Tokens.black
        font.family: Tokens.fontMono
        font.pixelSize: 12
    }
}

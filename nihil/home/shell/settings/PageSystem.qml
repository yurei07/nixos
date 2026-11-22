import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.config
import qs.services
import qs.components

Flickable {
    id: page

    readonly property var hostName: /^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$/

    contentHeight: column.implicitHeight + 24
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    ColumnLayout {
        id: column
        width: page.width
        spacing: 14

        Heading {
            title: Lang.cfgSystem
        }

        Setting {
            title: Lang.cfgHost
            sub: page.hostName.test(Machine.get("host.name", "nihil")) ? "" : Lang.cfgHostRule

            Field {
                width: 240
                value: Machine.get("host.name", "nihil")
                invalid: !page.hostName.test(text)
                // Saved as typed: what isn't valid stays red and Apply refuses it.
                onEdited: text => Machine.set("host.name", text)
            }
        }

        Setting {
            title: "Nilo"

            Row {
                spacing: 16

                Toggle {
                    anchors.verticalCenter: parent.verticalCenter
                    on: Machine.get("nilo.enable", false)
                    onToggled: Machine.set("nilo.enable", !on, false)
                }

                // Not in the welcome, which stays over everything: Nilo would open beneath it.
                KeyButton {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: Config.nilo.enabled && !Machine.welcoming
                    text: Lang.cfgNiloSettings
                    onClicked: {
                        Machine.hide();
                        Nilo.openSettings();
                    }
                }
            }
        }

        Setting {
            visible: Machine.get("nilo.enable", false)
            title: Lang.cfgAcceleration

            Choice {
                options: [{ value: "cpu", label: "CPU" }, { value: "vulkan", label: "Vulkan" }, { value: "rocm", label: "ROCm" }, { value: "cuda", label: "CUDA" }]
                value: Machine.get("nilo.acceleration", "cpu")
                onPicked: value => Machine.set("nilo.acceleration", value, "cpu")
            }
        }

        Setting {
            title: Lang.cfgClipboard

            Row {
                spacing: 12

                Choice {
                    anchors.verticalCenter: parent.verticalCenter
                    options: [{ value: 0, label: Lang.cfgClipboardOff }, { value: 5, label: "5" }, { value: 8, label: "8" },
                              { value: 15, label: "15" }, { value: 30, label: "30" }]
                    value: Machine.get("clipboard", 8)
                    onPicked: value => Machine.set("clipboard", value, 8)
                }

                CircleButton {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: Clipboard.enabled
                    glyph: Icons.broom
                    label: Lang.cfgClipboardWipe
                    size: 30
                    onClicked: Clipboard.wipe()
                }
            }
        }

        Setting {
            title: Lang.cfgBootSound

            Toggle {
                on: Machine.get("bootSound", true)
                onToggled: Machine.set("bootSound", !on, true)
            }
        }

        Setting {
            title: Lang.cfgFingerprint

            Toggle {
                on: Machine.get("fingerprint", false)
                onToggled: Machine.set("fingerprint", !on, false)
            }
        }

        Setting {
            title: "SSH"

            Toggle {
                on: Machine.get("ssh", false)
                onToggled: Machine.set("ssh", !on, false)
            }
        }
    }
}

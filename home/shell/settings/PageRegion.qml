import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.theme
import qs.config
import qs.services
import qs.components

Flickable {
    id: page

    readonly property var layouts: ["es", "us", "gb", "latam", "fr", "de", "it", "pt"]
    readonly property string layout: Machine.get("keyboard.layout", "us")
    // The layouts that exist and their variants; until they're read, the old rule stands in.
    property var xkb: ({})
    readonly property bool xkbRead: Object.keys(xkb).length > 0

    function layoutExists(name: string): bool {
        return xkbRead ? name in xkb : /^[a-z]{2,8}$/.test(name);
    }

    function variantExists(name: string): bool {
        return !xkbRead || (xkb[page.layout] ?? []).includes(name);
    }

    // A variant belongs to its layout: a new layout starts without one.
    function pickLayout(name: string): void {
        Machine.set("keyboard.layout", name);
        Machine.set("keyboard.variant", "");
    }

    FileView {
        path: Config.xkbLayouts
        printErrors: false
        onLoaded: {
            try { page.xkb = JSON.parse(text()); } catch (e) { page.xkb = {}; }
        }
    }
    property string search: ""
    readonly property var matches: {
        const wanted = page.search.trim().toLowerCase().replace(/ /g, "_");
        if (wanted.length < 2)
            return [];
        return Machine.timeZones.filter(zone => zone.toLowerCase().indexOf(wanted) >= 0).slice(0, 8);
    }

    contentHeight: column.implicitHeight + 24
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    function language(value: string): void {
        Machine.set("language", value);
        const locale = Machine.get("locale", "");
        if (locale === "" || locale === "es_ES.UTF-8" || locale === "en_US.UTF-8")
            Machine.set("locale", value === "es" ? "es_ES.UTF-8" : "en_US.UTF-8");
    }

    ColumnLayout {
        id: column
        width: page.width
        spacing: 14

        Heading {
            title: Lang.cfgRegion
        }

        Setting {
            title: Lang.cfgLanguage

            Choice {
                options: [{ value: "es", label: "Español" }, { value: "en", label: "English" }]
                value: Machine.get("language", "en")
                onPicked: value => page.language(value)
            }
        }

        Setting {
            title: Lang.cfgKeyboard

            Column {
                spacing: 8

                Choice {
                    mono: true
                    options: page.layouts.map(name => ({ value: name, label: name.toUpperCase() }))
                    value: page.layout
                    onPicked: value => page.pickLayout(value)
                }

                Row {
                    spacing: 8

                    Field {
                        width: 150
                        placeholder: Lang.cfgOther
                        value: page.layouts.indexOf(page.layout) < 0 ? page.layout : ""
                        // Saved as typed: what doesn't exist stays red and Apply refuses it, rather than
                        // the last piece that did exist going in unseen.
                        invalid: text !== "" && !page.layoutExists(text)
                        onEdited: text => {
                            if (text !== "")
                                page.pickLayout(text);
                        }
                    }

                    Field {
                        width: 172
                        placeholder: Lang.cfgVariant
                        value: Machine.get("keyboard.variant", "")
                        invalid: text.trim() !== "" && !page.variantExists(text.trim())
                        onEdited: text => Machine.set("keyboard.variant", text.trim(), "")
                    }
                }
            }
        }

        Setting {
            title: Lang.cfgTimeZone
            sub: Machine.get("timeZone", "UTC").replace(/_/g, " ")

            Field {
                id: zoneField
                width: 280
                placeholder: Lang.cfgTimeZoneSub
                onEdited: text => page.search = text
                onAccepted: {
                    if (page.matches.length > 0) {
                        Machine.set("timeZone", page.matches[0]);
                        page.search = "";
                        zoneField.clear();
                    }
                }
            }
        }

        Repeater {
            model: page.matches

            Surface {
                required property string modelData

                Layout.fillWidth: true
                implicitHeight: 32
                radius: 8
                color: zoneArea.containsMouse ? Tokens.raised : "transparent"

                Txt {
                    anchors.verticalCenter: parent.verticalCenter
                    x: 16
                    text: modelData.replace(/_/g, " ")
                    font.family: Tokens.fontMono
                    font.pixelSize: 13
                    color: zoneArea.containsMouse ? Tokens.ink : Tokens.dim
                }

                MouseArea {
                    id: zoneArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Machine.set("timeZone", modelData);
                        page.search = "";
                        zoneField.clear();
                    }
                }
            }
        }
    }
}

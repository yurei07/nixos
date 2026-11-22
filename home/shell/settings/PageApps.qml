import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.config
import qs.services
import qs.components

// Every app, and whether the launcher shows it.
Flickable {
    id: page

    readonly property string term: search.text.trim().toLowerCase()

    contentHeight: column.implicitHeight + 24
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    ColumnLayout {
        id: column
        width: page.width
        spacing: 16

        Heading {
            title: Lang.cfgApps
        }

        Field {
            id: search
            Layout.preferredWidth: 280
            placeholder: Lang.search
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Repeater {
                model: page.term === "" ? Apps.every : Apps.every.filter(entry => entry.name.toLowerCase().indexOf(page.term) >= 0)

                Setting {
                    id: app

                    required property var modelData

                    title: app.modelData.name

                    Toggle {
                        on: Apps.hidden.indexOf(app.modelData.id) < 0
                        onToggled: Apps.setHidden(app.modelData.id, on)
                    }
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.config
import qs.services
import qs.components

Flickable {
    id: page

    readonly property string current: Machine.wallpaper !== "" ? Machine.wallpaper : Machine.get("wallpaper", "night")

    contentHeight: column.implicitHeight + 24
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    ColumnLayout {
        id: column
        width: page.width
        spacing: 16

        Heading {
            title: Lang.cfgWallpaper
        }

        Flow {
            Layout.fillWidth: true
            spacing: 14

            Repeater {
                model: Config.wallpapers

                Column {
                    id: card

                    required property string modelData
                    readonly property bool chosen: page.current === modelData

                    spacing: 8

                    Surface {
                        width: 208
                        height: 132
                        radius: 12
                        color: Tokens.surface
                        border.width: card.chosen ? 2 : 1
                        border.color: card.chosen ? Tokens.ink : (cardArea.containsMouse ? Tokens.muted : Tokens.line)

                        Image {
                            anchors.fill: parent
                            anchors.margins: 3
                            source: "file://" + Config.wallpaperDir + "/" + card.modelData + "/" + Config.primaryOutput + ".png"
                            sourceSize.width: 416
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }

                        MouseArea {
                            id: cardArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Machine.setWallpaper(card.modelData)
                        }
                    }

                    Label {
                        text: Case.sentence(card.modelData.replace(/[-_]/g, " "))
                        color: card.chosen ? Tokens.ink : Tokens.muted
                    }
                }
            }
        }

        Setting {
            Layout.topMargin: 18
            title: Lang.cfgGlass

            Toggle {
                on: Machine.glass
                onToggled: Machine.setGlass(!on)
            }
        }

        Heading {
            Layout.topMargin: 18
            title: Lang.cfgWidgets
        }

        // Not in the welcome, which can't step aside for the desktop.
        Setting {
            visible: Machine.widgets.length > 0 && !Machine.welcoming
            title: Lang.cfgWidgetsArrange

            KeyButton {
                text: Lang.cfgArrange
                onClicked: Machine.arrangeWidgets()
            }
        }

        // Photos and notes, as many as wanted, are added here and taken away on the desktop.
        Repeater {
            model: Config.widgets

            Setting {
                id: widget

                required property string modelData
                readonly property bool several: Machine.several(widget.modelData)

                title: Lang["cfgWidget" + widget.modelData.charAt(0).toUpperCase() + widget.modelData.slice(1)] ?? widget.modelData

                RowLayout {
                    Toggle {
                        visible: !widget.several
                        on: Machine.widgets.indexOf(widget.modelData) >= 0
                        onToggled: Machine.setWidget(widget.modelData, !on)
                    }

                    KeyButton {
                        visible: widget.several
                        text: Lang.cfgWidgetAdd
                        onClicked: Machine.addWidget(widget.modelData, null, null)
                    }
                }
            }
        }

        // The weather's: where, looked for by its name when it's left.
        Setting {
            visible: Machine.widgets.indexOf("weather") >= 0
            title: Lang.cfgWeatherPlace
            sub: Weather.searching !== "" ? Lang.cfgWeatherSearching
                : Weather.notFound !== "" ? Lang.cfgWeatherNotFound.arg(Weather.notFound)
                : Weather.searchFailed ? Lang.cfgWeatherSearchFailed : ""

            Field {
                id: weatherPlace
                width: 240
                value: Machine.widgetOptions.weather?.place ?? ""
                invalid: Weather.notFound !== "" && Weather.notFound === weatherPlace.text.trim()
                onFinished: {
                    if (weatherPlace.text.trim() !== weatherPlace.value)
                        Weather.search(weatherPlace.text);
                }
            }
        }

        // The GitHub one's: whose contributions.
        Setting {
            visible: Machine.widgets.indexOf("github") >= 0
            title: Lang.cfgGithubUser

            Field {
                id: githubUser
                width: 240
                value: Machine.widgetOptions.github?.user ?? ""
                invalid: githubUser.text !== "" && !Contributions.valid(githubUser.text)
                // Kept when it's left, and only a name GitHub could have.
                onFinished: {
                    const name = githubUser.text;
                    if (name !== githubUser.value && (name === "" || Contributions.valid(name)))
                        Machine.setWidgetOption("github", "user", name);
                }
            }
        }

        // The calendar widget's: what's subscribed to, read-only.
        Heading {
            Layout.topMargin: 18
            visible: Calendar.shown
            title: Lang.cfgCalendars
        }

        Repeater {
            model: Calendar.shown ? Calendar.calendars : []

            Setting {
                id: subscribed

                required property var modelData

                title: subscribed.modelData.name
                sub: subscribed.modelData.ok ? "" : Lang.cfgCalendarUnread

                KeyButton {
                    text: Lang.cfgCalendarRemove
                    onClicked: Calendar.remove(subscribed.modelData.id)
                }
            }
        }

        // A new one by its address, which nihil-calendar keeps where only the user reads it, and
        // never in settings.json: whoever has the address reads the calendar.
        Setting {
            visible: Calendar.shown
            title: Lang.cfgCalendarAdd
            sub: Calendar.adding ? Lang.cfgCalendarAdding
                : Calendar.addError === "url" ? Lang.cfgCalendarErrUrl
                : Calendar.addError === "fetch" ? Lang.cfgCalendarErrFetch
                : Calendar.addError === "calendar" ? Lang.cfgCalendarErrCalendar : ""

            RowLayout {
                spacing: 8

                Field {
                    id: address
                    Layout.preferredWidth: 240
                    placeholder: "webcal://, https://"
                    invalid: Calendar.addError !== "" && !Calendar.adding
                    onAccepted: Calendar.add(address.text)
                    onEdited: Calendar.addError = ""
                }

                KeyButton {
                    text: Lang.cfgCalendarAddButton
                    onClicked: Calendar.add(address.text)
                }
            }

            // Once it's in, the field is empty for the next.
            Connections {
                target: Calendar
                function onAddingChanged(): void {
                    if (!Calendar.adding && Calendar.addError === "")
                        address.clear();
                }
            }
        }
    }
}

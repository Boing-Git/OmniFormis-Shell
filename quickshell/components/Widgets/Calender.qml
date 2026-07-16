import QtQuick
import QtQuick.Layouts
import "../../" // Adjust this to import your Theme variables

Item {
    id: root
    width: 320
    height: 320

    // --- Core State ---
    property date today: new Date()
    property int currentMonth: today.getMonth()
    property int currentYear: today.getFullYear()

    // Array of month names for the header
    readonly property var monthNames: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    readonly property var dayNames: ["S", "M", "T", "W", "T", "F", "S"]

    // --- Date Math Helpers ---
    function getDaysInMonth(month, year) {
        return new Date(year, month + 1, 0).getDate();
    }

    function getFirstDayOfMonth(month, year) {
        return new Date(year, month, 1).getDay();
    }

    function nextMonth() {
        if (currentMonth === 11) {
            currentMonth = 0;
            currentYear++;
        } else {
            currentMonth++;
        }
    }

    function prevMonth() {
        if (currentMonth === 0) {
            currentMonth = 11;
            currentYear--;
        } else {
            currentMonth--;
        }
    }

    // --- Background ---
    Rectangle {
        anchors.fill: parent
        color: Theme.surface_container_high // Matches your clock background
        radius: 24

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // 1. HEADER: Month, Year, and Navigation
            RowLayout {
                Layout.fillWidth: true

                // Previous Month Button
                Rectangle {
                    width: 32
                    height: 32
                    radius: 16
                    color: prevMouse.pressed ? Theme.surface_variant : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: "<"
                        color: Theme.on_surface
                        font.pixelSize: 18
                    }
                    MouseArea {
                        id: prevMouse
                        anchors.fill: parent
                        onClicked: prevMonth()
                    }
                }

                // Month/Year Label
                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: root.monthNames[root.currentMonth] + " " + root.currentYear
                    color: Theme.on_surface
                    font.pixelSize: 18
                    font.bold: true
                }

                // Next Month Button
                Rectangle {
                    width: 32
                    height: 32
                    radius: 16
                    color: nextMouse.pressed ? Theme.surface_variant : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: ">"
                        color: Theme.on_surface
                        font.pixelSize: 18
                    }
                    MouseArea {
                        id: nextMouse
                        anchors.fill: parent
                        onClicked: nextMonth()
                    }
                }
            }

            // 2. DAY OF WEEK LABELS (S, M, T, W, T, F, S)
            RowLayout {
                Layout.fillWidth: true
                Repeater {
                    model: root.dayNames
                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        color: Theme.on_surface_variant
                        font.pixelSize: 14
                        font.bold: true
                    }
                }
            }

            // 3. THE CALENDAR GRID
            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 7
                rowSpacing: 4
                columnSpacing: 4

                // A standard calendar grid is 6 weeks (42 days) to fit any month combination
                Repeater {
                    model: 42

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredHeight: width // Keeps the cells perfectly square
                        radius: width / 2 // Makes them circular

                        // --- Cell Logic ---
                        property int firstDay: root.getFirstDayOfMonth(root.currentMonth, root.currentYear)
                        property int daysInMonth: root.getDaysInMonth(root.currentMonth, root.currentYear)

                        property int dayNumber: index - firstDay + 1
                        property bool isCurrentMonth: dayNumber > 0 && dayNumber <= daysInMonth

                        property bool isToday: isCurrentMonth && dayNumber === root.today.getDate() && root.currentMonth === root.today.getMonth() && root.currentYear === root.today.getFullYear()

                        // --- Cell Styling ---
                        visible: isCurrentMonth // Hide cells outside the month (or keep visible and lower opacity)
                        color: isToday ? Theme.primary : (dayMouse.containsMouse ? Theme.surface_variant : "transparent")

                        Text {
                            anchors.centerIn: parent
                            text: parent.dayNumber
                            color: parent.isToday ? Theme.on_primary : Theme.on_surface
                            font.pixelSize: 14
                            font.bold: parent.isToday
                        }

                        MouseArea {
                            id: dayMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                console.log("Selected Date: " + root.currentMonth + "/" + parent.dayNumber + "/" + root.currentYear);
                                // Add logic here to highlight a selected date if desired
                            }
                        }
                    }
                }
            }
        }
    }
}

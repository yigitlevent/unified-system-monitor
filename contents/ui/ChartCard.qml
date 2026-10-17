import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "Format.js" as Format

// A Card with one StatsRow on top and one chart below.
// Children you declare (Stat, Divider, ...) go into the stats row.
// With showChart off, the stats are centred in the card instead.
Item {
    id: root

    required property var ui
    property string title: ""
    property string subtitle: ""
    property string iconName: ""
    property string headerRight: ""

    default property alias stats: statsRow.data

    property bool showChart: true
    property var seriesData: []
    property var seriesColors: []
    property var labelFormatter: Format.percentLabel
    property int capacity: 60
    property real maxValue: 0
    property real autoFloor: 1
    property bool zoom: false

    Layout.fillWidth: true
    Layout.fillHeight: true

    Card {
        anchors.fill: parent
        ui: root.ui
        title: root.title
        subtitle: root.subtitle
        iconName: root.iconName
        headerRight: root.headerRight

        ColumnLayout {
            anchors.fill: parent
            spacing: Kirigami.Units.gridUnit * 0.25

            Item {
                visible: !root.showChart
                Layout.fillHeight: true
            }
            StatsRow {
                id: statsRow
            }
            Sparkline {
                Layout.topMargin: 16
                ui: root.ui
                visible: root.showChart
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: Kirigami.Units.gridUnit * 2.5
                seriesData: root.seriesData
                seriesColors: root.seriesColors
                labelFormatter: root.labelFormatter
                capacity: root.capacity
                maxValue: root.maxValue
                autoFloor: root.autoFloor
                zoom: root.zoom
            }
            Item {
                visible: !root.showChart
                Layout.fillHeight: true
            }
        }
    }
}

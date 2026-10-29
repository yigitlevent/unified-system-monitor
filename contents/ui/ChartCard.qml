import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "Format.js" as Format

// A Card with the stats in its header (next to the title) and one chart filling the body.
// Children you declare (Stat, Divider, ...) go into the header, right after the title.
Item {
    id: root

    required property var ui
    property string title: ""
    property string subtitle: ""
    property string iconName: ""
    property string headerRight: ""

    default property alias stats: card.headerContent

    property bool showChart: true
    property var seriesData: []
    property var seriesColors: []
    property var labelFormatter: Format.percentLabel
    property int capacity: 60
    property real maxValue: 0
    property real autoFloor: 1
    // ms between samples; the chart's hover tooltip uses it for the "Xs ago" label
    property int sampleInterval: 1000

    Layout.fillWidth: true
    Layout.fillHeight: true

    Card {
        id: card
        anchors.fill: parent
        ui: root.ui
        title: root.title
        subtitle: root.subtitle
        iconName: root.iconName
        headerRight: root.headerRight

        Sparkline {
            anchors.fill: parent
            anchors.topMargin: Kirigami.Units.smallSpacing
            ui: root.ui
            visible: root.showChart
            seriesData: root.seriesData
            seriesColors: root.seriesColors
            labelFormatter: root.labelFormatter
            capacity: root.capacity
            maxValue: root.maxValue
            autoFloor: root.autoFloor
            sampleInterval: root.sampleInterval
        }
    }
}

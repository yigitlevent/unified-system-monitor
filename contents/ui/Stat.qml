import QtQuick
import QtQuick.Layouts

// Big coloured number with optional arrow, unit and caption.
Item {
    id: stat

    property string value: ""
    property string unit: ""
    property string arrow: ""
    required property var ui
    property color accent: ui.cpu
    property real valueSize: ui.valueSize

    Layout.alignment: Qt.AlignTop
    implicitWidth: col.implicitWidth
    implicitHeight: col.implicitHeight

    ColumnLayout {
        id: col
        spacing: 0

        RowLayout {
            spacing: 0

            Text {
                visible: stat.arrow !== ""
                text: stat.arrow
                color: stat.accent
                font.pixelSize: stat.valueSize * 0.8
                font.bold: true
                lineHeight: 0.9
                Layout.alignment: Qt.AlignBaseline
            }
            Text {
                text: stat.value
                color: stat.accent
                font.pixelSize: stat.valueSize
                font.bold: true
                lineHeight: 0.9
                Layout.alignment: Qt.AlignBaseline
            }
            Text {
                visible: stat.unit !== ""
                text: stat.unit
                color: stat.accent
                font.pixelSize: stat.valueSize
                font.bold: true
                Layout.alignment: Qt.AlignBaseline
            }
        }
    }
}

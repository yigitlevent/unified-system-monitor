import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.sensors as Sensors

// One vertical usage bar for a single logical CPU thread.
ColumnLayout {
    id: root

    required property var ui
    property int cpuIndex: 0
    property int interval: 1000
    property bool showLabel: true

    // Bumped by the Dashboard's single shared timer; each bump takes one sample.
    property int sampleTrigger: 0

    // Usage (%) at which the bar switches colour: low < mid <= usage < high <= usage
    property real midThreshold: 50
    property real highThreshold: 80

    // Sampled once per `interval`
    property real usage: 0
    property bool available: false

    // Set while the pointer is over the bar; drives the usage tooltip
    property bool hovered: false
    // Lift the hovered bar so its tooltip isn't drawn under the neighbouring bars
    z: hovered ? 1 : 0

    // Width comes from the grid, never from the label, so columns can't overflow the card
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.preferredWidth: 0
    Layout.minimumWidth: 0
    spacing: 4

    Sensors.Sensor {
        id: sensor
        sensorId: "cpu/cpu" + root.cpuIndex + "/usage"
        updateRateLimit: root.interval
    }

    function sample() {
        var raw = sensor.value;

        if (raw === undefined || raw === null) {
            root.available = false;
            return;
        }

        var v = Number(raw);

        if (!isFinite(v)) {
            root.available = false;
            return;
        }

        root.usage = Math.max(0, Math.min(100, v));
        root.available = true;
    }

    onSampleTriggerChanged: sample()
    Component.onCompleted: sample()

    Rectangle {
        id: track
        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: 5
        color: root.ui.track
        border.width: 1
        border.color: root.ui.trackBorder

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 3
            radius: 3
            height: root.available ? Math.max(3, (track.height - 6) * root.usage / 100) : 0
            color: root.usage >= root.highThreshold ? root.ui.barHigh : root.usage >= root.midThreshold ? root.ui.barMid : root.ui.barLow

            Behavior on height {
                NumberAnimation {
                    duration: 250
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: root.hovered = true
            onExited: root.hovered = false
        }

        // Hover tooltip: the core's usage, shown just above the bar. Lives in the track
        // (a plain Rectangle) so it never takes part in the column layout.
        Rectangle {
            id: tooltip
            z: 2
            visible: root.hovered && root.available
            width: tipText.implicitWidth + 14
            height: tipText.implicitHeight + 8
            radius: 5
            color: Qt.rgba(0.06, 0.09, 0.15, 0.96)
            border.width: 1
            border.color: root.ui.border
            // Centred on the bar, clamped to its width
            x: Math.max(0, Math.min(track.width - width, track.width / 2 - width / 2))
            y: -height - 4

            Text {
                id: tipText
                anchors.centerIn: parent
                text: Math.round(root.usage) + "%"
                color: root.ui.text
                font.family: root.ui.fontFamily
                font.pixelSize: root.ui.coreLabelSize + 1
            }
        }
    }

    Text {
        visible: root.showLabel
        Layout.fillWidth: true
        Layout.preferredWidth: 0
        horizontalAlignment: Text.AlignHCenter
        text: root.available ? Math.round(root.usage) + "%" : "—"
        color: root.ui.muted
        font.pixelSize: root.ui.coreLabelSize
        fontSizeMode: Text.HorizontalFit
        minimumPixelSize: 6
    }
}

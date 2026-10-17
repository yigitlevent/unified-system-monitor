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

    // Sampled once per `interval`
    property real usage: 0
    property bool available: false

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

    Timer {
        interval: root.interval
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
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
    }

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
            color: root.usage >= 40 ? root.ui.barHigh : root.usage >= 30 ? root.ui.barMid : root.ui.barLow

            Behavior on height {
                NumberAnimation {
                    duration: 250
                }
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

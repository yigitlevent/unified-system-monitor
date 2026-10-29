import QtQuick
import org.kde.ksysguard.sensors as Sensors

// A sensor sampled whenever `sampleTrigger` changes, with an optional rolling history
// buffer. The Dashboard bumps `sampleTrigger` from ONE shared timer, so `value` and
// `history` only change once per update interval and no per-metric timers are needed.
Item {
    id: root

    property string sensorId: ""
    property int capacity: 60
    property int interval: 1000
    property bool keepHistory: true
    property int sampleTrigger: 0

    // Latest sampled value (0 while the sensor is unavailable)
    property real value: 0
    property bool available: false

    // Raw value as text, for string sensors such as gpu/gpu0/name
    readonly property string text: (sensor.value === undefined || sensor.value === null) ? "" : String(sensor.value)

    property var history: []

    visible: false
    width: 0
    height: 0

    Sensors.Sensor {
        id: sensor
        sensorId: root.sensorId
        enabled: root.sensorId !== ""
        updateRateLimit: root.interval
    }

    function sample() {
        var raw = sensor.value;
        var v = (raw === undefined || raw === null) ? NaN : Number(raw);

        if (!isFinite(v)) {
            root.available = false;
            if (root.history.length > 0)
                pushHistory(NaN);
            return;
        }

        root.value = v;
        root.available = true;
        pushHistory(v);
    }

    function pushHistory(v) {
        if (!root.keepHistory)
            return;
        const cap = Math.max(1, Math.round(root.capacity));
        const h = root.history.slice(Math.max(0, root.history.length - (cap - 1)));

        h.push(v);
        root.history = h;
    }

    onSampleTriggerChanged: sample()
    Component.onCompleted: sample()

    // Don't hold on to stale data while the history is switched off
    onKeepHistoryChanged: {
        if (!keepHistory)
            root.history = [];
    }

    // A different sensor or sample spacing makes the old history meaningless: it would
    // join onto the new line, and the chart's "Xs ago" times assume one fixed interval.
    onSensorIdChanged: root.history = []
    onIntervalChanged: root.history = []
}

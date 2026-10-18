import QtQuick
import QtQuick.Controls as QQC2

QQC2.SpinBox {
    from: 5
    to: 250
    stepSize: 5
    editable: true
    textFromValue: function (v) {
        return v + "%";
    }
    valueFromText: function (t) {
        var n = parseInt(t);
        return isNaN(n) ? 100 : n;
    }
}

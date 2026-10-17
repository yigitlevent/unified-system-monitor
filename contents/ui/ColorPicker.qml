import QtQuick
import org.kde.kquickcontrols as KQuickControls

// Thin wrapper around KDE's colour button. Loaded through a Loader by ColorField,
// so if org.kde.kquickcontrols is unavailable only this file fails.
KQuickControls.ColorButton {
    id: button

    property string value: ""
    property bool alpha: false
    signal picked(string hex)

    showAlphaChannel: alpha
    dialogTitle: "Choose a colour"

    Binding {
        target: button
        property: "color"
        value: button.value
    }

    onAccepted: function (c) {
        button.picked(String(c));
    }
}

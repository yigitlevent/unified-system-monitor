import QtQuick
import QtQuick.Layouts

// Thin vertical separator between Stats.
Rectangle {
    required property var ui
    Layout.preferredWidth: 1
    Layout.fillHeight: true
    Layout.topMargin: 6
    Layout.bottomMargin: 6
    color: ui.border
}

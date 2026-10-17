import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Top row of every card: one or more Stat blocks separated by Dividers.
// Never stretches vertically, so every chart gets the same room.
RowLayout {
    Layout.fillWidth: true
    Layout.fillHeight: false
    spacing: Kirigami.Units.gridUnit
}

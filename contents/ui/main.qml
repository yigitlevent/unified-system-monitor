import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    id: root

    // Always show the full dashboard (it's a desktop widget, not a panel icon)
    preferredRepresentation: fullRepresentation

    // We draw our own rounded panel, so drop Plasma's frame
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    fullRepresentation: Dashboard {}
}

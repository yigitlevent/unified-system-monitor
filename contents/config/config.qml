import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: "General"
        icon: "preferences-system"
        source: "configGeneral.qml"
    }
    ConfigCategory {
        name: "Layout"
        icon: "view-grid"
        source: "configLayout.qml"
    }
    ConfigCategory {
        name: "Appearance"
        icon: "preferences-desktop-font"
        source: "configAppearance.qml"
    }
    ConfigCategory {
        name: "Colors"
        icon: "preferences-desktop-color"
        source: "configColors.qml"
    }
}

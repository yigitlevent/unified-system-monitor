pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import "Theme.js" as Theme

KCM.SimpleKCM {
    id: page

    // Colours, stored as "#rrggbb" / "#aarrggbb"
    property string cfg_panelColor: ""
    property string cfg_cardColor: ""
    property string cfg_borderColor: ""
    property string cfg_textColor: ""
    property string cfg_mutedColor: ""
    property string cfg_cpuColor: ""
    property string cfg_cpuTempColor: ""
    property string cfg_ramColor: ""
    property string cfg_gpuColor: ""
    property string cfg_gpuCoreColor: ""
    property string cfg_gpuJunctionColor: ""
    property string cfg_netDownColor: ""
    property string cfg_netUpColor: ""
    property string cfg_diskReadColor: ""
    property string cfg_diskWriteColor: ""
    property string cfg_barLowColor: ""
    property string cfg_barMidColor: ""
    property string cfg_barHighColor: ""

    // One row per colour setting. `key` names both the cfg_<key>Color property
    // above and its default in Theme.js.
    readonly property var surfaceFields: [
        { key: "panel", label: "Main box background:", alpha: true },
        { key: "card", label: "Card background:", alpha: true },
        { key: "border", label: "Borders:", alpha: true },
        { key: "text", label: "Text:", alpha: false },
        { key: "muted", label: "Secondary text:", alpha: false }
    ]
    readonly property var accentFields: [
        { key: "cpu", label: "CPU usage:", alpha: false },
        { key: "cpuTemp", label: "CPU temp:", alpha: false },
        { key: "ram", label: "RAM:", alpha: false },
        { key: "gpu", label: "GPU usage:", alpha: false },
        { key: "gpuCore", label: "GPU core temp:", alpha: false },
        { key: "gpuJunction", label: "GPU junction temp:", alpha: false },
        { key: "netDown", label: "Download:", alpha: false },
        { key: "netUp", label: "Upload:", alpha: false },
        { key: "diskRead", label: "Disk read:", alpha: false },
        { key: "diskWrite", label: "Disk write:", alpha: false }
    ]
    readonly property var barFields: [
        { key: "barLow", label: "Low load:", alpha: false },
        { key: "barMid", label: "Medium load:", alpha: false },
        { key: "barHigh", label: "High load:", alpha: false }
    ]

    // A colour setting row, built from one entry of the tables above
    component SettingField: ColorField {
        required property var modelData
        readonly property string prop: "cfg_" + modelData.key + "Color"

        Kirigami.FormData.label: modelData.label
        alpha: modelData.alpha
        value: page[prop]
        defaultValue: Theme[modelData.key]
        onEdited: function (v) {
            page[prop] = v;
        }
    }

    Kirigami.FormLayout {
        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Surfaces and text"
        }
        Repeater {
            model: page.surfaceFields
            delegate: SettingField {}
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Accents"
        }
        Repeater {
            model: page.accentFields
            delegate: SettingField {}
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "CPU core bars"
        }
        Repeater {
            model: page.barFields
            delegate: SettingField {}
        }
    }
}

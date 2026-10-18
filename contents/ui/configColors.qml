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

    Kirigami.FormLayout {
        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Surfaces and text"
        }

        ColorField {
            Kirigami.FormData.label: "Main box background:"
            alpha: true
            value: page.cfg_panelColor
            defaultValue: Theme.panel
            onEdited: function (v) {
                page.cfg_panelColor = v;
            }
        }
        ColorField {
            Kirigami.FormData.label: "Card background:"
            alpha: true
            value: page.cfg_cardColor
            defaultValue: Theme.card
            onEdited: function (v) {
                page.cfg_cardColor = v;
            }
        }
        ColorField {
            Kirigami.FormData.label: "Borders:"
            alpha: true
            value: page.cfg_borderColor
            defaultValue: Theme.border
            onEdited: function (v) {
                page.cfg_borderColor = v;
            }
        }
        ColorField {
            Kirigami.FormData.label: "Text:"
            alpha: false
            value: page.cfg_textColor
            defaultValue: Theme.text
            onEdited: function (v) {
                page.cfg_textColor = v;
            }
        }
        ColorField {
            Kirigami.FormData.label: "Secondary text:"
            alpha: false
            value: page.cfg_mutedColor
            defaultValue: Theme.muted
            onEdited: function (v) {
                page.cfg_mutedColor = v;
            }
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Accents"
        }

        ColorField {
            Kirigami.FormData.label: "CPU usage:"
            alpha: false
            value: page.cfg_cpuColor
            defaultValue: Theme.blue
            onEdited: function (v) {
                page.cfg_cpuColor = v;
            }
        }
        ColorField {
            Kirigami.FormData.label: "CPU temp:"
            alpha: false
            value: page.cfg_cpuTempColor
            defaultValue: Theme.sky
            onEdited: function (v) {
                page.cfg_cpuTempColor = v;
            }
        }
        ColorField {
            Kirigami.FormData.label: "RAM:"
            alpha: false
            value: page.cfg_ramColor
            defaultValue: Theme.purple
            onEdited: function (v) {
                page.cfg_ramColor = v;
            }
        }
        ColorField {
            Kirigami.FormData.label: "GPU usage:"
            alpha: false
            value: page.cfg_gpuColor
            defaultValue: Theme.orange
            onEdited: function (v) {
                page.cfg_gpuColor = v;
            }
        }
        ColorField {
            Kirigami.FormData.label: "GPU core temp:"
            alpha: false
            value: page.cfg_gpuCoreColor
            defaultValue: Theme.amber
            onEdited: function (v) {
                page.cfg_gpuCoreColor = v;
            }
        }
        ColorField {
            Kirigami.FormData.label: "GPU junction temp:"
            alpha: false
            value: page.cfg_gpuJunctionColor
            defaultValue: Theme.red
            onEdited: function (v) {
                page.cfg_gpuJunctionColor = v;
            }
        }
        ColorField {
            Kirigami.FormData.label: "Download:"
            alpha: false
            value: page.cfg_netDownColor
            defaultValue: Theme.teal
            onEdited: function (v) {
                page.cfg_netDownColor = v;
            }
        }
        ColorField {
            Kirigami.FormData.label: "Upload:"
            alpha: false
            value: page.cfg_netUpColor
            defaultValue: Theme.blue
            onEdited: function (v) {
                page.cfg_netUpColor = v;
            }
        }
        ColorField {
            Kirigami.FormData.label: "Disk read:"
            alpha: false
            value: page.cfg_diskReadColor
            defaultValue: Theme.blue
            onEdited: function (v) {
                page.cfg_diskReadColor = v;
            }
        }
        ColorField {
            Kirigami.FormData.label: "Disk write:"
            alpha: false
            value: page.cfg_diskWriteColor
            defaultValue: Theme.purple
            onEdited: function (v) {
                page.cfg_diskWriteColor = v;
            }
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "CPU core bars"
        }

        ColorField {
            Kirigami.FormData.label: "Low load:"
            alpha: false
            value: page.cfg_barLowColor
            defaultValue: Theme.teal
            onEdited: function (v) {
                page.cfg_barLowColor = v;
            }
        }
        ColorField {
            Kirigami.FormData.label: "Medium load:"
            alpha: false
            value: page.cfg_barMidColor
            defaultValue: Theme.green
            onEdited: function (v) {
                page.cfg_barMidColor = v;
            }
        }
        ColorField {
            Kirigami.FormData.label: "High load:"
            alpha: false
            value: page.cfg_barHighColor
            defaultValue: Theme.amber
            onEdited: function (v) {
                page.cfg_barHighColor = v;
            }
        }
    }
}

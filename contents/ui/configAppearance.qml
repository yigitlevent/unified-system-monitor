pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page

    property alias cfg_titleScale: titleScale.value
    property alias cfg_cardTitleScale: cardTitleScale.value
    property alias cfg_valueScale: valueScale.value
    property alias cfg_captionScale: captionScale.value
    property alias cfg_chartLabelScale: chartLabelScale.value
    property alias cfg_panelRadius: panelRadius.value
    property alias cfg_cardRadius: cardRadius.value
    property alias cfg_outerGap: outerGap.value
    property alias cfg_cardGap: cardGap.value

    // Main box parts are shown unless hidden
    property bool cfg_hidePanelBorder: false
    property bool cfg_hideTitleBar: false

    // Card icons are shown unless hidden
    property bool cfg_hideCardIcons: false

    Kirigami.FormLayout {
        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Text sizes"
        }

        PercentSpinBox {
            id: titleScale
            Kirigami.FormData.label: "Widget title:"
        }
        PercentSpinBox {
            id: cardTitleScale
            Kirigami.FormData.label: "Card titles:"
        }
        PercentSpinBox {
            id: valueScale
            Kirigami.FormData.label: "Big numbers:"
        }
        PercentSpinBox {
            id: captionScale
            Kirigami.FormData.label: "Captions & labels:"
        }
        PercentSpinBox {
            id: chartLabelScale
            Kirigami.FormData.label: "Chart axis labels:"
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Shape"
        }

        QQC2.SpinBox {
            id: panelRadius
            from: 0
            to: 60
            editable: true
            Kirigami.FormData.label: "Main box radius (px):"
        }
        QQC2.SpinBox {
            id: cardRadius
            from: 0
            to: 60
            editable: true
            Kirigami.FormData.label: "Card radius (px):"
        }
        QQC2.SpinBox {
            id: outerGap
            from: 0
            to: 80
            editable: true
            Kirigami.FormData.label: "Outer gap (px):"
        }
        QQC2.SpinBox {
            id: cardGap
            from: 0
            to: 80
            editable: true
            Kirigami.FormData.label: "Gap between cards (px):"
        }
        QQC2.CheckBox {
            Kirigami.FormData.label: "Main box:"
            text: "Show border"
            checked: !page.cfg_hidePanelBorder
            onToggled: page.cfg_hidePanelBorder = !checked
        }
        QQC2.CheckBox {
            text: "Show title bar (title and Live indicator)"
            checked: !page.cfg_hideTitleBar
            onToggled: page.cfg_hideTitleBar = !checked
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Icons"
        }

        QQC2.CheckBox {
            Kirigami.FormData.label: "Cards:"
            text: "Show card icons"
            checked: !page.cfg_hideCardIcons
            onToggled: page.cfg_hideCardIcons = !checked
        }
    }
}

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import "Theme.js" as Theme

KCM.SimpleKCM {
    id: page

    property alias cfg_processLimit: processLimit.value
    property alias cfg_processCardCols: processCardCols.value

    property alias cfg_cpuLabelOverride: cpuOverride.text
    property alias cfg_gpuLabelOverride: gpuOverride.text
    property alias cfg_gpuTempSensor: gpuTemp.text
    property alias cfg_gpuJunctionSensor: gpuJunction.text
    property alias cfg_diskId: diskId.text
    property alias cfg_diskLabel: diskLabel.text
    property alias cfg_updateInterval: interval.value
    property alias cfg_coreRows: coreRows.value
    property alias cfg_cardsPerRow: cardsPerRow.value

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

    // Charts are shown unless hidden (so a missing default can never hide them)
    property bool cfg_hideChartCpuUsage: false
    property bool cfg_hideChartCpuTemp: false
    property bool cfg_hideChartRam: false
    property bool cfg_hideChartGpuUsage: false
    property bool cfg_hideChartGpuCore: false
    property bool cfg_hideChartGpuJunction: false
    property bool cfg_hideChartNetwork: false
    property bool cfg_hideChartDisk: false

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

    // Card order, stored as "cpu,ram,cores,gpu,network,disk"
    property string cfg_cardOrder: ""

    readonly property var cardNames: ({
            cpuUsage: "CPU Usage",
            cpuTemp: "CPU Temperature",
            ram: "RAM",
            cores: "CPU Cores",
            gpuUsage: "GPU Usage",
            gpuCore: "GPU Core Temperature",
            gpuJunction: "GPU Junction Temperature",
            network: "Network",
            disk: "Disk I/O",
            processMonitor: "Process Monitor"
        })
    readonly property var cardKeys: ["cpuUsage", "cpuTemp", "ram", "cores", "gpuUsage", "gpuCore", "gpuJunction", "network", "disk", "processMonitor"]
    property bool busy: false
    readonly property real rowHeight: Kirigami.Units.gridUnit * 2.4

    ListModel {
        id: orderModel
    }

    function load() {
        busy = true;
        orderModel.clear();
        // old two-card keys from earlier versions expand to their new cards
        var legacy = {
            "cpu": ["cpuUsage", "cpuTemp"],
            "gpu": ["gpuUsage", "gpuCore", "gpuJunction"]
        };
        var seen = {};
        function add(k) {
            if (cardNames[k] !== undefined && !seen[k]) {
                seen[k] = true;
                orderModel.append({
                    cardKey: k,
                    cardName: cardNames[k]
                });
            }
        }
        var parts = String(cfg_cardOrder || "").split(",");
        for (let i = 0; i < parts.length; i++) {
            const k = parts[i].trim();
            if (legacy[k] !== undefined) {
                for (let j = 0; j < legacy[k].length; j++)
                    add(legacy[k][j]);
            } else
                add(k);
        }
        for (let m = 0; m < cardKeys.length; m++)
            add(cardKeys[m]);
        busy = false;
    }

    function save() {
        var out = [];
        for (let i = 0; i < orderModel.count; i++)
            out.push(orderModel.get(i).cardKey);
        busy = true;
        cfg_cardOrder = out.join(",");
        busy = false;
    }

    onCfg_cardOrderChanged: if (!busy)
        load()
    Component.onCompleted: load()

    Kirigami.FormLayout {
        QQC2.SpinBox {
            id: processLimit
            Kirigami.FormData.label: "Number of processes:"
            from: 1
            to: 50
        }

        QQC2.SpinBox {
            id: processCardCols
            Kirigami.FormData.label: "Process monitor column span:"
            from: 1
            to: 6
            editable: true
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Card order"
        }

        QQC2.SpinBox {
            id: cardsPerRow
            from: 1
            to: 6
            editable: true
            Kirigami.FormData.label: "Cards per row:"
        }

        // Reorderable list: drag the grip, or use the arrows
        Item {
            id: orderArea
            Kirigami.FormData.label: "Drag to reorder:"
            Kirigami.FormData.labelAlignment: Qt.AlignTop
            Layout.preferredWidth: Kirigami.Units.gridUnit * 20
            Layout.preferredHeight: orderModel.count * page.rowHeight
            Layout.minimumHeight: orderModel.count * page.rowHeight

            Repeater {
                model: orderModel

                delegate: Rectangle {
                    id: row

                    required property int index
                    required property string cardKey
                    required property string cardName

                    readonly property bool dragging: grip.drag.active

                    width: orderArea.width
                    height: page.rowHeight - 4
                    radius: 6
                    z: dragging ? 10 : 1
                    color: dragging ? Kirigami.Theme.highlightColor : Kirigami.Theme.alternateBackgroundColor
                    border.width: 1
                    border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.2)

                    // Snap to the slot for this index whenever we're not being dragged
                    Binding on y {
                        when: !row.dragging
                        value: row.index * page.rowHeight
                        restoreMode: Binding.RestoreNone
                    }
                    Behavior on y {
                        enabled: !row.dragging
                        NumberAnimation {
                            duration: Kirigami.Units.shortDuration
                        }
                    }

                    // While dragging, swap places with whichever slot we're over
                    onYChanged: {
                        if (!row.dragging)
                            return;
                        var target = Math.max(0, Math.min(orderModel.count - 1, Math.round(row.y / page.rowHeight)));
                        if (target !== row.index)
                            orderModel.move(row.index, target, 1);
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Kirigami.Units.smallSpacing * 2
                        anchors.rightMargin: Kirigami.Units.smallSpacing
                        spacing: Kirigami.Units.smallSpacing

                        Item {
                            Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                            Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium

                            Kirigami.Icon {
                                anchors.fill: parent
                                source: "handle-sort"
                            }
                            MouseArea {
                                id: grip
                                anchors.fill: parent
                                anchors.margins: -Kirigami.Units.smallSpacing
                                cursorShape: Qt.SizeVerCursor
                                drag.target: row
                                drag.axis: Drag.YAxis
                                drag.minimumY: 0
                                drag.maximumY: (orderModel.count - 1) * page.rowHeight
                                onReleased: page.save()
                            }
                        }

                        QQC2.Label {
                            text: row.cardName
                            Layout.fillWidth: true
                        }
                        QQC2.ToolButton {
                            icon.name: "go-up"
                            enabled: row.index > 0
                            onClicked: {
                                orderModel.move(row.index, row.index - 1, 1);
                                page.save();
                            }
                        }
                        QQC2.ToolButton {
                            icon.name: "go-down"
                            enabled: row.index < orderModel.count - 1
                            onClicked: {
                                orderModel.move(row.index, row.index + 1, 1);
                                page.save();
                            }
                        }
                    }
                }
            }
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "General"
        }

        QQC2.TextField {
            id: cpuOverride
            Layout.minimumWidth: Kirigami.Units.gridUnit * 20
            placeholderText: "Detected automatically"
            Kirigami.FormData.label: "Custom CPU label:"
        }
        QQC2.SpinBox {
            id: interval
            from: 250
            to: 10000
            stepSize: 250
            Kirigami.FormData.label: "Update interval (ms):"
        }
        QQC2.SpinBox {
            id: coreRows
            from: 1
            to: 8
            Kirigami.FormData.label: "CPU core rows:"
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "GPU"
        }

        QQC2.TextField {
            id: gpuOverride
            Layout.minimumWidth: Kirigami.Units.gridUnit * 20
            placeholderText: "Detected automatically"
            Kirigami.FormData.label: "Custom GPU label:"
        }
        QQC2.TextField {
            id: gpuTemp
            Layout.minimumWidth: Kirigami.Units.gridUnit * 20
            Kirigami.FormData.label: "Core temp sensor ID:"
        }
        QQC2.TextField {
            id: gpuJunction
            Layout.minimumWidth: Kirigami.Units.gridUnit * 20
            placeholderText: "e.g. lmsensors/amdgpu-pci-.../temp2 (empty = hide)"
            Kirigami.FormData.label: "Junction temp sensor ID:"
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Disk"
        }

        QQC2.TextField {
            id: diskId
            Layout.minimumWidth: Kirigami.Units.gridUnit * 20
            placeholderText: "all, or the device id from System Monitor"
            Kirigami.FormData.label: "Disk sensor ID:"
        }
        QQC2.TextField {
            id: diskLabel
            Kirigami.FormData.label: "Disk label:"
        }

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
            Kirigami.FormData.label: "Colors: surfaces and text"
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
            Kirigami.FormData.label: "Colors: accents"
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
            Kirigami.FormData.label: "Colors: CPU core bars"
        }

        ColorField {
            Kirigami.FormData.label: "Low load (< 30%):"
            alpha: false
            value: page.cfg_barLowColor
            defaultValue: Theme.teal
            onEdited: function (v) {
                page.cfg_barLowColor = v;
            }
        }
        ColorField {
            Kirigami.FormData.label: "Medium load (30–40%):"
            alpha: false
            value: page.cfg_barMidColor
            defaultValue: Theme.green
            onEdited: function (v) {
                page.cfg_barMidColor = v;
            }
        }
        ColorField {
            Kirigami.FormData.label: "High load (≥ 40%):"
            alpha: false
            value: page.cfg_barHighColor
            defaultValue: Theme.amber
            onEdited: function (v) {
                page.cfg_barHighColor = v;
            }
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Charts"
        }

        QQC2.CheckBox {
            Kirigami.FormData.label: "Show charts for:"
            text: "CPU usage"
            checked: !page.cfg_hideChartCpuUsage
            onToggled: page.cfg_hideChartCpuUsage = !checked
        }
        QQC2.CheckBox {
            text: "CPU temperature"
            checked: !page.cfg_hideChartCpuTemp
            onToggled: page.cfg_hideChartCpuTemp = !checked
        }
        QQC2.CheckBox {
            text: "RAM"
            checked: !page.cfg_hideChartRam
            onToggled: page.cfg_hideChartRam = !checked
        }
        QQC2.CheckBox {
            text: "GPU usage"
            checked: !page.cfg_hideChartGpuUsage
            onToggled: page.cfg_hideChartGpuUsage = !checked
        }
        QQC2.CheckBox {
            text: "GPU core temperature"
            checked: !page.cfg_hideChartGpuCore
            onToggled: page.cfg_hideChartGpuCore = !checked
        }
        QQC2.CheckBox {
            text: "GPU junction temperature"
            checked: !page.cfg_hideChartGpuJunction
            onToggled: page.cfg_hideChartGpuJunction = !checked
        }
        QQC2.CheckBox {
            text: "Network"
            checked: !page.cfg_hideChartNetwork
            onToggled: page.cfg_hideChartNetwork = !checked
        }
        QQC2.CheckBox {
            text: "Disk I/O"
            checked: !page.cfg_hideChartDisk
            onToggled: page.cfg_hideChartDisk = !checked
        }
    }
}

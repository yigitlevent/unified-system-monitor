pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page

    property alias cfg_cardsPerRow: cardsPerRow.value
    property alias cfg_processLimit: processLimit.value
    property alias cfg_processCardCols: processCardCols.value

    // Process monitor columns are shown unless hidden
    property bool cfg_hideColPid: false
    property bool cfg_hideColUser: false
    property bool cfg_hideColName: false
    property bool cfg_hideColCpu: false
    property bool cfg_hideColRam: false
    property bool cfg_hideColGpu: false
    property bool cfg_hideColVram: false
    property bool cfg_hideColDown: false
    property bool cfg_hideColUp: false
    property bool cfg_hideColRead: false
    property bool cfg_hideColWrite: false

    // Charts are shown unless hidden (so a missing default can never hide them)
    property bool cfg_hideChartCpuUsage: false
    property bool cfg_hideChartCpuTemp: false
    property bool cfg_hideChartRam: false
    property bool cfg_hideChartGpuUsage: false
    property bool cfg_hideChartGpuCore: false
    property bool cfg_hideChartGpuJunction: false
    property bool cfg_hideChartNetwork: false
    property bool cfg_hideChartDisk: false

    // Card order, stored as "cpuUsage,cpuTemp,ram,..."
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
            Kirigami.FormData.label: "Process monitor"
        }

        QQC2.SpinBox {
            id: processLimit
            Kirigami.FormData.label: "Number of processes:"
            from: 1
            to: 50
            editable: true
        }

        QQC2.SpinBox {
            id: processCardCols
            Kirigami.FormData.label: "Process monitor column span:"
            from: 1
            to: 6
            editable: true
        }

        QQC2.CheckBox {
            Kirigami.FormData.label: "Show columns:"
            text: "PID"
            checked: !page.cfg_hideColPid
            onToggled: page.cfg_hideColPid = !checked
        }
        QQC2.CheckBox {
            text: "User"
            checked: !page.cfg_hideColUser
            onToggled: page.cfg_hideColUser = !checked
        }
        QQC2.CheckBox {
            text: "Process"
            checked: !page.cfg_hideColName
            onToggled: page.cfg_hideColName = !checked
        }
        QQC2.CheckBox {
            text: "CPU"
            checked: !page.cfg_hideColCpu
            onToggled: page.cfg_hideColCpu = !checked
        }
        QQC2.CheckBox {
            text: "RAM"
            checked: !page.cfg_hideColRam
            onToggled: page.cfg_hideColRam = !checked
        }
        QQC2.CheckBox {
            text: "GPU"
            checked: !page.cfg_hideColGpu
            onToggled: page.cfg_hideColGpu = !checked
        }
        QQC2.CheckBox {
            text: "VRAM"
            checked: !page.cfg_hideColVram
            onToggled: page.cfg_hideColVram = !checked
        }
        QQC2.CheckBox {
            text: "Down"
            checked: !page.cfg_hideColDown
            onToggled: page.cfg_hideColDown = !checked
        }
        QQC2.CheckBox {
            text: "Up"
            checked: !page.cfg_hideColUp
            onToggled: page.cfg_hideColUp = !checked
        }
        QQC2.CheckBox {
            text: "Read"
            checked: !page.cfg_hideColRead
            onToggled: page.cfg_hideColRead = !checked
        }
        QQC2.CheckBox {
            text: "Write"
            checked: !page.cfg_hideColWrite
            onToggled: page.cfg_hideColWrite = !checked
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

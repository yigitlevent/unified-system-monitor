pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as P5Support
import "Theme.js" as Theme
import "Format.js" as Format

Item {
    id: dash

    readonly property var cfg: Plasmoid.configuration
    // Fallbacks so the widget still works if config defaults are missing/empty
    readonly property int tick: cfg.updateInterval >= 250 ? cfg.updateInterval : 1000
    // ---- Card order + grid ----
    readonly property var cardKeys: ["cpuUsage", "cpuTemp", "ram", "cores", "gpuUsage", "gpuCore", "gpuJunction", "network", "disk", "processMonitor"]
    readonly property bool junctionOn: cfg.gpuJunctionSensor !== ""
    readonly property int cols: Math.max(1, Math.min(6, cfg.cardsPerRow > 0 ? cfg.cardsPerRow : 3))
    readonly property var order: parseOrder(cfg.cardOrder, junctionOn)
    readonly property var gridPlan: buildGridPlan(order, cols, cfg.processCardCols)
    readonly property int rowCount: gridPlan.rowCount

    // Understands the old two-card keys ("cpu", "gpu") too, and appends anything missing.
    function parseOrder(str, junction) {
        var legacy = {
            "cpu": ["cpuUsage", "cpuTemp"],
            "gpu": ["gpuUsage", "gpuCore", "gpuJunction"]
        };
        var out = [];
        function add(k) {
            if (cardKeys.indexOf(k) >= 0 && out.indexOf(k) < 0)
                out.push(k);
        }
        var parts = String(str || "").split(",");
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
        // the junction card only exists when a junction sensor is set
        return junction ? out : out.filter(function (x) {
            return x !== "gpuJunction";
        });
    }

    function buildGridPlan(keys, columnCount, requestedProcessSpan) {
        const safeColumns = Math.max(1, Math.floor(columnCount));

        const processSpan = Math.max(1, Math.min(safeColumns, Math.floor(requestedProcessSpan > 0 ? requestedProcessSpan : 1)));

        const placements = [];
        let row = 0;
        let column = 0;

        for (let i = 0; i < keys.length; ++i) {
            const key = keys[i];
            const span = key === "processMonitor" ? processSpan : 1;

            // Start a new row if this card won't fit.
            if (column + span > safeColumns) {
                row++;
                column = 0;
            }

            placements.push({
                key: key,
                row: row,
                column: column,
                span: span
            });

            column += span;

            // Advance when the row is full.
            if (column >= safeColumns) {
                row++;
                column = 0;
            }
        }

        return {
            placements: placements,
            rowCount: Math.max(1, row + (column > 0 ? 1 : 0))
        };
    }

    function placementOf(key) {
        for (let i = 0; i < gridPlan.placements.length; ++i) {
            const placement = gridPlan.placements[i];

            if (placement.key === key)
                return placement;
        }

        return {
            row: 0,
            column: 0,
            span: 1
        };
    }

    function rowOf(key) {
        return placementOf(key).row;
    }

    function colOf(key) {
        return placementOf(key).column;
    }

    function colSpanOf(key) {
        return placementOf(key).span;
    }

    // Logical thread count, read from the system (0 until the sensor reports)
    readonly property int coreRows: cfg.coreRows > 0 ? cfg.coreRows : 2
    readonly property int threads: Math.max(0, Math.round(coreCount.value))
    readonly property string gpuTempId: cfg.gpuTempSensor !== "" ? cfg.gpuTempSensor : "gpu/gpu0/temperature"
    // CPU model comes from /proc/cpuinfo (read once at startup)
    property string cpuModel: ""

    P5Support.DataSource {
        id: cpuInfoSource
        engine: "executable"
        connectedSources: ["grep -m1 'model name' /proc/cpuinfo"]
        onNewData: function (sourceName, data) {
            dash.cpuModel = Format.cpuInfoModel(data["stdout"]);
            disconnectSource(sourceName);
        }
    }

    // Labels: a custom label from settings wins, otherwise use the detected name
    readonly property string cpuLabel: cfg.cpuLabelOverride !== "" ? cfg.cpuLabelOverride : Format.cleanCpu(dash.cpuModel)
    readonly property string gpuLabel: cfg.gpuLabelOverride !== "" ? cfg.gpuLabelOverride : Format.cleanGpu(gpuNameSensor.text)
    readonly property string diskKey: cfg.diskId !== "" ? cfg.diskId : "all"
    readonly property real u: Kirigami.Units.gridUnit
    readonly property real outerGap: cfg.outerGap   // space between the main box edge and the cards
    readonly property real cardGap: cfg.cardGap     // space between cards (and under the title bar)
    // Big-number size: 2 grid units, shrinking a little when the widget is narrow
    readonly property real statSize: Math.max(u * 1.2, Math.min(u * 2.0, ((dash.width - 2 * outerGap - (cols - 1) * cardGap) / cols - u * 1.8) / 10.5))

    Layout.minimumWidth: 0
    Layout.minimumHeight: 0
    Layout.preferredWidth: u * (40 + 6 * cols)
    Layout.preferredHeight: u * (8 + 11.3 * rowCount)

    // ---------- Sensors ----------
    Metric {
        id: cpu
        sensorId: "cpu/all/usage"
        interval: dash.tick
    }
    Metric {
        id: gpuNameSensor
        sensorId: "gpu/gpu0/name"
        interval: dash.tick
        keepHistory: false
    }
    Metric {
        id: coreCount
        sensorId: "cpu/all/coreCount"
        interval: dash.tick
        keepHistory: false
    }
    Metric {
        id: cpuTemp
        sensorId: "cpu/all/averageTemperature"
        interval: dash.tick
    }

    Metric {
        id: ram
        sensorId: "memory/physical/used"
        interval: dash.tick
    }
    Metric {
        id: ramTotal
        sensorId: "memory/physical/total"
        interval: dash.tick
        keepHistory: false
    }

    Metric {
        id: gpu
        sensorId: "gpu/gpu0/usage"
        interval: dash.tick
    }
    Metric {
        id: gpuTemp
        sensorId: dash.gpuTempId
        interval: dash.tick
    }
    Metric {
        id: gpuJunc
        sensorId: dash.cfg.gpuJunctionSensor
        interval: dash.tick
    }

    Metric {
        id: netDown
        sensorId: "network/all/download"
        interval: dash.tick
    }
    Metric {
        id: netUp
        sensorId: "network/all/upload"
        interval: dash.tick
    }

    Metric {
        id: diskRead
        sensorId: "disk/" + dash.diskKey + "/read"
        interval: dash.tick
    }
    Metric {
        id: diskWrite
        sensorId: "disk/" + dash.diskKey + "/write"
        interval: dash.tick
    }

    // ---------- Look & feel (from the settings, with safe fallbacks) ----------
    QtObject {
        id: uiStyle

        function pick(v, d) {
            return /^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/.test(String(v)) ? String(v) : d;
        }
        function factor(v) {
            return v > 0 ? v / 100 : 1;
        }

        // surfaces + text
        readonly property color panel: pick(dash.cfg.panelColor, Theme.panel)
        readonly property color card: pick(dash.cfg.cardColor, Theme.card)
        readonly property color border: pick(dash.cfg.borderColor, Theme.border)
        readonly property color text: pick(dash.cfg.textColor, Theme.text)
        readonly property color muted: pick(dash.cfg.mutedColor, Theme.muted)
        readonly property color track: Qt.rgba(0, 0, 0, 0.30)
        readonly property color trackBorder: Qt.rgba(text.r, text.g, text.b, 0.12)

        // accents
        readonly property color cpu: pick(dash.cfg.cpuColor, Theme.blue)
        readonly property color cpuTemp: pick(dash.cfg.cpuTempColor, Theme.sky)
        readonly property color ram: pick(dash.cfg.ramColor, Theme.purple)
        readonly property color gpu: pick(dash.cfg.gpuColor, Theme.orange)
        readonly property color gpuCore: pick(dash.cfg.gpuCoreColor, Theme.amber)
        readonly property color gpuJunction: pick(dash.cfg.gpuJunctionColor, Theme.red)
        readonly property color netDown: pick(dash.cfg.netDownColor, Theme.teal)
        readonly property color netUp: pick(dash.cfg.netUpColor, Theme.blue)
        readonly property color diskRead: pick(dash.cfg.diskReadColor, Theme.blue)
        readonly property color diskWrite: pick(dash.cfg.diskWriteColor, Theme.purple)
        readonly property color barLow: pick(dash.cfg.barLowColor, Theme.teal)
        readonly property color barMid: pick(dash.cfg.barMidColor, Theme.green)
        readonly property color barHigh: pick(dash.cfg.barHighColor, Theme.amber)

        // shape
        readonly property real panelRadius: dash.cfg.panelRadius
        readonly property real cardRadius: dash.cfg.cardRadius

        // text sizes (pixels)
        readonly property real titleSize: dash.u * 1.7 * factor(dash.cfg.titleScale)
        readonly property real cardTitleSize: dash.u * 1.05 * factor(dash.cfg.cardTitleScale)
        readonly property real cardSubtitleSize: dash.u * 0.95 * factor(dash.cfg.cardTitleScale)
        readonly property real valueSize: dash.statSize * factor(dash.cfg.valueScale)
        readonly property real captionSize: dash.u * 0.8 * factor(dash.cfg.captionScale)
        readonly property real smallSize: dash.u * 0.75 * factor(dash.cfg.captionScale)
        readonly property real coreLabelSize: dash.u * 0.75 * factor(dash.cfg.captionScale)
        readonly property real chartLabelSize: 9 * factor(dash.cfg.chartLabelScale)

        // same font as the rest of the desktop (used by the chart axis text)
        readonly property string fontFamily: Kirigami.Theme.defaultFont.family

        // icons follow the text they sit next to
        readonly property real iconSize: Math.round(cardTitleSize * 1.17)
        readonly property real headerIconSize: Math.round(titleSize * 1.05)

        // main box
        readonly property bool showPanelBorder: !dash.cfg.hidePanelBorder
        readonly property bool showTitleBar: !dash.cfg.hideTitleBar

        // charts on/off per card
        readonly property bool showCpuUsage: !dash.cfg.hideChartCpuUsage
        readonly property bool showCpuTemp: !dash.cfg.hideChartCpuTemp
        readonly property bool showRam: !dash.cfg.hideChartRam
        readonly property bool showGpuUsage: !dash.cfg.hideChartGpuUsage
        readonly property bool showGpuCore: !dash.cfg.hideChartGpuCore
        readonly property bool showGpuJunction: !dash.cfg.hideChartGpuJunction
        readonly property bool showNetwork: !dash.cfg.hideChartNetwork
        readonly property bool showDisk: !dash.cfg.hideChartDisk
    }

    // ---------- UI ----------
    Rectangle {
        anchors.fill: parent
        radius: uiStyle.panelRadius
        color: uiStyle.panel
        border.width: uiStyle.showPanelBorder ? 1 : 0
        border.color: uiStyle.border

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: dash.outerGap
            spacing: dash.cardGap

            // Header (title bar)
            RowLayout {
                visible: uiStyle.showTitleBar
                Layout.fillWidth: true
                spacing: dash.u * 0.7

                Kirigami.Icon {
                    source: "computer"
                    Layout.preferredWidth: uiStyle.headerIconSize
                    Layout.preferredHeight: uiStyle.headerIconSize
                }
                Text {
                    text: "System Monitor"
                    color: uiStyle.text
                    font.pixelSize: uiStyle.titleSize
                    font.weight: Font.DemiBold
                }
                Item {
                    Layout.fillWidth: true
                }
                Rectangle {
                    implicitWidth: 10
                    implicitHeight: 10
                    radius: 5
                    color: Theme.teal
                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        NumberAnimation {
                            to: 0.35
                            duration: 900
                        }
                        NumberAnimation {
                            to: 1.0
                            duration: 900
                        }
                    }
                }
                Text {
                    text: "Live"
                    color: uiStyle.muted
                    font.pixelSize: uiStyle.captionSize * 1.05
                }
            }

            // Cards, placed in a grid by the order and cards-per-row from the settings.
            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: dash.cols
                rowSpacing: dash.cardGap
                columnSpacing: dash.cardGap
                uniformCellWidths: true
                uniformCellHeights: true

                // ---- CPU usage ----
                ChartCard {
                    ui: uiStyle
                    Layout.row: dash.rowOf("cpuUsage")
                    Layout.column: dash.colOf("cpuUsage")
                    iconName: "cpu"
                    title: "CPU Usage"
                    subtitle: dash.cpuLabel
                    showChart: uiStyle.showCpuUsage
                    seriesData: [cpu.history]
                    seriesColors: [uiStyle.cpu]
                    capacity: cpu.capacity
                    labelFormatter: Format.percentLabel
                    maxValue: 0
                    autoFloor: 20

                    Stat {
                        ui: uiStyle
                        value: cpu.available ? Format.pct(cpu.value) : "--"
                        unit: cpu.available ? "%" : ""
                        label: "Total"
                        accent: uiStyle.cpu
                    }
                }

                // ---- CPU temperature ----
                ChartCard {
                    ui: uiStyle
                    Layout.row: dash.rowOf("cpuTemp")
                    Layout.column: dash.colOf("cpuTemp")
                    iconName: "cpu"
                    title: "CPU Temp"
                    showChart: uiStyle.showCpuTemp
                    seriesData: [cpuTemp.history]
                    seriesColors: [uiStyle.cpuTemp]
                    capacity: cpuTemp.capacity
                    labelFormatter: Format.tempLabel
                    maxValue: 0
                    zoom: true
                    autoFloor: 10

                    Stat {
                        ui: uiStyle
                        value: cpuTemp.available ? Format.tempNumber(cpuTemp.value) : "--"
                        unit: cpuTemp.available ? "°C" : ""
                        label: "Average"
                        accent: uiStyle.cpuTemp
                    }
                }

                // ---- RAM ----
                ChartCard {
                    ui: uiStyle
                    Layout.row: dash.rowOf("ram")
                    Layout.column: dash.colOf("ram")
                    iconName: "memory"
                    title: "RAM"
                    showChart: uiStyle.showRam
                    seriesData: [ram.history]
                    seriesColors: [uiStyle.ram]
                    capacity: ram.capacity
                    labelFormatter: Format.gibLabel
                    maxValue: 0
                    zoom: true
                    autoFloor: 536870912

                    Stat {
                        ui: uiStyle
                        value: ram.available ? Format.gib(ram.value).toFixed(1) : "--"
                        unit: ram.available ? "GB" : ""
                        label: "Used"
                        accent: uiStyle.ram
                    }
                    Divider {
                        ui: uiStyle
                    }
                    Stat {
                        ui: uiStyle
                        value: ram.available && ramTotal.available && ramTotal.value > 0 ? String(Math.round(ram.value / ramTotal.value * 100)) : "--"
                        unit: ram.available && ramTotal.available && ramTotal.value > 0 ? "%" : ""
                        label: ramTotal.available ? "of " + Math.round(Format.gib(ramTotal.value)) + " GB" : "Total unavailable"
                        accent: uiStyle.text
                    }
                }

                // ---- CPU cores ----
                Card {
                    ui: uiStyle
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.row: dash.rowOf("cores")
                    Layout.column: dash.colOf("cores")
                    iconName: "cpu"
                    title: "CPU Cores"
                    headerRight: dash.threads + " logical threads"

                    GridLayout {
                        id: coreGrid
                        anchors.fill: parent
                        readonly property int rowCount: Math.max(1, Math.min(dash.coreRows, Math.max(1, dash.threads)))
                        rows: rowCount
                        columns: Math.max(1, Math.ceil(dash.threads / rowCount))
                        columnSpacing: dash.u * 0.35
                        rowSpacing: dash.u * 0.35
                        uniformCellWidths: true
                        uniformCellHeights: true

                        Repeater {
                            model: dash.threads
                            CoreBar {
                                required property int index
                                ui: uiStyle
                                cpuIndex: index
                                interval: dash.tick
                                showLabel: coreGrid.height / coreGrid.rowCount > dash.u * 3
                            }
                        }
                    }
                }

                // ---- GPU usage ----
                ChartCard {
                    ui: uiStyle
                    Layout.row: dash.rowOf("gpuUsage")
                    Layout.column: dash.colOf("gpuUsage")
                    iconName: "video-card"
                    title: "GPU Usage"
                    subtitle: dash.gpuLabel
                    showChart: uiStyle.showGpuUsage
                    seriesData: [gpu.history]
                    seriesColors: [uiStyle.gpu]
                    capacity: gpu.capacity
                    labelFormatter: Format.percentLabel
                    maxValue: 0
                    autoFloor: 20

                    Stat {
                        ui: uiStyle
                        value: gpu.available ? Format.pct(gpu.value) : "--"
                        unit: gpu.available ? "%" : ""
                        label: "Utilization"
                        accent: uiStyle.gpu
                    }
                }

                // ---- GPU core temperature ----
                ChartCard {
                    ui: uiStyle
                    Layout.row: dash.rowOf("gpuCore")
                    Layout.column: dash.colOf("gpuCore")
                    iconName: "video-card"
                    title: "GPU Core Temp"
                    showChart: uiStyle.showGpuCore
                    seriesData: [gpuTemp.history]
                    seriesColors: [uiStyle.gpuCore]
                    capacity: gpuTemp.capacity
                    labelFormatter: Format.tempLabel
                    maxValue: 0
                    zoom: true
                    autoFloor: 10

                    Stat {
                        ui: uiStyle
                        value: gpuTemp.available ? Format.tempNumber(gpuTemp.value) : "--"
                        unit: gpuTemp.available ? "°C" : ""
                        label: "Core"
                        accent: uiStyle.gpuCore
                    }
                }

                // ---- GPU junction temperature (only with a junction sensor set) ----
                ChartCard {
                    ui: uiStyle
                    visible: dash.junctionOn
                    Layout.row: dash.rowOf("gpuJunction")
                    Layout.column: dash.colOf("gpuJunction")
                    iconName: "video-card"
                    title: "GPU Junction Temp"
                    showChart: uiStyle.showGpuJunction
                    seriesData: [gpuJunc.history]
                    seriesColors: [uiStyle.gpuJunction]
                    capacity: gpuJunc.capacity
                    labelFormatter: Format.tempLabel
                    maxValue: 0
                    zoom: true
                    autoFloor: 10

                    Stat {
                        ui: uiStyle
                        value: gpuJunc.available ? Format.tempNumber(gpuJunc.value) : "--"
                        unit: gpuJunc.available ? "°C" : ""
                        label: "Junction"
                        accent: uiStyle.gpuJunction
                    }
                }

                // ---- Network ----
                ChartCard {
                    ui: uiStyle
                    Layout.row: dash.rowOf("network")
                    Layout.column: dash.colOf("network")
                    iconName: "network-wired"
                    title: "Network"
                    showChart: uiStyle.showNetwork
                    seriesData: [netDown.history, netUp.history]
                    seriesColors: [uiStyle.netDown, uiStyle.netUp]
                    capacity: netDown.capacity
                    labelFormatter: Format.rateLabel
                    maxValue: 0
                    autoFloor: 2e5

                    Stat {
                        ui: uiStyle
                        arrow: "↓"
                        value: netDown.available ? Format.rate(netDown.value).value : "--"
                        unit: netDown.available ? Format.rate(netDown.value).unit : ""
                        label: "Download"
                        accent: uiStyle.netDown
                    }
                    Divider {
                        ui: uiStyle
                    }
                    Stat {
                        ui: uiStyle
                        arrow: "↑"
                        value: Format.rate(netUp.value).value
                        unit: Format.rate(netUp.value).unit
                        label: "Upload"
                        accent: uiStyle.netUp
                    }
                }

                // ---- Disk ----
                ChartCard {
                    ui: uiStyle
                    Layout.row: dash.rowOf("disk")
                    Layout.column: dash.colOf("disk")
                    iconName: "drive-harddisk"
                    title: "Disk I/O"
                    headerRight: dash.cfg.diskLabel
                    showChart: uiStyle.showDisk
                    seriesData: [diskRead.history, diskWrite.history]
                    seriesColors: [uiStyle.diskRead, uiStyle.diskWrite]
                    capacity: diskRead.capacity
                    labelFormatter: Format.rateLabel
                    maxValue: 0
                    autoFloor: 2e5

                    Stat {
                        ui: uiStyle
                        arrow: "↓"
                        value: diskRead.available ? Format.rate(diskRead.value).value : "--"
                        unit: diskRead.available ? Format.rate(diskRead.value).unit : ""
                        label: "Read"
                        accent: uiStyle.diskRead
                    }
                    Divider {
                        ui: uiStyle
                    }
                    Stat {
                        ui: uiStyle
                        arrow: "↑"
                        value: diskWrite.available ? Format.rate(diskWrite.value).value : "--"
                        unit: diskWrite.available ? Format.rate(diskWrite.value).unit : ""
                        label: "Write"
                        accent: uiStyle.diskWrite
                    }
                }

                // ---- Process monitor ----
                ProcessMonitor {
                    id: processMonitor

                    ui: uiStyle
                    interval: dash.tick
                    processLimit: dash.cfg.processLimit

                    Layout.row: dash.rowOf("processMonitor")
                    Layout.column: dash.colOf("processMonitor")
                    Layout.rowSpan: 1
                    Layout.columnSpan: dash.colSpanOf("processMonitor")

                    // Don't let the process monitor's implicit width affect grid sizing.
                    Layout.minimumWidth: 0
                    Layout.preferredWidth: 0

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }
        }
    }
}

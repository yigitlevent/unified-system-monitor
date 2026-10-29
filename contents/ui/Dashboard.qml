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

    // Process monitor columns the user switched off
    readonly property var hiddenProcessColumns: {
        const hidden = [];
        if (cfg.hideColPid)
            hidden.push("pid");
        if (cfg.hideColUser)
            hidden.push("user");
        if (cfg.hideColName)
            hidden.push("name");
        if (cfg.hideColCpu)
            hidden.push("cpu");
        if (cfg.hideColRam)
            hidden.push("memory");
        if (cfg.hideColGpu)
            hidden.push("gpuUsage");
        if (cfg.hideColVram)
            hidden.push("gpuMemory");
        if (cfg.hideColDown)
            hidden.push("download");
        if (cfg.hideColUp)
            hidden.push("upload");
        if (cfg.hideColRead)
            hidden.push("read");
        if (cfg.hideColWrite)
            hidden.push("write");
        return hidden;
    }

    // Logical thread count, read from the system (0 until the sensor reports)
    readonly property int coreRows: cfg.coreRows > 0 ? cfg.coreRows : 2
    readonly property int threads: Math.max(0, Math.round(coreCount.value))
    readonly property string gpuTempId: cfg.gpuTempSensor !== "" ? cfg.gpuTempSensor : "gpu/gpu0/temperature"
    // One shared timer drives every sensor sample (Metrics and CoreBars), instead of
    // one timer each. Paused while the widget is hidden.
    property int sampleCount: 0
    Timer {
        interval: dash.tick
        repeat: true
        running: dash.visible
        triggeredOnStart: true
        onTriggered: dash.sampleCount++
    }

    // CPU model comes from /proc/cpuinfo (read once at startup).
    // KSysGuard has no sensor for the model: cpu/all/name is just "All".
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

    // No width/height or Layout.preferred* here on purpose: Plasma re-applies a
    // preferred size after restoring the saved geometry, which made the widget jump
    // back to a computed width on every plasmashell restart. The size is whatever
    // the user (or Plasma's saved geometry) gives it.
    Layout.minimumWidth: 0
    Layout.minimumHeight: 0

    // ---------- Sensors ----------
    Metric {
        id: cpu
        sensorId: "cpu/all/usage"
        interval: dash.tick
        sampleTrigger: dash.sampleCount
        keepHistory: uiStyle.showCpuUsage
    }
    Metric {
        id: gpuNameSensor
        sensorId: "gpu/gpu0/name"
        interval: dash.tick
        sampleTrigger: dash.sampleCount
        keepHistory: false
    }
    Metric {
        id: coreCount
        sensorId: "cpu/all/coreCount"
        interval: dash.tick
        sampleTrigger: dash.sampleCount
        keepHistory: false
    }
    Metric {
        id: cpuTemp
        sensorId: "cpu/all/averageTemperature"
        interval: dash.tick
        sampleTrigger: dash.sampleCount
        keepHistory: uiStyle.showCpuTemp
    }

    Metric {
        id: ram
        sensorId: "memory/physical/used"
        interval: dash.tick
        sampleTrigger: dash.sampleCount
        keepHistory: uiStyle.showRam
    }
    Metric {
        id: ramTotal
        sensorId: "memory/physical/total"
        interval: dash.tick
        sampleTrigger: dash.sampleCount
        keepHistory: false
    }

    Metric {
        id: gpu
        sensorId: "gpu/gpu0/usage"
        interval: dash.tick
        sampleTrigger: dash.sampleCount
        keepHistory: uiStyle.showGpuUsage
    }
    Metric {
        id: gpuTemp
        sensorId: dash.gpuTempId
        interval: dash.tick
        sampleTrigger: dash.sampleCount
        keepHistory: uiStyle.showGpuCore
    }
    Metric {
        id: gpuJunc
        sensorId: dash.cfg.gpuJunctionSensor
        interval: dash.tick
        sampleTrigger: dash.sampleCount
        keepHistory: uiStyle.showGpuJunction
    }

    Metric {
        id: netDown
        sensorId: "network/all/download"
        interval: dash.tick
        sampleTrigger: dash.sampleCount
        keepHistory: uiStyle.showNetwork
    }
    Metric {
        id: netUp
        sensorId: "network/all/upload"
        interval: dash.tick
        sampleTrigger: dash.sampleCount
        keepHistory: uiStyle.showNetwork
    }

    Metric {
        id: diskRead
        sensorId: "disk/" + dash.diskKey + "/read"
        interval: dash.tick
        sampleTrigger: dash.sampleCount
        keepHistory: uiStyle.showDisk
    }
    Metric {
        id: diskWrite
        sensorId: "disk/" + dash.diskKey + "/write"
        interval: dash.tick
        sampleTrigger: dash.sampleCount
        keepHistory: uiStyle.showDisk
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
        readonly property color cpu: pick(dash.cfg.cpuColor, Theme.cpu)
        readonly property color cpuTemp: pick(dash.cfg.cpuTempColor, Theme.cpuTemp)
        readonly property color ram: pick(dash.cfg.ramColor, Theme.ram)
        readonly property color gpu: pick(dash.cfg.gpuColor, Theme.gpu)
        readonly property color gpuCore: pick(dash.cfg.gpuCoreColor, Theme.gpuCore)
        readonly property color gpuJunction: pick(dash.cfg.gpuJunctionColor, Theme.gpuJunction)
        readonly property color netDown: pick(dash.cfg.netDownColor, Theme.netDown)
        readonly property color netUp: pick(dash.cfg.netUpColor, Theme.netUp)
        readonly property color diskRead: pick(dash.cfg.diskReadColor, Theme.diskRead)
        readonly property color diskWrite: pick(dash.cfg.diskWriteColor, Theme.diskWrite)
        readonly property color barLow: pick(dash.cfg.barLowColor, Theme.barLow)
        readonly property color barMid: pick(dash.cfg.barMidColor, Theme.barMid)
        readonly property color barHigh: pick(dash.cfg.barHighColor, Theme.barHigh)

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
        readonly property bool showCardIcons: !dash.cfg.hideCardIcons
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
                    color: uiStyle.barLow
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
                    sampleInterval: dash.tick
                    Layout.row: dash.rowOf("cpuUsage")
                    Layout.column: dash.colOf("cpuUsage")
                    iconName: "cpu"
                    title: "CPU Usage"
                    subtitle: dash.cfg.hideCpuSubtitle ? "" : dash.cpuLabel
                    showChart: uiStyle.showCpuUsage
                    seriesData: [cpu.history]
                    seriesColors: [uiStyle.cpu]
                    capacity: cpu.capacity
                    labelFormatter: Format.percentLabel
                    maxValue: 100

                    Stat {
                        ui: uiStyle
                        value: cpu.available ? Format.pct(cpu.value) : "--"
                        unit: cpu.available ? "%" : ""
                        accent: uiStyle.cpu
                    }
                }

                // ---- CPU temperature ----
                ChartCard {
                    ui: uiStyle
                    sampleInterval: dash.tick
                    Layout.row: dash.rowOf("cpuTemp")
                    Layout.column: dash.colOf("cpuTemp")
                    iconName: "cpu"
                    title: "CPU Temp"
                    showChart: uiStyle.showCpuTemp
                    seriesData: [cpuTemp.history]
                    seriesColors: [uiStyle.cpuTemp]
                    capacity: cpuTemp.capacity
                    labelFormatter: Format.tempLabel
                    maxValue: 120

                    Stat {
                        ui: uiStyle
                        value: cpuTemp.available ? Format.tempNumber(cpuTemp.value) : "--"
                        unit: cpuTemp.available ? "°C" : ""
                        accent: uiStyle.cpuTemp
                    }
                }

                // ---- RAM ----
                ChartCard {
                    ui: uiStyle
                    sampleInterval: dash.tick
                    Layout.row: dash.rowOf("ram")
                    Layout.column: dash.colOf("ram")
                    iconName: "memory"
                    title: "RAM"
                    showChart: uiStyle.showRam
                    seriesData: [ram.history]
                    seriesColors: [uiStyle.ram]
                    capacity: ram.capacity
                    labelFormatter: Format.gibLabel
                    maxValue: ramTotal.value

                    Stat {
                        ui: uiStyle
                        value: ram.available ? Format.gib(ram.value).toFixed(1) + "/" + Math.ceil(Format.gib(ramTotal.value)) : "--"
                        unit: ram.available ? "GB" : ""
                        accent: uiStyle.ram
                    }
                    Stat {
                        ui: uiStyle
                        value: ram.available && ramTotal.available && ramTotal.value > 0 ? String(Math.round(ram.value / ramTotal.value * 100)) : "--"
                        unit: ram.available && ramTotal.available && ramTotal.value > 0 ? "%" : ""
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
                                sampleTrigger: dash.sampleCount
                                midThreshold: dash.cfg.barMidThreshold > 0 ? dash.cfg.barMidThreshold : 50
                                highThreshold: dash.cfg.barHighThreshold > 0 ? dash.cfg.barHighThreshold : 80
                                showLabel: coreGrid.height / coreGrid.rowCount > dash.u * 3
                            }
                        }
                    }
                }

                // ---- GPU usage ----
                ChartCard {
                    ui: uiStyle
                    sampleInterval: dash.tick
                    Layout.row: dash.rowOf("gpuUsage")
                    Layout.column: dash.colOf("gpuUsage")
                    iconName: "video-card"
                    title: "GPU Usage"
                    subtitle: dash.cfg.hideGpuSubtitle ? "" : dash.gpuLabel
                    showChart: uiStyle.showGpuUsage
                    seriesData: [gpu.history]
                    seriesColors: [uiStyle.gpu]
                    capacity: gpu.capacity
                    labelFormatter: Format.percentLabel
                    maxValue: 100

                    Stat {
                        ui: uiStyle
                        value: gpu.available ? Format.pct(gpu.value) : "--"
                        unit: gpu.available ? "%" : ""
                        accent: uiStyle.gpu
                    }
                }

                // ---- GPU core temperature ----
                ChartCard {
                    ui: uiStyle
                    sampleInterval: dash.tick
                    Layout.row: dash.rowOf("gpuCore")
                    Layout.column: dash.colOf("gpuCore")
                    iconName: "video-card"
                    title: "GPU Core Temp"
                    showChart: uiStyle.showGpuCore
                    seriesData: [gpuTemp.history]
                    seriesColors: [uiStyle.gpuCore]
                    capacity: gpuTemp.capacity
                    labelFormatter: Format.tempLabel
                    maxValue: 120

                    Stat {
                        ui: uiStyle
                        value: gpuTemp.available ? Format.tempNumber(gpuTemp.value) : "--"
                        unit: gpuTemp.available ? "°C" : ""
                        accent: uiStyle.gpuCore
                    }
                }

                // ---- GPU junction temperature (only with a junction sensor set) ----
                ChartCard {
                    ui: uiStyle
                    visible: dash.junctionOn
                    sampleInterval: dash.tick
                    Layout.row: dash.rowOf("gpuJunction")
                    Layout.column: dash.colOf("gpuJunction")
                    iconName: "video-card"
                    title: "GPU Junc Temp"
                    showChart: uiStyle.showGpuJunction
                    seriesData: [gpuJunc.history]
                    seriesColors: [uiStyle.gpuJunction]
                    capacity: gpuJunc.capacity
                    labelFormatter: Format.tempLabel
                    maxValue: 120

                    Stat {
                        ui: uiStyle
                        value: gpuJunc.available ? Format.tempNumber(gpuJunc.value) : "--"
                        unit: gpuJunc.available ? "°C" : ""
                        accent: uiStyle.gpuJunction
                    }
                }

                // ---- Network ----
                ChartCard {
                    ui: uiStyle
                    sampleInterval: dash.tick
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
                        accent: uiStyle.netDown
                    }
                    Stat {
                        ui: uiStyle
                        arrow: "↑"
                        value: netUp.available ? Format.rate(netUp.value).value : "--"
                        unit: netUp.available ? Format.rate(netUp.value).unit : ""
                        accent: uiStyle.netUp
                    }
                }

                // ---- Disk ----
                ChartCard {
                    ui: uiStyle
                    sampleInterval: dash.tick
                    Layout.row: dash.rowOf("disk")
                    Layout.column: dash.colOf("disk")
                    iconName: "drive-harddisk"
                    title: "Disks"
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
                        accent: uiStyle.diskRead
                    }
                    Stat {
                        ui: uiStyle
                        arrow: "↑"
                        value: diskWrite.available ? Format.rate(diskWrite.value).value : "--"
                        unit: diskWrite.available ? Format.rate(diskWrite.value).unit : ""
                        accent: uiStyle.diskWrite
                    }
                }

                // ---- Process monitor ----
                ProcessMonitor {
                    id: processMonitor

                    ui: uiStyle
                    interval: dash.tick
                    processLimit: dash.cfg.processLimit
                    hiddenColumns: dash.hiddenProcessColumns
                    sortKey: dash.cfg.processSortKey !== "" ? dash.cfg.processSortKey : "cpu"
                    sortDescending: dash.cfg.processSortDesc
                    onSortRequested: function (key, descending) {
                        Plasmoid.configuration.processSortKey = key;
                        Plasmoid.configuration.processSortDesc = descending;
                    }

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

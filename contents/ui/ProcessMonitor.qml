import QtQuick
import QtQuick.Layouts
import org.kde.ksysguard.process as Process
import "Format.js" as Format

Rectangle {
    id: root

    property var ui
    property int interval: 1000
    property int processLimit: 8
    property var processes: []
    property bool loading: true

    // Column proportions add up to 100%, so the table always fits its available width.
    readonly property var columnWeights: [0.06, 0.1, 0.2, 0.08, 0.08, 0.08, 0.08, 0.08, 0.08, 0.08, 0.08]
    readonly property int columnSpacing: 6
    readonly property var requestedAttributes: ["pid", "username", "name", "usage", "memory", "gpu_usage", "gpu_memory", "netInbound", "netOutbound", "ioCharactersActuallyReadRate", "ioCharactersActuallyWrittenRate"]

    implicitWidth: 280
    implicitHeight: 300
    radius: ui.cardRadius
    color: ui.card
    border.width: 1
    border.color: ui.border

    function columnWidth(index, availableWidth) {
        return Math.max(0, availableWidth * columnWeights[index]);
    }

    function columnX(index, availableWidth) {
        let x = 0;
        for (let i = 0; i < index; ++i)
            x += availableWidth * columnWeights[i];
        return x;
    }

    Process.ProcessDataModel {
        id: processModel
        enabled: root.visible
        flatList: true
        enabledAttributes: root.requestedAttributes.filter(function (attribute) {
            return processModel.availableAttributes.includes(attribute);
        })
    }

    function columnOf(attribute) {
        return processModel.enabledAttributes.indexOf(attribute);
    }

    function readValue(row, attribute) {
        const column = columnOf(attribute);
        if (column < 0)
            return null;
        return processModel.data(processModel.index(row, column), Process.ProcessDataModel.Value);
    }

    function readMaximum(row, attribute) {
        const column = columnOf(attribute);
        if (column < 0)
            return null;
        return processModel.data(processModel.index(row, column), Process.ProcessDataModel.Maximum);
    }

    function numberOrNull(value) {
        if (value === null || value === undefined || value === "")
            return null;
        const number = Number(value);
        return Number.isFinite(number) ? number : null;
    }

    function formatPercent(value, available) {
        return available ? Math.max(0, Number(value)).toFixed(1) + "%" : "—";
    }

    function formatRate(value, available) {
        if (!available)
            return "—";
        const rate = Format.rate(Math.max(0, Number(value)));
        return rate.value + " " + rate.unit;
    }

    function formatMemory(value, available) {
        if (!available)
            return "—";
        // KDE's process memory attributes are reported in KiB.
        const mib = Math.max(0, Number(value)) / 1024;
        return mib >= 1024 ? (mib / 1024).toFixed(1) + " GiB" : Math.round(mib) + " MiB";
    }

    function refreshProcesses() {
        // Replacing an array-backed ListView model resets its scroll position.
        // Remember the offset and restore it after Qt has updated the delegates.
        const previousContentY = processList.contentY;
        const updated = [];

        for (let row = 0; row < processModel.rowCount(); ++row) {
            const pid = numberOrNull(readValue(row, "pid"));
            const userValue = readValue(row, "username");
            const nameValue = readValue(row, "name");
            if (pid === null || nameValue === null || nameValue === undefined)
                continue;

            const rawCpu = numberOrNull(readValue(row, "usage"));
            const rawMemory = numberOrNull(readValue(row, "memory"));
            const maxMemory = numberOrNull(readMaximum(row, "memory"));
            const rawGpu = numberOrNull(readValue(row, "gpu_usage"));
            const rawGpuMemory = numberOrNull(readValue(row, "gpu_memory"));
            const rawDownload = numberOrNull(readValue(row, "netInbound"));
            const rawUpload = numberOrNull(readValue(row, "netOutbound"));
            const rawRead = numberOrNull(readValue(row, "ioCharactersActuallyReadRate"));
            const rawWrite = numberOrNull(readValue(row, "ioCharactersActuallyWrittenRate"));

            updated.push({
                pid: pid,
                user: userValue == null ? "—" : String(userValue),
                name: String(nameValue),
                cpu: rawCpu === null ? 0 : rawCpu,
                cpuAvailable: rawCpu !== null,
                memory: rawMemory !== null && maxMemory !== null && maxMemory > 0 ? Math.max(0, rawMemory / maxMemory * 100) : 0,
                memoryAvailable: rawMemory !== null && maxMemory !== null && maxMemory > 0,
                gpuUsage: rawGpu === null ? 0 : rawGpu,
                gpuUsageAvailable: rawGpu !== null,
                gpuMemory: rawGpuMemory === null ? 0 : rawGpuMemory,
                gpuMemoryAvailable: rawGpuMemory !== null,
                download: rawDownload === null ? 0 : rawDownload,
                downloadAvailable: rawDownload !== null,
                upload: rawUpload === null ? 0 : rawUpload,
                uploadAvailable: rawUpload !== null,
                readRate: rawRead === null ? 0 : rawRead,
                readAvailable: rawRead !== null,
                writeRate: rawWrite === null ? 0 : rawWrite,
                writeAvailable: rawWrite !== null
            });
        }

        updated.sort(function (a, b) {
            return b.cpu - a.cpu;
        });
        root.processes = updated.slice(0, Math.max(1, Math.min(50, root.processLimit)));
        root.loading = false;

        // Restore immediately to avoid a visible jump to the top.
        processList.contentY = previousContentY;

        // Clamp after the new content height has settled.
        Qt.callLater(function () {
            const maxContentY = Math.max(0, processList.contentHeight - processList.height);
            processList.contentY = Math.max(0, Math.min(previousContentY, maxContentY));
        });
    }

    Timer {
        interval: Math.max(1000, root.interval)
        repeat: true
        running: root.visible
        triggeredOnStart: true
        onTriggered: root.refreshProcesses()
    }

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 12
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(18, root.ui.cardTitleSize + 2)
            spacing: 6
            Text {
                text: "▤"
                color: root.ui.cpu
                font.pixelSize: root.ui.iconSize
            }
            Text {
                text: "Processes"
                color: root.ui.text
                font.pixelSize: root.ui.cardTitleSize
                font.weight: Font.DemiBold
            }
            Item {
                Layout.fillWidth: true
            }
            Text {
                text: "Sorted by CPU"
                color: root.ui.muted
                font.pixelSize: root.ui.smallSize
            }
        }

        // Match the header's usable width to the list by reserving the same
        // scrollbar column and spacing on the right.
        RowLayout {
            id: headerRow
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(18, root.ui.smallSize + 4)
            Layout.bottomMargin: -8
            spacing: 6

            Item {
                id: tableHeader
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.preferredHeight: headerRow.height
                Layout.minimumHeight: 18

                Repeater {
                    model: ["PID", "User", "Process", "CPU", "RAM", "GPU", "VRAM", "Down", "Up", "Read", "Write"]
                    delegate: Text {
                        required property int index
                        required property string modelData
                        x: root.columnX(index, tableHeader.width)
                        width: root.columnWidth(index, tableHeader.width)
                        height: tableHeader.height
                        leftPadding: 2
                        rightPadding: 2
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: index < 3 ? Text.AlignLeft : Text.AlignRight
                        text: modelData
                        elide: Text.ElideRight
                        color: root.ui.muted
                        font.pixelSize: root.ui.smallSize
                    }
                }
            }

            Item {
                Layout.preferredWidth: 10
                Layout.minimumWidth: 10
                Layout.maximumWidth: 10
                Layout.fillHeight: true
            }
        }

        RowLayout {
            id: listArea
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 80
            spacing: 6

            ListView {
                id: processList
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: 0
                Layout.minimumHeight: 80
                clip: true
                spacing: 3
                boundsBehavior: Flickable.StopAtBounds
                model: root.processes

                delegate: Item {
                    id: processRow
                    required property var modelData
                    width: processList.width
                    height: 14

                    Repeater {
                        model: [
                            {
                                value: String(processRow.modelData.pid),
                                color: root.ui.muted,
                                align: Text.AlignLeft
                            },
                            {
                                value: processRow.modelData.user,
                                color: root.ui.muted,
                                align: Text.AlignLeft
                            },
                            {
                                value: processRow.modelData.name,
                                color: root.ui.text,
                                align: Text.AlignLeft
                            },
                            {
                                value: root.formatPercent(processRow.modelData.cpu, processRow.modelData.cpuAvailable),
                                color: root.ui.cpu,
                                align: Text.AlignRight
                            },
                            {
                                value: root.formatPercent(processRow.modelData.memory, processRow.modelData.memoryAvailable),
                                color: root.ui.ram,
                                align: Text.AlignRight
                            },
                            {
                                value: root.formatPercent(processRow.modelData.gpuUsage, processRow.modelData.gpuUsageAvailable),
                                color: root.ui.gpu,
                                align: Text.AlignRight
                            },
                            {
                                value: root.formatMemory(processRow.modelData.gpuMemory, processRow.modelData.gpuMemoryAvailable),
                                color: root.ui.gpuCore,
                                align: Text.AlignRight
                            },
                            {
                                value: root.formatRate(processRow.modelData.download, processRow.modelData.downloadAvailable).replace(" ", ""),
                                color: root.ui.netDown,
                                align: Text.AlignRight
                            },
                            {
                                value: root.formatRate(processRow.modelData.upload, processRow.modelData.uploadAvailable).replace(" ", ""),
                                color: root.ui.netUp,
                                align: Text.AlignRight
                            },
                            {
                                value: root.formatRate(processRow.modelData.readRate, processRow.modelData.readAvailable).replace(" ", ""),
                                color: root.ui.diskRead,
                                align: Text.AlignRight
                            },
                            {
                                value: root.formatRate(processRow.modelData.writeRate, processRow.modelData.writeAvailable).replace(" ", ""),
                                color: root.ui.diskWrite,
                                align: Text.AlignRight
                            }
                        ]
                        delegate: Text {
                            required property int index
                            required property var modelData
                            x: root.columnX(index, processRow.width)
                            width: root.columnWidth(index, processRow.width)
                            height: processRow.height
                            leftPadding: 2
                            rightPadding: 2
                            verticalAlignment: Text.AlignVCenter
                            text: modelData.value
                            color: modelData.color
                            horizontalAlignment: modelData.align
                            elide: Text.ElideLeft
                            font.pixelSize: root.ui.smallSize
                        }
                    }
                }
            }

            // Dedicated scrollbar column; it never overlays the final table column.
            Item {
                id: verticalBar
                Layout.preferredWidth: 10
                Layout.minimumWidth: 10
                Layout.maximumWidth: 10
                Layout.fillHeight: true
                // Keep the column reserved even when the scrollbar is hidden,
                // so the header and data columns never shift horizontally.
                Rectangle {
                    visible: processList.contentHeight > processList.height + 1
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 4
                    height: parent.height
                    radius: 2
                    color: Qt.rgba(root.ui.text.r, root.ui.text.g, root.ui.text.b, 0.16)
                }
                Rectangle {
                    id: thumb
                    visible: processList.contentHeight > processList.height + 1
                    x: (parent.width - width) / 2
                    width: 8
                    height: Math.min(parent.height, Math.max(22, parent.height * processList.height / Math.max(1, processList.contentHeight)))
                    y: Math.max(0, Math.min(parent.height - height, processList.contentY / Math.max(1, processList.contentHeight) * parent.height))
                    radius: 4
                    color: Qt.rgba(root.ui.text.r, root.ui.text.g, root.ui.text.b, 0.72)
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: processList.contentHeight > processList.height + 1
                    visible: enabled
                    onPressed: function (mouse) {
                        processList.contentY = Math.max(0, Math.min(processList.contentHeight - processList.height, mouse.y / Math.max(1, height) * processList.contentHeight - processList.height / 2));
                    }
                    onPositionChanged: function (mouse) {
                        if (pressed)
                            processList.contentY = Math.max(0, Math.min(processList.contentHeight - processList.height, mouse.y / Math.max(1, height) * processList.contentHeight - processList.height / 2));
                    }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            visible: root.loading
            text: "Reading processes…"
            color: root.ui.muted
            font.pixelSize: root.ui.smallSize
        }
        Text {
            Layout.fillWidth: true
            visible: !root.loading && root.processes.length === 0
            text: "No process data available"
            color: root.ui.muted
            font.pixelSize: root.ui.smallSize
        }
    }
}

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.process as Process
import "Format.js" as Format

CardChrome {
    id: root

    // `ui` (look & feel, provided by the Dashboard) is inherited from CardChrome
    property int interval: 1000
    property int processLimit: 8

    // Sorting: click a column header. The Dashboard stores the choice in the settings.
    property string sortKey: "cpu"
    property bool sortDescending: true
    signal sortRequested(string key, bool descending)
    property bool loading: true

    // Rows are updated in place (not replaced), so delegates, scroll position and
    // hover state survive every refresh.
    ListModel {
        id: processItems
    }

    // Every column the table can show. `weight` is its share of the width; the weights of
    // the columns that are shown are rescaled, so the table always fills its space.
    // `attr` is the KSysGuard process attribute behind it.
    readonly property var allColumns: [
        {
            key: "pid",
            label: "PID",
            weight: 0.06,
            left: true,
            attr: "pid"
        },
        {
            key: "user",
            label: "User",
            weight: 0.10,
            left: true,
            attr: "username"
        },
        {
            key: "name",
            label: "Process",
            weight: 0.20,
            left: true,
            attr: "name"
        },
        {
            key: "cpu",
            label: "CPU",
            weight: 0.08,
            left: false,
            attr: "usage"
        },
        {
            key: "memory",
            label: "RAM",
            weight: 0.08,
            left: false,
            attr: "memory"
        },
        {
            key: "gpuUsage",
            label: "GPU",
            weight: 0.08,
            left: false,
            attr: "gpu_usage"
        },
        {
            key: "gpuMemory",
            label: "VRAM",
            weight: 0.08,
            left: false,
            attr: "gpu_memory"
        },
        {
            key: "download",
            label: "Down",
            weight: 0.08,
            left: false,
            attr: "netInbound"
        },
        {
            key: "upload",
            label: "Up",
            weight: 0.08,
            left: false,
            attr: "netOutbound"
        },
        {
            key: "read",
            label: "Read",
            weight: 0.08,
            left: false,
            attr: "ioCharactersActuallyReadRate"
        },
        {
            key: "write",
            label: "Write",
            weight: 0.08,
            left: false,
            attr: "ioCharactersActuallyWrittenRate"
        }
    ]

    // Keys of the columns the user switched off (set by the Dashboard from the settings)
    property var hiddenColumns: []

    readonly property var columns: allColumns.filter(function (c) {
        return hiddenColumns.indexOf(c.key) < 0;
    })
    readonly property real totalWeight: columns.reduce(function (sum, c) {
        return sum + c.weight;
    }, 0)

    // "pid", "name" and "usage" are always read: rows are skipped without a pid or name,
    // and the list is always sorted by CPU, even if those columns are hidden.
    readonly property var requestedAttributes: {
        const wanted = ["pid", "name", "usage"];
        for (let i = 0; i < columns.length; ++i)
            if (wanted.indexOf(columns[i].attr) < 0)
                wanted.push(columns[i].attr);
        return wanted;
    }

    implicitWidth: 280
    implicitHeight: 300

    function columnWidth(index, availableWidth) {
        if (index >= columns.length || totalWeight <= 0)
            return 0;
        return Math.max(0, availableWidth * columns[index].weight / totalWeight);
    }

    function columnX(index, availableWidth) {
        let x = 0;
        for (let i = 0; i < index && i < columns.length; ++i)
            x += columnWidth(i, availableWidth);
        return x;
    }

    // The column actually sorted by: a hidden column can't be (its data isn't requested),
    // so fall back to CPU, which is always read.
    readonly property string activeSortKey: columns.some(function (c) {
        return c.key === sortKey;
    }) ? sortKey : "cpu"

    function columnByKey(key) {
        for (let i = 0; i < allColumns.length; ++i)
            if (allColumns[i].key === key)
                return allColumns[i];
        return allColumns[3];
    }

    // Field of a refreshed row that a column sorts on
    function sortField(key) {
        switch (key) {
        case "read":
            return "readRate";
        case "write":
            return "writeRate";
        }
        return key;
    }

    function compareRows(a, b) {
        const field = sortField(activeSortKey);
        let r;
        if (typeof a[field] === "string")
            r = a[field].toLowerCase().localeCompare(b[field].toLowerCase());
        else
            r = a[field] - b[field];
        if (sortDescending)
            r = -r;
        // stable tie-break, so equal rows don't jump around between refreshes
        return r !== 0 ? r : (b.cpu - a.cpu) || (a.pid - b.pid);
    }

    // Header click: same column flips the direction; a new column starts with the
    // natural one (text and PID ascending, everything else largest first).
    function headerClicked(key) {
        if (key === activeSortKey)
            sortRequested(key, !sortDescending);
        else
            sortRequested(key, !columnByKey(key).left);
    }

    onSortKeyChanged: if (!loading)
        refreshProcesses()
    onSortDescendingChanged: if (!loading)
        refreshProcesses()

    // Text and colour of one cell, by column key
    function cellText(key, m) {
        switch (key) {
        case "pid":
            return String(m.pid);
        case "user":
            return m.user;
        case "name":
            return m.name;
        case "cpu":
            return formatPercent(m.cpu, m.cpuAvailable);
        case "memory":
            return formatPercent(m.memory, m.memoryAvailable);
        case "gpuUsage":
            return formatPercent(m.gpuUsage, m.gpuUsageAvailable);
        case "gpuMemory":
            return formatMemory(m.gpuMemory, m.gpuMemoryAvailable);
        case "download":
            return formatRate(m.download, m.downloadAvailable).replace(" ", "");
        case "upload":
            return formatRate(m.upload, m.uploadAvailable).replace(" ", "");
        case "read":
            return formatRate(m.readRate, m.readAvailable).replace(" ", "");
        case "write":
            return formatRate(m.writeRate, m.writeAvailable).replace(" ", "");
        }
        return "";
    }

    function cellColor(key) {
        switch (key) {
        case "pid":
        case "user":
            return ui.muted;
        case "name":
            return ui.text;
        case "cpu":
            return ui.cpu;
        case "memory":
            return ui.ram;
        case "gpuUsage":
            return ui.gpu;
        case "gpuMemory":
            return ui.gpuCore;
        case "download":
            return ui.netDown;
        case "upload":
            return ui.netUp;
        case "read":
            return ui.diskRead;
        case "write":
            return ui.diskWrite;
        }
        return ui.text;
    }

    Process.ProcessDataModel {
        id: processModel
        enabled: root.visible
        flatList: true
        enabledAttributes: root.requestedAttributes.filter(function (attribute) {
            return processModel.availableAttributes.includes(attribute);
        })
    }

    // attribute -> model column. Built once when the attributes change: reading
    // enabledAttributes copies the whole list, too slow for every cell of every refresh.
    readonly property var columnIndex: {
        const index = {};
        const attributes = processModel.enabledAttributes;
        for (let i = 0; i < attributes.length; ++i)
            index[attributes[i]] = i;
        return index;
    }

    function columnOf(attribute) {
        const column = columnIndex[attribute];
        return column === undefined ? -1 : column;
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
        // KDE's process memory attributes arrive in 1024-byte units; MB/GB are 1024-based too.
        const mb = Math.max(0, Number(value)) / 1024;
        return mb >= 1024 ? (mb / 1024).toFixed(1) + " GB" : Math.round(mb) + " MB";
    }

    function refreshProcesses() {
        const updated = [];

        const rowCount = processModel.rowCount();
        for (let row = 0; row < rowCount; ++row) {
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

        updated.sort(compareRows);

        const shown = updated.slice(0, Math.max(1, Math.min(50, root.processLimit)));

        // Overwrite existing rows, append new ones, drop the leftovers.
        for (let i = 0; i < shown.length; ++i) {
            if (i < processItems.count)
                processItems.set(i, shown[i]);
            else
                processItems.append(shown[i]);
        }
        if (processItems.count > shown.length)
            processItems.remove(shown.length, processItems.count - shown.length);

        root.loading = false;
    }

    // Scrollbar helpers: thumb position maps onto the scrollable distance
    // (contentHeight - viewport height), not the full content height.
    readonly property real scrollRange: Math.max(1, processList.contentHeight - processList.height)

    function scrollToTrackY(y, trackHeight, thumbHeight) {
        const travel = Math.max(1, trackHeight - thumbHeight);
        const fraction = Math.max(0, Math.min(1, (y - thumbHeight / 2) / travel));
        processList.contentY = fraction * scrollRange;
    }

    Timer {
        interval: root.interval
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
            Kirigami.Icon {
                source: "utilities-system-monitor"
                fallback: "view-list-details"
                visible: root.ui.showCardIcons
                Layout.preferredWidth: root.ui.iconSize
                Layout.preferredHeight: root.ui.iconSize
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
                text: "Sorted by " + root.columnByKey(root.activeSortKey).label
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
                    model: root.columns
                    delegate: Text {
                        id: headerCell
                        required property int index
                        required property var modelData
                        readonly property bool active: modelData.key === root.activeSortKey
                        x: root.columnX(index, tableHeader.width)
                        width: root.columnWidth(index, tableHeader.width)
                        height: tableHeader.height
                        leftPadding: 2
                        rightPadding: 2
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: modelData.left ? Text.AlignLeft : Text.AlignRight
                        text: modelData.label + (active ? (root.sortDescending ? " ▼" : " ▲") : "")
                        elide: Text.ElideRight
                        color: (active || headerMouse.containsMouse) ? root.ui.text : root.ui.muted
                        font.pixelSize: root.ui.smallSize
                        font.weight: active ? Font.DemiBold : Font.Normal

                        MouseArea {
                            id: headerMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.headerClicked(headerCell.modelData.key)
                        }
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
                model: processItems

                delegate: Item {
                    id: processRow
                    required property var model
                    width: processList.width
                    height: Math.max(14, Math.ceil(root.ui.smallSize * 1.5))

                    Rectangle {
                        anchors.fill: parent
                        radius: 3
                        color: Qt.rgba(root.ui.text.r, root.ui.text.g, root.ui.text.b, 0.08)
                        opacity: rowMouse.containsMouse ? 1 : 0
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 100
                            }
                        }
                    }

                    Repeater {
                        model: root.columns
                        delegate: Text {
                            required property int index
                            required property var modelData
                            x: root.columnX(index, processRow.width)
                            width: root.columnWidth(index, processRow.width)
                            height: processRow.height
                            leftPadding: 2
                            rightPadding: 2
                            verticalAlignment: Text.AlignVCenter
                            text: root.cellText(modelData.key, processRow.model)
                            color: root.cellColor(modelData.key)
                            horizontalAlignment: modelData.left ? Text.AlignLeft : Text.AlignRight
                            elide: Text.ElideLeft
                            font.pixelSize: root.ui.smallSize
                        }
                    }

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
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
                    y: (parent.height - height) * Math.max(0, Math.min(1, processList.contentY / root.scrollRange))
                    radius: 4
                    color: Qt.rgba(root.ui.text.r, root.ui.text.g, root.ui.text.b, 0.72)
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: processList.contentHeight > processList.height + 1
                    visible: enabled
                    onPressed: function (mouse) {
                        root.scrollToTrackY(mouse.y, height, thumb.height);
                    }
                    onPositionChanged: function (mouse) {
                        if (pressed)
                            root.scrollToTrackY(mouse.y, height, thumb.height);
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
            visible: !root.loading && processItems.count === 0
            text: "No process data available"
            color: root.ui.muted
            font.pixelSize: root.ui.smallSize
        }
    }
}

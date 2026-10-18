pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import "Format.js" as Format

// Filled line chart with a compact value axis on the left (labels centred on their
// gridlines, outside the plot, so data never runs through them).
// Accepts several series (arrays of numbers).
//
// Gridlines, fill and lines are drawn on a Canvas at the real device resolution. The axis
// labels are NOT: they are ordinary Text items, so Qt positions and renders them itself.
// (Text drawn into the Canvas bitmap got resampled and came out blurred or broken whenever
// the card landed on a fractional pixel position or the display scale was not 1:1.)
Item {
    id: chart

    required property var ui
    property var seriesData: []     // [[...], [...]]
    property var seriesColors: []   // ["#2f9bff", ...]
    property real maxValue: 100     // > 0 = fixed 0..max scale, <= 0 = auto scale
    property real autoFloor: 1      // auto mode: minimum size of the visible range
    property bool zoom: false       // auto mode: fit min..max instead of 0..max
    property int capacity: 60

    property bool showGrid: true
    property bool showLabels: true
    property var labelFormatter: function (v) {
        return Math.round(v);
    }
    property color gridColor: ui.muted
    property real labelSize: ui.chartLabelSize

    // Hover tooltips: `sampleInterval` is the ms between samples (for the "Xs ago"
    // label); `hoverOffset` is 0 for the newest sample, 1 for one older, ... (-1 = none)
    property int sampleInterval: 1000
    property bool interactive: true
    property int hoverOffset: -1

    readonly property real dpr: Math.max(1, Screen.devicePixelRatio)

    // Half a label of padding top and bottom, so the end labels (centred on their
    // lines) fit inside the item. No other padding is spent on labels.
    readonly property real plotTop: showLabels ? Math.ceil(labelSize / 2) + 1 : 3
    readonly property real plotBot: height - (showLabels ? Math.ceil(labelSize / 2) + 1 : 1)
    readonly property real plotH: plotBot - plotTop

    // Value range, number of gridlines and label texts. Recomputed when the data changes.
    readonly property var axis: computeAxis()

    function computeAxis() {
        var lo = 0;
        var hi = maxValue;
        if (hi <= 0) {
            let mx = 0;
            let mn = Infinity;
            for (let a = 0; a < seriesData.length; a++) {
                for (let b = 0; b < seriesData[a].length; b++) {
                    mx = Math.max(mx, seriesData[a][b]);
                    mn = Math.min(mn, seriesData[a][b]);
                }
            }
            if (mn === Infinity)
                mn = 0;

            if (zoom) {
                const range = Math.max(mx - mn, autoFloor);
                const step = Format.niceStep(range * 1.5 / 4);
                lo = Math.max(0, Math.floor(mn / step) * step);
                hi = lo + 4 * step;
            } else {
                hi = Format.niceCeil(mx * 1.1, autoFloor);
            }
        }
        if (hi <= lo)
            hi = lo + 1;

        // how many gridlines fit (keep >= 1.7 label heights between them)
        var divs = 4;
        if (plotH / 4 < labelSize * 1.7)
            divs = 2;
        if (plotH / 2 < labelSize * 1.7)
            divs = 1;

        var texts = [];
        for (let k = 0; k <= divs; k++)
            texts.push(String(labelFormatter(lo + (k / divs) * (hi - lo))));
        return {
            lo: lo,
            hi: hi,
            divs: divs,
            texts: texts
        };
    }

    // ---- Hover ----
    // Offset (from the newest sample) of the point closest to x, or -1 outside the plot
    function hoverAt(x, y) {
        if (x < axisW || x > width || y < plotTop || y > plotBot)
            return -1;
        var n = 0;
        for (let s = 0; s < seriesData.length; s++)
            n = Math.max(n, seriesData[s].length);
        if (n < 1)
            return -1;
        var stepX = (width - axisW) / Math.max(1, capacity - 1);
        var k = Math.round((width - x) / stepX);
        return Math.max(0, Math.min(n - 1, k));
    }

    // { color, text } for every series that has a value at the hovered sample
    function hoverRows() {
        var rows = [];
        var k = hoverOffset;
        if (k < 0)
            return rows;
        for (let s = 0; s < seriesData.length; s++) {
            const d = seriesData[s];
            const idx = d.length - 1 - k;
            if (idx < 0)
                continue;
            rows.push({
                color: String(seriesColors[s] || "#ffffff"),
                text: String(labelFormatter(d[idx]))
            });
        }
        return rows;
    }

    // How old the hovered sample is ("now", "5s ago", "1m 30s ago")
    function hoverTime() {
        var k = hoverOffset;
        if (k < 0)
            return "";
        if (k === 0)
            return "now";
        var s = Math.round(k * sampleInterval / 1000);
        if (s < 60)
            return s + "s ago";
        var m = Math.floor(s / 60);
        var r = s % 60;
        return r > 0 ? m + "m " + r + "s ago" : m + "m ago";
    }

    // Position of the hovered sample (the topmost point, for tooltip placement)
    function hoverPointX() {
        var k = hoverOffset;
        if (k < 0)
            return width;
        return width - k * ((width - axisW) / Math.max(1, capacity - 1));
    }
    function hoverPointY() {
        var k = hoverOffset;
        var best = plotBot;
        for (let s = 0; s < seriesData.length; s++) {
            const d = seriesData[s];
            const idx = d.length - 1 - k;
            if (idx < 0)
                continue;
            const v = Math.min(Math.max(d[idx], axis.lo), axis.hi);
            best = Math.min(best, plotBot - ((v - axis.lo) / (axis.hi - axis.lo)) * plotH);
        }
        return best;
    }

    // Width of the label column: the widest label, measured with the same font as the Text items
    readonly property string longestLabel: {
        var best = "";
        for (let i = 0; i < axis.texts.length; i++)
            if (axis.texts[i].length > best.length)
                best = axis.texts[i];
        return best;
    }
    TextMetrics {
        id: labelMetrics
        font.family: chart.ui.fontFamily
        font.pixelSize: chart.labelSize
        text: chart.longestLabel
    }
    readonly property real axisW: showLabels ? Math.ceil(labelMetrics.advanceWidth) + 6 : 0

    onAxisChanged: cv.requestPaint()
    onAxisWChanged: cv.requestPaint()
    onSeriesColorsChanged: cv.requestPaint()
    onGridColorChanged: cv.requestPaint()
    onWidthChanged: cv.requestPaint()
    onHeightChanged: cv.requestPaint()
    onHoverOffsetChanged: cv.requestPaint()

    Canvas {
        id: cv

        // bitmap = device pixels; shown at 1/dpr so it covers exactly the item
        width: Math.max(1, Math.round(chart.width * chart.dpr))
        height: Math.max(1, Math.round(chart.height * chart.dpr))
        scale: 1 / chart.dpr
        transformOrigin: Item.TopLeft
        smooth: true

        onPaint: {
            var ctx = getContext("2d");
            var dpr = chart.dpr;
            var W = chart.width;
            var H = chart.height;

            ctx.setTransform(1, 0, 0, 1, 0, 0);
            ctx.clearRect(0, 0, cv.width, cv.height);
            if (W <= 0 || H <= 0)
                return;
            ctx.setTransform(dpr, 0, 0, dpr, 0, 0);   // from here on: logical (item) coordinates

            var plotTop = chart.plotTop;
            var plotBot = chart.plotBot;
            var plotH = chart.plotH;
            if (plotH <= 4)
                return;

            var lo = chart.axis.lo;
            var hi = chart.axis.hi;
            var divs = chart.axis.divs;

            var x0 = chart.axisW;
            var plotW = W - x0;
            if (plotW <= 4)
                return;
            var gridCss = Format.rgba(chart.gridColor, 0.16);

            // ---- gridlines (snapped to whole device pixels) ----
            if (chart.showGrid) {
                ctx.lineWidth = 1 / dpr;
                ctx.strokeStyle = gridCss;
                for (let g = 0; g <= divs; g++) {
                    const gy = (Math.round((plotBot - (g / divs) * plotH) * dpr) - 0.5) / dpr;
                    ctx.beginPath();
                    ctx.moveTo(x0, gy);
                    ctx.lineTo(W, gy);
                    ctx.stroke();
                }
            }

            // ---- series ----
            var stepX = plotW / Math.max(1, chart.capacity - 1);

            for (let s = 0; s < chart.seriesData.length; s++) {
                const d = chart.seriesData[s];
                const n = d.length;
                if (n < 2)
                    continue;
                const col = String(chart.seriesColors[s] || "#ffffff");

                const xs = [], ys = [];
                for (let i = 0; i < n; i++) {
                    const v = Math.min(Math.max(d[i], lo), hi);
                    xs.push(W - (n - 1 - i) * stepX);
                    ys.push(plotBot - ((v - lo) / (hi - lo)) * plotH);
                }

                // Fill
                const grad = ctx.createLinearGradient(0, plotTop, 0, plotBot);
                grad.addColorStop(0, Format.rgba(col, 0.38));
                grad.addColorStop(1, Format.rgba(col, 0.02));
                ctx.beginPath();
                ctx.moveTo(xs[0], plotBot);
                for (let f = 0; f < n; f++)
                    ctx.lineTo(xs[f], ys[f]);
                ctx.lineTo(xs[n - 1], plotBot);
                ctx.closePath();
                ctx.fillStyle = grad;
                ctx.fill();

                // Line
                ctx.beginPath();
                ctx.moveTo(xs[0], ys[0]);
                for (let l = 1; l < n; l++)
                    ctx.lineTo(xs[l], ys[l]);
                ctx.lineWidth = 2;
                ctx.lineJoin = "round";
                ctx.strokeStyle = col;
                ctx.stroke();
            }

            // ---- hover: guide line + a marker on each series' point ----
            var k = chart.hoverOffset;
            if (k >= 0) {
                const hx = W - k * stepX;
                if (hx >= x0) {
                    ctx.strokeStyle = Format.rgba(chart.gridColor, 0.45);
                    ctx.lineWidth = 1 / dpr;
                    const gx = (Math.round(hx * dpr) - 0.5) / dpr;
                    ctx.beginPath();
                    ctx.moveTo(gx, plotTop);
                    ctx.lineTo(gx, plotBot);
                    ctx.stroke();

                    for (let s = 0; s < chart.seriesData.length; s++) {
                        const d = chart.seriesData[s];
                        const idx = d.length - 1 - k;
                        if (idx < 0)
                            continue;
                        const v = Math.min(Math.max(d[idx], lo), hi);
                        const dy = plotBot - ((v - lo) / (hi - lo)) * plotH;
                        const col = String(chart.seriesColors[s] || "#ffffff");
                        ctx.beginPath();
                        ctx.arc(hx, dy, 3.5, 0, Math.PI * 2);
                        ctx.fillStyle = col;
                        ctx.fill();
                        ctx.lineWidth = 1.5;
                        ctx.strokeStyle = Format.rgba(String(chart.ui.card), 1);
                        ctx.stroke();
                    }
                }
            }
        }
    }

    // Axis labels: real Text items, centred on their gridlines, right-aligned in the label column
    Repeater {
        model: chart.showLabels ? chart.axis.divs + 1 : 0
        delegate: Text {
            required property int index
            text: chart.axis.texts[index] !== undefined ? chart.axis.texts[index] : ""
            color: chart.gridColor
            font.family: chart.ui.fontFamily
            font.pixelSize: chart.labelSize
            renderType: Text.NativeRendering
            x: chart.axisW - 5 - width
            y: Math.round(chart.plotBot - (index / chart.axis.divs) * chart.plotH - height / 2)
        }
    }

    // Hover: the nearest sample gets a guide line, point markers and a tooltip
    MouseArea {
        anchors.fill: parent
        hoverEnabled: chart.interactive
        onEntered: chart.hoverOffset = chart.hoverAt(mouseX, mouseY)
        onPositionChanged: chart.hoverOffset = chart.hoverAt(mouseX, mouseY)
        onExited: chart.hoverOffset = -1
    }

    // Tooltip: the hovered sample's age and every series' value at that sample
    Rectangle {
        id: tooltip
        z: 2
        visible: chart.hoverOffset >= 0 && chart.hoverRows().length > 0
        width: Math.max(timeText.implicitWidth, rowsCol.implicitWidth) + 16
        height: timeText.implicitHeight + 12 + rowsCol.implicitHeight + 6
        radius: 6
        color: Qt.rgba(0.06, 0.09, 0.15, 0.96)
        border.width: 1
        border.color: chart.ui.border
        // Centred on the hovered point, clamped to the chart; flips below when there's no room above
        x: Math.max(2, Math.min(chart.width - width - 2, chart.hoverPointX() - width / 2))
        y: {
            var above = chart.hoverPointY() - height - 6;
            return above >= 2 ? above : chart.hoverPointY() + 8;
        }

        Text {
            id: timeText
            anchors.top: tooltip.top
            anchors.left: tooltip.left
            anchors.right: tooltip.right
            anchors.topMargin: 8
            anchors.leftMargin: 8
            text: chart.hoverTime()
            color: chart.ui.muted
            font.family: chart.ui.fontFamily
            font.pixelSize: chart.labelSize
        }
        ColumnLayout {
            id: rowsCol
            anchors.top: timeText.bottom
            anchors.topMargin: 4
            anchors.left: tooltip.left
            anchors.right: tooltip.right
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 3
            Repeater {
                model: tooltip.visible ? chart.hoverRows() : []
                delegate: RowLayout {
                    id: hoverRow
                    required property var modelData
                    spacing: 5
                    Rectangle {
                        width: 7
                        height: 7
                        radius: 3.5
                        color: hoverRow.modelData.color
                    }
                    Text {
                        text: hoverRow.modelData.text
                        color: chart.ui.text
                        font.family: chart.ui.fontFamily
                        font.pixelSize: chart.labelSize + 1
                    }
                }
            }
        }
    }
}

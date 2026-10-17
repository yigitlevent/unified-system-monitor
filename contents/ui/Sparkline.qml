import QtQuick
import "Format.js" as Format

// Filled line chart with a compact value axis on the left (labels centred on their
// gridlines, outside the plot, so data never runs through them).
// Accepts several series (arrays of numbers).
//
// The drawing surface is a Canvas rendered at the real device resolution and scaled
// back down, so lines and text are pixel-sharp on scaled (HiDPI / fractional) displays.
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

    readonly property real dpr: Math.max(1, Screen.devicePixelRatio)

    onSeriesDataChanged: cv.requestPaint()
    onSeriesColorsChanged: cv.requestPaint()
    onMaxValueChanged: cv.requestPaint()
    onGridColorChanged: cv.requestPaint()
    onLabelSizeChanged: cv.requestPaint()
    onWidthChanged: cv.requestPaint()
    onHeightChanged: cv.requestPaint()

    Canvas {
        id: cv

        // bitmap = device pixels; shown at 1/dpr so it covers exactly the item
        width: Math.max(1, Math.round(chart.width * chart.dpr))
        height: Math.max(1, Math.round(chart.height * chart.dpr))
        scale: 1 / chart.dpr
        transformOrigin: Item.TopLeft
        smooth: false

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

            var fs = chart.labelSize;
            var labelsOn = chart.showLabels;

            // Half a label of padding top and bottom, so the end labels (centred on their
            // lines) fit inside the canvas. No other padding is spent on labels.
            var padTop = labelsOn ? Math.ceil(fs / 2) + 1 : 3;
            var padBot = labelsOn ? Math.ceil(fs / 2) + 1 : 1;
            var plotTop = padTop;
            var plotBot = H - padBot;
            var plotH = plotBot - plotTop;
            if (plotH <= 4)
                return;

            // ---- scale ----
            var lo = 0;
            var hi = chart.maxValue;
            if (hi <= 0) {
                let mx = 0;
                let mn = Infinity;
                for (let a = 0; a < chart.seriesData.length; a++) {
                    for (let b = 0; b < chart.seriesData[a].length; b++) {
                        mx = Math.max(mx, chart.seriesData[a][b]);
                        mn = Math.min(mn, chart.seriesData[a][b]);
                    }
                }
                if (mn === Infinity)
                    mn = 0;

                if (chart.zoom) {
                    const range = Math.max(mx - mn, chart.autoFloor);
                    const step = Format.niceStep(range * 1.5 / 4);
                    lo = Math.max(0, Math.floor(mn / step) * step);
                    hi = lo + 4 * step;
                } else {
                    hi = Format.niceCeil(mx * 1.1, chart.autoFloor);
                }
            }
            if (hi <= lo)
                hi = lo + 1;

            // ---- how many gridlines fit (keep >= 1.7 label heights between them) ----
            var divs = 4;
            if (plotH / 4 < fs * 1.7)
                divs = 2;
            if (plotH / 2 < fs * 1.7)
                divs = 1;

            // ---- axis column: measured in device pixels, same font as the desktop ----
            var fsDev = Math.max(6, Math.round(fs * dpr));
            var fontCss = fsDev + 'px "' + chart.ui.fontFamily + '", sans-serif';
            var texts = [];
            var axisW = 0;
            if (labelsOn) {
                ctx.save();
                ctx.setTransform(1, 0, 0, 1, 0, 0);
                ctx.font = fontCss;
                for (let k = 0; k <= divs; k++) {
                    const t = String(chart.labelFormatter(lo + (k / divs) * (hi - lo)));
                    texts.push(t);
                    axisW = Math.max(axisW, ctx.measureText(t).width / dpr);
                }
                ctx.restore();
                axisW = Math.ceil(axisW) + 6;
            }
            var x0 = axisW;
            var plotW = W - x0;
            if (plotW <= 4)
                return;
            var gridCss = Format.rgba(chart.gridColor, 0.16);
            var labelCss = Format.rgba(chart.gridColor, 1.0);

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

            // ---- axis labels: untransformed device pixels, snapped, vertically centred on each gridline ----
            if (labelsOn) {
                ctx.setTransform(1, 0, 0, 1, 0, 0);
                ctx.font = fontCss;
                ctx.fillStyle = labelCss;
                ctx.textAlign = "right";
                ctx.textBaseline = "middle";
                for (let q = 0; q <= divs; q++)
                    ctx.fillText(texts[q], Math.round((axisW - 5) * dpr), Math.round((plotBot - (q / divs) * plotH) * dpr));
            }
        }
    }
}

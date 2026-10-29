.pragma library;

// "#rrggbb" -> "rgba(r,g,b,a)" for Canvas gradients
function rgba(hex, a) {
  var h = String(hex).replace("#", "");
  if (h.length === 8) h = h.substring(2);
  var r = parseInt(h.substring(0, 2), 16);
  var g = parseInt(h.substring(2, 4), 16);
  var b = parseInt(h.substring(4, 6), 16);
  return "rgba(" + r + "," + g + "," + b + "," + a + ")";
}

// bytes/second -> { value: "12.4", unit: "MB/s" }
function rate(bps) {
  var v = Number(bps) || 0;
  var n, u;
  if (v >= 1e9) { n = v / 1e9; u = "GB/s"; }
  else if (v >= 1e6) { n = v / 1e6; u = "MB/s"; }
  else if (v >= 1e3) { n = v / 1e3; u = "KB/s"; }
  else { n = v; u = "B/s"; }
  var s = (n >= 100 || u === "B/s") ? Math.round(n).toString() : n.toFixed(1);
  return { value: s, unit: u };
}

// bytes -> GB number. Memory uses 1024-based GB, like RAM sticks and Task Manager
// (a 16 GB module is 16 x 1024^3 bytes); rates above stay decimal.
function gb(bytes) {
  return (Number(bytes) || 0) / 1073741824;
}

// Usable RAM (bytes) -> installed size in GB. The kernel keeps a little memory back,
// so 64 GB installed reports ~62.4 GB usable; rounding up to even gives 64 again.
function installedGb(bytes) {
  return Math.ceil(gb(bytes) / 2) * 2;
}

function pct(v) {
  return Math.round(Number(v) || 0);
}

// "AMD Ryzen 9 5900X 12-Core Processor" -> "Ryzen 9 5900X"
// "Intel(R) Core(TM) i7-12700K CPU @ 3.60GHz" -> "Core i7-12700K"
function cleanCpu(name) {
  var s = String(name || "");
  s = s.replace(/\((R|TM|r|tm)\)/g, "");
  s = s.replace(/@.*$/, "");
  s = s.replace(/\b\d+-Core Processor\b/i, "");
  s = s.replace(/\b(CPU|Processor)\b/gi, "");
  s = s.replace(/^\s*(AMD|Intel)\s+/i, "");
  return s.replace(/\s+/g, " ").trim();
}

// PCI names list every model of a chip family, e.g.
//   "Navi 31 [Radeon RX 7900 XT/7900 XTX/7900 GRE/7900M] (PULSE RX 7900 XTX)"
// The trailing "(...)" is the board's subsystem name; use it to pick the right model.
function pickGpuModel(list, sub) {
  var parts = list.split("/");
  if (parts.length < 2 || !sub) return list;
  var pm = parts[0].match(/^(.*?)(\d.*)$/);
  if (!pm) return list;
  var prefix = pm[1];
  var models = [pm[2]].concat(parts.slice(1));
  var subL = sub.toLowerCase();
  var best = "";
  for (var i = 0; i < models.length; i++) {
    var t = models[i].trim();
    if (t !== "" && subL.indexOf(t.toLowerCase()) >= 0 && t.length > best.length)
      best = t;
  }
  return best !== "" ? prefix + best : list;
}

// -> "RX 7900 XTX", "GeForce RTX 4090", ...
function cleanGpu(name) {
  var s = String(name || "");

  var sub = "";
  var pm = s.match(/\(([^()]*)\)\s*$/);
  if (pm) { sub = pm[1]; s = s.substring(0, pm.index); }

  var re = /\[([^\]]+)\]/g;
  var m, last = null;
  while ((m = re.exec(s)) !== null) last = m[1];
  if (last !== null) s = pickGpuModel(last, sub);

  s = s.replace(/^\s*(NVIDIA Corporation|NVIDIA|Advanced Micro Devices, Inc\.|AMD\/ATI|AMD|ATI|Intel Corporation)\s*/i, "");
  s = s.replace(/^Radeon\s+(RX\s)/i, "$1");
  return s.replace(/\s+/g, " ").trim();
}

// "model name\t: AMD Ryzen 9 5900X 12-Core Processor" (first line of /proc/cpuinfo match)
function cpuInfoModel(out) {
  var s = String(out || "");
  var i = s.indexOf(":");
  return i >= 0 ? s.substring(i + 1).trim() : "";
}

// Smallest "tidy" number >= v (tidy = 1, 2, 3, 4, 6, 8, 10 x 10^k), at least `floor`.
// Keeps the top of an auto-scaled chart at a round value so quarter lines read nicely.
function niceCeil(v, floor) {
  v = Math.max(Number(v) || 0, Number(floor) || 0);
  if (v <= 0) return 1;
  var mag = Math.pow(10, Math.floor(Math.log(v) / Math.LN10));
  var r = v / mag;
  var c = [1, 2, 3, 4, 6, 8, 10];
  for (var i = 0; i < c.length; i++)
    if (c[i] >= r - 1e-9) return c[i] * mag;
  return 10 * mag;
}

// Tidy step size (1, 2, 2.5, 5, 10 x 10^k) that is >= x.
function niceStep(x) {
  if (!(x > 0)) return 1;
  var mag = Math.pow(10, Math.floor(Math.log(x) / Math.LN10));
  var r = x / mag;
  var c = [1, 2, 2.5, 5, 10];
  for (var i = 0; i < c.length; i++)
    if (c[i] >= r - 1e-9) return c[i] * mag;
  return 10 * mag;
}

function trim1(n) {
  var r = Math.round(n * 10) / 10;
  return (r % 1 === 0) ? String(r) : r.toFixed(1);
}

// Axis label formatters (used by Sparkline.labelFormatter)
function percentLabel(v) { return trim1(v) + "%"; }
function tempLabel(v) { return trim1(v) + "°C"; }
function gbLabel(v) { return trim1(gb(v)) + " GB"; }
function rateLabel(v) { var r = rate(v); return String(parseFloat(r.value)) + " " + r.unit; }

// Temperature as a bare number ("52") or "--" when the sensor has no reading
function tempNumber(v) {
  var n = Number(v) || 0;
  return n > 0 ? String(Math.round(n)) : "--";
}

.pragma library;

// Every dashboard card, in the default order, with the name the settings show.
// Shared by the Dashboard and the Layout settings page.
var keys = ["cpuUsage", "cpuTemp", "ram", "cores", "gpuUsage", "gpuCore", "gpuJunction", "network", "disk", "processMonitor"];

var names = {
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
};

// Old two-card keys from earlier versions expand to their new cards
var legacy = {
  cpu: ["cpuUsage", "cpuTemp"],
  gpu: ["gpuUsage", "gpuCore", "gpuJunction"]
};

// "cpuUsage,ram,..." -> every card key exactly once: the stored order first
// (unknown keys dropped, legacy keys expanded), then any missing cards appended.
function parseOrder(str) {
  var out = [];
  function add(k) {
    if (keys.indexOf(k) >= 0 && out.indexOf(k) < 0)
      out.push(k);
  }
  var parts = String(str || "").split(",");
  for (var i = 0; i < parts.length; i++) {
    var k = parts[i].trim();
    if (legacy.hasOwnProperty(k)) {
      for (var j = 0; j < legacy[k].length; j++)
        add(legacy[k][j]);
    } else
      add(k);
  }
  for (var m = 0; m < keys.length; m++)
    add(keys[m]);
  return out;
}

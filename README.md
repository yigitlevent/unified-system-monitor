# Unified System Monitor

A live system-monitoring dashboard widget for KDE Plasma 6.

## Features

- Separate cards, each with its own chart, for CPU usage, CPU temperature, GPU usage, GPU core temperature and GPU junction temperature
- Individual CPU thread usage grid
- RAM usage history
- Network download and upload speeds
- Disk read and write speeds
- Live line graphs and a dark dashboard interface

## Requirements

- KDE Plasma 6
- `ksystemstats` and `libksysguard` (the sensor backend used by Plasma's System Monitor)
- `plasma-sdk` (optional, for `plasmoidviewer`)

## Install

```sh
kpackagetool6 -t Plasma/Applet -i .      # first install
kpackagetool6 -t Plasma/Applet -u .      # update after changes
kpackagetool6 -t Plasma/Applet -r com.github.yigitlevent.unifiedsystemmonitor   # remove
```

Then right-click the desktop → **Add or Manage Widgets** → search for *Unified System Monitor*.

## Develop

```sh
plasmoidviewer -a .
```

If the widget doesn't refresh after an update: `kquitapp6 plasmashell && kstart plasmashell`.

## Card order

In the widget settings, drag the handles (or use the arrows) to reorder the six cards. They fill a 2-column grid, left to right, top to bottom.

## CPU core rows

In the settings, **CPU core rows** controls how many rows the per-thread bars are split into (1–8). Percentage labels are hidden automatically when the rows get too short to read.

## Layout

- **Cards per row** (1–6, default 3) sets the grid width. Nine cards at 3 per row make a 3×3 grid.
- **Card order**: drag the grip (or use the arrows) in the settings to reorder the cards.
- The **GPU Junction Temp** card only appears once a junction sensor ID is set in the settings.
- Orders saved by older versions (`cpu`, `gpu`) are upgraded automatically: `cpu` becomes CPU Usage + CPU Temp, and `gpu` becomes GPU Usage + Core + Junction.

## Appearance

Everything below is in the widget settings (right-click → Configure).

- **Text sizes**: widget title, card titles, big numbers, captions & labels, chart axis labels (50–250 %).
- **Shape**: corner radius of the main box and of the cards, the outer gap (main box edge to cards) and the gap between cards (also the space under the title bar), and show/hide the main box border and the title bar ("System Monitor" + Live indicator).
- **Colors**: main box, cards, borders, text, secondary text, every accent (CPU, RAM, GPU usage / core / junction, download, upload, disk read / write) and the three CPU core bar load colors. Each has a color picker, a hex field (`#rrggbb`, or `#aarrggbb` for transparency) and a reset button.
- **Charts**: switch charts off per card (CPU usage, CPU temperature, RAM, GPU usage, GPU core temperature, GPU junction temperature, Network, Disk I/O). With a chart off, the numbers are centred in the card.

## Configure sensors

Right-click the widget → **Configure**. Sensor IDs differ between machines. Open
**System Monitor → Sensors** (or the "Add sensor" browser) to find yours:

| Setting | Default |
| --- | --- |
| GPU core temp | `gpu/gpu0/temperature` |
| GPU junction temp | *(empty — set it to your amdgpu hwmon sensor)* |
| Disk | `all` → `disk/all/read` / `disk/all/write`; use a device id for a single drive |
| CPU / GPU label | Detected from `/proc/cpuinfo` (CPU) and the `gpu/gpu0/name` sensor (GPU); use *Custom CPU/GPU label* in settings to override |
| Logical threads | Detected automatically from `cpu/all/coreCount`, then one bar per `cpu/cpuN/usage` |

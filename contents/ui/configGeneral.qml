pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page

    property alias cfg_updateInterval: interval.value
    property alias cfg_cpuLabelOverride: cpuOverride.text
    property alias cfg_coreRows: coreRows.value
    property alias cfg_barMidThreshold: barMid.value
    property alias cfg_barHighThreshold: barHigh.value
    property alias cfg_gpuLabelOverride: gpuOverride.text
    property alias cfg_gpuIndex: gpuIndex.value
    property alias cfg_gpuTempSensor: gpuTemp.text
    property alias cfg_gpuJunctionSensor: gpuJunction.text
    property alias cfg_diskId: diskId.text
    property alias cfg_diskLabel: diskLabel.text

    // Card subtitles (the detected CPU/GPU model name) are shown unless hidden
    property bool cfg_hideCpuSubtitle: false
    property bool cfg_hideGpuSubtitle: false

    Kirigami.FormLayout {
        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Monitoring"
        }

        QQC2.TextField {
            id: cpuOverride
            Layout.minimumWidth: Kirigami.Units.gridUnit * 20
            placeholderText: "Detected automatically"
            Kirigami.FormData.label: "Custom CPU label:"
        }
        QQC2.CheckBox {
            Kirigami.FormData.label: "CPU card:"
            text: "Show CPU model subtitle"
            checked: !page.cfg_hideCpuSubtitle
            onToggled: page.cfg_hideCpuSubtitle = !checked
        }
        QQC2.SpinBox {
            id: interval
            from: 250
            to: 10000
            stepSize: 250
            editable: true
            Kirigami.FormData.label: "Update interval (ms):"
        }
        QQC2.SpinBox {
            id: coreRows
            from: 1
            to: 8
            editable: true
            Kirigami.FormData.label: "CPU core rows:"
        }

        QQC2.SpinBox {
            id: barMid
            from: 1
            to: 99
            editable: true
            Kirigami.FormData.label: "Core bar medium from (%):"
        }
        QQC2.SpinBox {
            id: barHigh
            from: barMid.value + 1
            to: 100
            editable: true
            Kirigami.FormData.label: "Core bar high from (%):"
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "GPU"
        }

        QQC2.CheckBox {
            Kirigami.FormData.label: "GPU card:"
            text: "Show GPU model subtitle"
            checked: !page.cfg_hideGpuSubtitle
            onToggled: page.cfg_hideGpuSubtitle = !checked
        }
        QQC2.SpinBox {
            id: gpuIndex
            from: 0
            to: 7
            editable: true
            Kirigami.FormData.label: "GPU number:"
        }
        QQC2.Label {
            text: "Which GPU to show: 0 = gpu0, 1 = gpu1, ... (see System Monitor -> Sensors)"
            font: Kirigami.Theme.smallFont
            opacity: 0.7
        }
        QQC2.TextField {
            id: gpuOverride
            Layout.minimumWidth: Kirigami.Units.gridUnit * 20
            placeholderText: "Detected automatically"
            Kirigami.FormData.label: "Custom GPU label:"
        }
        QQC2.TextField {
            id: gpuTemp
            Layout.minimumWidth: Kirigami.Units.gridUnit * 20
            placeholderText: "gpu/gpu" + gpuIndex.value + "/temperature (empty = this)"
            Kirigami.FormData.label: "Core temp sensor ID:"
        }
        QQC2.TextField {
            id: gpuJunction
            Layout.minimumWidth: Kirigami.Units.gridUnit * 20
            placeholderText: "e.g. lmsensors/amdgpu-pci-.../temp2 (empty = hide)"
            Kirigami.FormData.label: "Junction temp sensor ID:"
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Disk"
        }

        QQC2.TextField {
            id: diskId
            Layout.minimumWidth: Kirigami.Units.gridUnit * 20
            placeholderText: "all, or the device id from System Monitor"
            Kirigami.FormData.label: "Disk sensor ID:"
        }
        QQC2.TextField {
            id: diskLabel
            Kirigami.FormData.label: "Disk label:"
        }
    }
}

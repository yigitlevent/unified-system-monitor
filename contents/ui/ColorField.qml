import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

// Colour setting: picker button + hex field + reset.
// `value` is "#rrggbb" or "#aarrggbb".
RowLayout {
    id: root

    property string value: ""
    property string defaultValue: ""
    property bool alpha: false
    signal edited(string newValue)

    spacing: Kirigami.Units.smallSpacing

    // Picker (falls back to a plain swatch if the KDE colour button can't load)
    Loader {
        id: pickerLoader
        source: "ColorPicker.qml"
        Layout.preferredWidth: Kirigami.Units.gridUnit * 3
        Layout.preferredHeight: Kirigami.Units.gridUnit * 1.7
    }
    Binding {
        target: pickerLoader.item
        property: "alpha"
        value: root.alpha
        when: pickerLoader.item !== null
    }
    Binding {
        target: pickerLoader.item
        property: "value"
        value: root.value
        when: pickerLoader.item !== null
    }
    Connections {
        target: pickerLoader.item
        ignoreUnknownSignals: true
        function onPicked(hex) {
            root.edited(hex);
        }
    }
    Rectangle {
        visible: pickerLoader.status === Loader.Error
        Layout.preferredWidth: Kirigami.Units.gridUnit * 3
        Layout.preferredHeight: Kirigami.Units.gridUnit * 1.7
        radius: 4
        color: root.value
        border.width: 1
        border.color: Qt.rgba(0.5, 0.5, 0.5, 0.6)
    }

    QQC2.TextField {
        id: hex
        Layout.preferredWidth: Kirigami.Units.gridUnit * 8
        maximumLength: 9
        placeholderText: root.alpha ? "#aarrggbb" : "#rrggbb"
        validator: RegularExpressionValidator {
            regularExpression: /^#[0-9a-fA-F]{0,8}$/
        }
        onEditingFinished: {
            if (/^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/.test(text))
                root.edited(text.toLowerCase());
            else
                text = root.value;
        }
    }
    Binding {
        target: hex
        property: "text"
        value: root.value
        when: !hex.activeFocus
    }

    QQC2.ToolButton {
        icon.name: "edit-undo"
        enabled: root.value.toLowerCase() !== root.defaultValue.toLowerCase()
        onClicked: root.edited(root.defaultValue)
        QQC2.ToolTip.text: "Reset to default"
        QQC2.ToolTip.visible: hovered
        QQC2.ToolTip.delay: 600
    }
}

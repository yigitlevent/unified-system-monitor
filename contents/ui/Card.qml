import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Rounded panel with an icon + title header. Children go into the body.
Rectangle {
    id: card

    required property var ui        // look & feel, provided by the Dashboard
    property string title: ""
    property string subtitle: ""
    property string iconName: ""
    property string headerRight: ""
    default property alias content: body.data

    color: ui.card
    radius: ui.cardRadius
    clip: true   // safety net: oversized text scales can never spill into the next card
    border.width: 1
    border.color: ui.border

    // Plain anchors (no outer layout): the card's size is fixed by the grid, and nothing
    // inside it can make it wider, however large the text scales are.
    TextMetrics {
        id: titleMetrics
        text: card.title
        font.pixelSize: card.ui.cardTitleSize
        font.weight: Font.DemiBold
    }
    TextMetrics {
        id: rightMetrics
        text: card.headerRight
        font.pixelSize: card.ui.smallSize
    }

    Item {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.gridUnit * 0.75

        RowLayout {
            id: header
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            spacing: Kirigami.Units.smallSpacing * 2

            Kirigami.Icon {
                source: card.iconName
                visible: card.iconName !== ""
                Layout.preferredWidth: card.ui.iconSize
                Layout.preferredHeight: card.ui.iconSize
            }
            Text {
                text: card.title
                color: card.ui.text
                font.pixelSize: card.ui.cardTitleSize
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                // flex between 0 and the natural width, so it truncates (with "...") when the card is narrow
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.maximumWidth: Math.ceil(titleMetrics.advanceWidth) + 2
            }
            Text {
                visible: card.subtitle !== ""
                text: "·  " + card.subtitle
                color: card.ui.muted
                font.pixelSize: card.ui.cardSubtitleSize
                elide: Text.ElideRight
                Layout.minimumWidth: 0
                Layout.fillWidth: true
            }
            Item {
                visible: card.subtitle === ""
                Layout.fillWidth: true
            }
            Text {
                visible: card.headerRight !== ""
                text: card.headerRight
                color: card.ui.muted
                font.pixelSize: card.ui.smallSize
                elide: Text.ElideRight
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.maximumWidth: Math.ceil(rightMetrics.advanceWidth) + 2
                horizontalAlignment: Text.AlignRight
            }
        }

        Item {
            id: body
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: header.bottom
            anchors.topMargin: Kirigami.Units.smallSpacing
            anchors.bottom: parent.bottom
        }
    }
}

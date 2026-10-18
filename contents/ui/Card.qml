import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Rounded panel with an icon + title header. Children go into the body.
CardChrome {
    id: card

    // `ui` (look & feel, provided by the Dashboard) is inherited from CardChrome
    property string title: ""
    property string subtitle: ""
    property string iconName: ""
    property string headerRight: ""
    default property alias content: body.data
    // Items placed here (e.g. Stat blocks) sit in the header row, right after the title.
    // If they don't fit there (even a bit smaller), they move to a row under the header.
    property alias headerContent: statsRow.data

    readonly property real innerWidth: width - Kirigami.Units.gridUnit * 1.5
    readonly property bool hasStats: statsRow.children.length > 0
    readonly property real statsWidth: statsRow.implicitWidth
    readonly property real statsHeight: statsRow.implicitHeight
    // Header room left for the stats once icon, title (and right-hand text) took theirs
    readonly property real inlineRoom: innerWidth - (ui.showCardIcons && iconName !== "" ? ui.iconSize + Kirigami.Units.smallSpacing * 2 : 0) - Math.ceil(titleMetrics.advanceWidth) - 2 - (headerRight !== "" ? Math.ceil(rightMetrics.advanceWidth) + Kirigami.Units.smallSpacing * 2 : 0) - Kirigami.Units.smallSpacing * 6
    readonly property real inlineScale: statsWidth > 0 ? Math.min(1, inlineRoom / statsWidth) : 1
    // Next to the title if that needs at most a 20% shrink, otherwise on a row of their own
    readonly property bool statsInline: hasStats && inlineScale >= 0.8
    readonly property real statsScale: statsInline ? inlineScale : Math.max(0.6, statsWidth > 0 ? Math.min(1, innerWidth / statsWidth) : 1)

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
                visible: card.iconName !== "" && card.ui.showCardIcons
                Layout.preferredWidth: card.ui.iconSize
                Layout.preferredHeight: card.ui.iconSize
            }
            Text {
                text: card.title
                color: card.ui.text
                font.pixelSize: card.ui.cardTitleSize
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                // Natural width, hugging left; shrinks (elides) only when the card is too narrow
                Layout.minimumWidth: 0
                Layout.maximumWidth: Math.ceil(titleMetrics.advanceWidth) + 2
            }
            // Flexible gap: pushes the stats/subtitle/header-right to the right edge
            Item {
                Layout.fillWidth: true
            }
            // Slot next to the title; the stats row is parked here when it fits
            Item {
                id: inlineSlot
                visible: card.statsInline
                Layout.leftMargin: Kirigami.Units.smallSpacing * 2
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: card.statsWidth * card.statsScale
                Layout.preferredHeight: card.statsHeight * card.statsScale
            }
            Text {
                visible: card.subtitle !== ""
                text: "·  " + card.subtitle
                color: card.ui.muted
                font.pixelSize: card.ui.cardSubtitleSize
                elide: Text.ElideRight
                Layout.minimumWidth: 0
            }
            Text {
                visible: card.headerRight !== ""
                text: card.headerRight
                color: card.ui.muted
                font.pixelSize: card.ui.smallSize
                elide: Text.ElideRight
                Layout.minimumWidth: 0
                horizontalAlignment: Text.AlignRight
            }
        }

        // Fallback slot: a row under the header, used when the stats don't fit beside the title
        Item {
            id: belowSlot
            visible: card.hasStats && !card.statsInline
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: header.bottom
            anchors.topMargin: Kirigami.Units.smallSpacing
            height: visible ? card.statsHeight * card.statsScale : 0
        }

        // The stats live here and are re-parented between the two slots
        RowLayout {
            id: statsRow
            parent: card.statsInline ? inlineSlot : belowSlot
            spacing: Kirigami.Units.gridUnit
            scale: card.statsScale
            transformOrigin: Item.TopLeft
            // keep the row at its natural size; `scale` does the shrinking
            width: implicitWidth
            height: implicitHeight
        }

        Item {
            id: body
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: belowSlot.visible ? belowSlot.bottom : header.bottom
            anchors.topMargin: Kirigami.Units.smallSpacing
            anchors.bottom: parent.bottom
        }
    }
}

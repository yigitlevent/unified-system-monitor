import QtQuick

// Shared card chrome: the rounded, filled, bordered panel every card sits in.
// Used as the root of Card and ProcessMonitor, so the card look lives in one place.
Rectangle {
    required property var ui

    color: ui.card
    radius: ui.cardRadius
    clip: true   // safety net: oversized content can never spill into the next card
    border.width: 1
    border.color: ui.border
}

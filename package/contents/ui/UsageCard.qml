// One usage window in the popup: how much is used, how much of the window's
// time has passed (to compare against the pace), and when it resets.
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: card

    property string title
    property bool known: true
    property int percent: 0
    property real elapsed: 0          // share of the window already gone, 0..1
    property color fillColor: Kirigami.Theme.highlightColor
    property string resetText

    spacing: Kirigami.Units.smallSpacing

    RowLayout {
        Layout.fillWidth: true

        PlasmaComponents.Label {
            Layout.fillWidth: true
            text: card.title
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }
        PlasmaComponents.Label {
            text: card.known ? card.percent + "% used" : "–"
            color: card.percent >= 70 ? card.fillColor : Kirigami.Theme.textColor
        }
    }

    MiniBar {
        Layout.fillWidth: true
        implicitHeight: Kirigami.Units.smallSpacing * 2
        value: card.percent / 100
        fillColor: card.fillColor
    }
    MiniBar {
        Layout.fillWidth: true
        implicitHeight: Math.max(3, Math.round(Kirigami.Units.smallSpacing * 0.75))
        value: card.elapsed
        fillColor: Kirigami.Theme.disabledTextColor
    }

    RowLayout {
        Layout.fillWidth: true

        PlasmaComponents.Label {
            Layout.fillWidth: true
            text: card.resetText
            elide: Text.ElideRight
            font: Kirigami.Theme.smallFont
        }
        PlasmaComponents.Label {
            visible: card.elapsed > 0
            text: Math.round(card.elapsed * 100) + "% of time elapsed"
            opacity: 0.6
            font: Kirigami.Theme.smallFont
        }
    }
}

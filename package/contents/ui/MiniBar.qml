// Thin rounded bar; `value` is 0..1.
import QtQuick
import org.kde.kirigami as Kirigami

Rectangle {
    id: bar

    property real value: 0
    property color fillColor: Kirigami.Theme.highlightColor

    implicitHeight: Math.max(3, Math.round(Kirigami.Units.gridUnit / 4))
    radius: height / 2
    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.18)

    Rectangle {
        width: Math.max(parent.height, parent.width * Math.min(1, bar.value))
        height: parent.height
        radius: parent.radius
        color: bar.fillColor
        visible: bar.value > 0
    }
}

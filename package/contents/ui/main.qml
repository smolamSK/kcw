// Panel widget for ~/.local/bin/claude-usage: Claude plan usage for the current
// 5-hour session and the weekly limit, with the time left until each resets.
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    readonly property string command: "$HOME/.local/bin/claude-usage"
    readonly property string usageUrl: "https://claude.ai/settings/usage"
    readonly property int sessionSecs: 5 * 3600
    readonly property int weekSecs: 7 * 86400

    property var info: ({})          // output of `claude-usage`
    property bool fetching: false
    property real now: Date.now()

    readonly property bool hasData: !!info.session
    readonly property int sessionPct: pct(info.session)
    readonly property int weeklyPct: pct(info.weekly)

    // A window's usage drops to zero once its reset time passes, even before the next fetch.
    function passed(limit) {
        return !!limit && !!limit.resets_at && limit.resets_at * 1000 <= now
    }
    function pct(limit) {
        return !limit || passed(limit) ? 0 : limit.percent
    }
    function elapsed(limit, windowSecs) {
        if (!limit || !limit.resets_at || passed(limit)) return 0
        return Math.max(0, Math.min(1, 1 - (limit.resets_at * 1000 - now) / (windowSecs * 1000)))
    }
    function levelColor(p) {
        return p >= 90 ? Kirigami.Theme.negativeTextColor
             : p >= 70 ? Kirigami.Theme.neutralTextColor
             : Kirigami.Theme.highlightColor
    }

    // "51 min", "3 h 12 min", "2 d 4 h"
    function duration(secs) {
        const mins = Math.max(1, Math.ceil(secs / 60))
        if (mins < 60) return mins + " min"
        const h = Math.floor(mins / 60), m = mins % 60
        if (h < 24) return m ? h + " h " + m + " min" : h + " h"
        const d = Math.floor(h / 24), rh = h % 24
        return rh ? d + " d " + rh + " h" : d + " d"
    }
    // "today 20:50", "tomorrow 06:00", "Wed 06:00"
    function clock(epochSecs) {
        const d = new Date(epochSecs * 1000)
        const time = d.toLocaleTimeString(Qt.locale(), Locale.ShortFormat)
        const today = new Date(now)
        const tomorrow = new Date(now + 86400000)
        if (d.toDateString() === today.toDateString()) return "today " + time
        if (d.toDateString() === tomorrow.toDateString()) return "tomorrow " + time
        return Qt.locale().dayName(d.getDay(), Locale.ShortFormat) + " " + time
    }
    function resetsIn(limit) {
        if (!limit) return ""
        if (!limit.resets_at) return "starts with your next message"
        if (passed(limit)) return "reset, updating…"
        return "resets in " + duration(limit.resets_at - now / 1000)
    }
    function resetText(limit) {
        if (!limit) return "No data yet"
        const text = resetsIn(limit)
        const line = text.charAt(0).toUpperCase() + text.slice(1)
        return limit.resets_at && !passed(limit) ? line + " · " + clock(limit.resets_at) : line
    }
    function ago(epochSecs) {
        const mins = Math.floor((now / 1000 - epochSecs) / 60)
        if (mins < 1) return "just now"
        return (mins < 60 ? mins + " min" : duration(mins * 60)) + " ago"
    }
    function money(value, currency) {
        const symbols = { EUR: "€", USD: "$", GBP: "£" }
        return Number(value).toLocaleCurrencyString(Qt.locale(), symbols[currency] || currency + " ")
    }

    function refresh(force) {
        fetching = true
        exec.connectSource(command + (force ? " --force" : ""))
    }

    // Fetch again once a window has reset, so the new one's numbers show up.
    function refreshAfterReset() {
        const fetched = (info.fetched_at || 0) * 1000
        const due = [info.session, info.weekly].some(l => passed(l) && fetched < l.resets_at * 1000)
        if (due && !fetching) refresh(false)
    }

    P5Support.DataSource {
        id: exec
        engine: "executable"
        onNewData: (source, data) => {
            disconnectSource(source)
            root.fetching = false
            root.now = Date.now()
            try {
                root.info = JSON.parse(data.stdout)
            } catch (e) {
                root.info = Object.assign({}, root.info, { stale: true, error: "claude-usage failed to run" })
            }
        }
    }

    Timer {
        interval: 5 * 60 * 1000
        running: true
        repeat: true
        onTriggered: root.refresh(false)
    }
    Timer {
        interval: 30 * 1000   // keep the countdowns live between fetches
        running: true
        repeat: true
        onTriggered: {
            root.now = Date.now()
            root.refreshAfterReset()
        }
    }

    Component.onCompleted: refresh(false)
    onExpandedChanged: if (expanded) { now = Date.now(); refresh(false) }

    Plasmoid.icon: "speedometer"
    toolTipMainText: "Claude usage"
    toolTipTextFormat: Text.PlainText
    toolTipSubText: {
        if (!hasData) return info.error || "Loading…"
        const lines = [
            "Session " + sessionPct + "% · " + resetsIn(info.session),
            "Weekly " + weeklyPct + "% · " + resetsIn(info.weekly),
        ]
        if (info.stale) lines.push(info.error)
        return lines.join("\n")
    }

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: "Refresh"
            icon.name: "view-refresh"
            enabled: !root.fetching
            onTriggered: root.refresh(true)
        },
        PlasmaCore.Action {
            text: "Open usage page"
            icon.name: "internet-web-browser-symbolic"
            onTriggered: Qt.openUrlExternally(root.usageUrl)
        }
    ]

    compactRepresentation: MouseArea {
        id: compact

        readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
        readonly property real fontPx: vertical ? Kirigami.Units.gridUnit * 0.7
                                                : Math.min(Kirigami.Units.gridUnit * 0.75, height * 0.34)
        property bool wasExpanded

        Layout.minimumWidth: vertical ? 0 : grid.implicitWidth + Kirigami.Units.smallSpacing * 2
        Layout.preferredWidth: Layout.minimumWidth
        Layout.minimumHeight: vertical ? grid.implicitHeight + Kirigami.Units.smallSpacing * 2 : 0
        Layout.preferredHeight: Layout.minimumHeight

        hoverEnabled: true
        opacity: root.info.stale ? 0.55 : 1
        onPressed: wasExpanded = root.expanded
        onClicked: root.expanded = !wasExpanded

        TextMetrics {
            id: pctMetrics
            font.pixelSize: compact.fontPx
            text: "100%"
        }

        GridLayout {
            id: grid
            anchors.centerIn: parent
            width: compact.vertical ? parent.width - Kirigami.Units.smallSpacing * 2 : implicitWidth
            columns: compact.vertical ? 1 : 2
            rowSpacing: Math.round(Kirigami.Units.smallSpacing / 2)
            columnSpacing: Kirigami.Units.smallSpacing

            MiniBar {
                Layout.fillWidth: compact.vertical
                Layout.preferredWidth: Kirigami.Units.gridUnit * 2.5
                value: root.sessionPct / 100
                fillColor: root.levelColor(root.sessionPct)
            }
            PlasmaComponents.Label {
                Layout.minimumWidth: pctMetrics.advanceWidth
                horizontalAlignment: compact.vertical ? Text.AlignHCenter : Text.AlignRight
                font.pixelSize: compact.fontPx
                text: root.hasData ? root.sessionPct + "%" : "–"
            }
            MiniBar {
                Layout.fillWidth: compact.vertical
                Layout.preferredWidth: Kirigami.Units.gridUnit * 2.5
                value: root.weeklyPct / 100
                fillColor: root.levelColor(root.weeklyPct)
            }
            PlasmaComponents.Label {
                Layout.minimumWidth: pctMetrics.advanceWidth
                horizontalAlignment: compact.vertical ? Text.AlignHCenter : Text.AlignRight
                font.pixelSize: compact.fontPx
                text: root.hasData ? root.weeklyPct + "%" : "–"
            }
        }
    }

    fullRepresentation: PlasmaExtras.Representation {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 20
        Layout.minimumWidth: Kirigami.Units.gridUnit * 16
        Layout.preferredHeight: implicitHeight
        Layout.minimumHeight: implicitHeight

        ColumnLayout {
            anchors { left: parent.left; right: parent.right; top: parent.top }
            spacing: Kirigami.Units.largeSpacing

            RowLayout {
                Layout.fillWidth: true

                PlasmaExtras.Heading {
                    Layout.fillWidth: true
                    level: 3
                    text: "Claude usage"
                }
                PlasmaComponents.Label {
                    visible: !!root.info.plan
                    opacity: 0.7
                    text: root.info.plan ? root.info.plan.charAt(0).toUpperCase() + root.info.plan.slice(1) + " plan" : ""
                }
                PlasmaComponents.ToolButton {
                    icon.name: "view-refresh"
                    text: "Refresh"
                    display: PlasmaComponents.AbstractButton.IconOnly
                    enabled: !root.fetching
                    onClicked: root.refresh(true)
                    PlasmaComponents.ToolTip { text: "Refresh now" }
                }
            }

            UsageCard {
                Layout.fillWidth: true
                title: "Current session (5 h)"
                known: root.hasData
                percent: root.sessionPct
                elapsed: root.elapsed(root.info.session, root.sessionSecs)
                fillColor: root.levelColor(root.sessionPct)
                resetText: root.resetText(root.info.session)
            }

            UsageCard {
                Layout.fillWidth: true
                title: "Weekly (all models)"
                known: !!root.info.weekly
                percent: root.weeklyPct
                elapsed: root.elapsed(root.info.weekly, root.weekSecs)
                fillColor: root.levelColor(root.weeklyPct)
                resetText: root.resetText(root.info.weekly)
            }

            Repeater {
                model: root.info.models || []
                UsageCard {
                    required property var modelData
                    Layout.fillWidth: true
                    title: modelData.label
                    percent: root.pct(modelData)
                    elapsed: root.elapsed(modelData, root.weekSecs)
                    fillColor: root.levelColor(percent)
                    resetText: root.resetText(modelData)
                }
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                visible: !!root.info.extra && root.info.extra.enabled
                wrapMode: Text.Wrap
                text: visible
                    ? "Extra usage: " + root.money(root.info.extra.used, root.info.extra.currency)
                      + " of " + root.money(root.info.extra.limit, root.info.extra.currency) + " this month"
                    : ""
            }

            Kirigami.Separator { Layout.fillWidth: true }

            RowLayout {
                Layout.fillWidth: true

                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    font: Kirigami.Theme.smallFont
                    color: root.info.stale ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.textColor
                    opacity: root.info.stale ? 1 : 0.7
                    text: {
                        if (root.fetching && !root.hasData) return "Loading…"
                        const updated = root.info.fetched_at ? "Updated " + root.ago(root.info.fetched_at) : ""
                        return root.info.stale ? [root.info.error, updated].filter(Boolean).join(" · ") : updated
                    }
                }
                PlasmaComponents.ToolButton {
                    text: "Usage page"
                    icon.name: "internet-web-browser-symbolic"
                    onClicked: Qt.openUrlExternally(root.usageUrl)
                }
            }
        }
    }
}

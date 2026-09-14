#!/bin/sh
# Install (or upgrade) the Claude Usage widget for the current user.
set -eu
cd "$(dirname "$0")"

install -Dm755 bin/claude-usage "$HOME/.local/bin/claude-usage"

if kpackagetool6 --type Plasma/Applet --show org.smolam.claudeusage >/dev/null 2>&1; then
    kpackagetool6 --type Plasma/Applet --upgrade package
else
    kpackagetool6 --type Plasma/Applet --install package
fi

echo "Installed. Add \"Claude Usage\" to a panel (right-click panel → Add Widgets…)."
echo "If you upgraded, run: systemctl --user restart plasma-plasmashell"

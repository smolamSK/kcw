# Claude Usage widget for KDE Plasma

A Plasma 6 panel widget that shows your Claude plan usage at a glance: the current 5-hour session and the weekly limit.

- **Panel:** two thin bars with percentages (session on top, weekly below). Each bar is colored by level: normal, from 70% amber, from 90% red.
- **Tooltip:** usage and time until reset for both windows.
- **Popup:** one card for each limit, plus any model-specific weekly limit your plan has. Each card shows:
  - the percent used;
  - how much of the window's time has passed, so you can tell if you're ahead of pace;
  - when it resets ("Resets in 52 min · today 20:50").

  The popup also shows your extra usage credits (if enabled) and has a link to claude.ai/settings/usage.

## Requirements

- KDE Plasma 6
- Python 3 (standard library only)
- [Claude Code](https://claude.com/claude-code) signed in with a Claude subscription (Pro/Max). The widget reuses its sign-in from `~/.claude/.credentials.json`.

## Install

```sh
git clone https://github.com/smolamSK/kcw.git
cd kcw
./install.sh
```

Then right-click a panel, choose **Add Widgets…**, and add **Claude Usage**.

## How it works

`bin/claude-usage` (installed to `~/.local/bin`) reads the Claude Code OAuth token and calls `https://api.anthropic.com/api/oauth/usage`, the same data Claude Code's `/usage` shows. It prints a small JSON summary and caches it in `~/.cache/claude-usage/last.json`. The widget runs it every 5 minutes and when you open the popup. Calls less than 60 s apart are served from the cache; `claude-usage --force` bypasses the cache.

The token is only read. It is never refreshed and the credentials file is never written, so the widget can't interfere with Claude Code. The token expires a few hours after you last used Claude Code. When that happens, the widget shows the last known numbers dimmed and marked as stale, and the reset countdowns keep running. It goes back to live numbers the next time you use Claude Code.

The usage endpoint is not a documented public API, so it may change without notice.

## Uninstall

```sh
kpackagetool6 --type Plasma/Applet --remove org.smolam.claudeusage
rm ~/.local/bin/claude-usage
rm -r ~/.cache/claude-usage
```

## License

MIT

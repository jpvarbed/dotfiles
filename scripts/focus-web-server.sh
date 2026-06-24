#!/bin/sh
# focus.jasonv.dev local dev server, kept alive by launchd (dev.jasonv.focus-web.plist) so
# https://focus.localhost is always up regardless of Claude/terminal sessions. launchd has a bare
# PATH, so set one that has portless + node. `exec` so launchd's KeepAlive tracks the real process.
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$HOME/.bun/bin"
cd "$HOME/dev/focus-timer/apps/web" || exit 1
exec portless focus vite

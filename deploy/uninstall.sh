#!/bin/bash
# uninstall.sh — remove the DATBOI LaunchAgents installed by install.sh.
set -u
LA="$HOME/Library/LaunchAgents"
for plist in "$LA"/com.datboi.*.plist; do
    [ -e "$plist" ] || continue
    label="$(basename "$plist" .plist)"
    launchctl bootout "gui/$(id -u)/$label" 2>/dev/null || true
    rm -f "$plist"
    echo "✓ removed $label"
done
echo "Done. (Your code, .env, and trade data are untouched.)"

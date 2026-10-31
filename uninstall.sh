#!/bin/bash
# Unloads the launchd agent and removes everything install.sh added.
set -uo pipefail

label=io.github.fireseasonnow.nightcap

launchctl bootout "gui/$(id -u)/$label" 2>/dev/null
rm -f "$HOME/Library/LaunchAgents/$label.plist" \
      "$HOME/.local/bin/nightcap" \
      "$HOME/Library/Logs/nightcap.log"

echo "Uninstalled."

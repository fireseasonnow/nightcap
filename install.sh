#!/bin/bash
# Installs nightcap to ~/.local/bin and loads a daily launchd agent for it.
# Re-running is safe: it replaces the script and reloads the agent.
#
#   ./install.sh          run every 24 hours, counted from install/login
#   ./install.sh 03:00    run daily at 03:00 (or on wake, if asleep then)
set -euo pipefail

label=io.github.fireseasonnow.nightcap
bin="$HOME/.local/bin/nightcap"
plist="$HOME/Library/LaunchAgents/$label.plist"
domain="gui/$(id -u)"

if [ $# -eq 0 ]; then
  schedule="  <key>StartInterval</key>
  <integer>86400</integer>"
  when="every 24 hours"
elif [[ $1 =~ ^([01]?[0-9]|2[0-3]):([0-5][0-9])$ ]]; then
  schedule="  <key>StartCalendarInterval</key>
  <dict>
    <key>Hour</key>
    <integer>$((10#${BASH_REMATCH[1]}))</integer>
    <key>Minute</key>
    <integer>$((10#${BASH_REMATCH[2]}))</integer>
  </dict>"
  when="daily at $1"
else
  echo "usage: $0 [HH:MM]" >&2
  exit 1
fi

if ! command -v brew >/dev/null && [ ! -x /opt/homebrew/bin/brew ] && [ ! -x /usr/local/bin/brew ]; then
  echo "Homebrew not found; install it first: https://brew.sh" >&2
  exit 1
fi

mkdir -p "$(dirname "$bin")" "$(dirname "$plist")"
install -m 755 "$(dirname "$0")/nightcap" "$bin"

# launchd doesn't expand ~, so the paths are written out in full here
cat > "$plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$label</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>$bin</string>
  </array>
$schedule
  <key>RunAtLoad</key>
  <true/>
  <key>ProcessType</key>
  <string>Background</string>
  <key>LowPriorityIO</key>
  <true/>
</dict>
</plist>
EOF

launchctl bootout "$domain/$label" 2>/dev/null || true
launchctl bootstrap "$domain" "$plist"

echo "Installed, running $when and at login. First run starts now; log: ~/Library/Logs/nightcap.log"

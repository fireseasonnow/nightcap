#!/bin/bash
# Installs nightcap to ~/.local/bin and loads a launchd agent for it.
# Re-running is safe: it replaces the script, reloads the agent and runs now.
#
#   ./install.sh                 run daily, counted from the last run
#   ./install.sh weekly          also: daily, biweekly (every 2 weeks), monthly
#   ./install.sh weekly 03:00    run weekly at 03:00 (or on wake, if asleep then)
set -euo pipefail

label=io.github.fireseasonnow.nightcap
bin="$HOME/.local/bin/nightcap"
plist="$HOME/Library/LaunchAgents/$label.plist"
next_run="$HOME/.local/state/nightcap-next-run"
domain="gui/$(id -u)"

step=+1d when=daily
case ${1:-} in
  daily)    shift ;;
  weekly)   step=+1w when=weekly; shift ;;
  biweekly) step=+2w when="every 2 weeks"; shift ;;
  monthly)  step=+1m when=monthly; shift ;;
esac

# The agent fires hourly and the script decides whether a run is due: launchd
# can't express every 2 weeks, and its own timers restart at every login.
if [ $# -eq 0 ]; then
  schedule="  <key>StartInterval</key>
  <integer>3600</integer>"
  time_args=""
elif [ $# -eq 1 ] && [[ $1 =~ ^([01]?[0-9]|2[0-3]):([0-5][0-9])$ ]]; then
  hour=$((10#${BASH_REMATCH[1]}))
  minute=$((10#${BASH_REMATCH[2]}))
  # Minute alone means every hour, on that minute, so a 03:00 run starts at 03:00
  schedule="  <key>StartCalendarInterval</key>
  <dict>
    <key>Minute</key>
    <integer>$minute</integer>
  </dict>"
  time_args="    <string>-v${hour}H</string>
    <string>-v${minute}M</string>
"
  when="$when at $1"
else
  echo "usage: $0 [daily|weekly|biweekly|monthly] [HH:MM]" >&2
  exit 1
fi

if ! command -v brew >/dev/null && [ ! -x /opt/homebrew/bin/brew ] && [ ! -x /usr/local/bin/brew ]; then
  echo "Homebrew not found; install it first: https://brew.sh" >&2
  exit 1
fi

mkdir -p "$(dirname "$bin")" "$(dirname "$plist")" "$(dirname "$next_run")"
install -m 755 "$(dirname "$0")/nightcap" "$bin"
rm -f "$next_run"

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
    <string>-v$step</string>
$time_args    <string>-v0S</string>
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

echo "Installed, running $when. First run starts now if on AC power; log: ~/Library/Logs/nightcap.log"

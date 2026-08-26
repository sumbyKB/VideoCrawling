#!/bin/bash
# === TikTok scrape Chrome launcher (macOS / Linux) ===
# Independent profile + debug port 9223, no auth popup
# First time: login TikTok once in the new window
# Repo: tiktok-creator-scan

# detect Chrome path
if [ -x "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ]; then
  CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
elif command -v google-chrome >/dev/null 2>&1; then
  CHROME="google-chrome"
elif command -v chromium-browser >/dev/null 2>&1; then
  CHROME="chromium-browser"
else
  echo "Chrome not found. Please install Google Chrome first."
  exit 1
fi

PROFILE="$HOME/WorkBuddy/tiktok-chrome"
mkdir -p "$PROFILE"

# check if 9223 already listening
if command -v lsof >/dev/null 2>&1 && lsof -i :9223 >/dev/null 2>&1; then
  echo "[INFO] TikTok Chrome is already running on port 9223"
  echo "To restart: close that Chrome window first, then run this script again"
  exit 0
fi

echo "Starting TikTok scrape Chrome..."
"$CHROME" --remote-debugging-port=9223 --user-data-dir="$PROFILE" --no-first-run --no-default-browser-check --restore-last-session=false --window-size=1280,800 "https://www.tiktok.com/" &

echo ""
echo "Started (port 9223, independent profile)"
echo "First time: please login TikTok once in the new Chrome window"
echo "After that, just keep this window open, Claude will connect automatically"

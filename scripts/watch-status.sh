#!/usr/bin/env bash
# watch-status.sh — Poll meter connection status every N seconds
# Usage: ./scripts/watch-status.sh [interval_seconds]
#   Default interval: 60 seconds

source "$(dirname "$0")/eagle-common.sh"

INTERVAL="${1:-60}"

echo "=== Watching EAGLE-200 Meter Status (every ${INTERVAL}s) ==="
echo "Press Ctrl+C to stop"
echo ""

while true; do
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  response=$(eagle_api '<Command><n>device_list</n></Command>')
  status=$(echo "$response" | grep -oP '(?<=<ConnectionStatus>).*?(?=</ConnectionStatus>)')
  last_contact=$(echo "$response" | grep -oP '(?<=<LastContact>).*?(?=</LastContact>)')

  if [[ "$status" == "Connected" ]]; then
    echo "[$timestamp] ✅ CONNECTED! (LastContact: $last_contact)"
    echo ""
    echo "🎉 Meter is back online! Run ./scripts/query-demand.sh to see live data."
    # Optional: macOS notification
    if command -v osascript &> /dev/null; then
      osascript -e 'display notification "Smart meter connection restored!" with title "EAGLE-200" sound name "Glass"'
    fi
    break
  else
    echo "[$timestamp] ❌ ${status:-UNKNOWN} (LastContact: $last_contact)"
  fi

  sleep "$INTERVAL"
done

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
  response=$(eagle_api '<Command><Name>device_list</Name></Command>')

  # Extract the configured meter's <Device> entry (device_list can include multiple devices).
  response_flat=$(printf '%s' "$response" | tr -d '\r\n')
  meter_device=$(printf '%s' "$response_flat" \
    | sed 's#</Device>#</Device>\n#g' \
    | grep -F "<HardwareAddress>${EAGLE_METER_ADDRESS}</HardwareAddress>" \
    | head -n 1)

  if [[ -z "$meter_device" ]]; then
    meter_device="$response_flat"
  fi

  status=$(printf '%s' "$meter_device" | sed -n 's/.*<ConnectionStatus>\(.*\)<\/ConnectionStatus>.*/\1/p')
  last_contact=$(printf '%s' "$meter_device" | sed -n 's/.*<LastContact>\(.*\)<\/LastContact>.*/\1/p')

  if [[ "$status" == "Connected" ]]; then
    echo "[$timestamp] CONNECTED (LastContact: $last_contact)"
    echo ""
    echo "Meter is back online. Run ./scripts/query-demand.sh to see live data."
    # Optional: macOS notification
    if command -v osascript &> /dev/null; then
      osascript -e 'display notification "Smart meter connection restored!" with title "EAGLE-200" sound name "Glass"'
    fi
    break
  else
    echo "[$timestamp] ${status:-UNKNOWN} (LastContact: $last_contact)"
  fi

  sleep "$INTERVAL"
done

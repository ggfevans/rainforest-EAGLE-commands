#!/usr/bin/env bash
# check-status.sh - Quick check of meter connection status
# Usage:
#   ./scripts/check-status.sh
#   ./scripts/check-status.sh --json
#   ./scripts/check-status.sh --status-only

source "$(dirname "$0")/eagle-common.sh"

OUTPUT_MODE="human" # human | json | status_only

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json)
      OUTPUT_MODE="json"
      ;;
    --status-only)
      OUTPUT_MODE="status_only"
      ;;
    -h|--help)
      echo "Usage: $0 [--json] [--status-only]"
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
  shift
done

json_escape() {
  local s="$1"
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  s=${s//$'\n'/}
  s=${s//$'\r'/}
  printf '%s' "$s"
}

response=$(eagle_api '<Command><Name>device_list</Name></Command>')

# device_list can include multiple <Device> entries; select the configured meter.
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
network_addr=$(printf '%s' "$meter_device" | sed -n 's/.*<NetworkAddress>\(.*\)<\/NetworkAddress>.*/\1/p')

status=${status:-UNKNOWN}
last_contact=${last_contact:-UNKNOWN}
network_addr=${network_addr:-UNKNOWN}

if [[ "$OUTPUT_MODE" == "json" ]]; then
  connected="false"
  if [[ "$status" == "Connected" ]]; then
    connected="true"
  fi

  printf '{'
  printf '"status":"%s",' "$(json_escape "$status")"
  printf '"connected":%s,' "$connected"
  printf '"last_contact":"%s",' "$(json_escape "$last_contact")"
  printf '"network_address":"%s",' "$(json_escape "$network_addr")"
  printf '"eagle_address":"%s",' "$(json_escape "$EAGLE_ADDRESS")"
  printf '"cloud_id":"%s",' "$(json_escape "$EAGLE_CLOUD_ID")"
  printf '"meter_address":"%s"' "$(json_escape "$EAGLE_METER_ADDRESS")"
  printf '}'
  printf '\n'
  exit 0
fi

if [[ "$OUTPUT_MODE" == "status_only" ]]; then
  echo "$status"
  exit 0
fi

echo "=== EAGLE-200 Meter Connection Status ==="
echo "Device: ${EAGLE_ADDRESS} (Cloud ID: ${EAGLE_CLOUD_ID})"
echo ""
echo "Connection Status: ${status}"
echo "Last Contact:      ${last_contact}"
echo "Network Address:   ${network_addr}"
echo ""

if [[ "$status" == "Connected" ]]; then
  echo "Meter is connected."
elif [[ "$status" == "Not joined" ]]; then
  echo "Meter is not joined. Waiting for BC Hydro to re-provision."
else
  echo "Unexpected status: $status"
fi

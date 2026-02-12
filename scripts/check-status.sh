#!/usr/bin/env bash
# check-status.sh — Quick check of meter connection status
# Usage: ./scripts/check-status.sh
#   Returns connection status and last contact timestamp

source "$(dirname "$0")/eagle-common.sh"

echo "=== EAGLE-200 Meter Connection Status ==="
echo "Device: ${EAGLE_ADDRESS} (Cloud ID: ${EAGLE_CLOUD_ID})"
echo ""

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

echo "Connection Status: ${status:-UNKNOWN}"
echo "Last Contact:      ${last_contact:-UNKNOWN}"
echo "Network Address:   ${network_addr:-UNKNOWN}"
echo ""

if [[ "$status" == "Connected" ]]; then
  echo "✅ Meter is connected!"
elif [[ "$status" == "Not joined" ]]; then
  echo "❌ Meter is NOT joined — waiting for BC Hydro to re-provision"
else
  echo "⚠️  Unexpected status: $status"
fi

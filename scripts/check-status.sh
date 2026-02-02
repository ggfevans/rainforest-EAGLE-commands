#!/usr/bin/env bash
# check-status.sh — Quick check of meter connection status
# Usage: ./scripts/check-status.sh
#   Returns connection status and last contact timestamp

source "$(dirname "$0")/eagle-common.sh"

echo "=== EAGLE-200 Meter Connection Status ==="
echo "Device: ${EAGLE_ADDRESS} (Cloud ID: ${EAGLE_CLOUD_ID})"
echo ""

response=$(eagle_api '<Command><Name>device_list</Name></Command>')

status=$(echo "$response" | sed -n 's/.*<ConnectionStatus>\(.*\)<\/ConnectionStatus>.*/\1/p')
last_contact=$(echo "$response" | sed -n 's/.*<LastContact>\(.*\)<\/LastContact>.*/\1/p')
network_addr=$(echo "$response" | sed -n 's/.*<NetworkAddress>\(.*\)<\/NetworkAddress>.*/\1/p')

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

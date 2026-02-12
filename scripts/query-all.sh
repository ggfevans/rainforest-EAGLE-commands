#!/usr/bin/env bash
# query-all.sh — Query all available variables from the meter
# Usage: ./scripts/query-all.sh

source "$(dirname "$0")/eagle-common.sh"

echo "=== EAGLE-200 Full Meter Query ==="
eagle_api "<Command><Name>device_query</Name><DeviceDetails><HardwareAddress>${EAGLE_METER_ADDRESS}</HardwareAddress></DeviceDetails><Components><All>Y</All></Components></Command>"
echo ""

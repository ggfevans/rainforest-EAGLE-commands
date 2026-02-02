#!/usr/bin/env bash
# device-details.sh — Full meter profile and variable list
# Usage: ./scripts/device-details.sh

source "$(dirname "$0")/eagle-common.sh"

echo "=== EAGLE-200 Meter Details ==="
eagle_api "<Command><n>device_details</n><DeviceDetails><HardwareAddress>${EAGLE_METER_ADDRESS}</HardwareAddress></DeviceDetails></Command>"
echo ""

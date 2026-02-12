#!/usr/bin/env bash
# query-demand.sh — Query instantaneous power demand from meter
# Usage: ./scripts/query-demand.sh [--refresh]
#   --refresh  Force the EAGLE to send a fresh request to the meter

source "$(dirname "$0")/eagle-common.sh"

REFRESH=""
if [[ "$1" == "--refresh" ]]; then
  REFRESH="<Refresh>Y</Refresh>"
  echo "=== Querying Meter (with refresh) ==="
else
  echo "=== Querying Meter (from buffer) ==="
fi

eagle_api "<Command><Name>device_query</Name><DeviceDetails><HardwareAddress>${EAGLE_METER_ADDRESS}</HardwareAddress></DeviceDetails><Components><Component><Name>Main</Name><Variables><Variable><Name>zigbee:InstantaneousDemand</Name>${REFRESH}</Variable></Variables></Component></Components></Command>"
echo ""

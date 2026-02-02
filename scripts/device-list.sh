#!/usr/bin/env bash
# device-list.sh — Full device list from EAGLE
# Usage: ./scripts/device-list.sh

source "$(dirname "$0")/eagle-common.sh"

echo "=== EAGLE-200 Device List ==="
eagle_api '<Command><Name>device_list</Name></Command>'
echo ""

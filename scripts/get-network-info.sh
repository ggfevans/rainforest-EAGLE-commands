#!/usr/bin/env bash
# get-network-info.sh — Query ZigBee network info
# Usage: ./scripts/get-network-info.sh

source "$(dirname "$0")/eagle-common.sh"

echo "=== EAGLE-200 Network Info ==="
eagle_api '<Command><n>get_network_info</n></Command>'
echo ""

#!/usr/bin/env bash
# eagle-common.sh — shared setup for all EAGLE scripts
# Source the .env file relative to this script's location

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

if [[ -f "$PROJECT_DIR/.env" ]]; then
  set -a
  source "$PROJECT_DIR/.env"
  set +a
else
  echo "ERROR: .env not found at $PROJECT_DIR/.env"
  exit 1
fi

# Common curl function for EAGLE local API
eagle_api() {
  local command_xml="$1"
  curl --silent --anyauth \
    -u "${EAGLE_CLOUD_ID}:${EAGLE_INSTALL_CODE}" \
    -XPOST "http://${EAGLE_ADDRESS}/cgi-bin/post_manager" \
    -d "$command_xml"
}

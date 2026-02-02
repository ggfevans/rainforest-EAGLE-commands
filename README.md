# Rainforest Automation EAGLE-200 — Local API Commands

Hacked-together personal scripts for interacting with a Rainforest Automation EAGLE-200 device via the Local API. Shared here in case it helps someone else.

These scripts require access to an EAGLE-200 device. They were built and tested on macOS, but will likely work on other Unix-like systems with minimal changes.

## Setup

All scripts source `.env` for device credentials. Copy `.env.example` to `.env` and edit if the device IP or credentials change.

```bash
chmod +x scripts/*.sh
```

## Quick Reference

### Check connection status (one-shot)
```bash
./scripts/check-status.sh
```

### Watch for reconnection (polling)
```bash
./scripts/watch-status.sh        # Default: every 60 seconds
./scripts/watch-status.sh 30     # Custom: every 30 seconds
```
Sends a macOS notification when the meter reconnects.

### Query meter data (once connected)
```bash
./scripts/query-demand.sh            # Read buffered demand value
./scripts/query-demand.sh --refresh  # Force fresh read from meter
./scripts/query-all.sh               # Dump all meter variables
```

### Diagnostics
```bash
./scripts/device-list.sh         # List all devices EAGLE knows about
./scripts/device-details.sh      # Full meter profile and variable list
./scripts/get-network-info.sh    # ZigBee network info
```

## Current Issue (2025-02-01)

Meter connection status: **Not joined**
- EAGLE hardware, firmware, network, and cloud are all healthy
- ZigBee radio is active (solid green LED)
- Smart meter is not accepting join requests
- BC Hydro request submitted: #18785050
- Rainforest Automation support ticket also submitted
- Waiting for BC Hydro to re-provision the meter for HAN communication

## Useful Info

- Local web interface: http://{EAGLE device IP}:80 (login: Cloud ID / Install Code)
- Cloud portal: https://portal.rainforestcloud.com/user/home
- Rainforest support: https://support.rainforestautomation.com
- BC Hydro Rainforest page: https://www.bchydro.com/powersmart/residential/tools-and-calculators/rainforest-devices.html
- EAGLE-200 Local API manual: https://rainforestautomation.com/wp-content/uploads/2017/02/EAGLE-200-Local-API-Manual-v1.0.pdf

## Third-party content

This repo includes a copy and a derived markdown reference of the Rainforest Automation EAGLE-200 Local API Manual. Copyright remains with Rainforest Automation, Inc. The manual was retrieved on Feb 1, 2026 from the URL above.

## License

Code in this repository is licensed under the MIT License (see `LICENSE`). This license does not apply to `EAGLE-200-Local-API-Manual-v1.0.pdf` or `EAGLE-200-Local-API-Manual-v1.0.md`.

## Disclaimer

All content in this repository is provided "as is", without warranties or guarantees of any kind. Use at your own risk.

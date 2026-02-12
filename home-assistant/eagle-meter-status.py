#!/usr/bin/env python3
"""eagle-meter-status.py

Home Assistant helper for tracking EAGLE-200 meter join/connection status.

- Reads credentials from a .env file (default: alongside this script)
- Calls the local EAGLE API (device_list)
- Emits one line of JSON suitable for command_line sensor parsing

Expected .env keys:
  EAGLE_ADDRESS
  EAGLE_CLOUD_ID
  EAGLE_INSTALL_CODE
  EAGLE_METER_ADDRESS
"""

from __future__ import annotations

import base64
import json
import os
import sys
import time
import urllib.error
import urllib.request
import xml.etree.ElementTree as ET


def _load_env(env_path: str) -> dict[str, str]:
    env: dict[str, str] = {}
    with open(env_path, "r", encoding="utf-8") as f:
        for raw_line in f:
            line = raw_line.strip()
            if not line or line.startswith("#"):
                continue
            if "=" not in line:
                continue
            k, v = line.split("=", 1)
            k = k.strip()
            v = v.strip().strip('"').strip("'")
            if k:
                env[k] = v
    return env


def _first_text(elem: ET.Element | None, tag: str) -> str | None:
    if elem is None:
        return None
    child = elem.find(tag)
    if child is None or child.text is None:
        return None
    return child.text.strip()


def _post_eagle(address: str, cloud_id: str, install_code: str, command_xml: str) -> bytes:
    url = f"http://{address}/cgi-bin/post_manager"
    token = base64.b64encode(f"{cloud_id}:{install_code}".encode("utf-8")).decode("ascii")

    req = urllib.request.Request(
        url=url,
        data=command_xml.encode("utf-8"),
        method="POST",
        headers={
            "Content-Type": "text/xml",
            "Authorization": f"Basic {token}",
        },
    )

    with urllib.request.urlopen(req, timeout=10) as resp:
        return resp.read()


def main() -> int:
    script_dir = os.path.dirname(os.path.abspath(__file__))
    env_path = os.environ.get("EAGLE_ENV_PATH", os.path.join(script_dir, ".env"))

    out: dict[str, object] = {
        "ok": False,
        "status": "UNKNOWN",
        "connected": False,
        "last_contact": "UNKNOWN",
        "network_address": "UNKNOWN",
        "ts": int(time.time()),
    }

    try:
        env = _load_env(env_path)

        address = env.get("EAGLE_ADDRESS", "").strip()
        cloud_id = env.get("EAGLE_CLOUD_ID", "").strip()
        install_code = env.get("EAGLE_INSTALL_CODE", "").strip()
        meter_addr = env.get("EAGLE_METER_ADDRESS", "").strip()

        out["eagle_address"] = address
        out["cloud_id"] = cloud_id
        out["meter_address"] = meter_addr

        missing = [
            k
            for k in ["EAGLE_ADDRESS", "EAGLE_CLOUD_ID", "EAGLE_INSTALL_CODE", "EAGLE_METER_ADDRESS"]
            if not env.get(k)
        ]
        if missing:
            out["error"] = f"Missing keys in {env_path}: {', '.join(missing)}"
            print(json.dumps(out, separators=(",", ":")))
            return 0

        xml_bytes = _post_eagle(
            address=address,
            cloud_id=cloud_id,
            install_code=install_code,
            command_xml="<Command><Name>device_list</Name></Command>",
        )

        root = ET.fromstring(xml_bytes)
        devices = root.findall(".//Device")
        match = None
        for dev in devices:
            hw = _first_text(dev, "HardwareAddress")
            if hw == meter_addr:
                match = dev
                break

        if match is None and devices:
            match = devices[0]

        status = _first_text(match, "ConnectionStatus") or "UNKNOWN"
        last_contact = _first_text(match, "LastContact") or "UNKNOWN"
        network_address = _first_text(match, "NetworkAddress") or "UNKNOWN"

        out["ok"] = True
        out["status"] = status
        out["connected"] = status == "Connected"
        out["last_contact"] = last_contact
        out["network_address"] = network_address

        print(json.dumps(out, separators=(",", ":")))
        return 0

    except FileNotFoundError:
        out["error"] = f"Env file not found: {env_path}"
        print(json.dumps(out, separators=(",", ":")))
        return 0
    except (urllib.error.URLError, urllib.error.HTTPError) as e:
        out["error"] = f"HTTP error: {getattr(e, 'reason', str(e))}"
        print(json.dumps(out, separators=(",", ":")))
        return 0
    except ET.ParseError:
        out["error"] = "Failed to parse XML response"
        print(json.dumps(out, separators=(",", ":")))
        return 0
    except Exception as e:  # noqa: BLE001
        out["error"] = f"Unhandled error: {e}"
        print(json.dumps(out, separators=(",", ":")))
        return 0


if __name__ == "__main__":
    sys.exit(main())

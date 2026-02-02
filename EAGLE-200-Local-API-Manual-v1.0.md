# EAGLE-200 Local API Manual (v1.0)

Version: 1.0  
Date: Sep 2017  
Source: https://rainforestautomation.com/wp-content/uploads/2017/02/EAGLE-200-Local-API-Manual-v1.0.pdf (retrieved Feb 1, 2026)

## Overview
- The EAGLE-200 gateway is an Ethernet network node that communicates over HTTP (TCP/IP).
- The Local API lets devices on the same local network issue commands and retrieve data.
- Devices outside the local network should use the EAGLE-200 REST API.
- The EAGLE is identified by its Cloud ID (last 6 digits of its Ethernet MAC ID), shown on the device label.
- The EAGLE can be discovered via mDNS as `eagle-xxxxxx` where `xxxxxx` is the Cloud ID.
- Requests are HTTP POSTs using 8-bit Extended ASCII (code page 1252) and XML fragments.

## Data Format
### Commands (HTTP POST)
POST requests use this structure:

```
POST <URL> HTTP/1.0
<headers>
<blank>
<body>
```

Notes:
- Each line ends with CRLF (`0x0D 0x0A`).
- `<URL>` is the EAGLE address.
- `<headers>` are standard HTTP headers. Required headers:
  - `Content-type: text/xml`
  - `Content-Length: xx` (number of characters in the body)
  - `Authorization: Basic xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`
    - The 32-character Basic Auth credential is formed using:
      - Username: EAGLE Cloud ID
      - Password: EAGLE Install Code
- `<blank>` is an empty CRLF line.
- `<body>` contains XML fragments.

#### XML Fragments
Structure:

```
<tag>
<element>value</element>
...
</tag>
```

Conventions:
- Element names are case-insensitive.
- Value types in the manual:
  - `{string}`: Extended ASCII text
  - `{enumeration}`: one of a specific list
  - `0xFFFFF`: base-16 (hex) value
  - `00`: integer
  - `000.000`: signed decimal
  - `[<element>]`: optional element
  - `value1|value2|value3`: enumeration values

#### Example POST Request
```
POST http://192.168.100.164/cgi-bin/post_manager HTTP/1.0
Content-type: text/xml
Content-Length: 43
Authorization: Basic MDA0NzkyOmJmYjBmYzA1ZjUxYTM5MzI=
<Command><Name>wifi_status</Name></Command>
```

### Responses
EAGLE responses are valid HTTP responses:

```
HTTP/1.0 <code>
<headers>
<blank>
<body>
```

Notes:
- `<code>` is the HTTP status code (typically `200 OK`).
- `<body>` contains XML fragments.

#### Example Response
```
HTTP/1.0 200 OK
Date: Sat, 19 Aug 2017 01:04:06 GMT
Access-Control-Allow-Credentials: true
Access-Control-Allow-Headers: Authorization
Content-Length: 205
Content-Type: text/html
<WiFiStatus>
<Enabled>Y</Enabled>
<Type>router</Type>
<SSID>eagle-004792 (router)</SSID>
<Encryption>WPA2 PSK (CCMP)</Encryption>
<Channel>11</Channel>
<IpAddress>192.168.7.1</IpAddress>
</WiFiStatus>
```

### HTTP 1.1
- If HTTP/1.1 is used, the response uses `Transfer-Encoding: chunked` instead of `Content-Length`.
- Each chunk is preceded by the chunk length (hex) and followed by a blank line.
- The message ends with a single `0` line.

## Subdevice Networks
The EAGLE-200 has two Zigbee radios that create two independent networks:

1. **Utility HAN**
   - Communicates with the smart meter using Smart Energy Profile (SEP).
   - The smart meter is the Coordinator; the EAGLE is an Endpoint.
   - The meter appears as an `electric_meter` device.

2. **Control Network**
   - The EAGLE is the Coordinator for this independent Zigbee network.
   - Used to connect and control supported subdevices (SEP or HA).
   - Subdevices must be supported by Rainforest Automation profiles.

Either network can be active independently. All devices share the same Local API.

## Reading Meter Data
### 1) Discover the meter hardware address
Send a `device_list` command:

```
<Command>
<Name>device_list</Name>
</Command>
```

Example `<DeviceList>` response (meter entry):
```
<Device>
<HardwareAddress>0x000781000081fd0b</HardwareAddress>
<Manufacturer>generic</Manufacturer>
<ModelId>electric_meter</ModelId>
<Protocol>Zigbee</Protocol>
<LastContact>0x5989f8f5</LastContact>
<ConnectionStatus>Connected</ConnectionStatus>
<NetworkAddress>0x0000</NetworkAddress>
</Device>
```

### 2) Query a specific variable
Use `device_query` with the meter hardware address:

```
<Command>
<Name>device_query</Name>
<DeviceDetails>
<HardwareAddress>0x000781000081fd0b</HardwareAddress>
</DeviceDetails>
<Components>
<Component>
<Name>Main</Name>
<Variables>
<Variable>
<Name>zigbee:InstantaneousDemand</Name>
</Variable>
</Variables>
</Component>
</Components>
</Command>
```

Example response excerpt:
```
<Variable>
<Name>zigbee:InstantaneousDemand</Name>
<Value>21.499 kW</Value>
</Variable>
```

Note: `<Value>` is ASCII text. Convert to a number for calculations.

### 3) List available variables
Use `device_details`:

```
<Command>
<Name>device_details</Name>
<DeviceDetails>
<HardwareAddress>0x000781000081fd0b</HardwareAddress>
</DeviceDetails>
</Command>
```

Example response excerpt:
```
<Variables>
<Variable>zigbee:InstantaneousDemand</Variable>
<Variable>zigbee:Multiplier</Variable>
<Variable>zigbee:Divisor</Variable>
<Variable>zigbee:CurrentSummationDelivered</Variable>
<Variable>zigbee:Price</Variable>
<Variable>zigbee:RateLabel</Variable>
<Variable>zigbee:Message</Variable>
</Variables>
```

### 4) Query all variables (shortcut)
```
<Command>
<Name>device_query</Name>
<DeviceDetails>
<HardwareAddress>0x000781000081fd0b</HardwareAddress>
</DeviceDetails>
<Components>
<All>Y</All>
</Components>
</Command>
```

## Monitoring and Controlling a Smart Plug
### Add a smart plug to the Control Network
Use `device_add` with the plug MAC and install code:

```
<Command>
<Name>device_add</Name>
<DeviceDetails>
<HardwareAddress>0x00244600000ebaba</HardwareAddress>
<InstallCode>0x0a1b2c3d4e5f6a7b</InstallCode>
<Manufacturer>SafePlug</Manufacturer>
<ModelId>1202</ModelId>
<Protocol>Zigbee</Protocol>
<Name>safeplug 1202</Name>
</DeviceDetails>
<NetworkInterface>
<HardwareAddress>0xd8d5b9000000b49f</HardwareAddress>
</NetworkInterface>
</Command>
```

Notes:
- `<HardwareAddress>` (DeviceDetails): smart plug MAC (16-digit hex)
- `<InstallCode>`: plug install code (16-digit hex)
- `<HardwareAddress>` (NetworkInterface): EAGLE MAC (16-digit hex)
- `<Manufacturer>` and `<ModelId>` must exactly match the device profile

After adding, the plug appears in `device_list` with `ModelId` and `Manufacturer`.

### Components example (SafePlug 1202)
The plug has three components: `Global`, `Receptacle 1`, and `Receptacle 2`.

### Monitoring
Query instantaneous demand for both receptacles:

```
<Command>
<Name>device_query</Name>
<DeviceDetails>
<HardwareAddress>0x00244600000ebaba</HardwareAddress>
</DeviceDetails>
<Components>
<Component>
<Name>Receptacle 1</Name>
<Variables>
<Variable>
<Name>zigbee:InstantaneousDemand</Name>
</Variable>
</Variables>
</Component>
<Component>
<Name>Receptacle 2</Name>
<Variables>
<Variable>
<Name>zigbee:InstantaneousDemand</Name>
</Variable>
</Variables>
</Component>
</Components>
</Command>
```

Example response excerpt:
```
<Value>0.120 kW</Value>
```

### Control
Turn off the top outlet and turn on the bottom outlet:

```
<Command>
<Name>device_control</Name>
<DeviceDetails>
<HardwareAddress>0x00244600000ebaba</HardwareAddress>
</DeviceDetails>
<Components>
<Component>
<Name>Receptacle 1</Name>
<Variables>
<Variable>
<Name>zigbee:OnOff</Name>
<Value>off</Value>
</Variable>
</Variables>
</Component>
<Component>
<Name>Receptacle 2</Name>
<Variables>
<Variable>
<Name>zigbee:OnOff</Name>
<Value>on</Value>
</Variable>
</Variables>
</Component>
</Components>
</Command>
```

#### Refreshing status
A `device_query` with `<Refresh>Y</Refresh>` triggers an update, but does not return the value immediately. Send a follow-up query to read the updated value:

```
<Variable>
<Name>zigbee:OnOff</Name>
<Refresh>Y</Refresh>
</Variable>
```

## Monitoring and Controlling a Thermostat
### Add a thermostat to the Control Network
Example for Emerson EE542-1Z:

```
<Command>
<Name>device_add</Name>
<DeviceDetails>
<HardwareAddress>0x00244600000abcde</HardwareAddress>
<InstallCode>0x0a1b2c3d4e5f6a7b</InstallCode>
<Manufacturer>emerson</Manufacturer>
<ModelId>ee542</ModelId>
<Protocol>Zigbee</Protocol>
<Name>emerson_ee542</Name>
</DeviceDetails>
<NetworkInterface>
<HardwareAddress>0xd8d5b9000000b49f</HardwareAddress>
</NetworkInterface>
</Command>
```

### List available variables
`device_details` response excerpt:
```
<Variables>
<Variable>zigbee:LocalTemperature</Variable>
<Variable>zigbee:OccupiedCoolingSetpoint</Variable>
<Variable>zigbee:OccupiedHeatingSetpoint</Variable>
<Variable>zigbee:SystemMode</Variable>
</Variables>
```

### Monitoring temperature
```
<Command>
<Name>device_query</Name>
<DeviceDetails>
<HardwareAddress>0x00244600000abcde</HardwareAddress>
</DeviceDetails>
<Components>
<Component>
<Name>Global</Name>
<Variables>
<Variable>
<Name>zigbee:LocalTemperature</Name>
</Variable>
</Variables>
</Component>
</Components>
</Command>
```

Example response excerpt:
```
<Value>27.22 C</Value>
```

Notes:
- `<Value>` is ASCII text and includes the scale (C or F).
- Use `<Refresh>Y</Refresh>` to force an update, then query again.

### System mode values
| Value | Mode |
| --- | --- |
| 0 | Off |
| 1 | Auto |
| 2 | Cool |
| 3 | Heat |
| 4 | Emergency Heat |
| 5 | Precool |
| 6 | Fan Only |
| 7 | Dry |
| 8 | Sleep |

### Control setpoints and mode
Example: set Cool mode and cooling setpoint to 20 C:

```
<Command>
<Name>device_control</Name>
<DeviceDetails>
<HardwareAddress>0x00244600000abcde</HardwareAddress>
</DeviceDetails>
<Components>
<Component>
<Name>Global</Name>
<Variables>
<Variable>
<Name>zigbee:OccupiedCoolingSetpoint</Name>
<Value>20</Value>
</Variable>
<Variable>
<Name>zigbee:SystemMode</Name>
<Value>3</Value>
</Variable>
</Variables>
</Component>
</Components>
</Command>
```

Note: temperature values are in degrees Celsius.

## Appendix: Supported Devices
| Type | Brand | Model | Profile Elements |
| --- | --- | --- | --- |
| Thermostat | RTCOA | CT32 | `<Manufacturer>RTCOA</Manufacturer>`<br>`<ModelId>CT32</ModelId>` |
| Thermostat | Carrier | ComfortChoice Touch | `<Manufacturer>Carrier</Manufacturer>`<br>`<ModelId>TouchPCT</ModelId>` |
| Thermostat | Emerson | EE542-1Z | `<Manufacturer>emerson</Manufacturer>`<br>`<ModelId>ee542</ModelId>` |
| Thermostat | ecobee | EB-SmartSi-01 | `<Manufacturer>Ecobee</Manufacturer>`<br>`<ModelId>EBSmartSi1</ModelId>` |
| Thermostat | Zen | Zen-01 | `<Manufacturer>mmbnetworks</Manufacturer>`<br>`<ModelId>zen-01</ModelId>` |
| Load Switch | Cooper | LCR-6600 | `<Manufacturer>cooper</Manufacturer>`<br>`<ModelId>lcr6200</ModelId>` |
| Load Switch | SafePlug | 1313 | `<Manufacturer>SafePlug</Manufacturer>`<br>`<ModelId>1313</ModelId>` |
| Load Switch | Energate | LC2200 | `<Manufacturer>energate</Manufacturer>`<br>`<ModelId>lc2200</ModelId>` |
| Smart Plug | SafePlug | 1202 | `<Manufacturer>SafePlug</Manufacturer>`<br>`<ModelId>1202</ModelId>` |
| Smart Plug | Energate | PLM6193 | `<Manufacturer>energate</Manufacturer>`<br>`<ModelId>plm6193</ModelId>` |
| H/W Switch | Emerson | 75A01 | `<Manufacturer>Rainforest Automation</Manufacturer>`<br>`<ModelId>Z140E</ModelId>` |
| CT Meter | Neurio | PowerBlaster | `<Manufacturer>Neurio</Manufacturer>`<br>`<ModelId>PB1</ModelId>` |
| Inverter | SolarEdge | SE1000-CCG | `<Manufacturer>SolarEdge</Manufacturer>`<br>`<ModelId>SE1000-CCG</ModelId>` |

# Home Assistant Router Device Trackers

A collection of router-based device tracking implementations for Home Assistant.

The purpose is to detect the presence of wireless devices connected to a router
and expose their presence as Home Assistant binary sensors.

## Implementations

- **MikroTik** – RouterOS script for detecting connected wireless devices.
- **OpenWrt** – Device tracking implementation for OpenWrt routers.
- **webhook4mqtt** – Lightweight HTTP POST to MQTT bridge.

## MQTT messages

Each detected zone is represented by a Home Assistant binary sensor with two
MQTT topics:

**State**

```text
my/binary_sensor/presence_{device}/state
```

Payload: `ON` or `OFF`, indicating whether devices are present in the zone.

**Attributes**

```text
my/binary_sensor/presence_{device}/attributes
```

Payload:

```json
{
  "macs": "",
  "names": "",
  "zone": "home",
  "source_type": "router"
}
```

The attributes provide additional information about the detected devices and
their zone:

 - macs – MAC comma-separated MAC addresses of the devices.
 - names – DHCP client names reported by the devices, when available.
 - zone – Home Assistant zone associated with the sensor.
 - source_type – Identifies the data source (router).

### General (Guest) Occupancy Detection

`presence_guest` is a sensor name used for devices with unknown / unassigned MAC
addresses. It reports ON when at least one such device is detected and OFF when
none are present. These devices are neither individually tracked nor explicitly
excluded; they are simply grouped under guest presence.

## Configuration

The list of known devices and other settings, such as webhook and MQTT broker
addresses, are configured by editing the scripts directly.
`webhook4mqtt` uses environment variables for its configuration.

While individual implementations differ slightly, they produce the same
result. Configuration methods vary between implementations and deserve
particular attention.

## Webhook4MQTT

My personal MikroTik router has limited storage, so installing its MQTT
subsystem is not practical.

Instead, the router sends HTTP POST requests to `webhook4mqtt`, which converts
these requests into MQTT messages and forwards them to the MQTT broker.

This keeps the router-side implementation lightweight while allowing Home
Assistant to receive device presence updates over MQTT.

## Requirements

The MikroTik implementation should work out of the box using the built-in
RouterOS functionality. The OpenWrt implementation requires `ubus` and
`mosquitto-client`.

## Purpose

The implementations share the same general goal and MQTT sensor format, while
using different router platforms as their data source. This makes it possible
to detect wireless device presence without installing tracking applications on
individual devices.

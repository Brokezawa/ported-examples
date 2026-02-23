# Classio Battery Connection Watchface

A Pebble watchface ported from the official Pebble SDK examples to demonstrate Nebble's high-level API.

## Original Example

**Source:** https://github.com/pebble-examples/classio-battery-connection

This watchface displays:
- Current time (HH:MM:SS format, updates every second)
- Bluetooth connection status (connected/disconnected)
- Battery level with charging indicator

## Nebble Highlights

### Declarative DSL

The watchface is defined using Nebble's `nebbleWatchface` DSL:

```nim
nebbleWatchface:
  window:
    backgroundColor = GColorBlack
  
  textLayer:
    id = timeLayer
    frame = (0, 40, 144, 34)
    text = "00:00:00"
    font = FONT_KEY_GOTHIC_28_BOLD
    color = GColorWhite
    alignment = GTextAlignmentCenter
  # ... more layers
```

### High-Level System Services

Battery and Bluetooth state are accessed through clean APIs:

```nim
# Get current state
let batteryState = battery.state()
let isConnected = connection.isConnected()

# Subscribe to changes
battery.subscribe(updateBattery)
connection.subscribe(updateConnection)
```

### Zero-Heap Text with FixedString

All text formatting uses `FixedString` for zero heap allocations:

```nim
var batteryBuffer: FixedString[32]

proc updateBattery(state: BatteryChargeState) {.cdecl.} =
  batteryBuffer.clear()
  if state.is_charging.bool:
    batteryBuffer.add("charging")
  else:
    batteryBuffer.addInt(state.charge_percent.int32)
    batteryBuffer.add("% charged")
  batteryLayer.text = batteryBuffer.cstr
```

## Comparison: C vs Nim

| Aspect | C (Original) | Nim (Nebble) |
|--------|-------------|--------------|
| Lines of Code | ~103 | ~95 |
| Manual Memory Management | Yes (create/destroy) | No (ARC handles it) |
| Service Subscriptions | Manual callback setup | High-level API |
| Text Formatting | snprintf | FixedString.add/addInt |
| Layer Management | Manual add_child | Declarative DSL |

## Building

```bash
nebble build --platform basalt
nebble install --emulator basalt
```

## License

MIT License (same as original Pebble example)

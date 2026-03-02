## classio_battery_connection
## Pebble watchface ported to Nebble (Nim)
##
## Original: https://github.com/pebble-examples/classio-battery-connection
##
## This watchface displays:
## - Current time (updating every second)
## - Bluetooth connection status
## - Battery level and charging state
##
## Demonstrates:
## - System event handling (battery, bluetooth)
## - TextLayer management
## - FixedString for heap-free text formatting
## - Declarative DSL with nebbleWatchface

import nebble
import nebble/util/fixed_strings
import nebble/foundation/events/battery
import nebble/foundation/events/connection

# Text buffers using FixedString for zero heap allocations
var
  timeBuffer: FixedString[16]     # "00:00:00"
  batteryBuffer: FixedString[32]  # "100% charged" or "charging"
  connectionBuffer: FixedString[32] # "connected" or "disconnected"

# Forward declarations
proc updateTime(tickTime: ptr tm; unitsChanged: TimeUnits) {.cdecl.}
proc updateBattery(state: BatteryChargeState) {.cdecl.}
proc updateConnection(connected: bool) {.cdecl.}

# Scaling helpers for different screen sizes
const
  BaseHeight = 168
  ScaleY = platform.PBLDisplayHeight.float / BaseHeight.float
  
  # Additional offset for high-res rect displays to center content vertically
  HighResOffsetY = platform.pblIfHighResRectElse(20, 0)

proc sY(y: int): int16 {.inline.} = int16((y.float * ScaleY) + HighResOffsetY)

# Declarative Watchface Definition
nebbleWatchface:
  
  window:
    backgroundColor = GColorBlack
  
  # Time display - large and centered
  textLayer:
    id = timeLayer
    fullWidth = true
    y = sY(40)
    h = if platform.isHighRes: 50 else: 34
    text = "00:00:00"
    font = if platform.isHighRes: FONT_KEY_BITHAM_42_BOLD else: FONT_KEY_GOTHIC_28_BOLD
    color = GColorWhite
    alignment = GTextAlignmentCenter
    backgroundColor = GColorClear
  
  # Bluetooth connection status
  textLayer:
    id = connectionLayer
    fullWidth = true
    y = sY(100)
    h = if platform.isHighRes: 30 else: 24
    text = ""
    font = if platform.isHighRes: FONT_KEY_GOTHIC_24 else: FONT_KEY_GOTHIC_18
    color = GColorWhite
    alignment = GTextAlignmentCenter
    backgroundColor = GColorClear
  
  # Battery level status
  textLayer:
    id = batteryLayer
    fullWidth = true
    y = sY(135)
    h = if platform.isHighRes: 30 else: 24
    text = ""
    font = if platform.isHighRes: FONT_KEY_GOTHIC_24 else: FONT_KEY_GOTHIC_18
    color = GColorWhite
    alignment = GTextAlignmentCenter
    backgroundColor = GColorClear
  
  # Update time every second
  tickTimer:
    unit = TimeUnits.SECOND_UNIT
    handler = updateTime

  init:
    # Initialize display values after layers are created using high-level APIs
    updateBattery(battery.state())
    updateConnection(connection.isConnected())
    
    # Subscribe to battery state changes using high-level API
    battery.subscribe(updateBattery)

    # Subscribe to bluetooth connection changes using high-level API
    connection.subscribe(updateConnection)

# Event Handlers

proc updateTime(tickTime: ptr tm; unitsChanged: TimeUnits) {.cdecl.} =
  ## Update the time display every second using high-level FixedString API
  discard timeBuffer.formatTime("%T", tickTime)
  if timeLayer.isValid:
    timeLayer.text = timeBuffer.cstr

proc updateBattery(state: BatteryChargeState) {.cdecl.} =
  ## Update battery display when charge state changes
  batteryBuffer.clear()
  if state.is_charging.bool:
    batteryBuffer.add("charging")
  else:
    batteryBuffer.addInt(state.charge_percent.int32)
    batteryBuffer.add("% charged")
  
  if batteryLayer.isValid:
    batteryLayer.text = batteryBuffer.cstr

proc updateConnection(connected: bool) {.cdecl.} =
  ## Update connection status when Bluetooth state changes
  connectionBuffer.clear()
  connectionBuffer.add(if connected: "connected" else: "disconnected")
  
  if connectionLayer.isValid:
    connectionLayer.text = connectionBuffer.cstr

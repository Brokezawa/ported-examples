## simple_analog
## Pebble watchface ported to Nebble (Nim)
##
## Original: https://github.com/pebble-examples/simple-analog
##
## Demonstrates:
## - Custom drawing with update procs
## - GPath for clock hands and tick marks
## - Layer hierarchy
## - Math/Trigonometry for clock hands
## - Responsive layout for all platforms (including Emery)

import nebble
import nebble/ffi
import nebble/graphics/gpath
import nebble/util/fixed_strings
import nebble/foundation/logging
import std/math

# === Scaling Helpers ===

const
  BaseWidth = 144
  BaseHeight = 168
  
  # PBLDisplayWidth/Height are defined in platform.nim
  # We scale for Emery but keep 1:1 for Round (using centering offsets instead)
  ScaleX = if platform.isRound: 1.0 else: platform.PBLDisplayWidth.float / BaseWidth.float
  ScaleY = if platform.isRound: 1.0 else: platform.PBLDisplayHeight.float / BaseHeight.float

proc sX(x: int): int16 {.inline.} = int16(x.float * ScaleX)
proc sY(y: int): int16 {.inline.} = int16(y.float * ScaleY)
proc sPt(x, y: int): GPoint {.inline.} = GPoint(x: sX(x), y: sY(y))

# === GPath Data ===

const NUM_CLOCK_TICKS = 11

var
  # Hands points scaled for the current display
  # Original: { -8, 20 }, { 8, 20 }, { 0, -80 }
  MINUTE_HAND_POINTS_VAR = [
    sPt(-8, 20),
    sPt(8, 20),
    sPt(0, -80)
  ]

  # Original: {-6, 20}, {6, 20}, {0, -60}
  HOUR_HAND_POINTS_VAR = [
    sPt(-6, 20),
    sPt(6, 20),
    sPt(0, -60)
  ]

  # Background tick points - scaled for all platforms
  BG_POINTS_DATA: array[NUM_CLOCK_TICKS, array[4, GPoint]] = [
    [sPt(68, 0), sPt(71, 0), sPt(71, 12), sPt(68, 12)],
    [sPt(72, 0), sPt(75, 0), sPt(75, 12), sPt(72, 12)],
    [sPt(112, 10), sPt(114, 12), sPt(108, 23), sPt(106, 21)],
    [sPt(132, 47), sPt(144, 40), sPt(144, 44), sPt(135, 49)],
    [sPt(135, 118), sPt(144, 123), sPt(144, 126), sPt(132, 120)],
    [sPt(108, 144), sPt(114, 154), sPt(112, 157), sPt(106, 147)],
    [sPt(70, 155), sPt(73, 155), sPt(73, 167), sPt(70, 167)],
    [sPt(32, 10), sPt(30, 12), sPt(36, 23), sPt(38, 21)],
    [sPt(12, 47), sPt(-1, 40), sPt(-1, 44), sPt(9, 49)],
    [sPt(9, 118), sPt(-1, 123), sPt(-1, 126), sPt(12, 120)],
    [sPt(36, 144), sPt(30, 154), sPt(32, 157), sPt(38, 147)]
  ]

# === App State ===

var
  s_tick_paths: array[NUM_CLOCK_TICKS, GPathHandle]
  s_minute_arrow: GPathHandle
  s_hour_arrow: GPathHandle
  
  numBuffer: FixedString[4]
  dayBuffer: FixedString[6]

# === Forward Declarations ===

proc bgUpdateProc(layer: ptr Layer, ctx: ptr GContext) {.cdecl.}
proc handsUpdateProc(layer: ptr Layer, ctx: ptr GContext) {.cdecl.}
proc dateUpdateProc(layer: ptr Layer, ctx: ptr GContext) {.cdecl.}
proc handleTick(tickTime: ptr tm, unitsChanged: TimeUnits) {.cdecl.}
proc initGPaths()

# === Watchface Definition ===

nebbleWatchface:
  window:
    backgroundColor = GColorBlack
    
  layer:
    id = bgLayer
    fullWidth = true
    fullHeight = true
    onUpdate = bgUpdateProc
    
  layer:
    id = dateLayer
    fullWidth = true
    fullHeight = true
    onUpdate = dateUpdateProc
    
  textLayer:
    id = dayLabel
    parent = dateLayer
    # Use relative positioning for labels
    x = pblIfRoundElse(63, sX(46))
    y = sY(114)
    w = sX(27)
    h = sY(20)
    text = ""
    font = FONT_KEY_GOTHIC_18
    color = GColorWhite
    backgroundColor = GColorBlack
    
  textLayer:
    id = numLabel
    parent = dateLayer
    x = pblIfRoundElse(90, sX(73))
    y = sY(114)
    w = sX(18)
    h = sY(20)
    text = ""
    font = FONT_KEY_GOTHIC_18_BOLD
    color = GColorWhite
    backgroundColor = GColorBlack
    
  layer:
    id = handsLayer
    fullWidth = true
    fullHeight = true
    onUpdate = handsUpdateProc
    
  tickTimer:
    unit = TimeUnits.SECOND_UNIT
    handler = handleTick

  init:
    initGPaths()
    logInfo("Simple Analog Initialized")

# === Implementation ===

proc bgUpdateProc(layer: ptr Layer, ctx: ptr GContext) {.cdecl.} =
  # Use high-level bounds property instead of ffi.layer_get_bounds
  let bounds = layer.bounds
  
  # Fill background
  ctx.fillColor = GColorBlack
  ctx.fillRect(bounds)
  
  # Draw ticks
  ctx.fillColor = GColorWhite
  for i in 0 ..< NUM_CLOCK_TICKS:
    # Adjust for round screen using responsive logic
    let offset = pblIfRoundElse(makeGPoint(18, 6), makeGPoint(0, 0))
    s_tick_paths[i].moveTo(offset)
    s_tick_paths[i].drawFilled(ctx)

proc handsUpdateProc(layer: ptr Layer, ctx: ptr GContext) {.cdecl.} =
  # Use high-level bounds property instead of ffi.layer_get_bounds
  let bounds = layer.bounds
  let center = bounds.centerPoint()

  # Second hand length scaled for the platform
  let secondHandLength = pblIfRoundElse((bounds.size.w div 2) - 19, bounds.size.w div 2)

  # Get current time using FFI API
  var now = ffi.time(nil)
  let t = ffi.localtime(addr now)

  # 1. Draw Second Hand
  let secondAngle = constants.TRIG_MAX_ANGLE.int32 * t.tm_sec div 60
  let secondHand = makeGPoint(
    (sin_lookup(secondAngle).int32 * secondHandLength.int32 div ffi.TRIG_MAX_RATIO.int32).int16 + center.x,
    (-cos_lookup(secondAngle).int32 * secondHandLength.int32 div ffi.TRIG_MAX_RATIO.int32).int16 + center.y
  )

  ctx.strokeColor = GColorWhite
  ctx.drawLine(center, secondHand)

  # 2. Draw Minute/Hour hands using high-level GPath API
  ctx.fillColor = GColorWhite
  ctx.strokeColor = GColorBlack

  # Minute hand
  s_minute_arrow.rotateTo(constants.TRIG_MAX_ANGLE.int32 * t.tm_min div 60)
  s_minute_arrow.drawFilled(ctx)
  s_minute_arrow.drawOutline(ctx)

  # Hour hand
  let hourAngle = (constants.TRIG_MAX_ANGLE.int32 * (((t.tm_hour mod 12) * 6) + (t.tm_min div 10))) div (12 * 6)
  s_hour_arrow.rotateTo(hourAngle)
  s_hour_arrow.drawFilled(ctx)
  s_hour_arrow.drawOutline(ctx)
  
  # 3. Draw Center Dot
  ctx.fillColor = GColorBlack
  ctx.fillRect(makeGRect(center.x - 1, center.y - 1, 3, 3))

proc dateUpdateProc(layer: ptr Layer, ctx: ptr GContext) {.cdecl.} =
  # Get current time using FFI API
  var now = ffi.time(nil)
  let t = ffi.localtime(addr now)

  discard dayBuffer.formatTime("%a", t)
  if dayLabel.isValid:
    dayLabel.text = dayBuffer.cstr
  
  discard numBuffer.formatTime("%d", t)
  if numLabel.isValid:
    numLabel.text = numBuffer.cstr


proc handleTick(tickTime: ptr tm, unitsChanged: TimeUnits) {.cdecl.} =
  if pebbleWindow.isValid:
    # Mark window root layer dirty using FFI
    ffi.layer_mark_dirty(pebbleWindow.rootLayer())

proc initGPaths() =
  # Use high-level rootLayer bounds property
  let center = pebbleWindow.rootLayer().bounds.centerPoint()
  
  # Initialize handles with global persistent points using high-level GPath API
  s_minute_arrow = newGPath(MINUTE_HAND_POINTS_VAR)
  s_hour_arrow = newGPath(HOUR_HAND_POINTS_VAR)
  
  s_minute_arrow.moveTo(center)
  s_hour_arrow.moveTo(center)
  
  for i in 0 ..< NUM_CLOCK_TICKS:
    s_tick_paths[i] = newGPath(BG_POINTS_DATA[i])

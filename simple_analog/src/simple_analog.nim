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
import nebble/graphics/gpath
import nebble/util/fixed_strings

# === Scaling Helpers ===

const
  BaseWidth = 144
  BaseHeight = 168
  
  # PBLDisplayWidth/Height are defined in platform.nim
  # Scale relative to design base (144x168) for all platforms
  # Chalk is 180x180, so we need to scale by 180/144 for X and 180/168 for Y
  ScaleX = when platform.isGabbro: 260.0 / float(BaseWidth)
           elif platform.isRound: 180.0 / float(BaseWidth)  # Chalk
           else: float(platform.PBLDisplayWidth) / float(BaseWidth)

  ScaleY = when platform.isGabbro: 260.0 / float(BaseHeight)
           elif platform.isRound: 180.0 / float(BaseHeight)  # Chalk
           else: float(platform.PBLDisplayHeight) / float(BaseHeight)

  # Center X position for labels on high-res displays
  LabelCenterX = int(platform.PBLDisplayWidth div 2)

proc sX(x: int): int16 {.inline.} = int16(float(x) * ScaleX)
proc sY(y: int): int16 {.inline.} = int16(float(y) * ScaleY)
proc sPt(x, y: int): GPoint {.inline.} = GPoint(x: sX(x), y: sY(y))

const NUM_CLOCK_TICKS = 11

# === GPath Data ===

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

## Background tick geometry — translated from the original C example and
## scaled with `sPt` so it adapts to high-res platforms.
var BG_POINTS_DATA: array[NUM_CLOCK_TICKS, array[4, GPoint]] = [
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
  s_minute_arrow: GPathHandle
  s_hour_arrow: GPathHandle
  s_tick_paths: array[NUM_CLOCK_TICKS, GPathHandle]

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
    # Use relative positioning for labels - center on high-res displays
    x = if platform.isHighRes: LabelCenterX - 30 else: pblIfRoundElse(63, sX(46))
    y = sY(114)
    w = if platform.isHighRes: 40 else: sX(27)
    h = sY(20)
    text = ""
    font = FONT_KEY_GOTHIC_18
    color = GColorWhite
    backgroundColor = GColorBlack
    
  textLayer:
    id = numLabel
    parent = dateLayer
    x = if platform.isHighRes: LabelCenterX + 10 else: pblIfRoundElse(90, sX(73))
    y = sY(114)
    w = if platform.isHighRes: 30 else: sX(18)
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

# === Implementation ===

proc bgUpdateProc(layer: ptr Layer, ctx: ptr GContext) {.cdecl.} =
  # Use high-level bounds property instead of ffi.layer_get_bounds
  let bounds = layer.bounds

  # Fill background
  ctx.fillColor = GColorBlack
  ctx.fillRect(bounds)

  # Draw tick marks using GPath (matching original C example)
  # Each tick is a small filled rectangle positioned around the clock face
  ctx.fillColor = GColorWhite
  for i in 0 ..< NUM_CLOCK_TICKS:
    s_tick_paths[i].drawFilled(ctx)

proc handsUpdateProc(layer: ptr Layer, ctx: ptr GContext) {.cdecl.} =
  # Use high-level bounds property instead of ffi.layer_get_bounds
  let bounds = layer.bounds
  let center = bounds.centerPoint()

  # Second hand length - use full half of display minus padding
  let secondHandLength = platform.pblIfRoundOrHighResElse(
    (bounds.size.w div 2) - 19,   # Round
    (bounds.size.w div 2) - 10,   # High-res rect
    (bounds.size.w div 2) - 10    # Normal rect
  )

  # Get current time using high-level API
  let t = getLocalTime()

  # 1. Draw Second Hand
  let secondAngle = constants.TRIG_MAX_ANGLE.int32 * t.tm_sec div 60
  let secondHand = makeGPoint(
    (sin_lookup(secondAngle).int32 * secondHandLength.int32 div TRIG_MAX_RATIO.int32).int16 + center.x,
    (-cos_lookup(secondAngle).int32 * secondHandLength.int32 div TRIG_MAX_RATIO.int32).int16 + center.y
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
  # Get current time using high-level API
  let t = getLocalTime()

  discard dayBuffer.formatTime("%a", t)
  if dayLabel.isValid:
    dayLabel.text = dayBuffer.cstr
  
  discard numBuffer.formatTime("%d", t)
  if numLabel.isValid:
    numLabel.text = numBuffer.cstr


proc handleTick(tickTime: ptr tm, unitsChanged: TimeUnits) {.cdecl.} =
  if pebbleWindow.isValid:
    # Mark window root layer dirty using high-level API
    pebbleWindow.rootLayer().markDirty()

proc initGPaths() =
  # Use high-level rootLayer bounds property
  let center = pebbleWindow.rootLayer().bounds.centerPoint()

  # Initialize handles with global persistent points using high-level GPath API
  s_minute_arrow = newGPath(MINUTE_HAND_POINTS_VAR)
  s_hour_arrow = newGPath(HOUR_HAND_POINTS_VAR)

  s_minute_arrow.moveTo(center)
  s_hour_arrow.moveTo(center)

  # Initialize tick mark GPaths - each tick is a 4-point filled rectangle
  for i in 0 ..< NUM_CLOCK_TICKS:
    s_tick_paths[i] = newGPath(BG_POINTS_DATA[i])

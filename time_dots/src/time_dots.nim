## time_dots
## Pebble watchface ported to Nebble (Nim)
##
## Original: https://github.com/pebble-examples/time-dots
##
## A unique watchface showing time as radial graphics:
## - Minutes: Expanding arc that fills the circle
## - Hours: Dots around the inner ring (12 dots = 12 hours)
##
## Demonstrates:
## - Custom layer drawing with radial graphics
## - Platform-adaptive colors (color vs B&W)
## - Round display support
## - Trigonometry for positioning

import nebble
import nebble/graphics/graphics
import nebble/ui/layer
import nebble/util/math
import std/math

# === Constants ===

const
  # Geometry constants
  HoursRadius = 3
  Inset = when platform.isRound: 5 else: 3
  ArcThickness = 20

# === App State ===

var
  s_hours: int = 0
  s_minutes: int = 0

# === Color Helpers ===

proc getMinutesColor(): GColor {.inline.} =
  ## Platform-adaptive color for minutes arc
  when defined(pebbleBasalt) or defined(pebbleChalk) or defined(pebbleEmery) or defined(pebbleGabbro):
    GColorBlueMoon
  else:
    GColorBlack

proc getHoursColorInactive(): GColor {.inline.} =
  ## Platform-adaptive color for inactive hour dots
  when defined(pebbleBasalt) or defined(pebbleChalk) or defined(pebbleEmery) or defined(pebbleGabbro):
    GColorBlack
  else:
    GColorDarkGray

proc getBgColor(): GColor {.inline.} =
  ## Platform-adaptive background color
  when defined(pebbleBasalt) or defined(pebbleChalk) or defined(pebbleEmery) or defined(pebbleGabbro):
    GColorDukeBlue
  else:
    GColorWhite

# === Forward Declarations ===

proc canvasUpdateProc(layer: ptr Layer, ctx: ptr GContext) {.cdecl.}
proc tickHandler(tickTime: ptr tm, unitsChanged: TimeUnits) {.cdecl.}

# === Watchface Definition ===

nebbleWatchface:
  window:
    backgroundColor = getBgColor()
  
  # Canvas layer for custom drawing
  layer:
    id = canvasLayer
    fullWidth = true
    fullHeight = true
    onUpdate = canvasUpdateProc
  
  tickTimer:
    unit = TimeUnits.MINUTE_UNIT
    handler = tickHandler
  
  deinit:
    discard

# === Implementation ===

proc getAngleForHour(hour: int): int32 {.inline.} =
  ## Progress through 12 hours, out of 360 degrees
  int32((hour * 360) div 12)

proc getAngleForMinute(minute: int): int32 {.inline.} =
  ## Progress through 60 minutes, out of 360 degrees  
  int32((minute * 360) div 60)

proc canvasUpdateProc(layer: ptr Layer, ctx: ptr GContext) {.cdecl.} =
  ## Custom drawing for the time dots watchface
  let bounds = layer.bounds
  
  # 12 hours only (wrap around)
  let displayHours = if s_hours > 12: s_hours - 12 else: s_hours
  
  # Minutes: Expanding radial arc
  let minuteAngle = getAngleForMinute(s_minutes)
  var frame = inset(bounds, GEdgeInsets(top: Inset * 4, left: Inset * 4, bottom: Inset * 4, right: Inset * 4))
  
  ctx.fillColor = getMinutesColor()
  ctx.fillRadial(frame, GOvalScaleModeFitCircle, ArcThickness, 0, degToTrigAngle(minuteAngle.float32))
  
  # Adjust frame for inner ring (hours)
  frame = inset(frame, GEdgeInsets(top: HoursRadius * 3, left: HoursRadius * 3, bottom: HoursRadius * 3, right: HoursRadius * 3))
  
  # Hours: Dots around the circle
  for i in 0 ..< 12:
    let hourAngle = getAngleForHour(i)
    let pos = fromPolar(frame, GOvalScaleModeFitCircle, degToTrigAngle(hourAngle.float32))
    
    # Active hour dots are white, inactive are darker
    ctx.fillColor = if i <= displayHours: GColorWhite else: getHoursColorInactive()
    ctx.fillCircle(pos, HoursRadius)

proc tickHandler(tickTime: ptr tm, unitsChanged: TimeUnits) {.cdecl.} =
  ## Update time display on each minute tick
  s_hours = tickTime.tm_hour
  s_minutes = tickTime.tm_min
  
  # Mark canvas layer dirty to trigger redraw using high-level API
  if canvasLayer.isValid:
    canvasLayer.markDirty()

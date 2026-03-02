## ks_clock_face
## Pebble watchface ported to Nebble (Nim)
##
## Original: https://github.com/pebble-examples/ks-clock-face
##
## Demonstrates:
## - Custom animations via AnimationImplementation
## - UnobstructedArea service (Quick View)
## - GContext drawing (circles, lines)
## - Responsive layout constants

import nebble
import nebble/constants
import nebble/ui/unobstructed_area

const
  ANTIALIASING = true
  HAND_MARGIN = 10
  ANIMATION_DURATION = 500
  ANIMATION_DELAY = 600

# Standard C functions often used in Pebble but sometimes not wrapped by Futhark
proc rand(): cint {.importc, cdecl.}
proc srand(seed: cuint) {.importc, cdecl.}

# Platform-dependent colors
template getColors(): bool =
  pblIfColorElse(true, false)

type
  TimeObj = object
    hours: uint8
    minutes: uint8

# === App State ===

var
  s_canvas_layer: LayerHandle
  s_center: GPoint
  s_last_time, s_anim_time: TimeObj
  s_radius: uint8 = 0
  s_radius_final: uint8
  s_color_channels: array[3, uint8]
  s_animating: bool = false

# === Helper Procs ===

proc gColorFromRGB(r, g, b: uint8): GColor {.inline.} =
  ## Map 0-255 RGB to Pebble 8-bit color (0b11RRGGBB)
  let rr = (r shr 6) and 0b11
  let gg = (g shr 6) and 0b11
  let bb = (b shr 6) and 0b11
  makeGColor8(0b11000000'u8 or (rr shl 4) or (gg shl 2) or bb)

proc animPercentage(dist_normalized: AnimationProgress, maxVal: int): int {.inline.} =
  (dist_normalized.int * maxVal div ANIMATION_NORMALIZED_MAX.int)

proc hoursToMinutes(hours_out_of_12: int): int {.inline.} =
  (hours_out_of_12 * 60 div 12)

# === Forward Declarations ===

proc updateProc(layer: ptr Layer, ctx: ptr GContext) {.cdecl.}
proc tickHandler(tickTime: ptr tm, changed: TimeUnits) {.cdecl.}
proc animationStarted(anim: ptr Animation, context: pointer) {.cdecl.}
proc animationStopped(anim: ptr Animation, stopped: bool, context: pointer) {.cdecl.}
proc radiusUpdate(anim: ptr Animation, dist_normalized: AnimationProgress) {.cdecl.}
proc handsUpdate(anim: ptr Animation, dist_normalized: AnimationProgress) {.cdecl.}
proc startAnimation()
proc unobstructedWillChange(final_area: GRect, context: pointer) {.cdecl.}
proc unobstructedDidChange(context: pointer) {.cdecl.}

# === Animation Logic ===

var 
  s_radius_impl = AnimationImplementation(update: radiusUpdate)
  s_hands_impl = AnimationImplementation(update: handsUpdate)

proc animate(duration, delay: int, implementation: ptr AnimationImplementation, handlers: bool) =
  # Use high-level AnimationHandle API
  var anim = newAnimationHandle()
  anim.duration = duration.uint32
  anim.delay = delay.uint32
  anim.setCurve(constants.AnimationCurveEaseInOut)
  
  anim.setImplementation(implementation)
  
  if handlers:
    anim.setHandlers(onStarted = animationStarted, onStopped = animationStopped)
  
  anim.schedule()
  anim.forget() # Let system manage the lifetime

# === Event Handlers ===

proc updateProc(layer: ptr Layer, ctx: ptr GContext) {.cdecl.} =
  # Use high-level bounds property
  let full_bounds = layer.bounds
  
  # Cross-platform unobstructed bounds using FFI function if available
  let bounds = when declared(getUnobstructedBounds):
                 getUnobstructedBounds(layer)
               else:
                 full_bounds
                  
  s_center = bounds.centerPoint()

  # Background
  if getColors():
    ctx.fillColor = gColorFromRGB(s_color_channels[0], s_color_channels[1], s_color_channels[2])
  else:
    ctx.fillColor = GColorDarkGray
  ctx.fillRect(full_bounds)

  ctx.strokeColor = GColorBlack
  ctx.strokeWidth = 4
  ctx.antialiased = ANTIALIASING

  # White clockface
  ctx.fillColor = GColorWhite
  ctx.fillCircle(s_center, s_radius.uint16)
  ctx.drawCircle(s_center, s_radius.uint16)

  # Hands
  let mode_time = if s_animating: s_anim_time else: s_last_time

  let minute_angle = constants.TRIG_MAX_ANGLE.int32 * mode_time.minutes.int32 div 60
  var hour_angle: int32
  if s_animating:
    hour_angle = constants.TRIG_MAX_ANGLE.int32 * mode_time.hours.int32 div 60
  else:
    hour_angle = constants.TRIG_MAX_ANGLE.int32 * mode_time.hours.int32 div 12

  hour_angle += (minute_angle * (constants.TRIG_MAX_ANGLE.int32 div 12)) div constants.TRIG_MAX_ANGLE.int32

  let minute_hand = makeGPoint(
    (sin_lookup(minute_angle).int32 * (s_radius.int32 - HAND_MARGIN) div TRIG_MAX_RATIO.int32).int16 + s_center.x,
    (-cos_lookup(minute_angle).int32 * (s_radius.int32 - HAND_MARGIN) div TRIG_MAX_RATIO.int32).int16 + s_center.y
  )
  let hour_hand = makeGPoint(
    (sin_lookup(hour_angle).int32 * (s_radius.int32 - (2 * HAND_MARGIN)) div TRIG_MAX_RATIO.int32).int16 + s_center.x,
    (-cos_lookup(hour_angle).int32 * (s_radius.int32 - (2 * HAND_MARGIN)) div TRIG_MAX_RATIO.int32).int16 + s_center.y
  )

  if s_radius > 2 * HAND_MARGIN:
    ctx.drawLine(s_center, hour_hand)
  if s_radius > HAND_MARGIN:
    ctx.drawLine(s_center, minute_hand)

proc tickHandler(tickTime: ptr tm, changed: TimeUnits) {.cdecl.} =
  s_last_time.hours = tickTime.tm_hour.uint8
  if s_last_time.hours > 12: s_last_time.hours -= 12
  s_last_time.minutes = tickTime.tm_min.uint8

  # Random colors
  for i in 0 .. 2:
    s_color_channels[i] = (rand() mod 256).uint8

  if s_canvas_layer.isValid:
    s_canvas_layer.markDirty()

proc animationStarted(anim: ptr Animation, context: pointer) {.cdecl.} =
  s_animating = true

proc animationStopped(anim: ptr Animation, stopped: bool, context: pointer) {.cdecl.} =
  s_animating = false

proc radiusUpdate(anim: ptr Animation, dist_normalized: AnimationProgress) {.cdecl.} =
  s_radius = animPercentage(dist_normalized, s_radius_final.int).uint8
  s_canvas_layer.markDirty()

proc handsUpdate(anim: ptr Animation, dist_normalized: AnimationProgress) {.cdecl.} =
  s_anim_time.hours = animPercentage(dist_normalized, hoursToMinutes(s_last_time.hours.int)).uint8
  s_anim_time.minutes = animPercentage(dist_normalized, s_last_time.minutes.int).uint8
  s_canvas_layer.markDirty()

proc startAnimation() =
  animate(ANIMATION_DURATION, ANIMATION_DELAY, addr s_radius_impl, false)
  animate(2 * ANIMATION_DURATION, ANIMATION_DELAY, addr s_hands_impl, true)

proc unobstructedWillChange(final_area: GRect, context: pointer) {.cdecl.} =
  if s_animating: return
  s_radius = 0
  # Reset hours for animation
  s_anim_time.hours = 0

proc unobstructedDidChange(context: pointer) {.cdecl.} =
  if s_animating: return
  startAnimation()

# === Watchface Definition ===

nebbleWatchface:
  window:
    backgroundColor = GColorBlack
    
  layer:
    id = canvasLayer
    fullWidth = true
    fullHeight = true
    onUpdate = updateProc
    
  tickTimer:
    unit = TimeUnits.MINUTE_UNIT
    handler = tickHandler

  init:
    s_canvas_layer = canvasLayer.toHandle() # Unowned reference for global state
    
    # Initialize time using high-level API
    let t = getLocalTime()
    tickHandler(t, TimeUnits.MINUTE_UNIT)
    
    # Setup radius using high-level bounds property
    let bounds = when declared(layer_get_unobstructed_bounds):
                   canvasLayer.unobstructedBounds
                 else:
                   canvasLayer.bounds
                   
    s_radius_final = ((bounds.size.w - 30) div 2).uint8
    
    startAnimation()
    
    # Subscribe to unobstructed area using high-level service API
    var s_unobstructed_handlers = UnobstructedAreaHandlers(
      will_change: unobstructedWillChange,
      did_change: unobstructedDidChange
    )
    when declared(unobstructed_area_service_subscribe):
      unobstructed_area_service_subscribe(s_unobstructed_handlers, nil)

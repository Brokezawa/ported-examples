## feature_accel_discs
## Pebble app ported to Nebble (Nim)
##
## Original: https://github.com/pebble-examples/feature-accel-discs
##
## A physics simulation demonstrating accelerometer input.
## Discs respond to device tilt and bounce off screen edges.
##
## Demonstrates:
## - Accelerometer service
## - Physics simulation (velocity, mass, collision)
## - Custom layer drawing
## - Round display support with reflection math

import nebble
import nebble/graphics/graphics
import nebble/foundation/timer
import nebble/foundation/events/accel
import std/math

# === Constants ===

const
  MathPi = 3.141592653589793238462
  NumDiscs = 20
  DiscDensity = 0.25
  AccelRatio = 0.05
  AccelStepMs = 50

# === Types ===

type
  Vec2d = object
    x: float
    y: float
  
  Disc = object
    pos: Vec2d
    vel: Vec2d
    mass: float
    radius: float
    color: GColor

# === App State ===

var
  s_discs: array[NumDiscs, Disc]
  s_windowFrame: GRect
  s_nextRadius: float = 3.0

# Forward declaration for timer callback
proc timerCallback(data: pointer) {.cdecl.}

# === Math Helpers ===

proc square(num: float): float {.inline.} = num * num

proc getSqrt(num: float): float =
  ## Babylonian method for square root
  var approx = num
  let tolerance = 0.001
  while square(approx) - num >= tolerance:
    approx = (approx + num / approx) / 2.0
  return approx

proc multiply(vec: Vec2d, scale: float): Vec2d {.inline.} =
  Vec2d(x: vec.x * scale, y: vec.y * scale)

proc add(a, b: Vec2d): Vec2d {.inline.} =
  Vec2d(x: a.x + b.x, y: a.y + b.y)

proc subtract(a, b: Vec2d): Vec2d {.inline.} =
  Vec2d(x: a.x - b.x, y: a.y - b.y)

proc getLength(vec: Vec2d): float {.inline.} =
  getSqrt(square(vec.x) + square(vec.y))

proc setLength(vec: Vec2d, newLength, oldLength: float): Vec2d {.inline.} =
  Vec2d(x: vec.x * newLength / oldLength, y: vec.y * newLength / oldLength)

proc dot(a, b: Vec2d): float {.inline.} =
  a.x * b.x + a.y * b.y

proc normalize(vec: Vec2d): Vec2d =
  let length = getLength(vec)
  if length != 0:
    Vec2d(x: vec.x / length, y: vec.y / length)
  else:
    vec

proc findReflectionVelocity(bounds: Vec2d, disc: Disc): Vec2d =
  ## Calculate reflection velocity when disc hits a boundary
  let normal = normalize(subtract(disc.pos, bounds))
  let perpendicular = multiply(normal, dot(disc.vel, normal))
  let parallel = subtract(disc.vel, perpendicular)
  let friction = 1.0
  let elasticity = 1.0
  subtract(multiply(parallel, friction), multiply(perpendicular, elasticity))

# === Disc Physics ===

proc calcMass(radius: float): float {.inline.} =
  MathPi * radius * radius * DiscDensity

proc initDisc(disc: var Disc) =
  ## Initialize a disc with properties based on index
  disc.pos = Vec2d(
    x: s_windowFrame.size.w.float / 2.0,
    y: s_windowFrame.size.h.float / 2.0
  )
  disc.vel = Vec2d(x: 0.0, y: 0.0)
  disc.radius = s_nextRadius
  disc.mass = calcMass(disc.radius)
  
  # Use a simple color based on index for color platforms
  when defined(pebbleBasalt) or defined(pebbleChalk) or defined(pebbleEmery) or defined(pebbleGabbro):
    let colorIndex = (s_nextRadius.int - 3) mod 10
    disc.color = case colorIndex:
      of 0: GColorRed
      of 1: GColorBlue
      of 2: GColorGreen
      of 3: GColorYellow
      of 4: GColorPurple
      of 5: GColorOrange
      of 6: GColorCyan
      of 7: GColorJazzberryJam
      of 8: GColorIslamicGreen
      else: GColorVividCerulean
  
  s_nextRadius += 0.5

proc applyForce(disc: var Disc, force: Vec2d) {.inline.} =
  disc.vel.x += force.x / disc.mass
  disc.vel.y += force.y / disc.mass

proc applyAccel(disc: var Disc, accel: AccelData) {.inline.} =
  applyForce(disc, Vec2d(
    x: accel.x.float * AccelRatio,
    y: -accel.y.float * AccelRatio
  ))

proc updateDisc(disc: var Disc) =
  ## Update disc position and handle collisions
  let e = if platform.isRound: 0.7 else: 0.5  # Restitution coefficient
  
  # Update position
  disc.pos.x += disc.vel.x
  disc.pos.y += disc.vel.y
  
  when platform.isRound:
    # Round screen collision detection
    let circleCenter = Vec2d(
      x: s_windowFrame.size.w.float / 2.0 - 1.0,
      y: s_windowFrame.size.h.float / 2.0 - 1.0
    )
    let distSquared = square(circleCenter.x - disc.pos.x) + square(circleCenter.y - disc.pos.y)
    let radiusSquared = square(circleCenter.x - disc.radius)
    
    if distSquared > radiusSquared:
      var norm = subtract(disc.pos, circleCenter)
      let normLength = getLength(norm)
      if normLength > (circleCenter.x - disc.radius):
        norm = setLength(norm, circleCenter.x - disc.radius, normLength)
        disc.pos = add(circleCenter, norm)
      disc.vel = multiply(findReflectionVelocity(circleCenter, disc), e)
  else:
    # Rectangular screen collision detection
    if (disc.pos.x - disc.radius < 0 and disc.vel.x < 0) or
       (disc.pos.x + disc.radius > s_windowFrame.size.w.float and disc.vel.x > 0):
      disc.vel.x = -disc.vel.x * e
    
    if (disc.pos.y - disc.radius < 0 and disc.vel.y < 0) or
       (disc.pos.y + disc.radius > s_windowFrame.size.h.float and disc.vel.y > 0):
      disc.vel.y = -disc.vel.y * e

proc drawDisc(ctx: ptr GContext, disc: Disc) {.inline.} =
  when defined(pebbleBasalt) or defined(pebbleChalk) or defined(pebbleEmery) or defined(pebbleGabbro):
    ctx.fillColor = disc.color
  else:
    ctx.fillColor = GColorWhite
  ctx.fillCircle(GPoint(x: disc.pos.x.int16, y: disc.pos.y.int16), disc.radius.uint16)

# === Drawing Callback ===

proc canvasUpdateProc(layer: ptr Layer, ctx: ptr GContext) {.cdecl.} =
  ## Draw all discs
  for i in 0 ..< NumDiscs:
    drawDisc(ctx, s_discs[i])

# === App Definition ===

nebbleApp:
  window:
    backgroundColor = GColorBlack
  
  # Canvas layer for drawing discs
  layer:
    id = canvasLayer
    fullWidth = true
    fullHeight = true
    onUpdate = canvasUpdateProc
  
  init:
    # Store window frame for physics calculations
    s_windowFrame = pebbleWindow.rootLayer().frame
    
    # Initialize all discs
    for i in 0 ..< NumDiscs:
      initDisc(s_discs[i])
    
    # Subscribe to accelerometer data service
    accel.subscribe(0, nil)
    
    # Start physics timer
    discard timer.register(AccelStepMs.uint32, timerCallback, nil)
  
  deinit:
    # Unsubscribe from accelerometer
    accel.unsubscribeData()

# === Timer Callback Implementation ===
# This is defined after nebbleApp so canvasLayer is available

proc timerCallback(data: pointer) {.cdecl.} =
  ## Update physics and schedule next frame
  let (accelData, _) = accel.peek()
  
  for i in 0 ..< NumDiscs:
    applyAccel(s_discs[i], accelData)
    updateDisc(s_discs[i])
  
  # Mark layer dirty to trigger redraw
  if canvasLayer.isValid:
    canvasLayer.markDirty()
  
  # Schedule next update
  discard timer.register(AccelStepMs.uint32, timerCallback, nil)

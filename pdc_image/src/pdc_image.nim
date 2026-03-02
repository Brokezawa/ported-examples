## pdc_image
## Pebble app ported to Nebble (Nim)
##
## Original: https://github.com/pebble-examples/pdc-image
##
## Demonstrates loading and displaying a PDC (Pebble Drawing Commands) image.
## PDC images are vector graphics that can be scaled and rendered at any size.
##
## Demonstrates:
## - GDrawCommandImage loading and rendering
## - Centering content on screen
## - Platform-adaptive colors

import nebble
import nebble/graphics/graphics
import nebble/graphics/draw_command_image
import gen/resources

# === App State ===

var
  s_commandImage: DrawCommandImageHandle

# === Drawing Callback ===

proc canvasUpdateProc(layer: ptr Layer, ctx: ptr GContext) {.cdecl.} =
  ## Draw the PDC image centered on the screen
  
  # Only draw if image was loaded successfully
  if s_commandImage.isValid:
    let imgSize = s_commandImage.getBoundsSize()
    let bounds = layer.bounds
    
    # Calculate centering insets
    let frameInsets = GEdgeInsets(
      top: (bounds.size.h - imgSize.h) div 2,
      left: (bounds.size.w - imgSize.w) div 2,
      bottom: 0,
      right: 0
    )
    
    let drawOrigin = inset(bounds, frameInsets).origin
    s_commandImage.draw(ctx, drawOrigin)

# === App Definition ===

nebbleApp:
  window:
    backgroundColor = when defined(pebbleBasalt) or defined(pebbleChalk) or defined(pebbleEmery) or defined(pebbleGabbro):
                        GColorJazzberryJam
                      else:
                        GColorWhite
  
  # Canvas layer for drawing the PDC image
  layer:
    id = canvasLayer
    fullWidth = true
    fullHeight = true
    onUpdate = canvasUpdateProc
  
  init:
    # Load the PDC image from resources
    s_commandImage = newDrawCommandImageHandle(RESOURCE_ID_DRAW_COMMAND)
    if not s_commandImage.isValid:
      # Image failed to load - this shouldn't happen with valid resources
      discard

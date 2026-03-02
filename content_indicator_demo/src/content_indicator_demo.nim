## content_indicator_demo
## Pebble app ported to Nebble (Nim)
##
## Original: https://github.com/pebble-examples/content-indicator-demo
##
## Demonstrates:
## - ScrollLayer with ContentIndicator
## - Managed handles with automatic cleanup
## - High-level API without FFI
## - Declarative DSL with nebbleApp

import nebble
import nebble/ui/content_indicator
import nebble/ui/scroll_layer

const content = """Cupcake

Donut

Eclair

Froyo

Gingerbread

Honeycomb

Ice Cream Sandwich

Jelly Bean

KitKat

Lollipop

Marshmallow

"""

# Config structs must be global (Pebble SDK requirement)
var upConfig, downConfig: ContentIndicatorConfig

nebbleApp:
  window:
    backgroundColor = GColorWhite

  scrollLayer:
    id = mainScrollLayer
    fullScreen = true

  textLayer:
    id = contentLayer
    parent = mainScrollLayer
    fullWidth = true
    h = 2000
    text = content
    alignment = GTextAlignmentCenter
    font = FONT_KEY_GOTHIC_18_BOLD

  layer:
    id = upIndicatorLayer
    x = 0
    y = 0
    w = platform.PBLDisplayWidth
    h = platform.StatusBarLayerHeight.int16

  layer:
    id = downIndicatorLayer
    x = 0
    y = platform.PBLDisplayHeight.int16 - platform.StatusBarLayerHeight.int16
    w = platform.PBLDisplayWidth
    h = platform.StatusBarLayerHeight.int16

  onLoad:
    # Setup scroll layer click config and hide shadow
    mainScrollLayer.setClickConfigOntoWindow(pebbleWindow)
    mainScrollLayer.setShadowHidden(true)

    # Calculate and set content size based on text
    let textSize = contentLayer.contentSize
    contentLayer.frame = makeGRect(0, 0, platform.PBLDisplayWidth, textSize.h)
    mainScrollLayer.contentSize = textSize

    # Configure content indicators using high-level API
    let indicator = mainScrollLayer.getContentIndicator()
    if indicator.isValid:
      discard indicator.configure(
        ContentIndicatorDirectionUp,
        upConfig,
        upIndicatorLayer.toPtr,
        foreground = GColorBlack,
        background = GColorWhite,
        alignment = GAlignCenter,
        timesOut = false
      )
      discard indicator.configure(
        ContentIndicatorDirectionDown,
        downConfig,
        downIndicatorLayer.toPtr,
        foreground = GColorBlack,
        background = GColorWhite,
        alignment = GAlignCenter,
        timesOut = false
      )
  deinit:
    discard

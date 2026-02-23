## feature_custom_font
## Pebble app ported to Nebble (Nim)
##
## Original: https://github.com/pebble-examples/feature-custom-font
##
## Demonstrates:
## - Loading custom fonts from resources
## - Using GFontRef for automatic font cleanup
## - Responsive text for round vs rectangular displays

import nebble
import nebble/graphics/font_ref
import nebble/foundation/logging
import gen/resources

var customFont: GFontRef

nebbleApp:
  window:
    backgroundColor = GColorWhite
  
  textLayer:
    id = textLayer
    fullWidth = true
    fullHeight = true
    text = pblIfRoundElse("Hello, World!", "  Hello,\n  World!")
    font = nil
    color = GColorBlack
    alignment = pblIfRoundElse(GTextAlignmentCenter, GTextAlignmentLeft)
    backgroundColor = GColorClear
  
  init:
    customFont = loadFontRef(RESOURCE_ID_FONT_OSP_DIN_44)
    if customFont.isValid:
      textLayer.font = customFont.font
    else:
      logError("Failed to load custom font")
    
    when defined(pebbleChalk) or defined(pebbleEmery):
      textLayer.enableScreenTextFlowAndPaging(8)
    
    logInfo("Custom Font Demo Initialized")

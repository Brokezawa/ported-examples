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
import gen/resources

var customFont: GFontRef

nebbleApp:
  window:
    backgroundColor = GColorWhite
  
  textLayer:
    id = textLayer
    x = 0
    y = 0
    w = platform.PBLDisplayWidth
    h = platform.PBLDisplayHeight
    text = if platform.isHighRes: "Hello,\nWorld!" else: pblIfRoundElse("Hello, World!", "  Hello,\n  World!")
    font = nil
    color = GColorBlack
    alignment = if platform.isHighRes or platform.isRound: GTextAlignmentCenter else: GTextAlignmentLeft
    backgroundColor = GColorClear
  
  init:
    customFont = loadFontRef(RESOURCE_ID_FONT_OSP_DIN_44)
    if customFont.isValid:
      textLayer.font = customFont.font
    
    when defined(pebbleChalk) or defined(pebbleEmery) or defined(pebbleGabbro):
      textLayer.enableScreenTextFlowAndPaging(8)

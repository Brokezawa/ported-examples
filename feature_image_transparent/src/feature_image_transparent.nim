## feature_image_transparent
## Pebble app ported to Nebble (Nim)
##
## Original: https://github.com/pebble-examples/feature-image-transparent
##
## Demonstrates:
## - Loading bitmap resources with GBitmapRef
## - BitmapLayer with compositing mode (GCompOpSet for transparency)
## - Layering bitmap over text content
## - Dynamic text filling based on screen size

import nebble
import nebble/graphics/bitmap_ref
import nebble/graphics/graphics
import nebble/ui/bitmap_layer
import nebble/ui/text_layer
import nebble/ui/layer
import gen/resources
import nebble/util/fixed_strings

var
  pandaBitmap: GBitmapRef
  bmpLayer: BitmapLayerHandle
  bgTextLayer: TextLayerHandle
  bgText: FixedString[1024]

const baseText = "pandamonium"

proc buildTextForScreen(height: int16): cstring =
  # Each line is ~14 pixels high with default font
  # Calculate how many characters needed to fill screen
  let lineCount = (height.int + 13) div 14
  let charsPerLine = 30  # approximate chars per line before wrap
  let totalChars = lineCount * charsPerLine

  bgText.clear()
  var baseIdx = 0
  while bgText.len < totalChars and bgText.len < bgText.data.len - 1:
    bgText.add(baseText[baseIdx])
    inc baseIdx
    if baseIdx >= baseText.len:
      baseIdx = 0

  # Return cstring pointer to internal buffer (FixedString must remain alive)
  bgText.cstr

nebbleApp:
  window:
    backgroundColor = GColorWhite
  
  onLoad:
    let windowLayer = pebbleWindow.rootLayer()
    let bounds = windowLayer.bounds
    
    # Use frame (not bounds) and reset origin to (0,0) to account for status bar
    var layerFrame = windowLayer.frame
    layerFrame.origin.x = 0
    layerFrame.origin.y = 0
    
    # Create text layer with full frame
    bgTextLayer = newTextLayer(layerFrame)
    bgTextLayer.text = buildTextForScreen(layerFrame.size.h)
    bgTextLayer.textColor = GColorBlack
    bgTextLayer.backgroundColor = GColorClear
    bgTextLayer.textAlignment = pblIfRoundElse(GTextAlignmentCenter, GTextAlignmentLeft)
    
    windowLayer.addChild(bgTextLayer)
    
    # Enable text flow for round displays
    when defined(pebbleChalk):
      bgTextLayer.enableScreenTextFlowAndPaging(2)
    
    # Load and center the bitmap
    pandaBitmap = newBitmapRef(RESOURCE_ID_IMAGE_PANDA)
    
    if pandaBitmap.isValid:
      let center = bounds.centerPoint()
      let imgSize = pandaBitmap.size()
      
      let imgFrame = makeGRect(
        center.x.int16 - imgSize.w.int16 div 2,
        center.y.int16 - imgSize.h.int16 div 2,
        imgSize.w,
        imgSize.h
      )
      
      bmpLayer = newBitmapLayer(imgFrame)
      bmpLayer.bitmap = pandaBitmap.bitmap()
      bmpLayer.compositingMode = GCompOpSet
      
      windowLayer.addChild(bmpLayer.getLayer())

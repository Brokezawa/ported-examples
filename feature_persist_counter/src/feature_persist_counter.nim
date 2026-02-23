## feature_persist_counter
## Pebble app ported to Nebble (Nim)
##
## Original: https://github.com/pebble-examples/feature-persist-counter
##
## A "99 Bottles of Beer" style counter demonstrating:
## - Persistent storage (save/load integers)
## - ActionBarLayer with icons
## - Button click handling with repeat
## - FixedString for text formatting

import nebble
import nebble/ui/clicks
import nebble/util/fixed_strings
import nebble/foundation/logging
import gen/resources

const
  REPEAT_INTERVAL_MS = 50
  NUM_DRINKS_PKEY = 1u32    # Persistent storage key
  NUM_DRINKS_DEFAULT = 0    # Default value
  
  # Compile-time layout calculations based on platform
  ContentWidth = platform.PBLDisplayWidth - platform.ActionBarWidth - 3
  ContentX = if platform.isRound: 0 else: 4
  
  # Scale Y positions based on screen height (Emery is taller)
  # Base positions are for 168px height screen
  HeightScale = platform.PBLDisplayHeight.float / 168.0
  
  HeaderY = if platform.isRound: int16((30.0 * HeightScale).int) else: 0
  BodyY = int16((44.0 * HeightScale).int)
  LabelY = int16((72.0 * HeightScale).int)
  
  TextAlignment = if platform.isRound: GTextAlignmentCenter else: GTextAlignmentLeft

# App state
var
  numDrinks: int = NUM_DRINKS_DEFAULT
  counterBuffer: FixedString[32]

# Forward declarations
proc updateText() {.inline.}
proc incrementHandler(recognizer: ClickRecognizerRef; context: pointer) {.cdecl.}
proc decrementHandler(recognizer: ClickRecognizerRef; context: pointer) {.cdecl.}
proc clickConfigProvider(context: pointer) {.cdecl.}

# Declarative App Definition
nebbleApp:
  
  window:
    backgroundColor = GColorWhite
  
  # Title at top - on rect platforms, leave room for action bar on right
  textLayer:
    id = headerLayer
    x = ContentX
    y = HeaderY
    w = ContentWidth
    h = 60
    text = "Drink Counter"
    font = FONT_KEY_GOTHIC_24
    color = GColorBlack
    alignment = TextAlignment
    backgroundColor = GColorClear
  
  # Main counter display (large)
  textLayer:
    id = bodyLayer
    x = ContentX
    y = BodyY
    w = ContentWidth
    h = 60
    text = ""
    font = FONT_KEY_GOTHIC_28_BOLD
    color = GColorBlack
    alignment = TextAlignment
    backgroundColor = GColorClear
  
  # Label below counter
  textLayer:
    id = labelLayer
    x = ContentX
    y = LabelY
    w = ContentWidth
    h = 60
    text = "of beer on the wall"
    font = FONT_KEY_GOTHIC_18
    color = GColorBlack
    alignment = TextAlignment
    backgroundColor = GColorClear
  
  # Action bar with + and - buttons
  actionBarLayer:
    id = actionBar
    icons:
      up = RESOURCE_ID_IMAGE_ACTION_ICON_PLUS
      down = RESOURCE_ID_IMAGE_ACTION_ICON_MINUS
    bgColor = GColorBlack

  init:
    # Set click config provider for action bar using high-level API
    actionBar.clickConfigProvider = clickConfigProvider
    
    # Load saved value on startup using high-level storage API
    if storage.exists(NUM_DRINKS_PKEY):
      numDrinks = storage.readInt(NUM_DRINKS_PKEY).int
    
    # Update text after layers are created
    updateText()
    
    logInfo("Feature Persist Counter Initialized")

# Event Handlers

proc updateText() {.inline.} =
  ## Update the counter display
  counterBuffer.clear()
  counterBuffer.addInt(numDrinks.int32)
  counterBuffer.add(" Bottles")
  if bodyLayer.isValid:
    bodyLayer.text = counterBuffer.cstr

proc incrementHandler(recognizer: ClickRecognizerRef; context: pointer) {.cdecl.} =
  ## Increase the counter
  numDrinks.inc
  updateText()
  # Save immediately on change using high-level storage API
  discard storage.writeInt(NUM_DRINKS_PKEY, numDrinks.int32)

proc decrementHandler(recognizer: ClickRecognizerRef; context: pointer) {.cdecl.} =
  ## Decrease the counter (but not below zero)
  if numDrinks > 0:
    numDrinks.dec
    updateText()
    # Save immediately on change using high-level storage API
    discard storage.writeInt(NUM_DRINKS_PKEY, numDrinks.int32)

proc clickConfigProvider(context: pointer) {.cdecl.} =
  ## Configure button handlers with repeating clicks using high-level API
  onRepeatingClick(BUTTON_ID_UP, uint16(REPEAT_INTERVAL_MS), incrementHandler)
  onRepeatingClick(BUTTON_ID_DOWN, uint16(REPEAT_INTERVAL_MS), decrementHandler)

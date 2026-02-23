# Feature Persist Counter

A Pebble app ported from the official Pebble SDK examples to demonstrate Nebble's persistence API.

## Original Example

**Source:** https://github.com/pebble-examples/feature-persist-counter

This app demonstrates:
- Persistent storage (save/load integers)
- Button click handling
- Counter with increment/decrement
- Immediate save on change

## Nebble Highlights

### Declarative DSL

```nim
nebbleApp:
  window:
    backgroundColor = GColorBlack
  
  textLayer:
    id = bodyLayer
    frame = (0, 60, 144, 40)
    text = "0 Bottles"
    font = FONT_KEY_GOTHIC_28_BOLD
  
  clicks:
    BUTTON_ID_UP = incrementHandler
    BUTTON_ID_DOWN = decrementHandler
```

### High-Level Persistence API

```nim
# Load on startup
if storage.exists(NUM_DRINKS_PKEY):
  numDrinks = storage.readInt(NUM_DRINKS_PKEY)

# Save on change
discard storage.writeInt(NUM_DRINKS_PKEY, numDrinks)
```

### Zero-Heap Text

```nim
var counterBuffer: FixedString[32]

counterBuffer.clear()
counterBuffer.addInt(numDrinks.int32)
counterBuffer.add(" Bottles")
bodyLayer.text = counterBuffer.cstr
```

## Building

```bash
nebble build --platform basalt
nebble install --emulator basalt
```

## Usage

- **UP button**: Increase counter
- **DOWN button**: Decrease counter
- Counter automatically saves on every change
- Value persists across app restarts

## License

MIT License (same as original Pebble example)

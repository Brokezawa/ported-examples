# Ported Pebble Examples (Nebble)

This directory contains a selection of official Pebble SDK examples ported to the Nebble (Nim) framework. These examples demonstrate how to use Nebble's high-level API and declarative DSL to create Pebble applications and watchfaces with minimal boilerplate and enhanced type safety.

## 🚀 Ported Examples

| Example | Status | Type | Key Features Demonstrated |
|---------|--------|------|---------------------------|
| **[simple_analog](./simple_analog)** | ✅ | Watchface | GPath, Custom drawing, Trigonometry |
| **[ks_clock_face](./ks_clock_face)** | ✅ | Watchface | Custom AnimationImplementation, UnobstructedArea (Quick View) |
| **[classio_battery_connection](./classio_battery_connection)** | ✅ | Watchface | Battery & Bluetooth events, FixedString text |
| **[feature_persist_counter](./feature_persist_counter)** | ✅ | App | Persistent storage, Button clicks, ActionBarLayer |
| **[feature_custom_font](./feature_custom_font)** | ✅ | App | Custom fonts, GFontRef, Resource loading |
| **[feature_image_transparent](./feature_image_transparent)** | ✅ | App | GBitmap, BitmapLayer, Compositing modes |
| **[content_indicator_demo](./content_indicator_demo)** | ⚠️ | App | ScrollLayer, ContentIndicator configuration |

## ⏭️ Skipped Examples

| Example | Reason |
|---------|--------|
| **isotime** | Requires PGE (Pebble Game Engine) library port |
| **feature-background-counter** | Requires worker binary support (separate worker_src/) |

## ⚠️ Known Issues

### content_indicator_demo
- **Issue**: ContentIndicator arrows are not rendering correctly. 
- **Symptoms**: The overlay layers appear and disappear correctly as the user scrolls to the top/bottom, but the arrow graphics themselves are not visible.
- **Status**: Pending investigation. Likely a low-level rendering or struct layout issue between Nim and the C SDK despite matching ABI layouts.


## 🛠️ How to Build

Each example is a standalone Nebble project. To build an example:

```bash
cd <example_name>
nebble build --platform basalt
```

To install on an emulator:

```bash
nebble install --emulator basalt
```

## 📖 Key Differences (Nim vs C)

- **Zero-Heap by Default**: Uses `FixedString` and ARC memory management instead of `malloc/free` and `snprintf`.
- **Declarative UI**: Window and Layer hierarchies are defined using the `nebbleApp` or `nebbleWatchface` DSL.
- **Safety**: Managed handles (`*Handle`) prevent common errors like use-after-free or double-free of Pebble resources.
- **Conciseness**: Boilerplate for window handlers and service subscriptions is significantly reduced.

## 🔗 Original Source

The original C implementations can be found in the [Pebble Examples GitHub organization](https://github.com/pebble-examples).

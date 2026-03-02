# Ported Pebble Examples (Nebble)

This directory contains a selection of official Pebble SDK examples ported to the Nebble (Nim) framework. These examples demonstrate how to use Nebble's high-level API and declarative DSL to create Pebble applications and watchfaces with minimal boilerplate and enhanced type safety.

## 📋 Prerequisites

Before building examples, you need to install Nebble:

### For Users (Released Version)
```bash
nimble install nebble
```

### For Contributors (Local Development)
```bash
cd /path/to/nebble
nimble develop
```

This creates a symlink in `~/.nimble/pkgs2/` (or `%USERPROFILE%\.nimble\pkgs2\` on Windows), allowing `import nebble` to work without hardcoded paths.

## 🚀 Ported Examples

| Example | Status | Type | Key Features Demonstrated |
|---------|--------|------|---------------------------|
| **[simple_analog](./simple_analog)** | ✅ | Watchface | GPath, Custom drawing, Trigonometry |
| **[ks_clock_face](./ks_clock_face)** | ✅ | Watchface | Custom AnimationImplementation, UnobstructedArea (Quick View) |
| **[classio_battery_connection](./classio_battery_connection)** | ✅ | Watchface | Battery & Bluetooth events, FixedString text |
| **[time_dots](./time_dots)** | ✅ | Watchface | Radial graphics, Custom layer drawing, Platform colors |
| **[feature_persist_counter](./feature_persist_counter)** | ✅ | App | Persistent storage, Button clicks, ActionBarLayer |
| **[feature_accel_discs](./feature_accel_discs)** | ✅ | App | Accelerometer physics, collision detection, round display support |
| **[feature_custom_font](./feature_custom_font)** | ✅ | App | Custom fonts, GFontRef, Resource loading |
| **[feature_image_transparent](./feature_image_transparent)** | ✅ | App | GBitmap, BitmapLayer, Compositing modes |
| **[pdc_image](./pdc_image)** | ✅ | App | PDC vector graphics, GDrawCommandImage, ARC-managed handles |
| **[content_indicator_demo](./content_indicator_demo)** | ✅ | App | ScrollLayer, ContentIndicator configuration, window management |

## ⏭️ Skipped Examples

| Example | Reason |
|---------|--------|
| **isotime** | Requires PGE (Pebble Game Engine) library port |
| **feature-background-counter** | Requires worker binary support (separate worker_src/) - planned for v1.2.0 |
| **app-font-browser** | Requires MenuLayer DSL - planned for v1.2.0 |
| **feature-app-wakeup** | Requires MenuLayer DSL - planned for v1.2.0 |
| **feature-menu-layer** | Requires MenuLayer DSL - planned for v1.2.0 |
| **ui-patterns** | Requires MenuLayer DSL - planned for v1.2.0 |
| **hello-timeline** | Requires JavaScript/AppMessage - planned for v1.2.0 |
| **timeline-push-pin** | Requires JavaScript/AppMessage - planned for v1.2.0 |
| **timeline-tv-tracker** | Requires JavaScript/AppMessage - planned for v1.2.0 |
| **owm-weather** | Requires JavaScript/AppMessage - planned for v1.2.0 |
| **pebblekit-js-weather** | Requires JavaScript/AppMessage - planned for v1.2.0 |
| **cards-example** | Requires Animation DSL - planned for v1.3.0 |
| **feature-frame-buffer** | Requires Framebuffer Access API - planned for v1.3.0 |
| **block-world** | Requires PGE library port |
| **pandas-and-bananas** | Requires PGE library port |

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

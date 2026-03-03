# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-03-03

### Added

- First public release as a separate repository
- 10 ported examples from the official Pebble C SDK, rewritten in Nim:
  - `simple_analog`: GPath, custom drawing, trigonometry (watchface)
  - `ks_clock_face`: Custom AnimationImplementation, UnobstructedArea (watchface)
  - `classio_battery_connection`: Battery & Bluetooth events, FixedString text (watchface)
  - `time_dots`: Radial graphics, custom layer drawing (watchface)
  - `feature_persist_counter`: Persistent storage, ActionBarLayer, click handling (app)
  - `feature_accel_discs`: Accelerometer physics, collision detection (app)
  - `feature_custom_font`: Custom fonts, GFontRef, resource loading (app)
  - `feature_image_transparent`: GBitmap, BitmapLayer, compositing modes (app)
  - `pdc_image`: PDC vector graphics, DrawCommandImageHandle (app)
  - `content_indicator_demo`: ScrollLayer, ContentIndicator (app)
- Requires nebble >= 1.1.0

[1.1.0]: https://github.com/pebble-dev/ported-examples/releases/tag/v1.1.0

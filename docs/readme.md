# Fallout 1 Rebirth Documentation

Documentation for Fallout 1 Rebirth — an Apple-only fork of Fallout 1 Community Edition for macOS and iOS/iPadOS.

Last updated: 2026-02-07

## Documentation Index

| Document | Description |
|----------|-------------|
| [architecture.md](architecture.md) | Codebase architecture, directory structure, engine internals |
| [building.md](building.md) | Build instructions for all platforms |
| [configuration.md](configuration.md) | Config file reference (fallout.cfg, f1_res.ini) |
| [contributing.md](contributing.md) | How to contribute |
| [features.md](features.md) | Complete feature history and changelog |
| [input.md](input.md) | Input system deep dive (mouse, touch, Pencil) |
| [scripts.md](scripts.md) | Reference for all automation scripts |
| [sdl3.md](sdl3.md) | SDL3 migration notes and API mapping |
| [setup_guide.md](setup_guide.md) | Step-by-step setup guide for end users |
| [testing.md](testing.md) | Testing procedures and scripts |
| [vsync.md](vsync.md) | VSync and display settings |

## Quick Links

### Getting Started

- **Building for macOS**: [building.md#macos-build](building.md#macos-build)
- **Building for iOS**: [building.md#ios-device-build](building.md#ios-device-build)
- **Running on iPad Simulator**: [testing.md#ios-simulator-testing](testing.md#ios-simulator-testing)

### Development

- **Code Structure**: [architecture.md#directory-structure](architecture.md#directory-structure)
- **Adding Features**: [architecture.md#adding-new-features](architecture.md#adding-new-features)
- **Pre-commit Checks**: [contributing.md#before-submitting](contributing.md#before-submitting)

## Project Overview

Fallout 1 Rebirth is a working re-implementation of Fallout with:

- Original gameplay preserved
- Engine bug fixes
- Quality of life improvements
- Optimizations for Apple platforms

### Target Platforms

| Platform | Minimum Version | Notes |
|----------|-----------------|-------|
| macOS | 11.0 (Big Sur) | Universal binary (Intel + Apple Silicon) |
| iOS/iPadOS | 15.0+ | iPad is the primary target platform |

### Key Features

- **VSync enabled by default** for smooth display
- **Touch input** with gesture recognition and coordinate conversion
- **Apple Pencil support** with gesture recognition and precise positioning
- **f1_res.ini configuration system** for display and resolution settings
- **Local-only builds** (no CI/CD) — use provided scripts
- **ProMotion support** — automatic 120Hz adaptation on compatible devices
- **iPad mouse/trackpad and F-key support**
- **Touch control optimization**
- **Borderless window mode**
- **Engine bug fixes** including Survivalist perk, combat AI, and coordinate transformation
- **TeamX Patch 1.3.5 compatibility**
- **RME 1.1e data integration**

### Additional Documentation

| Folder | Description |
|--------|-------------|
| `development/` | Internal development docs (resolution, VSync, Apple Pencil research) |
| `gameconfig/` | Platform-specific configuration files for iOS and macOS |

## Requirements

### Build Requirements

- **Xcode** with Command Line Tools
- **CMake** 3.13 or later
- **clang-format** (for code formatting)
- **cppcheck** (for static analysis)

### Runtime Requirements

- Original Fallout game data files (from your own copy):
  - `master.dat`
  - `critter.dat`
  - `data/` folder
- Obtain from your preferred storefront or installer

## License

The source code is available under the [Sustainable Use License](../LICENSE.md).

Game assets are NOT included and must be obtained from a legal copy of Fallout.
---

## Proof of Work

- **Timestamp**: 2026-02-07
- **Files verified**:
  - `CMakeLists.txt` - Confirmed iOS deployment target 15.0, macOS 11.0
  - All linked documentation files exist and are accessible
- **Updates made**:
- Added input.md and sdl3.md to the documentation index and refreshed timestamps

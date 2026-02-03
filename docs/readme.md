# Fallout 1 Rebirth Documentation

Documentation for Fallout 1 Rebirth — an Apple-only fork of Fallout 1 Community Edition for macOS and iOS/iPadOS.

> ⚠️ **LOCAL BUILDS ONLY** — This project is built locally. CI/CD workflows have been removed. Use the provided scripts for building and testing. See [scripts.md](scripts.md) for details.

## Documentation Index

| Document | Description |
|----------|-------------|
| [architecture.md](architecture.md) | Codebase architecture, directory structure, engine internals |
| [building.md](building.md) | Build instructions for all platforms |
| [testing.md](testing.md) | Testing procedures and scripts |
| [scripts.md](scripts.md) | Reference for all automation scripts |
| [configuration.md](configuration.md) | Config file reference (fallout.cfg, f1_res.ini) |
| [vsync.md](vsync.md) | VSync and display settings |
| [contributing.md](contributing.md) | How to contribute |

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
| iOS/iPadOS | 14.0+ | iPad is the primary target platform |

### Key Features

- **VSync enabled by default** for smooth display
- **Touch input** with proper coordinate handling
- **Apple Pencil support** (in development)
- **f1_res.ini configuration system** for display and resolution settings
- **Local-only builds** (no CI/CD) — use provided scripts
- iPad mouse/trackpad and F-key support
- Touch control optimization
- Borderless window mode
- TeamX Patch 1.3.5 compatibility
- RME 1.1e data integration

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

- Original Fallout game data files:
  - `master.dat`
  - `critter.dat`
  - `data/` folder
- Purchase from [GOG](https://www.gog.com/game/fallout) or [Steam](https://store.steampowered.com/app/38400)

## License

The source code is available under the [Sustainable Use License](../LICENSE.md).

Game assets are NOT included and must be obtained from a legal copy of Fallout.

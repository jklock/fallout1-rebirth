---
name: fallout1-rebirth
description: Build, test, and develop the Fallout 1 Rebirth project - an Apple-only fork (macOS/iOS/iPadOS) of Fallout 1 Community Edition. Use this skill for building the game, running iOS simulator tests, understanding the C++ game engine architecture, and following project conventions.
---

# Fallout 1 Rebirth Development Skill

## Overview
This skill provides guidance for working with the Fallout 1 Rebirth project, an Apple-only fork of Fallout 1 Community Edition targeting macOS and iPad/iOS.

**Primary target: iPad** — this is the main use case for this project.

## ⚠️ CRITICAL: ALWAYS Use Project Scripts

**NEVER run raw cmake, xcodebuild, or xcrun simctl commands directly. ALWAYS use the provided scripts.**

| Task | ALWAYS Use | NEVER Do This |
|------|------------|---------------|
| iOS Testing | `./scripts/test/test-ios-simulator.sh` | ❌ `cmake ...` or `xcrun simctl boot` |
| macOS Testing | `./scripts/test/test-macos.sh` | ❌ `./build/fallout1-rebirth` directly |
| iOS Build | `./scripts/build/build-ios.sh` | ❌ `cmake -B build-ios ...` |
| macOS Build | `./scripts/build/build-macos.sh` | ❌ `cmake -B build-macos ...` |
| Pre-commit | `./scripts/dev/dev-check.sh` | ❌ running `clang-format` manually |

### iOS Simulator Rules (MUST FOLLOW)
1. **ALWAYS** use `./scripts/test/test-ios-simulator.sh` for iOS testing
2. **NEVER** run multiple simulators simultaneously — causes memory pressure
3. **NEVER** use raw cmake commands for simulator builds
4. **ALWAYS** run `./scripts/test/test-ios-simulator.sh --shutdown` before starting a new simulator
5. Check running simulators: `xcrun simctl list devices | grep Booted`

The scripts handle proper build configuration, simulator lifecycle management, and cleanup. Ignoring them causes test failures and wastes significant debugging time.

## ⚠️ CRITICAL: Git Safety (NO Rebases / NO PRs Unless Explicitly Asked)

**NEVER** run `git rebase` (including interactive rebases) or create/open Pull Requests unless the user explicitly tells you to.

Also forbidden unless explicitly instructed:
- History-rewriting operations: `git reset --hard`, `git commit --amend`, `git filter-branch`/`filter-repo`
- Force pushes: `git push --force` / `--force-with-lease`

Default to read-only git inspection (`git status/log/diff/reflog`) and ask before taking any destructive git action.

## Build Commands

### macOS (fast iteration)
```bash
./scripts/build/build-macos.sh
# or manual:
cmake -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build build -j $(sysctl -n hw.physicalcpu)
```

### iOS Device
```bash
./scripts/build/build-ios.sh
```

### iOS Simulator Testing (PRIMARY)
**ALWAYS use this script for simulator testing:**
```bash
./scripts/test/test-ios-simulator.sh              # Full flow: build + install + launch
./scripts/test/test-ios-simulator.sh --build-only # Just build
./scripts/test/test-ios-simulator.sh --launch     # Launch existing install
./scripts/test/test-ios-simulator.sh --shutdown   # Shutdown all simulators
./scripts/test/test-ios-simulator.sh --list       # Show available iPad sims
```

**CRITICAL RULES:**
- **ONE SIMULATOR AT A TIME** — multiple simulators cause severe memory pressure
- Always run `--shutdown` before starting a new simulator
- Default target: `iPad Pro 13-inch (M4)` (configurable via `SIMULATOR_NAME` env var)
- **DO NOT** manually run `xcrun simctl boot` on multiple devices

### Validation
```bash
./scripts/check.sh    # Pre-commit checks
./scripts/test.sh     # Build verification + static analysis
./scripts/format.sh   # Code formatting
```

## Architecture Quick Reference

| Directory | Purpose |
|-----------|---------|
| `src/game/` | Game logic, main loop, save/load |
| `src/int/` | Script interpreter, opcodes |
| `src/plib/` | Graphics, input, dialogs (SDL) |
| `src/platform/` | Platform abstraction |
| `os/ios/`, `os/macos/` | Platform-specific code |
| `third_party/` | SDL2, dependencies |

### Key Files
| File | Purpose |
|------|---------|
| `src/game/main.cc` | Entry point, main loop |
| `src/game/game.h` | Core game definitions |
| `src/int/support/intextra.cc` | Script opcode handlers |
| `CMakeLists.txt` | Build configuration |

## Adding New Features

### New Source File
1. Create `.cc` and `.h` in appropriate `src/` subdirectory
2. Add to `CMakeLists.txt` under `target_sources`
3. Run `./scripts/check.sh` before committing

### New Script Opcode
1. Implement handler in `src/int/support/intextra.cc`
2. Register with `interpretAddFunc(OPCODE, handler)`
3. Use `dbg_error()` for error logging

## Platform Notes
- **macOS**: Uses Cocoa, Metal rendering
- **iOS/iPadOS**: Touch controls, external keyboard support
- **NOT supported**: Windows, Linux, Android (use upstream for those)

## Game Data
- Files `master.dat`, `critter.dat`, `data/` are **NOT included** in repo
- Obtain from your Fallout 1 copy
- For simulator: game data goes in app's **data container**, not app bundle

## Project Documentation
See `FCE/` directory for phase guides and implementation plans.

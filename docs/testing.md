# Testing

> **⚠️ LOCAL BUILDS ONLY**: This project does not use CI/CD. All testing and verification must be performed locally before submitting pull requests.

Testing procedures for Fallout 1 Rebirth: automated tests, simulator testing, and manual verification.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Automated Testing](#automated-testing)
- [iOS Simulator Testing](#ios-simulator-testing)
- [macOS Testing](#macos-testing)
- [Headless Testing](#headless-testing)
- [Manual Testing](#manual-testing)
- [Local Verification](#local-verification)

---

## Overview

### Local-Only Testing

**All testing happens locally.** There is no CI/CD pipeline—contributors must run verification scripts before submitting PRs. This ensures code quality while keeping the development workflow simple and fast.

### Test Categories

| Category | Purpose | Scripts |
|----------|---------|---------|
| Build Verification | Ensure code compiles | `dev-verify.sh` |
| Static Analysis | Catch bugs without running | `dev-check.sh` |
| Simulator Testing | Run on iPad Simulator | `test-ios-simulator.sh` |
| Headless Testing | CI-friendly validation | `test-ios-headless.sh` |
| macOS Testing | Verify macOS app bundle | `test-macos.sh` |

### Platform Focus

iPad is the **primary target platform** for this project. Testing priorities:

1. iPad Simulator (primary development testing)
2. macOS (secondary, for quick iteration)
3. Physical iOS devices (final verification)

---

## Quick Start

```bash
# Pre-commit checks (formatting + static analysis)
./scripts/dev-check.sh

# Full build verification
./scripts/dev-verify.sh

# Test on iPad Simulator
./scripts/test-ios-simulator.sh

# Test macOS build
./scripts/test-macos.sh
```

---

## Automated Testing

### Pre-Commit Checks

Run before every commit:

```bash
./scripts/dev-check.sh
```

**Checks performed**:
1. Code formatting (clang-format)
2. Static analysis (cppcheck)
3. CMake configuration validation
4. Platform-specific code audit

**Example output**:
```
=== Running Pre-Commit Checks ===

>>> Checking code formatting...
All files correctly formatted.

>>> Running static analysis...
Static analysis OK

>>> Checking CMake configuration...
CMake configuration OK

>>> Checking for common issues...
Common issues check complete

=== Summary ===
All checks passed!
```

### Build Verification Suite

Run the full verification suite:

```bash
./scripts/dev-verify.sh
```

**Tests performed**:
1. Build verification (CMake + compile)
2. Binary execution check
3. Static analysis (cppcheck)
4. Code formatting verification
5. Source file inventory
6. iOS CMake configuration validation

**Environment variables**:
```bash
BUILD_DIR=build-test ./scripts/dev-verify.sh
GAME_DATA=/path/to/fallout ./scripts/dev-verify.sh
```

---

## iOS Simulator Testing

### Overview

The iOS Simulator lets you test iPad functionality without a physical device. It runs iOS apps compiled for the Mac's architecture.

**Rules:**
- Run **ONE SIMULATOR AT A TIME** — multiple simulators cause severe memory pressure
- Always shut down existing simulators before starting new ones
- Requires ~8GB free RAM

### Using the Test Script

```bash
# Full test cycle: build, install, launch
./scripts/test-ios-simulator.sh

# Build only (no simulator)
./scripts/test-ios-simulator.sh --build-only

# Launch existing installation
./scripts/test-ios-simulator.sh --launch

# Shutdown all simulators
./scripts/test-ios-simulator.sh --shutdown

# List available iPad simulators
./scripts/test-ios-simulator.sh --list

# Show help
./scripts/test-ios-simulator.sh --help
```

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SIMULATOR_NAME` | "iPad Pro 13-inch (M4)" | Target device name |
| `GAME_DATA` | "GOG/Fallout1" | Path to game data |
| `BUILD_DIR` | "build-ios-sim" | Build output directory |
| `BUILD_TYPE` | "RelWithDebInfo" | Build configuration |
| `CLEAN` | "0" | Set to "1" to force rebuild |

### Example Workflow

```bash
# 1. First, ensure no simulators are running
./scripts/test-ios-simulator.sh --shutdown

# 2. Check available iPad simulators
./scripts/test-ios-simulator.sh --list

# 3. Set your preferred simulator (if different from default)
export SIMULATOR_NAME="iPad Pro 11-inch (M4)"

# 4. Run full test cycle
./scripts/test-ios-simulator.sh
```

### Game Data Setup

The simulator test script copies game data to the app's Documents container. Make sure your game data is accessible:

```bash
# Default location
GOG/Fallout1/
├── master.dat
├── critter.dat
├── data/
│   └── ...
└── sound/
    └── music/

# Or specify custom location
GAME_DATA=/path/to/fallout ./scripts/test-ios-simulator.sh
```

### Troubleshooting Simulator Issues

**Simulator won't boot**:
```bash
# Shutdown all first
xcrun simctl shutdown all

# Check status
xcrun simctl list devices | grep Booted

# If still issues, reset simulators
xcrun simctl erase all
```

**App won't install**:
```bash
# Check build architecture matches simulator
# For Apple Silicon Macs: SIMULATORARM64
# For Intel Macs: SIMULATOR64
```

**Out of memory**:
- Close other applications
- Ensure only ONE simulator is running
- Check Activity Monitor for zombie simulator processes

---

## macOS Testing

### Using the Test Script

```bash
# Full build and verification
./scripts/test-macos.sh

# Verify existing build only
./scripts/test-macos.sh --verify

# Show help
./scripts/test-macos.sh --help
```

### Verification Checks

The macOS test script verifies:

1. **App bundle structure**:
   - `Contents/MacOS/` exists
   - `Contents/Resources/` exists
   - `Info.plist` present

2. **Executable**:
   - Binary exists and is executable
   - Correct architecture (arm64/x86_64)
   - Mach-O format validation

3. **Info.plist**:
   - `CFBundleIdentifier` set
   - `CFBundleExecutable` set
   - `CFBundleName` set

4. **Code signature** (if signed)

5. **Runtime test**:
   - Binary loads without immediate crash

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `BUILD_DIR` | "build-macos" | Build output directory |
| `BUILD_TYPE` | "RelWithDebInfo" | Build configuration |
| `CLEAN` | "0" | Set to "1" to force rebuild |
| `JOBS` | Physical CPU count | Parallel build jobs |

---

## Headless Testing

### iOS Headless Testing

For CI/CD environments without GUI access:

```bash
# Full headless test cycle
./scripts/test-ios-headless.sh

# Build first, then test
./scripts/test-ios-headless.sh --build

# Skip simulator tests (bundle validation only)
./scripts/test-ios-headless.sh --skip-sim

# Show help
./scripts/test-ios-headless.sh --help
```

**Tests performed**:
1. App bundle exists with correct iOS structure
2. Binary architecture validation
3. Info.plist required keys check
4. Headless simulator: boot, install, brief launch, terminate, shutdown
5. Clean exit code
6. No lingering simulator processes

**Exit codes**:
- `0`: All tests passed
- `1`: One or more tests failed

### macOS Headless Testing

For CI-friendly macOS verification:

```bash
./scripts/test-macos-headless.sh
```

Performs the same checks as `test-macos.sh` but optimized for non-interactive environments.

---

## Manual Testing

### Essential Test Cases

Before submitting changes, manually verify:

1. **Game Launch**
   - Main menu loads
   - Music plays
   - UI is responsive

2. **New Game**
   - Character creation works
   - Game starts correctly
   - Save/load functions

3. **Controls**
   - Mouse movement and clicks (macOS)
   - Touch controls (iOS Simulator)
   - Keyboard input (where applicable)

4. **Display**
   - Correct resolution
   - No graphical glitches
   - Palette colors correct

### Platform-Specific Testing

#### macOS

- Window resizing
- Fullscreen toggle
- Borderless mode
- Mouse cursor behavior

#### iPad (Simulator)

- Touch tap (move + click)
- One-finger drag (cursor movement)
- Two-finger tap (right-click)
- Two-finger scroll
- Three-finger tap (click without move)

---

## Local Verification

### Why Local-Only?

This project uses **local builds exclusively**. CI/CD workflows have been removed to simplify the development process. Contributors are responsible for running verification before submitting pull requests.

### Pre-Commit Checklist

Before every commit, run:

```bash
./scripts/dev-check.sh
```

Before submitting a PR, run:

```bash
./scripts/dev-verify.sh
```

### Running All Checks

Complete verification mirrors what would happen in CI:

```bash
# Static analysis
cppcheck --std=c++17 src/

# Format check
find src -type f -name '*.cc' -o -name '*.h' | \
  xargs clang-format --dry-run --Werror

# Full build verification
./scripts/dev-verify.sh

# Test on iOS Simulator
./scripts/test-ios-simulator.sh

# Test macOS build
./scripts/test-macos.sh
```

### Verification Results

| Check | Pass Criteria | Fix |
|-------|--------------|-----|
| Static analysis | No errors | Address cppcheck warnings |
| Code format | No differences | Run `./scripts/dev-format.sh` |
| iOS build | Compiles successfully | Fix build errors |
| macOS build | Compiles successfully | Fix build errors |

### Releasing

Builds are created locally and uploaded to GitHub Releases:

```bash
# Create macOS DMG
./scripts/build-macos-dmg.sh

# Create iOS IPA
./scripts/build-ios.sh && cd build-ios && cpack -C RelWithDebInfo
```

Then upload artifacts to GitHub Releases manually.

### Contributor Responsibility

Since there's no automated CI, **you are responsible** for ensuring:

1. ✅ Code compiles on both macOS and iOS
2. ✅ No formatting violations (`dev-check.sh` passes)
3. ✅ Static analysis clean (`dev-verify.sh` passes)
4. ✅ App launches successfully on target platform
5. ✅ No regressions in existing functionality

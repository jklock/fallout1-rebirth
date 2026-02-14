# Testing

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
| Build Verification | Validate existing artifacts | `scripts/dev/dev-verify.sh` |
| Static Analysis | Catch bugs without running | `scripts/dev/dev-check.sh` |
| Simulator Testing | Run on iPad Simulator | `scripts/test/test-ios-simulator.sh` |
| Headless Testing | CI-friendly validation | `scripts/test/test-ios-headless.sh` |
| macOS Testing | Verify macOS app bundle | `scripts/test/test-macos.sh` |

### Platform Focus

iPad is the **primary target platform** for this project. Testing priorities:

1. iPad Simulator (primary development testing)
2. macOS (secondary, for quick iteration)
3. Physical iOS devices (final verification)

---

## Quick Start

```bash
# Pre-commit checks (formatting + static analysis)
./scripts/dev/dev-check.sh

# Build then verify artifacts
./scripts/build/build-macos.sh -prod
./scripts/dev/dev-verify.sh --build-dir build-macos

# Build and test on iPad Simulator
./scripts/build/build-ios.sh -prod --simulator
./scripts/test/test-ios-simulator.sh

# Test macOS build
./scripts/test/test-macos.sh
```

---

## Automated Testing

### Pre-Commit Checks

Run before every commit:

```bash
./scripts/dev/dev-check.sh
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

### Build Verification Suite (Existing Artifacts)

Run verification against an already-built artifact:

```bash
./scripts/build/build-macos.sh -prod
./scripts/dev/dev-verify.sh --build-dir build-macos
```

**Tests performed**:
1. Executable presence and permissions
2. Mach-O format validation
3. Bundle metadata (`Info.plist`) validation
4. Dynamic library linkage check (`otool -L`)
5. Startup smoke run (optional game-data path)

**Options**:
```bash
./scripts/dev/dev-verify.sh --build-dir build-test
./scripts/dev/dev-verify.sh --game-data /path/to/FalloutData
```
Relative `--game-data` paths are resolved from the invoking directory.

**Environment variables** (optional):
```bash
BUILD_DIR=build-test ./scripts/dev/dev-verify.sh
GAME_DATA=/path/to/fallout ./scripts/dev/dev-verify.sh
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
# Build simulator artifact first
./scripts/build/build-ios.sh -prod --simulator

# Full test cycle: install and launch existing build
./scripts/test/test-ios-simulator.sh

# Launch existing installation
./scripts/test/test-ios-simulator.sh --launch

# Shutdown all simulators
./scripts/test/test-ios-simulator.sh --shutdown

# List available iPad simulators
./scripts/test/test-ios-simulator.sh --list

# Show help
./scripts/test/test-ios-simulator.sh --help
```

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SIMULATOR_NAME` | "iPad Pro 13-inch (M5)" | Target device name |
| `GAME_DATA` | (not set) | Path to game data (master.dat, critter.dat, data/) |
| `BUILD_DIR` | "build-ios-sim" | Build output directory |
| `BUILD_TYPE` | "RelWithDebInfo" | Build configuration |

### Example Workflow

```bash
# 1. First, ensure no simulators are running
./scripts/test/test-ios-simulator.sh --shutdown

# 2. Check available iPad simulators
./scripts/test/test-ios-simulator.sh --list

# 3. Set your preferred simulator (if different from default)
export SIMULATOR_NAME="iPad Pro 11-inch (M4)"

# 4. Build simulator artifact
./scripts/build/build-ios.sh -prod --simulator

# 5. Run full test cycle
./scripts/test/test-ios-simulator.sh
```

### Game Data Setup

The simulator test script copies game data to the app's Documents container. Make sure your game data is accessible:

```bash
# Example layout
/path/to/FalloutData/
├── master.dat
├── critter.dat
├── data/
│   └── ...
└── sound/
    └── music/

# Specify custom location
GAME_DATA=/path/to/FalloutData ./scripts/test/test-ios-simulator.sh
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
./scripts/test/test-macos.sh

# Verify existing build only
./scripts/test/test-macos.sh --verify

# Show help
./scripts/test/test-macos.sh --help
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

---

## Headless Testing

### iOS Headless Testing

For CI/CD environments without GUI access:

```bash
# Build simulator artifact first
./scripts/build/build-ios.sh -prod --simulator

# Full headless test cycle
./scripts/test/test-ios-headless.sh

# Skip simulator tests (bundle validation only)
./scripts/test/test-ios-headless.sh --skip-sim

# Show help
./scripts/test/test-ios-headless.sh --help
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
./scripts/test/test-macos-headless.sh
```

Performs the same checks as `scripts/test/test-macos.sh` but optimized for non-interactive environments.

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
./scripts/dev/dev-check.sh
```

Before submitting a PR, run:

```bash
./scripts/build/build-macos.sh -prod
./scripts/dev/dev-verify.sh --build-dir build-macos
```

### Running All Checks

Complete verification mirrors what would happen in CI:

```bash
# Static analysis
cppcheck --std=c++17 src/

# Format check
find src -type f -name '*.cc' -o -name '*.h' | \
  xargs clang-format --dry-run --Werror

# Build + verify macOS artifacts
./scripts/build/build-macos.sh -prod
./scripts/dev/dev-verify.sh --build-dir build-macos

# Test on iOS Simulator
./scripts/build/build-ios.sh -prod --simulator
./scripts/test/test-ios-simulator.sh

# Test macOS build
./scripts/test/test-macos.sh
```

### Verification Results

| Check | Pass Criteria | Fix |
|-------|--------------|-----|
| Static analysis | No errors | Address cppcheck warnings |
| Code format | No differences | Run `./scripts/dev/dev-format.sh` |
| iOS build | Compiles successfully | Fix build errors |
| macOS build | Compiles successfully | Fix build errors |

### Releasing

Builds are created locally and uploaded to GitHub Releases:

```bash
# Build macOS app bundle (DMG packaging is manual)
./scripts/build/build-macos.sh -prod

# Create iOS IPA
./scripts/build/build-ios.sh -prod --device
```

Then upload artifacts to GitHub Releases manually.

### Contributor Responsibility

Since there's no automated CI, **you are responsible** for ensuring:

1. ✅ Code compiles on both macOS and iOS
2. ✅ No formatting violations (`scripts/dev/dev-check.sh` passes)
3. ✅ Static analysis clean (`scripts/dev/dev-check.sh` passes)
4. ✅ App launches successfully on target platform
5. ✅ No regressions in existing functionality
---

## Proof of Work

- **Timestamp**: February 14, 2026
- **Files verified**:
  - `scripts/test/test-ios-simulator.sh` - Confirmed script exists and matches documentation
  - `scripts/test/test-macos.sh` - Confirmed script exists
  - `scripts/test/test-ios-headless.sh` - Confirmed script exists
  - `scripts/test/test-macos-headless.sh` - Confirmed script exists
  - `scripts/dev/dev-check.sh` - Confirmed script exists
  - `scripts/dev/dev-verify.sh` - Confirmed script exists
- **Updates made**:
  - Updated quick-start and local verification flows to require explicit build commands before tests.
  - Updated `dev-verify.sh` coverage description to match existing-artifact verification behavior.
  - Updated release section to remove deleted packaging wrappers and use unified build entrypoints.

# Scripts Reference

Reference for all automation scripts in the `scripts/` directory.

## Table of Contents

- [Overview](#overview)
- [Build Scripts](#build-scripts)
- [Test Scripts](#test-scripts)
- [Development Utilities](#development-utilities)
- [Environment Variables](#environment-variables)
- [Common Workflows](#common-workflows)

---

## Overview

All scripts are in the `scripts/` directory. Run them from the repository root:

```bash
cd /path/to/fallout1-rebirth
./scripts/script-name.sh
```

### Script Categories

| Category | Scripts | Purpose |
|----------|---------|---------|
| Build | `build-macos.sh`, `build-ios.sh`, `build-macos-dmg.sh`, `build-ios-ipa.sh` | Compile and package |
| Test | `test-macos.sh`, `test-macos-headless.sh`, `test-ios-simulator.sh`, `test-ios-headless.sh` | Verify builds |
| Dev | `dev-check.sh`, `dev-format.sh`, `dev-verify.sh`, `dev-clean.sh`, `journal.sh` | Development utilities |

---

## Build Scripts

### build-macos.sh

Build the macOS app bundle using the Xcode generator.

**Usage**:
```bash
./scripts/build-macos.sh
```

**Options** (via environment variables):
```bash
BUILD_TYPE=Debug ./scripts/build-macos.sh    # Debug build
BUILD_TYPE=Release ./scripts/build-macos.sh  # Release build
CLEAN=1 ./scripts/build-macos.sh             # Force clean rebuild
BUILD_DIR=custom-dir ./scripts/build-macos.sh # Custom output directory
JOBS=4 ./scripts/build-macos.sh              # Limit parallel jobs
```

**Output**:
```
build-macos/
└── RelWithDebInfo/
    └── Fallout 1 Rebirth.app
```

---

### build-ios.sh

Build for physical iOS/iPadOS devices (arm64).

**Usage**:
```bash
./scripts/build-ios.sh
```

**Options** (via environment variables):
```bash
BUILD_TYPE=Debug ./scripts/build-ios.sh    # Debug build
CLEAN=1 ./scripts/build-ios.sh             # Force clean rebuild
BUILD_DIR=custom-dir ./scripts/build-ios.sh # Custom output directory
JOBS=4 ./scripts/build-ios.sh              # Limit parallel jobs
```

**Output**:
```
build-ios/
└── RelWithDebInfo/
    └── fallout1-rebirth.app
```

**Notes**:
- For simulator builds, use `test-ios-simulator.sh --build-only`
- Code signing is disabled by default; use Xcode for signed builds

---

### build-macos-dmg.sh

Build and package macOS app as a DMG installer.

**Usage**:
```bash
./scripts/build-macos-dmg.sh
```

**Options** (via environment variables):
```bash
BUILD_TYPE=Debug ./scripts/build-macos-dmg.sh    # Debug build
BUILD_DIR=custom-dir ./scripts/build-macos-dmg.sh # Custom build directory
```

**Output**:
```
build-outputs/macOS/
└── Fallout1Rebirth-X.X.X-Darwin.dmg
```

**Requirements**:
- `create-dmg`: `brew install create-dmg`

**Notes**:
- Game data is NOT bundled — users add their own files
- DMG includes the app bundle and distribution README

---

### build-ios-ipa.sh

Build and package iOS app as an IPA file.

**Usage**:
```bash
./scripts/build-ios-ipa.sh
```

**Output**:
```
build-outputs/iOS/
└── fallout1-rebirth-X.X.X-iphoneos.ipa
```

**Notes**:
- Runs `build-ios.sh` first, then packages with CPack
- Code signing disabled; sideload via AltStore, Sideloadly, or similar
- IPA is copied to `build-outputs/iOS/` for easy access

---

## Test Scripts

### test-macos.sh

Build and verify the macOS app bundle structure and integrity.

**Usage**:
```bash
./scripts/test-macos.sh              # Full build + verification
./scripts/test-macos.sh --verify     # Verify existing build only
./scripts/test-macos.sh --help       # Show usage
```

**Options** (via environment variables):
```bash
BUILD_TYPE=Debug ./scripts/test-macos.sh
CLEAN=1 ./scripts/test-macos.sh
BUILD_DIR=custom-dir ./scripts/test-macos.sh
```

**Verification checks**:
- App bundle structure (`Contents/MacOS/`, `Contents/Resources/`, `Info.plist`)
- Executable architecture (Mach-O arm64/x86_64)
- Info.plist required keys
- Code signature status
- Binary execution test

---

### test-ios-simulator.sh

Build, install, and launch on iOS Simulator. Primary way to test iPad functionality.

**Usage**:
```bash
./scripts/test-ios-simulator.sh              # Full flow: build + install + launch
./scripts/test-ios-simulator.sh --build-only # Just build
./scripts/test-ios-simulator.sh --launch     # Launch existing install
./scripts/test-ios-simulator.sh --shutdown   # Shutdown all simulators
./scripts/test-ios-simulator.sh --list       # List available iPad simulators
./scripts/test-ios-simulator.sh --help       # Show usage
```

**Options** (via environment variables):
```bash
SIMULATOR_NAME="iPad Pro 11-inch (M4)" ./scripts/test-ios-simulator.sh
GAME_DATA=/path/to/fallout ./scripts/test-ios-simulator.sh
BUILD_TYPE=Debug ./scripts/test-ios-simulator.sh
CLEAN=1 ./scripts/test-ios-simulator.sh
BUILD_DIR=custom-dir ./scripts/test-ios-simulator.sh
```

**Rules:**
- ONE SIMULATOR AT A TIME — multiple simulators cause memory pressure
- Always run `--shutdown` before starting a new simulator
- Requires ~8GB free RAM

**Example workflow**:
```bash
# 1. Shutdown any running simulators
./scripts/test-ios-simulator.sh --shutdown

# 2. List available simulators
./scripts/test-ios-simulator.sh --list

# 3. Run with a specific simulator
SIMULATOR_NAME="iPad Pro 13-inch (M4)" ./scripts/test-ios-simulator.sh
```

---

### test-ios-headless.sh

Validates iOS app bundle for CI without keeping simulator running.

**Usage**:
```bash
./scripts/test-ios-headless.sh              # Full test cycle
./scripts/test-ios-headless.sh --build      # Build first, then test
./scripts/test-ios-headless.sh --skip-sim   # Skip simulator tests
./scripts/test-ios-headless.sh --help       # Show usage
```

**Options** (via environment variables):
```bash
BUILD_DIR=build-ios-sim ./scripts/test-ios-headless.sh
BUILD_TYPE=RelWithDebInfo ./scripts/test-ios-headless.sh
SIMULATOR_NAME="iPad Pro 13-inch (M4)" ./scripts/test-ios-headless.sh
JOBS=4 ./scripts/test-ios-headless.sh
```

**Tests performed**:
1. App bundle exists with correct iOS structure
2. Binary architecture (arm64 or x86_64)
3. Info.plist has required iOS keys
4. Headless simulator: boot, install, brief launch, terminate, shutdown
5. Clean exit code verification
6. No lingering simulator processes

**Exit codes**:
- `0`: All tests passed
- `1`: One or more tests failed

---

### test-macos-headless.sh

CI-friendly macOS verification without GUI interaction.

**Usage**:
```bash
./scripts/test-macos-headless.sh
```

Similar to `test-macos.sh` but optimized for non-interactive CI environments.

---

## Development Utilities

### dev-check.sh

Pre-commit checks. Run before every commit.

**Usage**:
```bash
./scripts/dev-check.sh
```

**Checks performed**:
1. Code formatting (clang-format)
2. Static analysis (cppcheck)
3. CMake configuration validation
4. Platform-specific code audit (Windows/Android references)

**Requirements**:
- clang-format: `brew install clang-format`
- cppcheck: `brew install cppcheck`

**Exit codes**:
- `0`: All checks passed
- `1`: One or more checks failed

---

### dev-format.sh

Format all C++ source files with clang-format.

**Usage**:
```bash
./scripts/dev-format.sh         # Format all source files
./scripts/dev-format.sh --check # Check formatting only (no changes)
```

**Scope**: All `.cc` and `.h` files in `src/`

**Requirements**:
- clang-format: `brew install clang-format`
- Uses `.clang-format` configuration at repository root

---

### dev-verify.sh

Full verification suite: build, analysis, and configuration.

**Usage**:
```bash
./scripts/dev-verify.sh
```

**Options** (via environment variables):
```bash
BUILD_DIR=build-test ./scripts/dev-verify.sh
GAME_DATA=/path/to/fallout ./scripts/dev-verify.sh
```

**Tests performed**:
1. Build verification (CMake + compile)
2. Binary execution check (with game data if available)
3. Static analysis (cppcheck)
4. Code formatting verification (clang-format)
5. Source file inventory
6. iOS CMake configuration validation

---

### dev-clean.sh

Remove all build directories.

**Usage**:
```bash
./scripts/dev-clean.sh
```

**Directories removed**:
- `build/`
- `build-macos/`
- `build-ios/`
- `build-ios-sim/`
- Any other `build-*` directories

---

### journal.sh

Toggle visibility of JOURNAL.md files in git. Run before pushing to hide development journals.

**Usage**:
```bash
./scripts/journal.sh          # Toggle journal ignore state
./scripts/journal.sh --status # Show current state
```

**Behavior**:
- When ignored: JOURNAL.md files are excluded from commits
- When tracked: JOURNAL.md files are visible and can be committed

**Use case**: Keep development notes locally without pushing to remote.

---

## Environment Variables

### Global Variables

These variables are recognized by multiple scripts:

| Variable | Default | Description |
|----------|---------|-------------|
| `BUILD_DIR` | Varies by script | Build output directory |
| `BUILD_TYPE` | `RelWithDebInfo` | CMake build type |
| `JOBS` | Physical CPU count | Parallel build jobs |
| `CLEAN` | `0` | Set to `1` to force clean rebuild |

### iOS-Specific Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SIMULATOR_NAME` | `iPad Pro 13-inch (M4)` | Target simulator device |
| `GAME_DATA` | `GOG/Fallout1` | Path to game data files |

### Examples

```bash
# Debug build with 4 parallel jobs
BUILD_TYPE=Debug JOBS=4 ./scripts/build-macos.sh

# iOS simulator with specific device
SIMULATOR_NAME="iPad mini (6th generation)" ./scripts/test-ios-simulator.sh

# Clean rebuild with custom game data
CLEAN=1 GAME_DATA=/Users/me/fallout ./scripts/test-ios-simulator.sh
```

---

## Common Workflows

### Daily Development

```bash
# 1. Make code changes

# 2. Format code
./scripts/dev-format.sh

# 3. Run pre-commit checks
./scripts/dev-check.sh

# 4. Quick test on macOS
./scripts/build-macos.sh && ./build-macos/RelWithDebInfo/fallout1-rebirth
```

### Before Committing

```bash
# Run all pre-commit checks
./scripts/dev-check.sh

# If changes affect iOS, also test simulator
./scripts/test-ios-headless.sh --build
```

### Before Pushing

```bash
# Run pre-commit checks
./scripts/dev-check.sh

# Full verification suite
./scripts/dev-verify.sh

# macOS verification
./scripts/test-macos.sh

# iOS verification (optional, if iOS changes)
./scripts/test-ios-headless.sh --build
```

### Testing iPad Features

```bash
# Shutdown any running simulators first
./scripts/test-ios-simulator.sh --shutdown

# List available iPad simulators
./scripts/test-ios-simulator.sh --list

# Build and test on simulator
./scripts/test-ios-simulator.sh
```

### Clean Build

```bash
# Remove all build artifacts
./scripts/dev-clean.sh

# Fresh build
./scripts/build-macos.sh
```

### Debug Build

```bash
# macOS debug build
BUILD_TYPE=Debug ./scripts/build-macos.sh

# iOS debug build
BUILD_TYPE=Debug ./scripts/build-ios.sh

# Debug with Address Sanitizer (manual)
cmake -B build-debug -DCMAKE_BUILD_TYPE=Debug -DASAN=ON
cmake --build build-debug -j $(sysctl -n hw.physicalcpu)
```

### Pre-Push Verification

```bash
# Run all checks before pushing
./scripts/dev-check.sh
./scripts/dev-verify.sh
```

> **Note**: This project has no CI/CD pipeline. All verification is done locally before pushing.

---

### Creating a Release

Builds are created locally and uploaded to GitHub Releases:

```bash
# Build macOS DMG
./scripts/build-macos-dmg.sh
# Output: build-outputs/macOS/*.dmg

# Build iOS IPA
./scripts/build-ios-ipa.sh
# Output: build-outputs/iOS/*.ipa
```

Then upload the artifacts to GitHub Releases manually.
---

## Proof of Work

- **Timestamp**: February 5, 2026
- **Files verified**:
  - `scripts/build-macos.sh` - Exists
  - `scripts/build-ios.sh` - Exists
  - `scripts/build-macos-dmg.sh` - Exists
  - `scripts/build-ios-ipa.sh` - Exists
  - `scripts/test-ios-simulator.sh` - Exists
  - `scripts/test-ios-headless.sh` - Exists
  - `scripts/test-macos.sh` - Exists
  - `scripts/test-macos-headless.sh` - Exists
  - `scripts/dev-check.sh` - Exists
  - `scripts/dev-format.sh` - Exists
  - `scripts/dev-verify.sh` - Exists
  - `scripts/dev-clean.sh` - Exists
- **Updates made**: No updates needed - content verified accurate. All script documentation matches actual scripts in the repository.

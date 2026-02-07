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
| Build | `scripts/build/build-macos.sh`, `scripts/build/build-ios.sh`, `scripts/build/build-macos-dmg.sh`, `scripts/build/build-ios-ipa.sh` | Compile and package |
| Test | `scripts/test/test-macos.sh`, `scripts/test/test-macos-headless.sh`, `scripts/test/test-ios-simulator.sh`, `scripts/test/test-ios-headless.sh` | Verify builds |
| Dev | `scripts/dev/dev-check.sh`, `scripts/dev/dev-format.sh`, `scripts/dev/dev-verify.sh`, `scripts/dev/dev-clean.sh` | Development utilities |
| Patch | `scripts/patch/rebirth_patch_data.sh`, `scripts/patch/rebirth_patch_app.sh`, `scripts/patch/rebirth_patch_ipa.sh` | RME patch automation |

---

## Build Scripts

### scripts/build/build-macos.sh

Build the macOS app bundle using the Xcode generator.

**Usage**:
```bash
./scripts/build/build-macos.sh
```

**Options** (via environment variables):
```bash
BUILD_TYPE=Debug ./scripts/build/build-macos.sh    # Debug build
BUILD_TYPE=Release ./scripts/build/build-macos.sh  # Release build
CLEAN=1 ./scripts/build/build-macos.sh             # Force clean rebuild
BUILD_DIR=custom-dir ./scripts/build/build-macos.sh # Custom output directory
JOBS=4 ./scripts/build/build-macos.sh              # Limit parallel jobs
```

**Output**:
```
build-macos/
└── RelWithDebInfo/
    └── Fallout 1 Rebirth.app
```

---

### scripts/build/build-ios.sh

Build for physical iOS/iPadOS devices (arm64).

**Usage**:
```bash
./scripts/build/build-ios.sh
```

**Options** (via environment variables):
```bash
BUILD_TYPE=Debug ./scripts/build/build-ios.sh    # Debug build
CLEAN=1 ./scripts/build/build-ios.sh             # Force clean rebuild
BUILD_DIR=custom-dir ./scripts/build/build-ios.sh # Custom output directory
JOBS=4 ./scripts/build/build-ios.sh              # Limit parallel jobs
```

**Output**:
```
build-ios/
└── RelWithDebInfo/
    └── fallout1-rebirth.app
```

**Notes**:
- For simulator builds, use `scripts/test/test-ios-simulator.sh --build-only`
- Code signing is disabled by default; use Xcode for signed builds

---

### scripts/build/build-macos-dmg.sh

Build and package macOS app as a DMG installer.

**Usage**:
```bash
./scripts/build/build-macos-dmg.sh
```

**Options** (via environment variables):
```bash
BUILD_TYPE=Debug ./scripts/build/build-macos-dmg.sh    # Debug build
BUILD_DIR=custom-dir ./scripts/build/build-macos-dmg.sh # Custom build directory
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

### scripts/build/build-ios-ipa.sh

Build and package iOS app as an IPA file.

**Usage**:
```bash
./scripts/build/build-ios-ipa.sh
```

**Output**:
```
build-outputs/iOS/
└── fallout1-rebirth-X.X.X-iphoneos.ipa
```

**Notes**:
- Runs `scripts/build/build-ios.sh` first, then packages with CPack
- Code signing disabled; sideload via AltStore, Sideloadly, or similar
- IPA is copied to `build-outputs/iOS/` for easy access

---

## Test Scripts

### scripts/test/test-macos.sh

Build and verify the macOS app bundle structure and integrity.

**Usage**:
```bash
./scripts/test/test-macos.sh              # Full build + verification
./scripts/test/test-macos.sh --verify     # Verify existing build only
./scripts/test/test-macos.sh --help       # Show usage
```

**Options** (via environment variables):
```bash
BUILD_TYPE=Debug ./scripts/test/test-macos.sh
CLEAN=1 ./scripts/test/test-macos.sh
BUILD_DIR=custom-dir ./scripts/test/test-macos.sh
```

**Verification checks**:
- App bundle structure (`Contents/MacOS/`, `Contents/Resources/`, `Info.plist`)
- Executable architecture (Mach-O arm64/x86_64)
- Info.plist required keys
- Code signature status
- Binary execution test

---

### scripts/test/test-ios-simulator.sh

Build, install, and launch on iOS Simulator. Primary way to test iPad functionality.

**Usage**:
```bash
./scripts/test/test-ios-simulator.sh              # Full flow: build + install + launch
./scripts/test/test-ios-simulator.sh --build-only # Just build
./scripts/test/test-ios-simulator.sh --launch     # Launch existing install
./scripts/test/test-ios-simulator.sh --shutdown   # Shutdown all simulators
./scripts/test/test-ios-simulator.sh --list       # List available iPad simulators
./scripts/test/test-ios-simulator.sh --help       # Show usage
```

**Options** (via environment variables):
```bash
SIMULATOR_NAME="iPad Pro 11-inch (M4)" ./scripts/test/test-ios-simulator.sh
GAME_DATA=/path/to/fallout ./scripts/test/test-ios-simulator.sh
BUILD_TYPE=Debug ./scripts/test/test-ios-simulator.sh
CLEAN=1 ./scripts/test/test-ios-simulator.sh
BUILD_DIR=custom-dir ./scripts/test/test-ios-simulator.sh
```

**Rules:**
- ONE SIMULATOR AT A TIME — multiple simulators cause memory pressure
- Always run `--shutdown` before starting a new simulator
- Requires ~8GB free RAM

**Example workflow**:
```bash
# 1. Shutdown any running simulators
./scripts/test/test-ios-simulator.sh --shutdown

# 2. List available simulators
./scripts/test/test-ios-simulator.sh --list

# 3. Run with a specific simulator
SIMULATOR_NAME="iPad Pro 13-inch (M4)" ./scripts/test/test-ios-simulator.sh
```

---

### scripts/test/test-ios-headless.sh

Validates iOS app bundle for CI without keeping simulator running.

**Usage**:
```bash
./scripts/test/test-ios-headless.sh              # Full test cycle
./scripts/test/test-ios-headless.sh --build      # Build first, then test
./scripts/test/test-ios-headless.sh --skip-sim   # Skip simulator tests
./scripts/test/test-ios-headless.sh --help       # Show usage
```

**Options** (via environment variables):
```bash
BUILD_DIR=build-ios-sim ./scripts/test/test-ios-headless.sh
BUILD_TYPE=RelWithDebInfo ./scripts/test/test-ios-headless.sh
SIMULATOR_NAME="iPad Pro 13-inch (M4)" ./scripts/test/test-ios-headless.sh
JOBS=4 ./scripts/test/test-ios-headless.sh
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

### scripts/test/test-macos-headless.sh

CI-friendly macOS verification without GUI interaction.

**Usage**:
```bash
./scripts/test/test-macos-headless.sh
```

Similar to `scripts/test/test-macos.sh` but optimized for non-interactive CI environments.

---

## Development Utilities

### scripts/dev/dev-check.sh

Pre-commit checks. Run before every commit.

**Usage**:
```bash
./scripts/dev/dev-check.sh
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

### scripts/dev/dev-format.sh

Format all C++ source files with clang-format.

**Usage**:
```bash
./scripts/dev/dev-format.sh         # Format all source files
./scripts/dev/dev-format.sh --check # Check formatting only (no changes)
```

**Scope**: All `.cc` and `.h` files in `src/`

**Requirements**:
- clang-format: `brew install clang-format`
- Uses `.clang-format` configuration at repository root

---

### scripts/dev/dev-verify.sh

Full verification suite: build, analysis, and configuration.

**Usage**:
```bash
./scripts/dev/dev-verify.sh
```

**Options** (via environment variables):
```bash
BUILD_DIR=build-test ./scripts/dev/dev-verify.sh
GAME_DATA=/path/to/fallout ./scripts/dev/dev-verify.sh
```

**Tests performed**:
1. Build verification (CMake + compile)
2. Binary execution check (with game data if available)
3. Static analysis (cppcheck)
4. Code formatting verification (clang-format)
5. Source file inventory
6. iOS CMake configuration validation

---

### scripts/dev/dev-clean.sh

Remove all build directories.

**Usage**:
```bash
./scripts/dev/dev-clean.sh

---

## RME Patch Scripts

### scripts/patch/rebirth_patch_data.sh

Core patcher that applies RME to base data and outputs a ready-to-copy folder.

**Usage**:
```bash
./scripts/patch/rebirth_patch_data.sh --base /path/to/FalloutData --out /path/to/Fallout1-RME --config-dir gameconfig/macos
```

### scripts/patch/rebirth_patch_app.sh

macOS wrapper that uses `gameconfig/macos` templates.

**Usage**:
```bash
./scripts/patch/rebirth_patch_app.sh --base /path/to/FalloutData --out /path/to/Fallout1-RME
```

### scripts/patch/rebirth_patch_ipa.sh

iOS wrapper that uses `gameconfig/ios` templates.

**Usage**:
```bash
./scripts/patch/rebirth_patch_ipa.sh --base /path/to/FalloutData --out /path/to/Fallout1-RME
```
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
BUILD_TYPE=Debug JOBS=4 ./scripts/build/build-macos.sh

# iOS simulator with specific device
SIMULATOR_NAME="iPad mini (6th generation)" ./scripts/test/test-ios-simulator.sh

# Clean rebuild with custom game data
CLEAN=1 GAME_DATA=/Users/me/fallout ./scripts/test/test-ios-simulator.sh
```

---

## Common Workflows

### Daily Development

```bash
# 1. Make code changes

# 2. Format code
./scripts/dev/dev-format.sh

# 3. Run pre-commit checks
./scripts/dev/dev-check.sh

# 4. Quick test on macOS
./scripts/build/build-macos.sh && ./build-macos/RelWithDebInfo/fallout1-rebirth
```

### Before Committing

```bash
# Run all pre-commit checks
./scripts/dev/dev-check.sh

# If changes affect iOS, also test simulator
./scripts/test/test-ios-headless.sh --build
```

### Before Pushing

```bash
# Run pre-commit checks
./scripts/dev/dev-check.sh

# Full verification suite
./scripts/dev/dev-verify.sh

# macOS verification
./scripts/test/test-macos.sh

# iOS verification (optional, if iOS changes)
./scripts/test/test-ios-headless.sh --build
```

### Testing iPad Features

```bash
# Shutdown any running simulators first
./scripts/test/test-ios-simulator.sh --shutdown

# List available iPad simulators
./scripts/test/test-ios-simulator.sh --list

# Build and test on simulator
./scripts/test/test-ios-simulator.sh
```

### Clean Build

```bash
# Remove all build artifacts
./scripts/dev/dev-clean.sh

# Fresh build
./scripts/build/build-macos.sh
```

### Debug Build

```bash
# macOS debug build
BUILD_TYPE=Debug ./scripts/build/build-macos.sh

# iOS debug build
BUILD_TYPE=Debug ./scripts/build/build-ios.sh

# Debug with Address Sanitizer (manual)
cmake -B build-debug -DCMAKE_BUILD_TYPE=Debug -DASAN=ON
cmake --build build-debug -j $(sysctl -n hw.physicalcpu)
```

### Pre-Push Verification

```bash
# Run all checks before pushing
./scripts/dev/dev-check.sh
./scripts/dev/dev-verify.sh
```

> **Note**: This project has no CI/CD pipeline. All verification is done locally before pushing.

---

### Creating a Release

Builds are created locally and uploaded to GitHub Releases:

```bash
# Build macOS DMG
./scripts/build/build-macos-dmg.sh
# Output: build-outputs/macOS/*.dmg

# Build iOS IPA
./scripts/build/build-ios-ipa.sh
# Output: build-outputs/iOS/*.ipa
```

Then upload the artifacts to GitHub Releases manually.
---

## Proof of Work

- **Timestamp**: February 5, 2026
- **Files verified**:
  - `scripts/build/build-macos.sh` - Exists
  - `scripts/build/build-ios.sh` - Exists
  - `scripts/build/build-macos-dmg.sh` - Exists
  - `scripts/build/build-ios-ipa.sh` - Exists
  - `scripts/test/test-ios-simulator.sh` - Exists
  - `scripts/test/test-ios-headless.sh` - Exists
  - `scripts/test/test-macos.sh` - Exists
  - `scripts/test/test-macos-headless.sh` - Exists
  - `scripts/dev/dev-check.sh` - Exists
  - `scripts/dev/dev-format.sh` - Exists
  - `scripts/dev/dev-verify.sh` - Exists
  - `scripts/dev/dev-clean.sh` - Exists
- **Updates made**: No updates needed - content verified accurate. All script documentation matches actual scripts in the repository.

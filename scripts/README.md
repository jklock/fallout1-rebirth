# scripts/

Build, test, and development automation scripts for Fallout 1 Rebirth.

All scripts should be run from the repository root directory.

## Script Reference

### Build Scripts

| Script | Description |
|--------|-------------|
| `build-macos.sh` | Build for macOS (Xcode generator, creates .app bundle) |
| `build-ios.sh` | Build for iOS devices (arm64, requires iOS SDK) |

**Environment Variables** (all build scripts):
- `BUILD_DIR` - Output directory (default varies by script)
- `BUILD_TYPE` - Debug/Release/RelWithDebInfo (default: RelWithDebInfo)
- `JOBS` - Parallel build jobs (default: physical CPU count)
- `CLEAN` - Set to "1" to force reconfigure

### Test Scripts

| Script | Description |
|--------|-------------|
| `test-macos.sh` | Build and verify macOS app bundle structure |
| `test-macos-headless.sh` | Headless macOS app validation (no GUI) |
| `test-ios-simulator.sh` | Build, install, and launch on iOS Simulator (iPad) |
| `test-ios-headless.sh` | Headless iOS Simulator validation (automated) |

### Development Utilities

| Script | Description |
|--------|-------------|
| `dev-verify.sh` | Automated verification suite (build, static analysis, configuration) |
| `dev-check.sh` | Pre-commit checks (formatting, static analysis, CMake) |
| `dev-format.sh` | Apply clang-format to all C++ source files |
| `dev-clean.sh` | Remove all build directories |

---

## iOS Simulator Testing

The `test-ios-simulator.sh` script is the primary way to test on iPad (the main target platform):

```bash
./scripts/test-ios-simulator.sh              # Full flow: build + install + launch
./scripts/test-ios-simulator.sh --build-only # Just build for simulator
./scripts/test-ios-simulator.sh --launch     # Launch existing installation
./scripts/test-ios-simulator.sh --shutdown   # Stop all running simulators
./scripts/test-ios-simulator.sh --list       # List available iPad simulators
```

**Environment Variables**:
- `SIMULATOR_NAME` - Target device (default: "iPad Pro 13-inch (M4)")
- `GAME_DATA` - Path to game files (default: "GOG/Fallout1")
- `BUILD_TYPE` - Build configuration (default: "RelWithDebInfo")

**Critical Rules**:
- ONE SIMULATOR AT A TIME - multiple simulators cause severe memory pressure
- Always run `--shutdown` before starting a new simulator
- Game data is copied to the app's Documents container (not the bundle)

---

## macOS Testing

Build and verify the macOS app bundle:

```bash
./scripts/test-macos.sh              # Full build + verification
./scripts/test-macos.sh --verify     # Verify existing build only
```

**Verification Checks**:
- App bundle structure (Contents/MacOS, Contents/Resources, Info.plist)
- Executable architecture (Mach-O arm64/x86_64)
- Info.plist required keys
- Code signature status
- Binary execution test

---

## Pre-Commit Workflow

Before committing changes:

```bash
./scripts/dev-format.sh   # Apply clang-format to source files
./scripts/dev-check.sh    # Verify formatting, static analysis, CMake config
```

Or check formatting only (no modifications):

```bash
./scripts/dev-format.sh --check
```

---

## Usage Examples

```bash
# Full macOS build and test
./scripts/test-macos.sh

# Debug build for macOS
BUILD_TYPE=Debug ./scripts/build-macos.sh

# Full iOS Simulator test cycle
./scripts/test-ios-simulator.sh

# Clean rebuild for iOS device
CLEAN=1 ./scripts/build-ios.sh

# Pre-commit verification
./scripts/dev-verify.sh

# Clean all build artifacts
./scripts/dev-clean.sh
```

---

## Requirements

- **Xcode** with Command Line Tools
- **clang-format** (`brew install clang-format`)
- **cppcheck** (`brew install cppcheck`)
- **iOS SDK** (for iOS builds)
- **Game data files** (master.dat, critter.dat, data/) - not included in repo


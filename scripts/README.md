# scripts/

Build, test, and development automation scripts for Fallout 1 Rebirth.

Last updated: 2026-02-07

All scripts should be run from the repository root directory.

## Script Reference

### Build Scripts

| Script | Description |
|--------|-------------|
| `scripts/build/build-macos.sh` | Build for macOS (Xcode generator, creates .app bundle) |
| `scripts/build/build-macos-dmg.sh` | Build macOS and create DMG installer |
| `scripts/build/build-ios.sh` | Build for iOS devices (arm64, requires iOS SDK) |
| `scripts/build/build-ios-ipa.sh` | Build iOS and create IPA package |

**Environment Variables** (all build scripts):
- `BUILD_DIR` - Output directory (default varies by script)
- `BUILD_TYPE` - Debug/Release/RelWithDebInfo (default: RelWithDebInfo)
- `JOBS` - Parallel build jobs (default: physical CPU count)
- `CLEAN` - Set to "1" to force reconfigure

### Test Scripts

| Script | Description |
|--------|-------------|
| `scripts/test/test-macos.sh` | Build and verify macOS app bundle structure |
| `scripts/test/test-macos-headless.sh` | Headless macOS app validation (no GUI) |
| `scripts/test/test-ios-simulator.sh` | Build, install, and launch on iOS Simulator (iPad) |
| `scripts/test/test-ios-headless.sh` | Headless iOS Simulator validation (automated) |

### Development Utilities

| Script | Description |
|--------|-------------|
| `scripts/dev/dev-verify.sh` | Automated verification suite (build, static analysis, configuration) |
| `scripts/dev/dev-check.sh` | Pre-commit checks (formatting, static analysis, CMake) |
| `scripts/dev/dev-format.sh` | Apply clang-format to all C++ source files |
| `scripts/dev/dev-clean.sh` | Remove all build directories |

### RME Patch Scripts

| Script | Description |
|--------|-------------|
| `scripts/patch/rebirth-patch-data.sh` | Core RME patcher (xdelta + DATA overlay) |
| `scripts/patch/rebirth-patch-app.sh` | macOS wrapper (produces patched data for .app) |
| `scripts/patch/rebirth-patch-ipa.sh` | iOS wrapper (produces patched data for .ipa) |
| `scripts/patch/rebirth-validate-data.sh` | Validate patched data against RME payload |

### Other Utilities

| Script | Description |
|--------|-------------|
| `scripts/build/build-releases.sh` | Build release artifacts for all platforms |
| `scripts/test/test-install-game-data.sh` | Install game data files to app bundle |


---

## iOS Simulator Testing

The `scripts/test/test-ios-simulator.sh` script is the primary way to test on iPad (the main target platform):

```bash
./scripts/test/test-ios-simulator.sh              # Full flow: build + install + launch
./scripts/test/test-ios-simulator.sh --build-only # Just build for simulator
./scripts/test/test-ios-simulator.sh --launch     # Launch existing installation
./scripts/test/test-ios-simulator.sh --shutdown   # Stop all running simulators
./scripts/test/test-ios-simulator.sh --list       # List available iPad simulators
```

**Environment Variables**:
- `SIMULATOR_NAME` - Target device (default: "iPad Pro 13-inch (M5)")
- `GAME_DATA` - Path to game files (master.dat, critter.dat, data/)
- `BUILD_TYPE` - Build configuration (default: "RelWithDebInfo")

**Critical Rules**:
- ONE SIMULATOR AT A TIME - multiple simulators cause severe memory pressure
- Always run `--shutdown` before starting a new simulator
- Game data is copied to the app's Documents container (not the bundle)
- Set `GAME_DATA` to the folder that contains `master.dat`, `critter.dat`, and `data/`

---

## macOS Testing

Build and verify the macOS app bundle:

```bash
./scripts/test/test-macos.sh              # Full build + verification
./scripts/test/test-macos.sh --verify     # Verify existing build only
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
./scripts/dev/dev-format.sh   # Apply clang-format to source files
./scripts/dev/dev-check.sh    # Verify formatting, static analysis, CMake config
```

Or check formatting only (no modifications):

```bash
./scripts/dev/dev-format.sh --check
```

---

## Usage Examples

```bash
# Full macOS build and test
./scripts/test/test-macos.sh

# Debug build for macOS
BUILD_TYPE=Debug ./scripts/build/build-macos.sh

# Full iOS Simulator test cycle
./scripts/test/test-ios-simulator.sh

# Clean rebuild for iOS device
CLEAN=1 ./scripts/build/build-ios.sh

# Pre-commit verification
./scripts/dev/dev-verify.sh
./scripts/dev/dev-verify.sh --game-data /path/to/FalloutData

# Clean all build artifacts
./scripts/dev/dev-clean.sh
```

---

## Requirements

- **Xcode** with Command Line Tools
- **clang-format** (`brew install clang-format`)
- **cppcheck** (`brew install cppcheck`)
- **iOS SDK** (for iOS builds)
- **Game data files** (master.dat, critter.dat, data/) - not included in repo

---

## Proof of Work

**Last Verified**: 2026-02-07

**Files read to verify content**:
- scripts/ directory listing (all .sh files verified)
- Removed reference to journal.sh (does not exist)
- Added scripts/build/build-releases.sh, scripts/test/test-install-game-data.sh, scripts/hideall.sh (confirmed exist)

**Updates made**:
- Refreshed verification date and confirmed current script list

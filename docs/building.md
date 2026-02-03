# Building from Source

> ⚠️ **LOCAL BUILDS ONLY** — This project has no CI/CD pipeline. All builds are performed locally on your machine. See [Distribution Workflow](#distribution-workflow) for how to create and share release artifacts.

Build instructions for Fallout 1 Rebirth on all supported platforms (macOS and iOS/iPadOS).

## Table of Contents

- [Prerequisites](#prerequisites)
- [macOS Build](#macos-build)
- [iOS Device Build](#ios-device-build)
- [iOS Simulator Build](#ios-simulator-build)
- [Build Configuration Options](#build-configuration-options)
- [Packaging](#packaging)
- [Distribution Workflow](#distribution-workflow)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Software

| Software | Version | Installation |
|----------|---------|--------------|
| Xcode | 14.0+ | Mac App Store |
| Command Line Tools | - | `xcode-select --install` |
| CMake | 3.13+ | `brew install cmake` or download from cmake.org |

### Optional (for development)

| Software | Purpose | Installation |
|----------|---------|--------------|
| clang-format | Code formatting | `brew install clang-format` |
| cppcheck | Static analysis | `brew install cppcheck` |

### Verify Installation

```bash
# Check Xcode
xcode-select -p
# Should output: /Applications/Xcode.app/Contents/Developer

# Check CMake
cmake --version
# Should output: cmake version 3.x.x

# Check clang-format (optional)
clang-format --version
```

---

## macOS Build

### Method 1: Using Build Script (Recommended) ✅

**Always use the build script for standard builds.** It handles configuration, parallelization, and output paths correctly:

```bash
./scripts/build-macos.sh
```

The app bundle will be created at:
```
build-macos/RelWithDebInfo/Fallout 1 Rebirth.app
```

#### Build Script Options

```bash
# Debug build
BUILD_TYPE=Debug ./scripts/build-macos.sh

# Release build
BUILD_TYPE=Release ./scripts/build-macos.sh

# Force clean rebuild
CLEAN=1 ./scripts/build-macos.sh

# Custom build directory
BUILD_DIR=my-build ./scripts/build-macos.sh

# Limit parallel jobs
JOBS=4 ./scripts/build-macos.sh
```

### Method 2: Xcode Generator (GUI Development)

Use this method for Xcode IDE integration:

```bash
# Configure with Xcode generator
cmake -B build-macos -G Xcode \
  -D CMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY=''

# Build from command line
cmake --build build-macos --config RelWithDebInfo \
  -j $(sysctl -n hw.physicalcpu)

# Or open in Xcode
open build-macos/fallout1-rebirth.xcodeproj
```

### Method 3: Makefiles (Faster Iteration)

For faster incremental builds during development:

```bash
# Configure
cmake -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo

# Build
cmake --build build -j $(sysctl -n hw.physicalcpu)

# Run
./build/fallout1-rebirth
```

### Running the macOS Build

1. Copy the app bundle to your Fallout data directory:
   ```bash
   cp -r "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app" /path/to/fallout/
   ```

2. Ensure game data files are present:
   ```
   /path/to/fallout/
   ├── Fallout 1 Rebirth.app
   ├── master.dat
   ├── critter.dat
   └── data/
   ```

3. Run the app:
   ```bash
   open "/path/to/fallout/Fallout 1 Rebirth.app"
   ```

---

## iOS Device Build

### Using Build Script (Recommended) ✅

**Always use the build script for standard builds:**

```bash
./scripts/build-ios.sh
```

The app bundle will be created at:
```
build-ios/RelWithDebInfo/fallout1-rebirth.app
```

#### Build Script Options

```bash
# Debug build
BUILD_TYPE=Debug ./scripts/build-ios.sh

# Force clean rebuild
CLEAN=1 ./scripts/build-ios.sh

# Custom build directory
BUILD_DIR=my-ios-build ./scripts/build-ios.sh
```

### Manual Build Commands

```bash
# Configure
cmake -B build-ios \
  -D CMAKE_TOOLCHAIN_FILE=cmake/toolchain/ios.toolchain.cmake \
  -D ENABLE_BITCODE=0 \
  -D PLATFORM=OS64 \
  -G Xcode \
  -D CMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY=''

# Build
cmake --build build-ios --config RelWithDebInfo \
  -j $(sysctl -n hw.physicalcpu)
```

### Code Signing

For deployment to physical devices, you need to sign the app:

1. Open the Xcode project:
   ```bash
   open build-ios/fallout1-rebirth.xcodeproj
   ```

2. Select your development team in Signing & Capabilities

3. Build and deploy from Xcode

Alternatively, use Xcode command line signing:

```bash
cmake -B build-ios \
  -D CMAKE_TOOLCHAIN_FILE=cmake/toolchain/ios.toolchain.cmake \
  -D ENABLE_BITCODE=0 \
  -D PLATFORM=OS64 \
  -G Xcode \
  -D CMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY='Apple Development' \
  -D CMAKE_XCODE_ATTRIBUTE_DEVELOPMENT_TEAM='YOUR_TEAM_ID'
```

---

## iOS Simulator Build

### Using Test Script (Recommended)

The simulator test script handles building, installing, and launching:

```bash
# Full cycle: build, install, and launch
./scripts/test-ios-simulator.sh

# Build only (no simulator interaction)
./scripts/test-ios-simulator.sh --build-only

# List available iPad simulators
./scripts/test-ios-simulator.sh --list
```

See [testing.md](testing.md) for complete simulator testing documentation.

### Manual Simulator Build

For Apple Silicon Macs:

```bash
cmake -B build-ios-sim \
  -D CMAKE_TOOLCHAIN_FILE=cmake/toolchain/ios.toolchain.cmake \
  -D ENABLE_BITCODE=0 \
  -D PLATFORM=SIMULATORARM64 \
  -G Xcode \
  -D CMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY=''

cmake --build build-ios-sim --config RelWithDebInfo \
  -j $(sysctl -n hw.physicalcpu)
```

For Intel Macs:

```bash
cmake -B build-ios-sim \
  -D CMAKE_TOOLCHAIN_FILE=cmake/toolchain/ios.toolchain.cmake \
  -D ENABLE_BITCODE=0 \
  -D PLATFORM=SIMULATOR64 \
  -G Xcode \
  -D CMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY=''

cmake --build build-ios-sim --config RelWithDebInfo \
  -j $(sysctl -n hw.physicalcpu)
```

---

## Build Configuration Options

### CMake Options

| Option | Default | Description |
|--------|---------|-------------|
| `CMAKE_BUILD_TYPE` | RelWithDebInfo | Build type (Debug, Release, RelWithDebInfo) |
| `ASAN` | OFF | Enable Address Sanitizer |
| `UBSAN` | OFF | Enable Undefined Behavior Sanitizer |

### Build Types

| Type | Optimization | Debug Info | Use Case |
|------|--------------|------------|----------|
| `Debug` | None | Full | Development/debugging |
| `Release` | Full | None | Distribution |
| `RelWithDebInfo` | Full | Partial | Testing/profiling |

### Sanitizers

Enable sanitizers for debugging:

```bash
# Address Sanitizer (detects memory errors)
cmake -B build -DCMAKE_BUILD_TYPE=Debug -DASAN=ON

# Undefined Behavior Sanitizer
cmake -B build -DCMAKE_BUILD_TYPE=Debug -DUBSAN=ON

# Both
cmake -B build -DCMAKE_BUILD_TYPE=Debug -DASAN=ON -DUBSAN=ON
```

Note: Sanitizers significantly slow down execution but catch many bugs.

---

## Packaging

> **Important**: Distribution packages contain the game **engine only**. Game data files (`master.dat`, `critter.dat`, `data/`) are NOT bundled. Users must provide their own legally-obtained game files.

### macOS DMG (Recommended) ✅

Use the packaging script to create a distributable disk image:

```bash
./scripts/build-macos-dmg.sh
```

This script:
- Builds the app if needed
- Creates a styled DMG installer
- Outputs to `build-outputs/macOS/`

**Requirements**: Install `create-dmg` via `brew install create-dmg`

#### Manual DMG Creation

If you need more control:

```bash
# Build first
cmake -B build-macos -G Xcode \
  -D CMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY=''
cmake --build build-macos --config RelWithDebInfo

# Create DMG
cd build-macos
cpack -C RelWithDebInfo
```

Output: `build-macos/fallout1-rebirth.dmg`

### iOS IPA (Recommended) ✅

Use the packaging script to create a distributable iOS package:

```bash
./scripts/build-ios-ipa.sh
```

This script:
- Builds the app using `build-ios.sh`
- Runs CPack to create the IPA
- Outputs to `build-outputs/iOS/`

#### Manual IPA Creation

If you need more control:

```bash
# Build first
cmake -B build-ios \
  -D CMAKE_TOOLCHAIN_FILE=cmake/toolchain/ios.toolchain.cmake \
  -D ENABLE_BITCODE=0 \
  -D PLATFORM=OS64 \
  -G Xcode \
  -D CMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY=''
cmake --build build-ios --config RelWithDebInfo

# Create IPA
cd build-ios
cpack -C RelWithDebInfo
```

Output: `build-ios/fallout1-rebirth.ipa`

---

## Distribution Workflow

This project uses **local builds only** with manual GitHub Releases uploads. There is no automated CI/CD pipeline.

### Creating a Release

1. **Build the distribution packages locally:**
   ```bash
   # macOS DMG
   ./scripts/build-macos-dmg.sh
   
   # iOS IPA
   ./scripts/build-ios-ipa.sh
   ```

2. **Verify the outputs:**
   ```bash
   ls -la build-outputs/macOS/   # Contains .dmg
   ls -la build-outputs/iOS/     # Contains .ipa
   ```

3. **Upload to GitHub Releases:**
   - Go to the repository's Releases page
   - Create a new release with an appropriate version tag
   - Upload the DMG and IPA files from `build-outputs/`
   - Add release notes describing changes

### Why No CI/CD?

- **Code signing complexity**: iOS/macOS builds require Apple Developer credentials
- **Asset licensing**: Game data cannot be included in public builds
- **Simplicity**: Local builds give developers full control over the process

### Version Tags

When creating releases, use semantic versioning:
- `v1.0.0` — Major releases
- `v1.1.0` — Feature additions
- `v1.1.1` — Bug fixes

---

## Troubleshooting

### Common Issues

#### CMake cannot find Xcode

**Error**: `No CMAKE_CXX_COMPILER could be found`

**Solution**:
```bash
# Ensure Xcode is selected
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer

# Accept Xcode license
sudo xcodebuild -license accept
```

#### Missing iOS SDK

**Error**: `The iOS SDK could not be found`

**Solution**:
```bash
# Install iOS simulators and SDKs via Xcode
# Xcode -> Preferences -> Platforms -> + iOS
```

#### Build fails with "file not found"

**Error**: Missing header or source file

**Solution**: Ensure all source files are listed in `CMakeLists.txt` under `target_sources`.

#### App crashes on launch

**Solutions**:
1. Verify game data files are present (`master.dat`, `critter.dat`, `data/`)
2. Check file name case (must match `fallout.cfg` settings)
3. Enable ASAN to detect memory issues: `-DASAN=ON`

#### iOS Simulator won't boot

**Solutions**:
```bash
# Shutdown all simulators first
xcrun simctl shutdown all

# Check available simulators
xcrun simctl list devices available

# If disk full, delete old simulators
xcrun simctl delete unavailable
```

#### "Code Signing" errors

**Solution**: For local development, disable code signing:
```bash
-D CMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY=''
```

For distribution, set up proper signing via Xcode.

### Getting Help

1. Check the [ISSUES.md](../ISSUES.md) file for known issues
2. Review build output for specific error messages
3. Open an issue on GitHub with:
   - Your macOS/Xcode version
   - Complete build command used
   - Full error output

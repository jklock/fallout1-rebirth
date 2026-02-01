# Building from Source

Build instructions for Fallout 1 Rebirth on all supported platforms.

## Table of Contents

- [Prerequisites](#prerequisites)
- [macOS Build](#macos-build)
- [iOS Device Build](#ios-device-build)
- [iOS Simulator Build](#ios-simulator-build)
- [Build Configuration Options](#build-configuration-options)
- [Packaging](#packaging)
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

### Method 1: Using Build Script (Recommended)

The simplest way to build for macOS:

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

### Using Build Script (Recommended)

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

### macOS DMG

Create a distributable disk image:

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

### iOS IPA

Create a distributable iOS package:

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

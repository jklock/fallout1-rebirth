# Building from Source

Build instructions for Fallout 1 Rebirth on macOS and iOS.

## Prerequisites

| Software | Version | Installation |
|----------|---------|--------------|
| Xcode | 14.0+ | Mac App Store |
| Command Line Tools | current | `xcode-select --install` |
| CMake | 3.13+ | `brew install cmake` |

Optional:

| Software | Purpose |
|----------|---------|
| clang-format | code formatting |
| cppcheck | static analysis |

## Quick Start

### macOS build

```bash
# Production-style app (no embedded game data)
./scripts/build/build-macos.sh -prod

# Test-ready app (embed patched data/config into app)
./scripts/build/build-macos.sh -test --game-data /path/to/patchedfiles
```

Output:

```text
build-macos/RelWithDebInfo/Fallout 1 Rebirth.app
releases/prod/macOS/Fallout 1 Rebirth.app
```

### iOS build

```bash
# Device IPA (production-style)
./scripts/build/build-ios.sh -prod --device

# Simulator app only (production-style)
./scripts/build/build-ios.sh -prod --simulator

# Test-ready device + simulator artifacts (embed patched data/config)
./scripts/build/build-ios.sh -test --both --game-data /path/to/patchedfiles
```

Outputs:

```text
build-ios/<CONFIG>-iphoneos/fallout1-rebirth.app
build-ios-sim/<CONFIG>-iphonesimulator/fallout1-rebirth.app
build-outputs/iOS/*.ipa
```

For release staging used by this repo, copy the IPA into:

```text
releases/prod/iOS/fallout1-rebirth.ipa
```

## Build Script Options

### `scripts/build/build-macos.sh`

```bash
BUILD_TYPE=Debug ./scripts/build/build-macos.sh -prod
BUILD_TYPE=Release ./scripts/build/build-macos.sh -prod
BUILD_DIR=my-macos-build ./scripts/build/build-macos.sh -prod
JOBS=4 ./scripts/build/build-macos.sh -prod
CLEAN=1 ./scripts/build/build-macos.sh -prod
```

### `scripts/build/build-ios.sh`

```bash
BUILD_TYPE=Debug ./scripts/build/build-ios.sh -prod --device
BUILD_DIR_DEVICE=my-ios-device BUILD_DIR_SIM=my-ios-sim ./scripts/build/build-ios.sh -prod --both
JOBS=4 ./scripts/build/build-ios.sh -prod --simulator
CLEAN=1 ./scripts/build/build-ios.sh -prod --device
```

## Test Artifact Mode (`-test`)

`-test` builds embed patched game data/config into the app payload so the app can be launched immediately for validation.

Requirements:

- Provide `--game-data /path/to/patchedfiles`, or
- Set `GAME_DATA`, or
- Set `FALLOUT_GAMEFILES_ROOT` (uses `patchedfiles` under that root)

Minimum required files in the data source:

- `master.dat`
- `critter.dat`
- `data/`

## Manual CMake Build (fallback)

Use this only if you need direct CMake control.

### macOS

```bash
cmake -B build-macos -G Xcode \
  -D CMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY=''
cmake --build build-macos --config RelWithDebInfo -j "$(sysctl -n hw.physicalcpu)"
```

### iOS device

```bash
cmake -B build-ios \
  -D CMAKE_TOOLCHAIN_FILE=cmake/toolchain/ios.toolchain.cmake \
  -D ENABLE_BITCODE=0 \
  -D PLATFORM=OS64 \
  -G Xcode \
  -D CMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY=''
cmake --build build-ios --config RelWithDebInfo -j "$(sysctl -n hw.physicalcpu)"
```

### iOS simulator (Apple Silicon)

```bash
cmake -B build-ios-sim \
  -D CMAKE_TOOLCHAIN_FILE=cmake/toolchain/ios.toolchain.cmake \
  -D ENABLE_BITCODE=0 \
  -D PLATFORM=SIMULATORARM64 \
  -G Xcode \
  -D CMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY=''
cmake --build build-ios-sim --config RelWithDebInfo -j "$(sysctl -n hw.physicalcpu)"
```

## Packaging

This repository no longer provides a dedicated DMG script.

- iOS IPA packaging is handled by `scripts/build/build-ios.sh` (device target).
- macOS DMG packaging is manual (maintainer-managed).
- Production iOS payloads include `fallout.cfg` and `f1_res.ini` from `gameconfig/ios/`.

Example manual macOS package from an existing build directory:

```bash
cd build-macos
cpack -C RelWithDebInfo
```

## Distribution Workflow

1. Build local artifacts:
   - `./scripts/build/build-macos.sh -prod`
   - `./scripts/build/build-ios.sh -prod --device`
   - `cp build-outputs/iOS/fallout1-rebirth.ipa releases/prod/iOS/fallout1-rebirth.ipa`
2. Verify artifacts:
   - `./scripts/dev/dev-verify.sh --build-dir build-macos`
   - `./scripts/test/test-ios-headless.sh`
   - `./scripts/test/test-rme-config-packaging.sh`
3. Package macOS artifact manually (optional) and upload outputs to GitHub Releases.

## Troubleshooting

### Missing Xcode toolchain

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -license accept
```

### iOS SDK unavailable

Install simulator runtimes and SDK components from Xcode Settings > Platforms.

### App fails on launch

- Confirm `master.dat`, `critter.dat`, and `data/` are present.
- For `-test` mode, confirm `--game-data` points at patched payload.

### Build/test separation

- Build scripts (`scripts/build/*`) create artifacts.
- Test scripts (`scripts/test/*`) validate existing artifacts and do not compile binaries.

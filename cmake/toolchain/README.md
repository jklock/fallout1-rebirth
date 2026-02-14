# cmake/toolchain/

CMake toolchain files for cross-compilation to Apple platforms.

Last updated: 2026-02-14

## Contents

| File | Description |
|------|-------------|
| `ios.toolchain.cmake` | iOS and iOS Simulator cross-compilation toolchain |

## ios.toolchain.cmake

A comprehensive CMake toolchain file for building iOS applications. Based on the widely-used `ios-cmake` project with modifications for this project.

### Key Variables

| Variable | Description | Example Values |
|----------|-------------|----------------|
| `PLATFORM` | Target platform | `OS64` (device), `SIMULATORARM64` (Apple Silicon sim) |
| `ENABLE_BITCODE` | Bitcode embedding | `0` (disabled, deprecated by Apple) |
| `DEPLOYMENT_TARGET` | Minimum iOS version | `15.0` |

### Platform Values

| Value | Target |
|-------|--------|
| `OS64` | iOS device (arm64) |
| `SIMULATORARM64` | iOS Simulator on Apple Silicon |
| `SIMULATOR64` | iOS Simulator on Intel |

## Usage

### iOS Device Build

```bash
cmake -B build-ios \
  -D CMAKE_TOOLCHAIN_FILE=cmake/toolchain/ios.toolchain.cmake \
  -D PLATFORM=OS64 \
  -D ENABLE_BITCODE=0 \
  -G Xcode
```

### iOS Simulator Build (Apple Silicon)

```bash
cmake -B build-ios-sim \
  -D CMAKE_TOOLCHAIN_FILE=cmake/toolchain/ios.toolchain.cmake \
  -D PLATFORM=SIMULATORARM64 \
  -D ENABLE_BITCODE=0 \
  -G Xcode
```

## See Also

- [cmake/README.md](../README.md) - Parent directory documentation
- [scripts/build/build-ios.sh](../../scripts/build/build-ios.sh) - iOS build script
- [scripts/test/test-ios-simulator.sh](../../scripts/test/test-ios-simulator.sh) - Simulator testing script

---

## Proof of Work

**Last Verified**: 2026-02-07

**Files read to verify content**:
- cmake/toolchain/ios.toolchain.cmake (confirmed exists)
- scripts/build/build-ios.sh, scripts/test/test-ios-simulator.sh (confirmed exist)

**Updates made**: Refreshed deployment target example and verification date.

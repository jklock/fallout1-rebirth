# cmake/

CMake build system support files.

Last updated: 2026-02-14

## Structure

| Directory | Description |
|-----------|-------------|
| [toolchain/](toolchain/) | Cross-compilation toolchain files |

## toolchain/

### ios.toolchain.cmake

CMake toolchain file for iOS and iOS Simulator builds. Based on the popular `ios-cmake` project.

Key variables:
- `PLATFORM` - Target platform (OS64 for device, SIMULATORARM64 for Apple Silicon simulator)
- `ENABLE_BITCODE` - Bitcode embedding (set to 0, deprecated by Apple)
- `DEPLOYMENT_TARGET` - Minimum iOS version (this repo sets 15.0 in root CMakeLists.txt)

Usage:

```bash
cmake -B build-ios \
  -D CMAKE_TOOLCHAIN_FILE=cmake/toolchain/ios.toolchain.cmake \
  -D PLATFORM=OS64 \
  -G Xcode
```

For simulator on Apple Silicon:

```bash
cmake -B build-ios-sim \
  -D CMAKE_TOOLCHAIN_FILE=cmake/toolchain/ios.toolchain.cmake \
  -D PLATFORM=SIMULATORARM64 \
  -G Xcode
```

## Main CMakeLists.txt

The root `CMakeLists.txt` handles:

- Project configuration and C++17 standard
- Source file enumeration
- Third-party dependency fetching (SDL3, adecode, fpattern)
- Platform-specific build settings
- CPack configuration for DMG and IPA creation

---

## Proof of Work

**Last Verified**: 2026-02-07

**Files read to verify content**:
- cmake/toolchain/ (confirmed contains ios.toolchain.cmake)
- Root CMakeLists.txt (verified project structure and iOS target 15.0)

**Updates made**: Refreshed deployment target note and verification date.

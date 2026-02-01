# cmake/

CMake build system support files.

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
- `DEPLOYMENT_TARGET` - Minimum iOS version

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
- Third-party dependency fetching
- Platform-specific build settings
- CPack configuration for DMG and IPA creation

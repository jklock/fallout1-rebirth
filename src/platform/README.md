# src/platform/

Platform-specific code implementations.

## Structure

| Directory | Description |
|-----------|-------------|
| [ios/](ios/) | iOS and iPadOS specific code |

## ios/

iOS-specific path handling and system integration:

| File | Description |
|------|-------------|
| `paths.mm` | Objective-C++ file path resolution for iOS containers |
| `paths.h` | Path function declarations |

### iOS Path Resolution

On iOS, the app bundle is read-only. Game data files must be placed in the app's data container. The `paths.mm` file handles:

- Locating the Documents directory for user data
- Resolving paths to bundled resources
- Supporting the iOS sandbox model

## Adding Platform Support

This project supports macOS and iOS/iPadOS only. Android, Windows, and Linux are not supported (use upstream fallout1-ce for those platforms).

To add new platform-specific code:

1. Create a subdirectory under `platform/` (e.g., `platform/macos/`)
2. Add source files with platform-specific implementations
3. Use preprocessor guards or CMake conditions to include appropriately
4. Update `CMakeLists.txt` to include new sources for the target platform

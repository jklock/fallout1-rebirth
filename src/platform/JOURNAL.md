# JOURNAL: src/platform/

Last Updated: 2026-02-14

## Purpose

Platform-specific abstractions for iOS and macOS. Provides native integrations that can't be handled by SDL3 alone, including file system paths, Apple Pencil support, and iOS-specific behaviors.

## Recent Activity

### 2026-02-07
- Apple Pencil pressure sensitivity refined in `ios/pencil.mm`
- Coordinate mapping improvements for different display scales
- iOS file path handling for app containers

### Previous
- Initial Apple Pencil support added
- iOS document directory detection

## Directory Structure

| Directory | Purpose |
|-----------|---------|
| `ios/` | iOS/iPadOS specific implementations |

## Key Files

| File | Purpose |
|------|---------|
| `ios/paths.mm` | iOS file system paths (Documents, app bundle) |
| `ios/paths.h` | Path function declarations |
| `ios/pencil.mm` | Apple Pencil pressure/tilt handling |
| `ios/pencil.h` | Pencil API declarations |

## Development Notes

### For AI Agents

1. **Objective-C++**: Files use `.mm` extension for Obj-C++ interop
2. **iOS Sandboxing**: Apps can only write to Documents directory
3. **macOS**: Most platform code is cross-platform SDL3 in `plib/`
4. **Adding Features**: Create new files, add to CMakeLists.txt

### iOS File Paths (ios/paths.mm)

```objc
// Game data must be in Documents directory
NSString* documentsPath = NSSearchPathForDirectoriesInDomains(
    NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
```

Users copy game files to:
- **iOS**: Files app → Fallout 1 Rebirth folder
- **macOS**: Application's data directory

### Apple Pencil Support (ios/pencil.mm)

Provides pressure sensitivity for:
- Drawing in character editor
- Precision aiming in combat
- UI interactions

Pressure values: 0.0 (no pressure) to 1.0 (max pressure)
Falls back to touch if Pencil not detected.

### Adding New Platform Code

1. Create files in `platform/ios/` (or `platform/macos/` if needed)
2. Use `.mm` extension for Objective-C++
3. Add to CMakeLists.txt with platform guards:

```cmake
if(IOS)
    target_sources(${EXECUTABLE_NAME} PRIVATE
        src/platform/ios/newfile.mm
    )
endif()
```

### Testing Platform Code

```bash
# iOS - requires simulator or device
./scripts/test/test-ios-simulator.sh

# macOS
./scripts/test/test-macos.sh
```

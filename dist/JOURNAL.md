# JOURNAL: Distribution Files

Last Updated: 2026-02-14

## Purpose

Platform-specific distribution configuration files bundled into application releases. Contains default configurations and user documentation for DMG (macOS) and IPA (iOS) packages.

## Directory Structure

| Directory | Purpose |
|-----------|---------|
| `ios/` | iOS/iPadOS distribution files |
| `macos/` | macOS distribution files |

## Recent Activity

### 2026-02-07
- Created JOURNAL.md to track distribution configuration
- Both platforms have complete default configurations
- README files provide end-user setup instructions
- f1_res.ini and fallout.cfg defaults validated

### Previous
- Distribution structure established in Phase 5
- Platform-specific configs created for touch input (iOS) and desktop (macOS)

## Key Files

Both `ios/` and `macos/` directories contain:

| File | Purpose |
|------|---------|
| `README.md` | Markdown documentation |
| `README.txt` | Plain text end-user instructions |
| `f1_res.ini` | Resolution and display settings |
| `fallout.cfg` | Default game configuration |

## Build Integration

Files are copied into application bundles during CPack packaging:

- **macOS DMG**: Files go to `Contents/Resources/`
- **iOS IPA**: Files go to app bundle root

### CMake Integration

The root CMakeLists.txt handles file installation:

```cmake
if(APPLE)
    install(DIRECTORY ${CMAKE_SOURCE_DIR}/dist/macos/ 
            DESTINATION .)
endif()
```

## Development Notes

### For AI Agents

1. **Platform Differences**: iOS has touch-specific defaults, macOS has desktop defaults
2. **Bundle Location**: Check CPack configuration in CMakeLists.txt for file placement
3. **User Overrides**: Bundled files are defaults; users can override in Documents
4. **Testing**: Changes should be verified in packaged DMG/IPA, not just builds

### Configuration Hierarchy

At runtime, configuration files are loaded from:
1. User's Documents directory (highest priority)
2. Application bundle Resources (bundled defaults)
3. Built-in fallbacks (lowest priority)

### Testing Packaging

```bash
./scripts/build/build-macos-dmg.sh  # Build and package macOS DMG
./scripts/build/build-ios.sh && cd build-ios && cpack -C RelWithDebInfo  # iOS IPA
```

# os/ios/

iOS and iPadOS application bundle resources.

## Contents

| File | Description |
|------|-------------|
| `Info.plist` | iOS app configuration (bundle ID, version, capabilities) |
| `LaunchScreen.storyboard` | Launch screen UI definition |
| `AppIcon.xcassets/` | App icon asset catalog |

## Info.plist

Key configuration entries:

- Bundle identifier and version
- Required device capabilities
- Supported interface orientations
- iOS deployment target

## AppIcon.xcassets

Contains app icons at required sizes for:
- iPhone and iPad home screens
- App Store listing
- Spotlight search
- Settings

## LaunchScreen.storyboard

Defines the splash screen displayed while the app launches. Uses Auto Layout to support all device sizes.

## Build Integration

These resources are included in the iOS build via CMake's `MACOSX_BUNDLE` and `RESOURCE` properties. See the main `CMakeLists.txt` for configuration.

---

## Proof of Work

**Last Verified**: February 5, 2026

**Files read to verify content**:
- os/ios/Info.plist (confirmed exists)
- os/ios/LaunchScreen.storyboard (confirmed exists)
- os/ios/AppIcon.xcassets/ (confirmed exists)

**Updates made**: No updates needed - content verified accurate. All documented files present.

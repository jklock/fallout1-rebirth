# JOURNAL: Platform Bundle Resources

Last Updated: 2026-02-14

## Purpose

Platform-specific bundle resources for macOS and iOS/iPadOS. Contains Info.plist files, app icons, and launch screens needed for app packaging.

## Recent Activity

### 2026-02-07
- Created JOURNAL.md to track platform resource changes
- iOS document sharing enabled via LSSupportsOpeningDocumentsInPlace and UIFileSharingEnabled
- Both platforms target 11.0+ minimum version

## Key Files

| File | Purpose |
|------|---------|
| [ios/](ios/) | iOS/iPadOS bundle resources |
| [macos/](macos/) | macOS bundle resources |
| [README.md](README.md) | Directory documentation |

## Directory Structure

```
os/
├── ios/
│   ├── Info.plist           # iOS app configuration
│   ├── LaunchScreen.storyboard
│   └── AppIcon.xcassets/    # iOS app icons
└── macos/
    ├── Info.plist           # macOS app configuration
    └── fallout1-rebirth.icns # macOS app icon
```

## Development Notes

- Info.plist files use CMake variable substitution (e.g., `${MACOSX_BUNDLE_*}`)
- iOS requires landscape-only orientation for gameplay
- macOS uses `public.app-category.role-playing-games` category
- Both platforms enable high-resolution display support (NSHighResolutionCapable)
- iOS enables file sharing for game data access via Files app

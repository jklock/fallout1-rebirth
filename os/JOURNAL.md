# JOURNAL: Platform Bundle Resources

Last Updated: 2026-02-15

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

## 2026-02-15 Repository Sync
- Synced this journal to current repository state after deterministic SDL3 input hardening.
- Core input implementation commit: `c1accdf27927603e1d6b4c115dded9bac08c0a72`.
- LLM handoff summary commit: `fdc0f05f559c1d2f79706d395b6eae4b9ae4d48d`.
- Automated input evidence is recorded in `dev/state/latest-summary.tsv` and `dev/state/history.tsv` (latest PASS row: `2026-02-15T20:48:57Z`).
- iOS scripted touch evidence: `dev/state/logs/round-2-input-ios_headless-rerun.log`, `dev/state/logs/ios-touch-autotest-20260215T204516Z.patchlog.txt`, and screenshot `dev/state/logs/screens/ios-headless-com-fallout1rebirth-game-20260215T204510Z.png`.

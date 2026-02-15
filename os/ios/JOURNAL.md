# JOURNAL: iOS Bundle Resources

Last Updated: 2026-02-15

## Purpose

iOS/iPadOS-specific bundle resources. Contains Info.plist configuration, launch screen storyboard, and app icon assets for iOS builds.

## Recent Activity

### 2026-02-07
- Created JOURNAL.md to track iOS resource changes
- Document sharing enabled (LSSupportsOpeningDocumentsInPlace, UIFileSharingEnabled)
- iOS 15+ minimum deployment target (LSMinimumSystemVersion: 11.0 in plist, but CMake sets 15.0)
- Indirect input events supported (UIApplicationSupportsIndirectInputEvents)

## Key Files

| File | Purpose |
|------|---------|
| [Info.plist](Info.plist) | iOS app configuration with CMake variables |
| [LaunchScreen.storyboard](LaunchScreen.storyboard) | App launch screen UI |
| [AppIcon.xcassets/](AppIcon.xcassets/) | iOS app icon image assets |
| [README.md](README.md) | Directory documentation |

## Info.plist Key Settings

| Key | Value | Purpose |
|-----|-------|---------|
| `LSRequiresIPhoneOS` | true | iOS-only app |
| `UIFileSharingEnabled` | true | iTunes file sharing |
| `LSSupportsOpeningDocumentsInPlace` | true | Files app access |
| `UIStatusBarHidden` | true | Fullscreen gameplay |
| `UISupportedInterfaceOrientations` | Landscape only | Game orientation lock |
| `UIApplicationSupportsIndirectInputEvents` | true | Mouse/trackpad support |

## Development Notes

- Info.plist uses CMake substitution for bundle identifiers and version strings
- Landscape-only orientation for both iPhone and iPad
- File sharing enables users to add game data (master.dat, critter.dat) via Files app
- iPad is the primary target platform for this project
- Launch storyboard provides smooth app startup experience

## 2026-02-15 Repository Sync
- Synced this journal to current repository state after deterministic SDL3 input hardening.
- Core input implementation commit: `c1accdf27927603e1d6b4c115dded9bac08c0a72`.
- LLM handoff summary commit: `fdc0f05f559c1d2f79706d395b6eae4b9ae4d48d`.
- Automated input evidence is recorded in `dev/state/latest-summary.tsv` and `dev/state/history.tsv` (latest PASS row: `2026-02-15T20:48:57Z`).
- iOS scripted touch evidence: `dev/state/logs/round-2-input-ios_headless-rerun.log`, `dev/state/logs/ios-touch-autotest-20260215T204516Z.patchlog.txt`, and screenshot `dev/state/logs/screens/ios-headless-com-fallout1rebirth-game-20260215T204510Z.png`.

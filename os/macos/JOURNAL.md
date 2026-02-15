# JOURNAL: macOS Bundle Resources

Last Updated: 2026-02-15

## Purpose

macOS-specific bundle resources. Contains Info.plist configuration and app icon for macOS application bundle.

## Recent Activity

### 2026-02-07
- Created JOURNAL.md to track macOS resource changes
- macOS 11+ minimum deployment target (LSMinimumSystemVersion: 11.0)
- App category set to role-playing games

## Key Files

| File | Purpose |
|------|---------|
| [Info.plist](Info.plist) | macOS app configuration with CMake variables |
| [fallout1-rebirth.icns](fallout1-rebirth.icns) | macOS app icon (ICNS format) |
| [README.md](README.md) | Directory documentation |

## Info.plist Key Settings

| Key | Value | Purpose |
|-----|-------|---------|
| `LSMinimumSystemVersion` | 11.0 | macOS Big Sur minimum |
| `NSHighResolutionCapable` | True | Retina display support |
| `LSApplicationCategoryType` | public.app-category.role-playing-games | App Store category |
| `SDL_FILESYSTEM_BASE_DIR_TYPE` | parent | SDL file path behavior |

## Development Notes

- Info.plist uses CMake substitution for bundle identifiers, version strings, and copyright
- `CFBundleIconFile` references the .icns file for Dock and Finder icons
- macOS builds create a .app bundle, optionally packaged as DMG via CPack
- `SDL_FILESYSTEM_BASE_DIR_TYPE=parent` allows game to find data files relative to app bundle
- No file sharing keys needed - macOS users place game data adjacent to app or configure paths

## 2026-02-15 Repository Sync
- Synced this journal to current repository state after deterministic SDL3 input hardening.
- Core input implementation commit: `c1accdf27927603e1d6b4c115dded9bac08c0a72`.
- LLM handoff summary commit: `fdc0f05f559c1d2f79706d395b6eae4b9ae4d48d`.
- Automated input evidence is recorded in `dev/state/latest-summary.tsv` and `dev/state/history.tsv` (latest PASS row: `2026-02-15T20:48:57Z`).
- iOS scripted touch evidence: `dev/state/logs/round-2-input-ios_headless-rerun.log`, `dev/state/logs/ios-touch-autotest-20260215T204516Z.patchlog.txt`, and screenshot `dev/state/logs/screens/ios-headless-com-fallout1rebirth-game-20260215T204510Z.png`.

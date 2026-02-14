# JOURNAL: macOS Bundle Resources

Last Updated: 2026-02-14

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

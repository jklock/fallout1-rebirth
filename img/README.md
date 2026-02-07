# Project Images

**Last Updated:** 2026-02-07

## Purpose

Contains logo files and visual assets used for project branding and distribution packaging.

## Contents

| File/Directory | Description |
|----------------|-------------|
| `RebirthLogo.png` | Main project logo |
| `RebirthIconLogo.png` | Icon-sized logo variant |
| `dmg_files/` | macOS DMG installer assets |

### DMG Files

| File | Description |
|------|-------------|
| `dmgbackground.png` | Background image for macOS DMG installer window |
| `Game Manual.pdf` | Original Fallout game manual |
| `Ref Card.pdf` | Quick reference card |
| `Survival Guide.pdf` | Game survival guide |

## Usage

- Logo files are used in documentation and README
- DMG assets are bundled during `cpack` for macOS distribution
- PDF manuals are included as extras in the DMG installer

## Notes

- App icons are located in `os/ios/AppIcon.xcassets/` and `os/macos/`
- See `scripts/build/build-macos-dmg.sh` for DMG creation process

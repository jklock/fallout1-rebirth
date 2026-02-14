# Project Images

**Last Updated:** 2026-02-14

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
- DMG assets are bundled during maintainer-managed macOS packaging
- PDF manuals are included as extras in the DMG installer

## Notes

- App icons are located in `os/ios/AppIcon.xcassets/` and `os/macos/`
- macOS DMG creation is performed manually from an existing macOS build directory

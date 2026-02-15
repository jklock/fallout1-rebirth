# Images Directory Journal

Last updated (UTC): 2026-02-15


> AI Context File - Development history and decisions for `img/`

## Purpose

Project images and branding assets for documentation and packaging.

## Directory Structure

```
img/
├── README.md
├── RebirthLogo.png         # Main project logo (used in README)
├── RebirthIconLogo.png     # Icon variant of logo
└── dmg_files/
    └── background.png      # DMG installer background image
```

## Asset Usage

### RebirthLogo.png
- Displayed in project README.md
- Main branding image for the project

### RebirthIconLogo.png
- Icon-style variant of the logo
- Square format suitable for icons

### dmg_files/background.png
- Background image for macOS DMG installer
- Referenced by CPack during DMG creation
- Shows installation instructions visually

## Related Files

- [/README.md](../README.md) - Uses RebirthLogo.png
- [/CMakeLists.txt](../CMakeLists.txt) - CPack DMG configuration
- [/os/ios/AppIcon.xcassets/](../os/ios/AppIcon.xcassets/) - iOS app icons (separate from these images)
- [/os/macos/](../os/macos/) - macOS app resources

## Notes

- Keep images optimized for web/packaging size
- Logo assets should maintain consistent branding
- DMG background should work at various resolutions

---

## Changelog

### 2026-02-07
- Created JOURNAL.md for img directory
- Documents branding assets and DMG packaging images

## 2026-02-15 Repository Sync
- Synced this journal to current repository state after deterministic SDL3 input hardening.
- Core input implementation commit: `c1accdf27927603e1d6b4c115dded9bac08c0a72`.
- LLM handoff summary commit: `fdc0f05f559c1d2f79706d395b6eae4b9ae4d48d`.
- Automated input evidence is recorded in `dev/state/latest-summary.tsv` and `dev/state/history.tsv` (latest PASS row: `2026-02-15T20:48:57Z`).
- iOS scripted touch evidence: `dev/state/logs/round-2-input-ios_headless-rerun.log`, `dev/state/logs/ios-touch-autotest-20260215T204516Z.patchlog.txt`, and screenshot `dev/state/logs/screens/ios-headless-com-fallout1rebirth-game-20260215T204510Z.png`.

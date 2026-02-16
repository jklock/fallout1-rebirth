# Images Directory Journal

Last updated (UTC): 2026-02-14


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

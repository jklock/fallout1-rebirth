# JOURNAL: macOS Distribution Files

Last Updated: 2026-02-14

## Purpose

macOS-specific distribution files bundled into the DMG release. Contains default configurations for desktop usage and end-user documentation.

## Contents

| File | Purpose |
|------|---------|
| `README.md` | Markdown documentation for macOS users |
| `README.txt` | Plain text end-user instructions |
| `f1_res.ini` | Resolution and display settings for macOS |
| `fallout.cfg` | Default game configuration |

## Recent Activity

### 2026-02-07
- Created JOURNAL.md to track macOS distribution changes
- Desktop-optimized defaults for mouse/keyboard input
- Resolution settings support Retina displays
- Documentation includes dragging .app to Applications

### Previous
- macOS distribution structure established in Phase 5
- DMG packaging via CPack configured
- VSync enabled by default for tear-free rendering

## Key Configuration

### f1_res.ini

macOS-specific settings include:
- Native resolution detection
- VSync enabled for ProMotion displays
- Desktop window mode options
- High-DPI/Retina support

### fallout.cfg

Standard game configuration with:
- Data file paths (master.dat, critter.dat)
- Audio preferences
- Game options

## Build Integration

Files are bundled into the DMG via CPack:

```
Fallout1-Rebirth.dmg
├── Fallout1-Rebirth.app/
├── README.md
├── README.txt
├── f1_res.ini
└── fallout.cfg
```

## Development Notes

### For AI Agents

1. **Desktop Input**: No touch offsets needed - standard mouse/keyboard
2. **DMG Packaging**: CPack creates installer DMG with app and configs
3. **Retina Support**: High-DPI rendering enabled via SDL3 and Info.plist
4. **Bundle Placement**: Files go to Contents/Resources and DMG root

### DMG Creation

```bash
./scripts/build/build-macos-dmg.sh  # Full DMG build
# Or manually:
cmake -B build-macos -G Xcode
cmake --build build-macos --config RelWithDebInfo
cd build-macos && cpack -C RelWithDebInfo
```

### Testing

```bash
./scripts/test/test-macos.sh  # Build and test macOS app
./scripts/build/build-macos-dmg.sh  # Verify DMG packaging
```

### Related Files

- [dist/ios/](../ios/) - iOS distribution files  
- [os/macos/](../../os/macos/) - macOS bundle resources (Info.plist, icon)
- [gameconfig/macos/](../../gameconfig/macos/) - Development config templates

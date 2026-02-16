# JOURNAL: iOS Distribution Files

Last Updated: 2026-02-14

## Purpose

iOS/iPadOS-specific distribution files bundled into the IPA release. Contains default configurations optimized for touch input and end-user documentation.

## Contents

| File | Purpose |
|------|---------|
| `README.md` | Markdown documentation for iOS users |
| `README.txt` | Plain text end-user instructions |
| `f1_res.ini` | Resolution and display settings for iOS |
| `fallout.cfg` | Default game configuration |

## Recent Activity

### 2026-02-07
- Created JOURNAL.md to track iOS distribution changes
- Click offset defaults configured for touch input accuracy
- iPad-optimized resolution settings in f1_res.ini
- Documentation includes game data installation via Files app

### Previous
- iOS distribution structure established in Phase 5
- Touch input defaults validated on iPad Simulator
- File sharing enabled in Info.plist for game data access

## Key Configuration

### f1_res.ini

iOS-specific settings include:
- Touch-optimized click offsets
- iPad resolution defaults
- Landscape-only display orientation
- VSync enabled for smooth 60fps

### fallout.cfg

Standard game configuration with:
- Data file paths (master.dat, critter.dat)
- Audio preferences
- Game options

## Development Notes

### For AI Agents

1. **Touch Input**: Click offset settings compensate for finger occlusion
2. **File Location**: Users access game data via Files app (UIFileSharingEnabled)
3. **iPad Primary**: iPad is the primary iOS target - test on iPad Simulator
4. **Bundle Placement**: Files are copied to IPA root during CPack

### Click Offset Defaults

The f1_res.ini includes touch-specific offsets:
```ini
; Touch input click offset (compensates for finger covering target)
CLICK_OFFSET_X=0
CLICK_OFFSET_Y=-10
```

### Testing

```bash
./scripts/test/test-ios-simulator.sh  # Full iOS test flow
./scripts/build/build-ios.sh && cd build-ios && cpack -C RelWithDebInfo  # Build IPA
```

### Related Files

- [dist/macos/](../macos/) - macOS distribution files
- [os/ios/](../../os/ios/) - iOS bundle resources (Info.plist, icons)
- [gameconfig/ios/](../../gameconfig/ios/) - Development config templates

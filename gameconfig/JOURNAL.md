# Game Configuration Journal

Last updated (UTC): 2026-02-15


> AI Context File - Development history and decisions for `gameconfig/`

## Purpose

Platform-specific game configuration templates bundled with releases.

## Directory Structure

```
gameconfig/
├── README.md
├── ios/
│   ├── f1_res.ini        # Resolution and display settings
│   ├── fallout.cfg       # Game engine configuration
│   └── fallout.ini       # Additional game settings
└── macos/
    ├── f1_res.ini        # Resolution and display settings
    └── fallout.cfg       # Game engine configuration
```

## Configuration Files

### f1_res.ini
Display and resolution settings:
- `MAIN_MENU_SIZE` - Main menu scaling
- `IFACE_BAR_MODE` - Interface bar behavior
- `SCALE_2X` - Pixel scaling option
- `WINDOWED` - Windowed vs fullscreen
- `GRAPHICS_WIDTH/HEIGHT` - Resolution override

### fallout.cfg
Core game engine settings:
- `master_dat` / `critter_dat` - Game data paths
- `music_path` / `sound_path` - Audio paths
- `click_offset_x` / `click_offset_y` - Touch coordinate fixes
- `device_type` - Input device configuration
- `text_base_delay` - Text display timing

### fallout.ini
Additional game settings (iOS only):
- Extended configuration options
- Platform-specific overrides

## Key Settings

### Click Offset (Touch Fix)
```ini
click_offset_x=0
click_offset_y=0
```
Corrects touch coordinate mapping on iOS. Values may need adjustment based on device/resolution.

### VSync
VSync is enabled by default in the engine (not in config files).

## Related Files

- [/src/plib/gnw/gnw.cc](../src/plib/gnw/gnw.cc) - Config loading code
- [/development/bugfixes/](../development/bugfixes/) - Bug fix research

---

## Changelog

### 2026-02-07
- Created JOURNAL.md for gameconfig directory
- Documents platform-specific configuration structure
- Notes click offset and VSync settings

## 2026-02-15 Repository Sync
- Synced this journal to current repository state after deterministic SDL3 input hardening.
- Core input implementation commit: `c1accdf27927603e1d6b4c115dded9bac08c0a72`.
- LLM handoff summary commit: `fdc0f05f559c1d2f79706d395b6eae4b9ae4d48d`.
- Automated input evidence is recorded in `dev/state/latest-summary.tsv` and `dev/state/history.tsv` (latest PASS row: `2026-02-15T20:48:57Z`).
- iOS scripted touch evidence: `dev/state/logs/round-2-input-ios_headless-rerun.log`, `dev/state/logs/ios-touch-autotest-20260215T204516Z.patchlog.txt`, and screenshot `dev/state/logs/screens/ios-headless-com-fallout1rebirth-game-20260215T204510Z.png`.

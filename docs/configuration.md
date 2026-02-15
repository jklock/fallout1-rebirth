# Configuration Reference

Runtime configuration is loaded from the game data directory:

- `fallout.cfg`
- `f1_res.ini`

Platform templates ship in:

- `gameconfig/macos/`
- `gameconfig/ios/`

## f1_res.ini

### [MAIN]

- `SCR_WIDTH`
- `SCR_HEIGHT`
- `WINDOWED`
- `EXCLUSIVE`
- `SCALE_2X`

### [DISPLAY]

- `VSYNC`
- `FPS_LIMIT`

### [INPUT]

- `CLICK_OFFSET_X`
- `CLICK_OFFSET_Y`
- `CLICK_OFFSET_MOUSE_X`
- `CLICK_OFFSET_MOUSE_Y`

### Display Timing Rules

- `VSYNC=1`: enable renderer VSync.
- `VSYNC=0`: disable renderer VSync.
- `FPS_LIMIT=-1`: use display refresh.
- `FPS_LIMIT=0`: uncap (disable shared FPS limiter).
- `FPS_LIMIT>0`: explicit cap in Hz.

### Shipped Defaults

- macOS: `SCR_WIDTH=1024`, `SCR_HEIGHT=768`, `WINDOWED=1`, `SCALE_2X=1`, `VSYNC=1`, `FPS_LIMIT=-1`
- iOS/iPadOS: `SCR_WIDTH=1024`, `SCR_HEIGHT=768`, `WINDOWED=0`, `SCALE_2X=1`, `VSYNC=1`, `FPS_LIMIT=-1`

## fallout.cfg

Templates expose the unpatched baseline keyset (plus `debug.rme_log`) across:

- `[system]`
- `[sound]`
- `[preferences]`
- `[debug]`
- `[input]`

Canonical baseline manifests:

- `docs/audit/key-manifests/unpatched-f1_res.keys`
- `docs/audit/key-manifests/unpatched-fallout.cfg.keys`

Automated validation gate:

- `scripts/test/test-rme-config-surface.py`
- `scripts/test/test-rme-config-compat.sh`
- `scripts/test/test-rme-config-packaging.sh`

## Legacy Compatibility

- `preferences.player_speed` is backfilled to `preferences.player_speedup` when needed.
- `preferences.combat_looks` is backfilled to `preferences.running_burning_guy` when needed.

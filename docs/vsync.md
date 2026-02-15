# VSync and Frame Pacing

Runtime now reads and applies display timing keys from `f1_res.ini`:

- `[DISPLAY] VSYNC`
- `[DISPLAY] FPS_LIMIT`

## Behavior

- `VSYNC=1`: enables renderer VSync.
- `VSYNC=0`: disables renderer VSync.
- `FPS_LIMIT=-1`: uses current display refresh rate.
- `FPS_LIMIT=0`: uncapped (disables shared FPS limiter).
- `FPS_LIMIT>0`: explicit cap in Hz.

## Runtime Path

- Parse: `src/game/game.cc` (`f1_res.ini` load).
- Apply: `src/plib/gnw/svga.cc` (`svga_set_vsync`, `svga_set_fps_limit`, renderer init).

## Notes

- The shared `FpsLimiter` is used by many UI/game loops.
- See `docs/configuration.md` for full config key coverage.

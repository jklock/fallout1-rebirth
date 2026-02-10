# Landmark: macOS "Black Map After Load" (2026-02-08)

## Symptom
- Menus and character creation render normally.
- After loading into the playable map: UI and player sprite render, but the world (tiles) is black.

## Root Cause
The macOS `f1_res.ini` template defaulted to `SCALE_2X=0`, which makes the engine start at a 1280x960 *logical* resolution (scale=1).

The classic Fallout renderer expects 640x480 logical with a 2x scale (1280x960 window). With scale=1, the map render/dirty-rect flow can result in the world staying black even while UI/actors still update.

Evidence we used while debugging:
- Working run: `svga_init: starting with 640x480 (scale=2)`
- Broken run: `svga_init: starting with 1280x960 (scale=1)`

## Fix (Systemic)
Set `SCALE_2X=1` in the templates used for macOS installs/builds:
- `gameconfig/macos/f1_res.ini`
- `dist/macos/f1_res.ini`

Implemented in commit `0e9e132`.

## Install (macOS)
The known-good build bundle was installed into `/Applications`:
- Source: `build-macos/RelWithDebInfo/Fallout 1 Rebirth.app`
- Destination: `/Applications/Fallout 1 Rebirth.app`

We removed debug frame dumps (`present_*.bmp`, `scr*.bmp`) from the build bundle before copying to keep the installed app clean.

## Debug Hooks Used
The build includes env-var hooks used during this investigation:
- `F1R_PATCHLOG=1` and `F1R_PATCHLOG_PATH=...` (example output: `development/RME/validation/runtime/patchlogs/f1r-patchlog-scale2x1.txt`)
- `F1R_PRESENT_DUMP(_FRAMES)=...`
- `F1R_AUTORUN_*` (map-load automation)

## Related RME Validation Work (ISSUE-LST-002)
During the same session we also captured validation/mapping artifacts for fixing `.LST` reference drift:
- Commented obsolete `INTRFACE.LST` entries marked "NO LONGER USED": commit `a748601`
- Added action mapping CSV for missing tokens: commit `a2e0e68`
- Added enriched validation/fixer docs for scripted mapping workflows: commit `f42723b`


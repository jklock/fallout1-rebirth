# Runtime Map Sweep

This sweep loads every MAP via `F1R_AUTORUN_MAP` and captures a `dump_screen()` BMP via `F1R_AUTOSCREENSHOT`.
It is a smoke test for runtime load regressions (missing assets/scripts and black-world-after-load symptoms).

- Executable: `/Volumes/Storage/GitHub/fallout1-rebirth/build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth`
- Data root: `/Volumes/Storage/GitHub/fallout1-rebirth/build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/Resources`
- Total maps: **72**
- Failures (nonzero exit): **0**
- Suspicious screenshots: **5**

## Outputs
- CSV: `/Volumes/Storage/GitHub/fallout1-rebirth/development/RME/validation/runtime/runtime_map_sweep.csv`
- Run log: `/Volumes/Storage/GitHub/fallout1-rebirth/development/RME/validation/runtime/runtime_map_sweep_run.log`
- Screenshots (fail/suspicious only): `/Volumes/Storage/GitHub/fallout1-rebirth/development/RME/validation/runtime/screenshots`

## Suspicious Screenshots
- `CARAVAN.MAP`
- `TEMPLAT1.MAP`
- `ZDESERT1.MAP`
- `ZDESERT2.MAP`
- `ZDESERT3.MAP`

## Note
- Recent render-pipeline instrumentation detected `surf_pre>0 && surf_post==0` transitions correlated with `WIN_FILL_RECT` operations in several runs. An atomic "composite-fill" fix was implemented to apply background fills and restore overlapping map pixels in a single blit, and the crash caused by a double-free in that code path has been fixed (see `development/RME/validation/raw/13_render_pipeline_fix.md`). Re-run the sweep with `TIMEOUT=90` and `F1R_PATCHLOG=1 F1R_PATCHLOG_VERBOSE=1` to validate that the number of suspicious screenshots decreases and run `scripts/dev/patchlog_analyze.py` against the produced patchlogs for automated verification.


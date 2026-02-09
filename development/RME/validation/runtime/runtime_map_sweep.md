# Runtime Map Sweep

This sweep loads every MAP via `F1R_AUTORUN_MAP` and captures a `dump_screen()` BMP via `F1R_AUTOSCREENSHOT`.
It is a smoke test for runtime load regressions (missing assets/scripts and black-world-after-load symptoms).

- Executable: `/Volumes/Storage/GitHub/fallout1-rebirth/build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth`
- Data root: `/Volumes/Storage/GitHub/fallout1-rebirth/build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/Resources`
- Total maps: **72**
- Failures (nonzero exit): **0**
- Suspicious screenshots: **0**

## Outputs
- CSV: `/Volumes/Storage/GitHub/fallout1-rebirth/development/RME/validation/runtime/runtime_map_sweep.csv`
- Run log: `/Volumes/Storage/GitHub/fallout1-rebirth/development/RME/validation/runtime/runtime_map_sweep_run.log`


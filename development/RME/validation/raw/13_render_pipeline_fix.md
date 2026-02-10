# Render pipeline instrumentation & composite-fill fix

## Summary

- Implemented per-stage render instrumentation to trace where non-zero pixels vanish between tile draw and final presentation.
- Added an atomic composite-fill to prevent transient fills from overwriting freshly-drawn map pixels during presentation.
- A double-free in the composite-fill path caused a crash during validation; that double-free was fixed and the change is committed.

## Key files changed

- `src/plib/gnw/svga.cc`
  - New patchlog tags and telemetry: `GNW_SHOW_RECT_SRC`, enhanced `GNW_SHOW_RECT` (pre/post counts), `GNW_SURF_SUSPECT` ring buffer, present sampling + `RENDER_PRESENT_ANOMALY` (saves `development/RME/validation/runtime/present-anomalies/f1r-present-anom-*.bmp`).
- `src/plib/gnw/gnw.cc`
  - `WIN_FILL_RECT` instrumentation; implemented composite-fill atomic blit (create `compBuf`, overlay map pixels, single `scr_blit`). Added `DEBUG_MEM`, `DEBUG_COPY`, `DEBUG_COPY_ROW` messages for tracing. Fixed double-free (commit: `gnw: avoid double-free in WIN_FILL_RECT composite path`).
- `scripts/dev/patchlog_analyze.py`
  - Analyzer that scans for `GNW_SHOW_RECT` events where `surf_pre>0 && surf_post==0` and correlates with nearest prior `GNW_SHOW_RECT_SRC`, `WIN_FILL_RECT`, and `MAP_SCROLL_MEMMOVE` entries.
- `src/game/map.cc`
  - Added `map_count_display_non_zero` diagnostics and `map_display_draw()` now calls `win_refresh_all(rect)` earlier to process fills before display blit.

## Reproduction & validation

1. Build:

```bash
./scripts/build/build-macos.sh
```

2. Single-map autorun (with game data installed in app bundle or using `GAME_DATA`):

```bash
F1R_AUTORUN_MAP=CARAVAN.MAP \
  F1R_AUTOSCREENSHOT=1 F1R_PATCHLOG=1 F1R_PATCHLOG_VERBOSE=1 \
  F1R_PATCHLOG_PATH=/tmp/f1r-patchlog-CARAVAN.txt \
  ./build-macos/RelWithDebInfo/Fallout\ 1\ Rebirth.app/Contents/MacOS/fallout1-rebirth
```

3. Analyze the generated patchlog:

```bash
python3 scripts/dev/patchlog_analyze.py /tmp/f1r-patchlog-CARAVAN.txt
```

4. If a `RENDER_PRESENT_ANOMALY` was recorded, check `development/RME/validation/runtime/present-anomalies/f1r-present-anom-*.bmp` for the presented frame and use the patchlog analyzer output to correlate.

## Current status

- Composite-fill implemented and the crash (free of `buf` twice) was fixed; the fix is committed on branch `fix/ISSUE-LST-002-comment-no-longer-used` (commit message: `gnw: avoid double-free in WIN_FILL_RECT composite path (defer buf free to single location)`).
- Local builds succeed and the crash no longer reproduces in quick sanity runs.
- Remaining validation: re-run `CARAVAN.MAP` autorun and the full runtime sweep with `TIMEOUT=90` and `F1R_PATCHLOG=1 F1R_PATCHLOG_VERBOSE=1` and run `scripts/dev/patchlog_analyze.py` across produced patchlogs to confirm `surf_pre>0 && surf_post==0` cases are eliminated.

## ASAN build note

- Attempting an ASAN-enabled build previously failed at CMake configure due to a FetchContent failure when fetching SDL. If network fetch fails, clone SDL locally and retry:

```bash
git clone https://github.com/libsdl-org/SDL third_party/sdl3/SDL
cd third_party/sdl3/SDL && git checkout release-3.4.0
cmake -S . -B build-macos-asan -DASAN=ON -DCMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build build-macos-asan --config RelWithDebInfo -j $(sysctl -n hw.physicalcpu)
```

## Where to look for artifacts

- Patchlogs: captured when autorun: `F1R_PATCHLOG_PATH` (e.g., `/tmp/f1r-patchlog-CARAVAN.txt`).
- Anomaly screenshots: `development/RME/validation/runtime/present-anomalies/f1r-present-anom-*.bmp`.
- Runtime sweep outputs: `development/RME/validation/runtime/*`.

---

If you want, I can now push the branch, open a PR, and merge — then start re-running the runtime sweep and ASAN build in parallel and capture updated validation artifacts.
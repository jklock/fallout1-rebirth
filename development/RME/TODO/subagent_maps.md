# Subagent: Maps — flaky-map repeats + full 72‑map runtime sweep (fully automated)

Purpose
- Reproduce and triage flaky maps (CARAVAN, ZDESERT1, TEMPLAT1), then perform a complete automated sweep of all 72 maps and produce `runtime_map_sweep.csv`, per-map patchlogs and screenshots for triage.

Non-interactive commands (exact)
- Repeats (non-interactive with patchlog):
  - export APP="build-macos/RelWithDebInfo/Fallout 1 Rebirth.app"
  - export EXE="$APP/Contents/MacOS/fallout1-rebirth"
  - ./scripts/patch/rme-repeat-map.sh CARAVAN 10
  - ./scripts/patch/rme-repeat-map.sh ZDESERT1 10
  - ./scripts/patch/rme-repeat-map.sh TEMPLAT1 10
- Full 72-map sweep (patchlog enabled):
  - export F1R_PATCHLOG=1
  - python3 scripts/patch/rme-runtime-sweep.py --exe "$EXE" --timeout 120 --out-dir development/RME/ARTIFACTS/evidence/runtime

Important env hooks (engine-side)
- F1R_AUTORUN_MAP (set by scripts)
- F1R_AUTOSCREENSHOT=1
- F1R_PATCHLOG=1 → engine writes per-map patchlog to F1R_PATCHLOG_PATH
- F1R_PRESENT_ANOM_DIR → engine will write present-anomaly BMPs

Where outputs land (evidence)
- development/RME/ARTIFACTS/evidence/gate-2/repeats/
- development/RME/ARTIFACTS/evidence/runtime/
  - runtime_map_sweep.csv
  - patchlogs/*.patchlog.txt
  - screenshots/*.bmp
  - patchlogs/patchlog_summary.csv and `*.patchlog_analyze.txt`

Acceptance criteria
- CARAVAN, ZDESERT1, TEMPLAT1: each returns 10/10 PASS (rme-repeat-map.sh exit 0).
- runtime_map_sweep.csv contains 72 data rows (1 header + 72 rows) and no map has non-zero exit_code.
- Any map with exit_code != 0 must have a corresponding `.patchlog.txt` and `.patchlog_analyze.txt` explaining the failure.

If a flaky map fails
1. Capture the run log, patchlog, and `patchlog_analyze.py` output into `development/RME/ARTIFACTS/evidence/gate-2/repeats/`.
2. If patchlog shows `DB_OPEN_FAIL` or `missing FRM`, mark as data/packaging issue; otherwise flag as engine/gnw anomaly.

Subagent prompt (use this EXACT prompt when launching a subagent to run map tasks)

"Reproduce flaky maps and run a full automated runtime sweep. Steps:
1) Ensure patched app exists at `build-macos/RelWithDebInfo/Fallout 1 Rebirth.app` (fail early if not).
2) Run `./scripts/patch/rme-repeat-map.sh CARAVAN 10`, capture run log, patchlog and `patchlog_analyze` output.
3) Repeat for ZDESERT1 and TEMPLAT1.
4) Set `F1R_PATCHLOG=1` and run the sweep: `python3 scripts/patch/rme-runtime-sweep.py --exe "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth" --timeout 120 --out-dir development/RME/ARTIFACTS/evidence/runtime`.
5) Run `python3 scripts/dev/patchlog_analyze.py` on any produced patchlogs.

Return a JSON summary: `repeats` (per-map: pass_count, fail_count, paths to logs), `sweep_row_count`, `sweep_failures` (list), `suspicious_maps` (list), and `artifacts` (paths). If any test fails, include exact analyzer excerpts and recommend: data-fix / packaging-fix / engine-fix."
# Final End-to-End Validation Progress

Date: 2026-02-14
Repo: `fallout1-rebirth`
Scenario: Fresh-user full workflow from clean build + fresh patch output in `newpatchedfiles`.

## Task Checklist
- [x] Align script/docs references with renamed installer (`build-install-game-data.sh`).
- [x] Build a brand-new macOS `.app` from a clean build directory.
- [x] Rebuild patched payload into `/Volumes/Storage/GitHub/fallout1-rebirth-gamefiles/newpatchedfiles` from `unpatchedfiles`.
- [x] Compare `newpatchedfiles` vs existing `patchedfiles` for exact 1:1 parity.
- [x] If mismatch: remediate scripts and re-run until parity is exact.
- [x] Install `newpatchedfiles` into the new `.app`.
- [x] Run full end-to-end patched-feature validation suite (runtime + asset + patchlog/log sweeps, full game executable path).
- [x] Confirm all validations pass and record evidence.

## Execution Log
- 2026-02-14 19:45:24 UTC: Started final validation pass.
- 2026-02-14 19:45:24 UTC: Updated renamed installer references in scripts/docs:
  - `scripts/build/build-macos.sh`
  - `scripts/test/test-rme-ensure-patched-data.sh`
  - `scripts/build/build-install-game-data.sh` (usage/help examples)
  - `scripts/build/README.md`
  - `docs/scripts.md`
  - `docs/features.md`
- 2026-02-14 19:52:12 UTC: Built fresh app from clean tree:
  - `build-macos/RelWithDebInfo/Fallout 1 Rebirth.app`
- 2026-02-14 19:55:40 UTC: Rebuilt fresh patch payload:
  - `./scripts/patch/patch-rebirth-data.sh --base /Volumes/Storage/GitHub/fallout1-rebirth-gamefiles/unpatchedfiles --out /Volumes/Storage/GitHub/fallout1-rebirth-gamefiles/newpatchedfiles --config-dir gameconfig/macos --force`
- 2026-02-14 19:57:10 UTC: Initial parity compare found two deterministic deltas vs current `patchedfiles`:
  - `fallout.cfg` hash mismatch (template vs current working config)
  - missing loose `data/maps/CARAVAN.MAP` in fresh output
- 2026-02-14 19:59:25 UTC: Remediated pipeline for 1:1 parity target:
  - updated `gameconfig/macos/fallout.cfg` to current working config baseline
  - updated `scripts/patch/patch-rebirth-data.sh` to materialize `data/maps/CARAVAN.MAP` from patched `master.dat` during patch flow
- 2026-02-14 20:05:27 UTC: Re-ran patch flow and confirmed parity:
  - `MANIFEST_MATCH=1` across `master.dat`, `critter.dat`, `fallout.cfg`, `f1_res.ini`, and all files under `data/`
  - `rsync -anc` compare (excluding runtime artifacts `scr*.bmp` + `rme.log`) returned clean
- 2026-02-14 20:10:00 UTC: Installed rebuilt payload into fresh app:
  - `./scripts/build/build-install-game-data.sh --source /Volumes/Storage/GitHub/fallout1-rebirth-gamefiles/newpatchedfiles --target build-macos/RelWithDebInfo/Fallout\ 1\ Rebirth.app`
- 2026-02-14 20:13:30 UTC: Integration checks passed:
  - `scripts/test/test-rme-working-dir.sh` PASS
  - `scripts/test/test-rme-patchflow.sh --autorun-map CARAVAN.MAP` PASS
- 2026-02-14 20:15:00 UTC: Full E2E run found script defect and was remediated:
  - `scripts/test/test-rme-audit-script-refs.py` failed with `NameError: os is not defined`
  - fixed by adding missing `import os`
- 2026-02-14 21:21:00 UTC: Full runtime validation (`run3`) completed successfully:
  - `runtime_map_sweep.csv`: 72/72 maps, `nonzero_exit=0`
  - `runtime_map_sweep_run.log`: `FULL_LOAD_FAIL=0`, `suspicious=0`
  - `asset_sweep.json`: `Overlay failures: 0`
- 2026-02-14 21:24:00 UTC: Final-stage script defects remediated:
  - `scripts/test/test-rme-end-to-end.sh`: defaulted `F1R_PATCHLOG_VERBOSE` to `0` (fixes timeout-heavy runs)
  - `scripts/test/test-rme-log-sweep.sh`: executable bit restored + data-root fallback + grep no-match safe handling
  - `scripts/test/test-rme-gui-drive.sh`: executable bit restored + data-root fallback + grep no-match safe handling
- 2026-02-14 21:33:54 UTC: Final non-headless feature sweeps passed:
  - `scripts/test/test-rme-log-sweep.sh` PASS (all topic runs completed, logs emitted)
  - `scripts/test/test-rme-gui-drive.sh` PASS (GUI launch/input drive + `gui.log` captured)
- 2026-02-14 21:39:43 UTC: Final logging/GUI quality fixes applied and re-validated:
  - `scripts/test/test-rme-log-sweep.sh`: corrected `all` topic value (`RME_LOG=all` instead of `1`)
  - `scripts/test/test-rme-gui-drive.sh`: corrected GUI run topic value (`RME_LOG=all`)
  - re-ran both scripts successfully against `newpatchedfiles`; confirmed non-empty `all.log`, `db_config.log`, and `gui.log` outputs
  - note: runtime/GUI runs mutate `fallout.cfg`; strict 1:1 payload parity was validated and recorded before runtime execution

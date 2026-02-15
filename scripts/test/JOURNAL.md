# JOURNAL: scripts/test

Last updated (UTC): 2026-02-15

## 2026-02-14
- Consolidated RME validation tooling into `scripts/test`.
- Renamed RME test scripts to `test-rme-*` for consistency.
- Renamed checksum validator to `test-verify-checksums.py`.
- Moved `dev-extract-map.py` to `test-rme-extract-map.py`.
- Moved `dev-patchlog-analyze.py` to `test-rme-patchlog-analyze.py`.
- Removed hardcoded repo-local `GOG/` source path assumptions.
- Added env-driven source selection (`GAME_DATA`, `FALLOUT_GAMEFILES_ROOT`) across test harnesses.
- Added `test-rme-asset-sweep.py` for full asset-domain traversal and readability checks.
- Added `test-rme-end-to-end.sh` as a one-command final validation flow with maximum logging.
- Repointed `test-rme-full-coverage.sh` to the new end-to-end validator for backward compatibility.
- Fixed legacy `scripts/rme/...` references left in autofix orchestration.
- Added docs for `tmp_wd/` retained autofix fixture snapshot content.
- Added user-overridable fixture/data-dir inputs for `test-rme-patchflow-autofix.sh` and `test-rme-validate-ci.sh`.
- Added baseline `README.md`/`JOURNAL.md` files to nested fixture subdirectories under `scripts/test/` to keep directory-level docs complete.
- Added `test-rebirth-refresh-validation.sh`, `test-rebirth-validate-data.sh`, and `test-rebirth-toggle-logging.sh` under `scripts/test/` (reclassified from patch domain).
- Added Python RME suite runner at `scripts/test/rme/suite.py` for one-command execution.
- Renamed fixture/support directories for clarity:
  - `rme-data` -> `rme-fixtures`
  - `rme-tools` -> `rme-fixture-tools`
  - `tmp_wd` -> `rme-sample-workdir`

## 2026-02-15 Repository Sync
- Synced this journal to current repository state after deterministic SDL3 input hardening.
- Core input implementation commit: `c1accdf27927603e1d6b4c115dded9bac08c0a72`.
- LLM handoff summary commit: `fdc0f05f559c1d2f79706d395b6eae4b9ae4d48d`.
- Automated input evidence is recorded in `dev/state/latest-summary.tsv` and `dev/state/history.tsv` (latest PASS row: `2026-02-15T20:48:57Z`).
- iOS scripted touch evidence: `dev/state/logs/round-2-input-ios_headless-rerun.log`, `dev/state/logs/ios-touch-autotest-20260215T204516Z.patchlog.txt`, and screenshot `dev/state/logs/screens/ios-headless-com-fallout1rebirth-game-20260215T204510Z.png`.

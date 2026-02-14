# JOURNAL: scripts/test

Last updated (UTC): 2026-02-14

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

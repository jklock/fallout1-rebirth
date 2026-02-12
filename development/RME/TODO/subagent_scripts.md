# Subagent: Scripts & Dialog — runtime checks (RME_SELFTEST + autorun + patchflow)

Purpose
- Execute non-interactive script/dialog runtime checks, verify script files load, and run the patchflow harness.

Non-interactive commands (exact)
- RME selftest (non-interactive):
  - export RME_WORKING_DIR="build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/Resources"
  - export RME_SELFTEST=1
  - "$PWD/build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth"  # produces rme-selftest.json
- Patchflow test (static + runtime hooks):
  - ./scripts/test/test-rme-patchflow.sh --skip-build GOG/patchedfiles
- Autorun map script smoke (run map that triggers many scripts):
  - export F1R_AUTORUN_MAP=VAULT13
  - export F1R_PATCHLOG=1
  - TIMEOUT=60 "$PWD/build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth"

Where outputs land (evidence)
- development/RME/ARTIFACTS/evidence/gate-3/ (manual dialog evidence)
- development/RME/ARTIFACTS/evidence/runtime/ (patchlogs for autorun)
- rme-selftest.json (root of working dir)

Acceptance criteria
- `rme-selftest.json` exists and contains an empty `failures` array.
- `test-rme-patchflow.sh` returns exit code 0 (or documents only whitelist-suppressed warnings).
- Autorun map with `F1R_PATCHLOG=1` produces no `ERROR` lines for scripts in the per-map patchlog.

Subagent prompt (use this EXACT prompt when launching a subagent to run script/dialog tasks)

"Run the automated scripts & dialog validation. Steps:
1) Run the RME selftest: set `RME_WORKING_DIR` to the app Resources and `RME_SELFTEST=1`, then run the executable; save `rme-selftest.json` to `development/RME/ARTIFACTS/evidence/gate-3/`.
2) Run `./scripts/test/test-rme-patchflow.sh --skip-build GOG/patchedfiles` and save output to `development/RME/ARTIFACTS/evidence/gate-2/patchflow.txt`.
3) Run an autorun map (VAULT13) with `F1R_PATCHLOG=1` to generate a patchlog; analyze it with `scripts/dev/patchlog_analyze.py` and save the analyzer output.

Return a JSON summary: `selftest_ok` (bool), `patchflow_ok` (bool), `autorun_patchlog_issues` (list of messages), and `artifacts` (paths). Include any `ERROR` or `missing` strings found in logs."
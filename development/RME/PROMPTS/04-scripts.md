# Subagent orchestration prompt — Scripts & Dialog (RME_SELFTEST, patchflow, autorun)

Subagent prompt (EXACT — pass this to the scripts subagent):

"Run automated script/dialog validation (non-interactive). Steps:

1) RME selftest (non-interactive):
   - export RME_WORKING_DIR="build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/Resources"
   - export RME_SELFTEST=1
   - run the executable and save `rme-selftest.json` to `development/RME/ARTIFACTS/evidence/gate-3/rme-selftest.json` and logs to `gate-3-selftest-log.txt`.

2) Run patchflow test (static + autofix):
   - ./scripts/test/test-rme-patchflow.sh --skip-build GOG/patchedfiles
   - Save to `development/RME/ARTIFACTS/evidence/gate-2/patchflow.txt`.

3) Autorun map smoke: run `F1R_AUTORUN_MAP=VAULT13 F1R_PATCHLOG=1` with the executable, save per-map patchlog and analyze it with `scripts/dev/patchlog_analyze.py`.

Return JSON (exact schema):
{
  "selftest_ok": true|false,
  "selftest_path": "development/RME/ARTIFACTS/evidence/gate-3/rme-selftest.json",
  "patchflow_ok": true|false,
  "patchflow_log": "path",
  "autorun_issues": ["strings found in patchlog"],
  "artifacts": ["paths..."],
  "errors": ["text..."]
}

Failure rules:
- If `rme-selftest.json` contains `failures` entries, set `selftest_ok=false` and include the `failures` array in `errors`.
- If `test-rme-patchflow.sh` exits nonzero, capture stdout/stderr and set `patchflow_ok=false`.

Do not edit script files; only run diagnostics and save artifacts."
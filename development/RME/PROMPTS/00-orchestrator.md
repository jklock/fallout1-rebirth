# Orchestrator prompt — Full automated RME validation

Use this prompt to run the complete, non-interactive RME validation pipeline. It orchestrates the infra → maps → scripts → art → audit → iOS tasks and returns a single JSON summary.

Subagent prompt (EXACT — pass this to the subagent):

"You are an autonomous test orchestrator for the Fallout 1 Rebirth RME integration. Run the full, non-interactive validation pipeline and return a single JSON report. Do not ask the user any questions; fail fast with diagnostics if preconditions are not met.

Preconditions (fail if any missing):
- Current working directory is the repository root containing `scripts/`, `build-macos/`, and `GOG/patchedfiles/`.
- Branch must be `RME-DEV` and `git status --porcelain` must be clean. If not clean, include `git status` output in `diagnostic.git_status` and exit nonzero.

Sequence (execute in order):
1) Infrastructure (Gate‑1): run the exact commands from `development/RME/TODO/subagent_infrastructure.md` to build, patch, install and run `RME_SELFTEST`. Save logs to `development/RME/ARTIFACTS/evidence/gate-1/`.
2) Maps (Gate‑2): run CARAVAN/ZDESERT1/TEMPLAT1 repeats then run the 72‑map sweep as specified in `development/RME/TODO/subagent_maps.md`. Save `runtime_map_sweep.csv`, patchlogs and screenshots under `development/RME/ARTIFACTS/evidence/runtime/`.
   - If any flaky map fails with `DB_OPEN_FAIL` or `missing FRM` in the patchlog, re-run `./scripts/test/test-install-game-data.sh` then immediately re-run the failing repeats once. Record the remediation attempt and result.
3) Scripts & Dialog: run RME selftest, `test-rme-patchflow.sh`, and an autorun map (VAULT13) with `F1R_PATCHLOG=1` as in `development/RME/TODO/subagent_scripts.md`. Save outputs under `development/RME/ARTIFACTS/evidence/gate-3/` and `gate-2/` as appropriate.
4) Art checks: run the automated FRM/LST counts and collect present-anomaly screenshots as in `development/RME/TODO/subagent_art.md` (save under `development/RME/ARTIFACTS/evidence/gate-2/art/`).
5) Audit & cleanup: run placeholder audit and `patchlog_analyze.py` as described in `development/RME/TODO/subagent_audit.md`. Save `placeholder-audit.txt` and `patchlog-anomaly-report.txt` under `development/RME/ARTIFACTS/evidence/gate-2/`.
6) iOS simulator smoke (Gate‑4): run `./scripts/test/test-ios-simulator.sh --build-only` and then `--launch` with `GAME_DATA=GOG/patchedfiles` as in `development/RME/TODO/subagent_ios.md`. Save logs/screenshots under `development/RME/ARTIFACTS/evidence/gate-4/`.

For each step capture stdout/stderr to a named file under `development/RME/ARTIFACTS/evidence/` and include the path in the final JSON.

Return value (JSON) — required structure (include paths where files were written):
{
  "overall_status": "PASSED|FAILED|PARTIAL",
  "gates": {
    "gate1": {"ok": true|false, "logs": ["path", ...]},
    "gate2": {"ok": true|false, "sweep_rows": N, "sweep_csv":"path", "repeats": {"CARAVAN":{...}, ...}, "logs": ["path", ...]},
    "gate3": {"ok": true|false, "selftest":"path", "patchflow_log":"path", "logs": [...]},
    "gate4": {"ok": true|false, "simulator_logs":"path", "screenshot":"path"},
    "gate5": {"ok": true|false, "packaging_logs":"path"}
  },
  "failed_items": [ {"id":"CARAVAN","type":"map|data|engine","reason":"text","evidence":"path"}, ... ],
  "artifacts": ["development/RME/ARTIFACTS/evidence/..."],
  "recommendations": ["text", ...]
}

Timing & retries:
- Allow one automatic remediation retry for data/packaging failures (re-install patched data + re-run the failing repeat once).
- Do NOT attempt git history changes or any destructive git ops.

If any step errors unexpectedly, include the captured stderr and relevant `patchlog_analyze.py` excerpt in the JSON and set `overall_status` to `PARTIAL` or `FAILED`.

Finish by printing the JSON to stdout and exit with code 0 if `overall_status` is `PASSED`, else exit nonzero."
# Subagent orchestration prompt — Maps (Gate‑2)

Subagent prompt (EXACT — pass this to the maps subagent):

"Run the automated map validation and flaky-map remediation for RME (non-interactive). Steps:

Pre-checks:
- Confirm `build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth` exists and `GOG/patchedfiles` is present. Fail with diagnostics if not.

A — Flaky map repeats (must run first):
- ./scripts/patch/rme-repeat-map.sh CARAVAN 10  (save to development/RME/ARTIFACTS/evidence/gate-2/repeats/CARAVAN-10.txt and associated patchlogs)
- ./scripts/patch/rme-repeat-map.sh ZDESERT1 10
- ./scripts/patch/rme-repeat-map.sh TEMPLAT1 10

If any repeat fails and the patchlog contains `DB_OPEN_FAIL` or `missing` asset messages, run `./scripts/test/test-install-game-data.sh` then re-run the failing map once. Record both runs.

B — Full runtime sweep (autorun + screenshots + patchlogs):
- export F1R_PATCHLOG=1
- python3 scripts/patch/rme-runtime-sweep.py --exe "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth" --timeout 120 --out-dir development/RME/ARTIFACTS/evidence/runtime

C — Patchlog analysis:
- Run `python3 scripts/dev/patchlog_analyze.py` on every `*.patchlog.txt` produced and write `*.patchlog_analyze.txt` next to each patchlog.

Return JSON (exact schema):
{
  "repeats": {
    "CARAVAN": {"pass": N, "fail": M, "logs": ["path", ...]},
    "ZDESERT1": {...},
    "TEMPLAT1": {...}
  },
  "sweep_row_count": INT,
  "sweep_csv": "development/RME/ARTIFACTS/evidence/runtime/runtime_map_sweep.csv",
  "sweep_failures": ["mapname", ...],
  "suspicious_maps": ["mapname", ...],
  "patchlog_summary": "development/RME/ARTIFACTS/evidence/runtime/patchlogs/patchlog_summary.csv",
  "artifacts": [ "paths..." ],
  "errors": ["text..." ]
}

Fail rules:
- If `sweep_row_count` < 72, set `sweep_ok=false` in `errors` and include last 200 lines of the sweep run log.
- For flaky map failures that are data-related, include `remediation_attempted=true` and details of the re-run.

Do not modify source files; only run diagnostics and store artifacts."
# RME Patchflow Validation — Process & Plan

Purpose
- Design and operate a fully automated, non-interactive validation pipeline that uses `GOG/patchedfiles` as the authoritative patched dataset and validates that applying RME changes produced a working game.

Goals (short)
- Validate the overlayed RME changes from `GOG/patchedfiles` without manual steps.
- Provide deterministic, machine-readable outputs (JSON) and comprehensive logs to prove coverage across asset classes.
- Iterate until the game shows zero unresolved failures for the chosen acceptance criteria.

Scope & Constraints
- Authoritative patched dataset: `GOG/patchedfiles` (do not edit in place).
- Only code, scripts, small docs, and test harnesses will be committed to the repo.
- Optionally, a test-only normalization step (copy and case normalization) may be used to create a reproducible test working directory, but not to change `GOG/patchedfiles` source.

Phases
1. Discovery & Inventory
   - Confirm `GOG/patchedfiles` exists and contains master/dat/data overlay.
   - Run `./scripts/patch/rebirth-validate-data.sh` to verify file coverage against `third_party/rme/source/DATA`.
2. Implement Helpers
   - Add `RME_WORKING_DIR` override for the runtime working dir (winmain change).
   - Add `RME_SELFTEST` in-process self-test runner that enumerates & validates asset classes and writes `rme-selftest.json`.
3. Add Orchestrator & Parser
   - `scripts/test/test-rme-patchflow.sh`: copies `GOG/patchedfiles` -> `tmp/rme-run-*`, builds app, runs game with `RME_SELFTEST=1`, collects artifacts.
   - `scripts/test/parse-rme-log.py`: parses `rme.log` + `rme-selftest.json` -> `rme-run-summary.json`.
4. Iterate & Repair
   - Run, analyze failures, make small changes (logging + fixes), repeat.
   - If a systemic decision is needed (case fallback policy, data normalization), open a blocking todo and stop for human decision.
5. Acceptance & Handover
   - When `rme-run-summary.json` shows pass (or within documented whitelist), produce final run artifacts and create a PR with the changes and the validation evidence.

Key Tests (self-test responsibilities)
- DB & Patch probe: confirm master/critter loads, `db_get_file_list` inventories and patch tree completeness.
- Maps: header parse (default) for all `maps\*.map`, optional full `map_load` via `RME_SELFTEST_MAP_FULL=1`/`F1R_AUTORUN_MAP=1`.
- Scripts: parse `scripts.lst` and attempt `db_fopen` for each `.int`.
- Protos: `proto_list_str` and `db_fopen` of `.pro` files for proto types.
- Text/messages: `message_load` for `text\english\game/*.msg` and `text\english\dialog/*.msg`.
- Art: `db_dir_entry("art\\tiles\\grid000.frm")`, `db_get_file_list("art\\intrface\\*.frm")`.
- Sound: `db_get_file_list` for `sound\sfx\*` and `sound\music\*` and `db_fopen` sample files.
- Save/load smoke: open a save slot (if required) and ensure assets used in load are found.

Outputs & Acceptance Criteria
- `rme-selftest.json`: per-category totals and arrays of failures.
- `rme.log`: raw runtime logs including `rme_logf(...)` lines for `db`, `map`, `proto`, `text`, `art`, `sound` and `selftest` topics.
- `rme-run-summary.json`: aggregated counts + `pass: true|false`.
- Acceptance: default thresholds are 0 failures for DB opens and selftest; thresholds and whitelist documented in `development/RME/plan/OUTCOMES.md`.

Audit trail & artifacts
- Raw run: `tmp/rme-run-<timestamp>/` contains raw logs and JSON files.
- Canonical artifact dir: `development/RME/validation/run-<timestamp>/` containing digest, summary, and short report.

If blocked
- Create `development/RME/todo/<timestamp>-blocking-*.md` with reproducer + recommended next step.

---

This file is the canonical RME patchflow plan. See `TASKS.md`, `OUTCOMES.md`, and `SUBAGENT_INSTRUCTIONS.md` for task tracking, acceptance criteria, and instructions for autonomous subagents.
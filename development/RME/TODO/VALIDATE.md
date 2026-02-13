# Validation Prompt — RME TODO run

Purpose
- Validate the results produced by the orchestrator and all subagents.
- Confirm acceptance criteria for each TODO item and produce a final `orchestrator-summary.md` under `development/RME/ARTIFACTS/evidence/`.

Agent behavior (validator)
1. Read `development/RME/TODO/PROGRESS.MD` and all artifact folders referenced in `artifacts` fields.
2. For each task in `tasks` perform the item-specific validation checks listed below.
3. Produce a `development/RME/ARTIFACTS/evidence/orchestrator-summary.md` describing: overall verdict (pass/fail), per-task verdicts, failing evidence paths, and recommended next steps.
4. If any P0 item is `failed` or `verdict: fail`, mark the overall run `FAILED` and list blockers.

Validation checks (exact)
- caravan-repeat: verify each `development/RME/ARTIFACTS/evidence/caravan-repeat/<MAP>/` contains 10 patchlogs and each patchlog shows PASS. If any fail, attach the failing `*.patchlog.txt` and the `summary.md` and return `verdict: fail` for this task.

- install-game-data: verify `build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/Resources/master.dat` exists and that the install script log contains no `DB_OPEN_FAIL`. If missing or DB_OPEN_FAIL present, fail this task.

- runtime-sweep: ensure CSV row count == 72. Run `python3 scripts/dev/patchlog_analyze.py development/RME/ARTIFACTS/evidence/runtime/patchlogs/*.patchlog.txt` and ensure the analyzer report contains no untriaged CRITICALs. Fail otherwise.

- gate-3: confirm `development/RME/ARTIFACTS/evidence/gate-3/summary.md` lists the manual checklist results; if `manual-required` appears, mark `verdict: manual-required` and list steps left to complete.

- ios-simulator: check the simulator logs and screenshots exist and the smoke run exit code == 0.

- whitelist-review: ensure `git apply --check` was performed (or the diff was inspected); confirm `test-rme-patchflow.sh` (or equivalent) reports suppression of the known warnings. If not, mark `verdict: fail`.

- P2 items: run the specific checks listed in `development/RME/TODO/todo.md` and any referenced `subagent_*.md` files.

Output
- File: `development/RME/ARTIFACTS/evidence/orchestrator-summary.md` (include timestamps, per-task verdicts, and links to artifacts).
- Exit status: 0 if all P0 items pass and no untriaged CRITICALs; non-zero otherwise.

Example summary format (markdown)
- Overall verdict: PASS / FAIL
- Run started: <ISO timestamp>
- Run finished: <ISO timestamp>

Per-task results:
- P0-1 caravan-repeat: PASS — artifacts: `development/RME/ARTIFACTS/evidence/caravan-repeat/`
- P0-2 install-game-data: FAIL — missing `master.dat` in app bundle; logs: `...`

Next steps & recommended owners
- If FAIL: assign to owner(s) with suggested next actions.

End of validation prompt.

use #runsubagent to spawn the subagent runs. You yourself will do no work - it is all done through subagents. You will generate their prompts. You will have them produce output of every substantiation and communicate with you / each other via progress.md 

Purpose
- Orchestrate automated subagents to complete every actionable item in `development/RME/TODO/todo.md` (P0 → P3).
- Enforce project rules: use provided scripts only, do NOT perform history-rewriting git operations.
- Record every output under `development/RME/ARTIFACTS/evidence/` and update `development/RME/TODO/PROGRESS.MD` as the single source of truth for task status.

Agent behavior (must-follow)
1. Non-interactive: run commands, collect logs/artifacts, update PROGRESS.MD, and exit with a validation report.
2. Use only project-provided scripts (see `development/RME/TODO/todo.md`). Do not run raw cmake/xcodebuild or interact with system simulators outside those scripts.
3. DO NOT create new git branches. All automated commits must be made on `RME-DEV` unless the user explicitly authorizes branch creation. NEVER perform history-rewriting git operations (no rebase, no reset --hard, no force push).
4. Always ensure `GOG/patchedfiles` is used as the canonical source of patched game data for any automation that runs the engine. Subagents MUST auto-install patched data into the target `.app` (via `./scripts/test/test-install-game-data.sh --source GOG/patchedfiles --target <app>`) when the bundle lacks `master.dat`/`critter.dat` or map files.
5. Write every stdout/stderr, produced files, and structured summaries to `development/RME/ARTIFACTS/evidence/<task-slug>/`.
6. Update `PROGRESS.MD` at the start and end of each task (timestamps in ISO-8601 UTC).
7. After completing each P0/P1/P2 item run its validator (see "Validation" section) and record verdict under `PROGRESS.MD` and `evidence/`.

Directory & artifact rules
- Base artifacts dir: `development/RME/ARTIFACTS/evidence/`.
- Use lower-case, hyphen-separated task slugs (e.g., `caravan-repeat`, `install-game-data`, `runtime-sweep`).
- Include raw logs (`*.log` / `*.patchlog.txt`), a short `summary.md`, and any screenshots in the task folder.

PROGRESS.MD usage (location)
- File: `development/RME/TODO/PROGRESS.MD` (created if missing).
- Format: top YAML block named `tasks` followed by a human summary. Agents MUST update the YAML block only.

PROGRESS.MD YAML schema (example)
---
tasks:
  - id: P0-1
    slug: caravan-repeat
    title: Fix CARAVAN / ZDESERT1 / TEMPLAT1 flaky runs
    status: not-started    # not-started | in-progress | completed | failed
    owner: QA+Engine
    started_at: null
    completed_at: null
    verdict: null          # pass | fail | triaged
    artifacts: []
    notes: null
...

Task run sequence (execute top → down)
- P0 (critical):
  1) caravan-repeat (maps: CARAVAN, ZDESERT1, TEMPLAT1)
  2) install-game-data (packaging fix)
  3) runtime-sweep (72-map sweep)
- P1 (high):
  4) gate-3 (macOS manual smoke — run headless automation + collect evidence)
  5) ios-simulator (build + simulator smoke)
  6) whitelist-review (dry-run + patchflow)
- P2 (medium) and P3: run subagents listed in `development/RME/TODO/subagent_*.md` as needed.

Exact commands & acceptance checks (validators)
- caravan-repeat (for each MAP in CARAVAN,ZDESERT1,TEMPLAT1):
  - Run: F1R_PATCHLOG=1 ./scripts/patch/rme-repeat-map.sh <MAP> 10
  - Save: `development/RME/ARTIFACTS/evidence/caravan-repeat/<MAP>/` (all patchlogs and stdout)
  - Validate: must contain 10/10 PASS (or failing patchlog must include root-cause notes). Mark `verdict: pass` if OK.

- install-game-data:
  - Run: ./scripts/test/test-install-game-data.sh
  - Validate: `ls build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/Resources/master.dat` exists; no DB_OPEN_FAIL in logs.
  - Save: `development/RME/ARTIFACTS/evidence/install-game-data/` (installer log + file list + verification output)

- runtime-sweep:
  - Run: F1R_PATCHLOG=1 python3 scripts/patch/rme-runtime-sweep.py --exe "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth" --timeout 120 --out-dir development/RME/ARTIFACTS/evidence/runtime
  - Validate: produced CSV contains exactly 72 data rows; run `python3 scripts/dev/patchlog_analyze.py development/RME/ARTIFACTS/evidence/runtime/patchlogs/*.patchlog.txt` and ensure no untriaged CRITICALs remain.
  - Save: runtime CSV, patchlogs, analyzer output.

- gate-3 (macOS smoke):
  - Run: ./scripts/test/test-macos-headless.sh && capture screenshots/logs to `development/RME/ARTIFACTS/evidence/gate-3/`.
  - Acceptance: headless smoke passes; if headless can't cover manual checklist then create a `manual-checklist.md` with instructions and mark `verdict: manual-required`.

- ios-simulator (Gate‑4):
  - Run: ./scripts/build/build-ios.sh && ./scripts/test/test-ios-simulator.sh
  - Save: screenshots, simulator logs, `xcrun simctl` output to `development/RME/ARTIFACTS/evidence/ios-simulator/`.
  - Validate: app installed + smoke script passed.

- whitelist-review:
  - Dry-run: git apply --check development/RME/fixes-proposed/whitelist-proposed.diff
  - If clean: run ./scripts/patch/test-rme-patchflow.sh (dry-run mode if available), capture outputs in `development/RME/ARTIFACTS/evidence/whitelist-review/` and set verdict pass/failed.

Update rules for PROGRESS.MD (commands)
- Mark start: replace `status: not-started` -> `status: in-progress` and set `started_at: $(date -u +%FT%TZ)`.
- Mark finish: set `status: completed|failed`, `completed_at: $(date -u +%FT%TZ)`, `verdict: pass|fail|triaged`, and append `artifacts: ["development/RME/ARTIFACTS/evidence/<task-slug>/"]`.

Required outputs per task
- `summary.md` (human-readable summary with verdict)
- `stdout.log` and `stderr.log` (if separate)
- any `*.patchlog.txt`, `*.csv`, screenshots

Final validation step (see `development/RME/TODO/VALIDATE.md`)
- After all tasks finish, run the validation prompt to verify PROGRESS.MD, run targeted analyzers (patchlog_analyze.py), ensure acceptance criteria met, and create `development/RME/ARTIFACTS/evidence/orchestrator-summary.md` with a pass/fail verdict for the whole run.

Failure handling
- If a P0 item fails, stop the orchestrated run, mark the item `failed` in PROGRESS.MD, save all logs, and produce a `blocker-report.md` under the task's artifact folder. Do not proceed to P1/P2.
- For P1/P2 non-blocking failures, continue with remaining tasks but mark `failed` and add `notes` for triage.

Notes for humans / maintainers
- This orchestrator is intended to be re-runnable and idempotent when possible. Clean up only within `development/RME/ARTIFACTS/evidence/`.
- When in doubt about manual steps, annotate `verdict: manual-required` and attach a `manual-checklist.md` in the artifact folder.

---

Appendix — Quick commands reference (for automation)
- Update PROGRESS.MD (example sed usage):
  - Start task: sed -i.bak "0,/<slug>/ s/status: not-started/status: in-progress/" development/RME/TODO/PROGRESS.MD && sed -i.bak "0,/<slug>/ s/started_at: null/started_at: \"$(date -u +%FT%TZ)\"/" development/RME/TODO/PROGRESS.MD
  - Complete task: sed -i.bak "0,/<slug>/ s/status: in-progress/status: completed/" development/RME/TODO/PROGRESS.MD && sed -i.bak "0,/<slug>/ s/completed_at: null/completed_at: \"$(date -u +%FT%TZ)\"/" development/RME/TODO/PROGRESS.MD

End of orchestrator prompt.

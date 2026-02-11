# RME Patchflow Tasks

Status values: not-started | in-progress | completed | blocked

| ID | Title | Owner | Priority | Status | Estimate | Acceptance Criteria |
|----|-------|-------|----------|--------|----------|--------------------|
| T001 | Add runtime `RME_WORKING_DIR` override | Implement | P1 | not-started | 1d | Game respects `RME_WORKING_DIR` when set, logs override at `config` topic.
| T002 | Add in-process `RME_SELFTEST` runner | Implement | P1 | not-started | 3d | Selftest enumerates assets, writes `rme-selftest.json`, logs `selftest` summary lines. Exit code non-zero on failures.
| T003 | Hook selftest into startup (opt-in) | Implement | P1 | not-started | 0.5d | `game_init` calls selftest when `RME_SELFTEST=1` and stops early with artifacts.
| T004 | Add test orchestrator `test-rme-patchflow.sh` | Test | P1 | not-started | 2d | Creates `tmp/rme-run-*`, runs binary with envs, captures artifacts, and times out safely.
| T005 | Add `parse-rme-log.py` JSON parser | Test | P1 | not-started | 1.5d | Produces `rme-run-summary.json` and exits non-zero when limits exceeded.
| T006 | Add docs and `development/RME/validation/README.md` | Plan | P2 | not-started | 0.5d | Explains how to run harness and where artifacts land.
| T007 | Baseline run + iterate fixes | Implement/Test | P1 | not-started | 3-7d | Run fails identified, fixes applied in small commits and re-run until pass or blocked; each fix includes tests.
| T008 | Whitelist & expected-issues manifest | Test | P2 | not-started | 0.5d | A file containing allowed known failures to avoid flaky failures.
| T009 | Opt-in case-fallback behavior (if needed) | Implement | P2 | not-started | 2d | `RME_CASE_FALLBACK=1` attempts case-insensitive open on failures and logs attempts; off by default.
| T010 | Integrate final run into docs and create PR | Plan/Report | P1 | not-started | 1d | PR includes implementation commits and validation artifacts and acceptance summary.

Notes
- Tasks should be updated with status and a short note in `development/RME/todo/progress.md`.
- Each implementation task should have small commits and be followed by `./scripts/dev/dev-check.sh` and `./scripts/dev/dev-verify.sh` runs.
- If a task becomes blocked, create `development/RME/todo/<timestamp>-blocking-*.md` and mark the task `blocked`.

---

Next step: pick T001 and implement it as an initial low-risk start.
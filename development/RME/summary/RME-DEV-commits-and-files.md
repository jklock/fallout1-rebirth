# RME-DEV — Commit & file-level audit

Scope: commits on branch `RME-DEV` (range: `main..RME-DEV`) as of 2026-02-13 — every commit and file touched in this branch.

Summary: 20 commits (high level: RME doc migration + test-harness hardening + renderer fixes + diagnostic/triage instrumentation + test-script reorganization).

Update (2026-02-14):
- Branch snapshot remains historical context; use `development/RME/PLAN/plan.md` + `development/RME/TODO/todo.md` for live execution.
- Active runtime/testing flow is `scripts/test/*`; patching remains in `scripts/patch/*`.
- Canonical game-data source for validation is now fixed to `GOG/patchedfiles` across active test/post-build scripts.
- RME payload default path is `third_party/rme` (with fallback compatibility for legacy `third_party/rme/source` references).
- Live tracking has been split into domain documents under `development/RME/{PLAN,TODO,OUTCOME,VALIDATE}/domains/`.

---

## Per-commit breakdown (newest → oldest)

> Each entry lists: commit short hash, full hash, author, date, commit message, files touched (status) and a short "Why / rationale" explanation.

### ec363c8 — ec363c82ae4659ae0c9e569f92ac6d50e97d67ef
- Author / Date: John Klockenkemper — 2026-02-13 19:03:51 -0600
- Message: lkjh
- Files touched:
  - A scripts/patch/rme-repeat-map.sh — added (repeat-map wrapper / harness entry)
  - A scripts/patch/rme-runtime-sweep.py — added (72‑map runtime sweep harness)
- Why: initial/addition commit for the autorun test tooling — introduces the single-map repeat wrapper and the full runtime-sweep harness so QA can automate map load & verification.

---

### 7e73e13 — 7e73e13b4fb6de1da48d176d0544835f870368d6
- Author / Date: John Klockenkemper — 2026-02-13 19:03:50 -0600
- Message: jesus
- Files touched (selected):
  - M development/RME/PLAN/plan.md — update plan layout
  - M development/RME/TODO/PROGRESS.MD, M development/RME/TODO/todo.md — update TODO/status
  - D development/RME/validation/runtime/runtime_map_sweep.csv — removed (artifact cleanup)
  - D development/RME/validation/runtime/screenshots/* (selected BMPs) — removed
  - R100 many scripts/patch/* → scripts/test/* (mass rename/move)
  - M src/game/main.cc — engine changes
- Why: repository reorganization and cleanup (move test scripts to `scripts/test/` to separate them from patching utilities), remove stale validation artifacts, and apply engine updates. This commit consolidates test/script layout and updates docs to the new structure.

---

### 470305f — 470305f8a134df1c905fc153013b7ee33e3c2a74
- Author / Date: John Klockenkemper — 2026-02-13 18:43:14 -0600
- Message: rme-repeat-map.py: fix format specifiers (remove stray spaces)
- Files touched:
  - M scripts/patch/rme-repeat-map.py — formatting bug fix
- Why: fix a ValueError caused by an incorrect format specifier in the Python repeat-map script so the harness runs reliably.

---

### 7e55483 — 7e55483d7e1f5768ca1069fb0e66ef0f4fa0cda3
- Author / Date: John Klockenkemper — 2026-02-13 18:41:47 -0600
- Message: rme-repeat-map: convert shell script to Python; add delay/hold and runtime-sweep parity
- Files touched:
  - A scripts/patch/rme-repeat-map.py — new Python implementation (parity with runtime sweep)
  - M scripts/patch/rme-repeat-map.sh — wrapper updated to prefer Python impl
- Why: convert the legacy shell repeat harness to Python to guarantee parity with `rme-runtime-sweep.py` (same delays, hold behavior, stricter verification). Improves maintainability and consistent timing for autorun click/hold.

---

### 79474a5 — 79474a5ea7c67923a043500f85ec2a054c7bae5c
- Author / Date: John Klockenkemper — 2026-02-13 18:15:18 -0600
- Message: fixlatercommit
- Files touched (selected):
  - M development/RME/TODO/PROGRESS.MD — progress bookkeeping
  - A development/RME/validation/runtime/runtime_map_sweep.csv — runtime sweep evidence
  - A screenshots for CARAVAN/TEMPLAT1/ZDESERT1 — evidence added
  - M scripts/patch/rme-runtime-sweep.py — harness improvements (min durations, click delay/hold enforcement)
  - A scripts/test/test-shutdown-sanity.sh — new test helper
  - M src/game/main.cc, src/plib/db/db.cc, src/plib/gnw/memory.cc, src/plib/gnw/svga.cc, src/plib/gnw/winmain.cc — engine fixes/defensive guards
- Why: land a collection of fixes and artifacts from runtime validation: strengthen harness timing, add shutdown sanity tests, and apply engine-level defensive fixes (memory/shutdown/renderer) to reduce flakiness and capture artifacts.

---

### 595f51a — 595f51aed498c3305608fe4624c4d35b6bc73686
- Author / Date: John Klockenkemper — 2026-02-13 15:37:24 -0600
- Message: fix(svga): prevent large zero-source copy from wiping display (fix black-top in CARAVAN/ZDESERT1/TEMPLAT1)
- Files touched:
  - M src/plib/gnw/svga.cc — renderer safeguard / zero‑copy protection
- Why: implement a guard in the SVGA blitting path so an invalid/large zero-source copy cannot blank the display (fixes the "black top" rendering issue observed on several maps).

---

### d7992ef — d7992ef7d5e6c452fc3020d5750ede0c0f9ce788
- Author / Date: John Klockenkemper — 2026-02-13 15:17:20 -0600
- Message: RME: add placeholder patchlog for orchestrator runs; temporary SDL shutdown delay to reduce flaky shutdown double-free (triage instrumentation)
- Files touched:
  - M scripts/patch/rme-repeat-map.sh — placeholder patchlog behavior added
  - M src/game/main.cc — temporary SDL shutdown delay + triage logging
- Why: make orchestrated/automated runs more robust for triage: create a visible placeholder patchlog when the engine crashes early, and add a short shutdown delay in the engine to reduce racey double-free/shutdown flakiness while root-cause is investigated.

---

### c1bed8f — c1bed8f84958a441d2618c04f69c32acfbf9059b
- Author / Date: John Klockenkemper — 2026-02-13 13:00:29 -0600
- Message: rme(test): enforce patched game data preflight + auto-install from GOG/patchedfiles; policy: forbid automated branch creation (RME-DEV only)
- Files touched:
  - M .github/copilot-instructions.md — policy notes (AI agent constraints)
  - M development/RME/PROMPTS/subagent_orchestrator.md — orchestrator prompt updates
  - M scripts/dev/dev-check.sh — dev-check improvements
  - M scripts/patch/rme-repeat-map.sh — preflight/auto-install behavior
  - M scripts/patch/rme-runtime-sweep.py — preflight and harness hardening
  - M scripts/test/test-macos-headless.sh, scripts/test/test-macos.sh — test helpers
- Why: add deterministic preflight checks and auto-install behavior so tests fail early when required game data is missing; include policy guidance (no automated branch creation) and ensure test scripts are robust when run by automation or by humans.

---

### b1cadbc — b1cadbc05054d344a667c0b0fe56774d8377b06c
- Author / Date: John Klockenkemper — 2026-02-13 12:53:48 -0600
- Message: rme(test): add preflight asset-check to rme-repeat-map.sh — fail early when app Resources lack master.dat/critter.dat or map file
- Files touched:
  - M scripts/patch/rme-repeat-map.sh — explicit asset preflight checks
- Why: prevent false negatives and confusing DB_OPEN_FAIL errors by checking for master.dat/critter.dat and the target map before launching the engine.

---

### c1ef246 — c1ef2463b3d90bb2f81aab4adda680b09d2e092c
- Author / Date: John Klockenkemper — 2026-02-13 12:01:41 -0600
- Message: rme: caravan-repeat — record end timestamp and verdict=fail in PROGRESS.MD
- Files touched:
  - M development/RME/TODO/PROGRESS.MD — progress bookkeeping for caravan-repeat
- Why: improve traceability and allow automated reports to record run verdicts and timestamps for triage and reproducibility.

---

### cb357d5 — cb357d54944fd4d7b4dcfd545e741f2972fac5be
- Author / Date: John Klockenkemper — 2026-02-13 09:58:25 -0600
- Message: diag+defense: mem_check at shutdown, backtrace on mem stomp, log DB patches_path before free; null-out window slot in win_free
- Files touched:
  - M src/plib/gnw/gnw.cc — add runtime diagnostics and defensive nulling
- Why: triage and harden against memory stomps and double-free problems observed during shutdown; add better logging and safer cleanup.

---

### 133fc48 — 133fc486977613aab451274b6ef5840323dc2ce7
- Author / Date: John Klockenkemper — 2026-02-13 09:43:29 -0600
- Message: diag: mem_check before SDL_Quit; add backtrace for mem stomps; log DB patches_path before free (triage)
- Files touched:
  - M src/game/main.cc — memory-check hooks & logging around shutdown
  - M src/plib/db/db.cc — log DB patches_path before free
  - M src/plib/gnw/memory.cc — mem-check/backtrace helpers
- Why: add structured triage points so post‑mortem logs contain the state needed to find memory corruption and shutdown races.

---

### 2a9172c — 2a9172ceaa9c93dcf858fb921ba613fe7e03ad22
- Author / Date: John Klockenkemper — 2026-02-13 09:24:12 -0600
- Message: rme: fail on missing/empty patchlog; remove placeholder that masked crashes; reopen caravan-repeat for rerun
- Files touched:
  - M development/RME/OUTCOME/outcome.md — updated outcomes based on reruns
  - M development/RME/TODO/PROGRESS.MD — reopen/mark progress
  - M scripts/patch/rme-repeat-map.sh — treat placeholder/missing patchlogs as failures
- Why: change harness policy to fail loudly when the engine does not produce a real patchlog (placeholder behavior previously masked crashes and produced false positives).

---

### b2d910f — b2d910fdadc2359559326503a8b8fc54d513c0a6
- Author / Date: John Klockenkemper — 2026-02-13 09:06:11 -0600
- Message: Hygeine - moving files around
- Files touched (selected/high-impact):
  - M .github/copilot-instructions.md — agent/project policy and guidelines
  - D GOG/patchedfiles/data/font*.aaf, D GOG/patchedfiles/data/maps/CARAVAN* / TEMPLAT1* / ZDESERT1* — removed duplicate/large files from patchedfiles
  - R100 development/RME/plan.md → development/RME/PLAN/plan.md — docs reorganized
  - D many development/RME/PROMPTS/* and TODO/subagent_*.md — consolidated or removed
  - M scripts/dev/patchlog_analyze.py — analyzer tweaks
  - M src/game/map.cc, src/plib/db/db.cc, src/plib/db/patchlog.h, src/plib/gnw/gnw.cc — assorted fixes
- Why: project hygiene and reorganization (move doc fragments into canonical locations, remove stale evidence/artifacts and unnecessary duplicates, and apply a few small engine/script fixes). This reduces repo clutter and aligns the RME doc structure.

---

### 3d63f4b — 3d63f4b90dd26dc10f698ff5c50fcdb854d9f228
- Author / Date: John Klockenkemper — 2026-02-13 08:59:43 -0600
- Message: rme: update status — orchestrator run complete; caravan triaged, runtime sweep finished, Gate-3 headless smoke passed
- Files touched:
  - A development/RME/OUTCOME/outcome.md — add outcome summary
  - A development/RME/TODO/PROGRESS.MD — mark progress
- Why: record final status after an orchestrated run and mark triage results. Keeps the team informed of gate progress.

---

### 967af75 — 967af753dd625c74028fff29f19fb4a78ccde1c7
- Author / Date: John Klockenkemper — 2026-02-12 17:58:01 -0600
- Message: RME: add subagent orchestration prompts (PROMPTS/) for infra/maps/art/scripts/iOS/audit + orchestrator
- Files touched:
  - M development/RME/PROMPTS/00-orchestrator.md
  - A development/RME/PROMPTS/01-infrastructure.md
  - A development/RME/PROMPTS/02-maps.md
  - A development/RME/PROMPTS/03-art.md
  - A development/RME/PROMPTS/04-scripts.md
  - A development/RME/PROMPTS/05-ios.md
  - A development/RME/PROMPTS/06-audit.md
- Why: add machine-readable subagent prompts so automated subagents (or humans) can run infra/maps/art/scripts/iOS/audit tasks reproducibly.

---

### b4bf11c — b4bf11ceeb039d32785742ce11b9e7a586af0705
- Author / Date: John Klockenkemper — 2026-02-12 17:52:26 -0600
- Message: RME: add subagent task files + exact non-interactive prompts (infra/maps/art/scripts/iOS/audit); link from TODO
- Files touched:
  - A development/RME/TODO/subagent_art.md
  - A development/RME/TODO/subagent_audit.md
  - A development/RME/TODO/subagent_infrastructure.md
  - A development/RME/TODO/subagent_ios.md
  - A development/RME/TODO/subagent_maps.md
  - A development/RME/TODO/subagent_scripts.md
  - A development/RME/TODO/todo.md (linked)
- Why: deliver operationally precise instructions and non-interactive prompts for automated validation tasks — enables reproducible subagent runs and CI-style checks.

---

### b75502d — b75502dc577f98c3b9df6c5585172de75bf60316
- Author / Date: John Klockenkemper — 2026-02-12 17:42:37 -0600
- Message: RME: add new top-level plan.md, outcome.md, todo.md (synthesized); archive legacy plan/OUTCOME/TASKS/todo
- Files touched (selected):
  - M development/RME/outcome.md, M development/RME/plan.md, M development/RME/todo.md — add consolidated artifacts
  - D legacy files under development/RME/plan/, development/RME/TASKS/, etc. — archived/removed
- Why: consolidate and simplify RME project documentation (single canonical plan/outcome/todo) and remove legacy clutter.

---

### b251a59 — b251a59f4843cf48d6cc8458bce36e98a3672c91
- Author / Date: John Klockenkemper — 2026-02-12 17:31:17 -0600
- Message: RME: migrate docs from RME_old → RME (plan/outcome/todo/summary/TASKS/PROMPTS); create consolidated plan.md/outcome.md/todo.md; remove RME_old directory
- Files touched (selected):
  - D many `development/RME/ARTIFACTS/evidence/*` stale lists and intermediate evidence
  - D removed `RME_old` and old artifacts
  - M moved/updated manifests & summaries
- Why: large doc/data migration and cleanup to centralize RME materials and remove deprecated content.

---

### 8130945 — 8130945c170289a15152d30998823d3c890fc9f6
- Author / Date: John Klockenkemper — 2026-02-12 17:18:39 -0600
- Message: RME: archive stale repeat and timestamped gate-1 artifacts; update manifests/cleanup log (evidence moved to ARTIFACTS/archive)
- Files touched:
  - M development/RME/ARTIFACTS/evidence/gate-2/gate-2-cleanup-log.txt
  - M development/RME/ARTIFACTS/evidence/gate-2/gate-2-repeats-manifest.txt
- Why: housekeeping — archive old evidence and keep the canonical evidence manifest current.

---

## Consolidated file list (unique files touched on `RME-DEV`) — short rationale per file

Note: this is the union of files touched by the commits above. For brevity each file gets one-line rationale derived from the commit(s) that modified it.

- `.github/copilot-instructions.md` — update agent policy & RME-specific guidance.
- `CMakeLists.txt` (unchanged here) — (no direct changes in recent commits listed).
- `development/RME/PLAN/plan.md` — moved/updated canonical plan documents.
- `development/RME/TODO/todo.md` — TODO consolidation and linking to subagent tasks.
- `development/RME/TODO/PROGRESS.MD` — progress bookkeeping for repeat runs and orchestration.
- `development/RME/JOURNAL.md` — journal entries for harness/engine changes (status updates).
- `development/RME/OUTCOME/outcome.md` — add final orchestrator & triage outcomes.
- `development/RME/ARTIFACTS/...` (many files) — evidence added/archived/cleaned (runtime sweep CSV, patchlogs, screenshots).
- `development/RME/PROMPTS/*` — add subagent orchestration prompts for automated tasks.
- `development/RME/TODO/subagent_*.md` — new subagent task definitions (infra/maps/art/scripts/iOS/audit).
- `development/RME/summary/*` — (this file added now) — commit-level audit and explanations.
- `scripts/patch/rme-repeat-map.sh` — wrapper/harness: preflight, placeholder handling, and run policy changes.
- `scripts/patch/rme-repeat-map.py` / `scripts/test/rme-repeat-map.py` — Python repeat-map harness (parity with runtime-sweep; timing and patchlog verification).
- `scripts/patch/rme-runtime-sweep.py` / `scripts/test/rme-runtime-sweep.py` — full 72-map runtime sweep harness (enforce click delay/hold and per-test minimums).
- `scripts/dev/patchlog_analyze.py` — analyzer improvements and outputs for suspicious GNW_SHOW_RECT detection.
- `scripts/test/test-macos*.sh` / `scripts/test/test-shutdown-sanity.sh` — new/updated test helpers and shutdown sanity checks.
- `src/game/main.cc` — added autorun-click instrumentation + shutdown triage points; mem-check hooks.
- `src/game/map.cc` — small map-related fixes touched during hygiene/triage.
- `src/plib/gnw/svga.cc` — renderer fix to prevent zero-source blits from wiping display (black-top fix).
- `src/plib/gnw/memory.cc` / `src/plib/gnw/gnw.cc` — defensive nulling, mem-check, and backtrace helpers for stomps/double-free triage.
- `src/plib/db/db.cc` / `src/plib/db/patchlog.h` — more verbose patchlog/db-path logging for triage.
- `GOG/patchedfiles/*` — removed/cleaned large duplicate assets (fonts/maps) as part of hygiene.

---

## Quick conclusions / next recommended steps
- Harness parity fix landed: `rme-repeat-map.py` (Python) now matches `rme-runtime-sweep.py` timing and `F1R_AUTORUN_MAP` behavior — run the 3× smoke for CARAVAN / ZDESERT1 / TEMPLAT1 next.
- Renderer and shutdown defensive fixes are in place; if flakiness remains, run ASan build and the `test-shutdown-sanity.sh` helper.
- I added this audit file to `development/RME/summary/` so the change history and rationale are recorded centrally.

---

Generated: 2026-02-13 (commit snapshot)

# RME Validation — PROGRESS

> Purpose: Single source of truth for subagent activity and evidence as we execute Phase 1 (Infrastructure) of the RME validation plan.

## Current Phase
- **Phase:** 1 — Infrastructure (Build, Patch, Validate, Install)
- **Owner:** automation
- **Start:** 2026-02-10
- **Status:** IN PROGRESS ⚙️

---

## Update Guidelines for Subagents
- ALWAYS append an entry with:
  - Date (UTC), Subagent name, Short summary (1 line)
  - Commands run (shell commands)
  - Evidence files created (explicit paths under `development/RME/ARTIFACTS/evidence/`) 
  - Commit hash (if changes committed)
- Commit the updated `PROGRESS.md` to the repo after your changes.

---

## Phase 1 Task Checklist (follow `TODO.infrastructure.md`)
- [x] I-0 — Prerequisites verified
  - Date: 2026-02-10T20:48:42Z
  - Subagent: Executor
  - Evidence: `development/RME/ARTIFACTS/evidence/gate-1/gate-1-prereq-check.txt`, `development/RME/ARTIFACTS/evidence/gate-1/gate-1-prereq-check-20260210T204843Z.txt`
  - Commit: dc52623

- [x] I-1 — Clean macOS build succeeded
  - Date: 2026-02-10T20:57:17Z
  - Subagent: Executor
  - Evidence: `development/RME/ARTIFACTS/evidence/gate-1/gate-1-build-log.txt`, `development/RME/ARTIFACTS/evidence/gate-1/gate-1-build-log-20260210T205645Z.txt`, `development/RME/ARTIFACTS/evidence/gate-1/gate-1-build-manifest.txt`, `development/RME/ARTIFACTS/evidence/gate-1/gate-1-build-manifest-20260210T205717Z.txt`
  - Commit: d4bb39d87814548e81808bd2f773248ac3dcca2b

- [x] I-2 — Fresh patched data generated
  - Date: 2026-02-10T20:59:48Z
  - Subagent: Executor
  - Evidence: `GOG/patchedfiles/` listing, `development/RME/ARTIFACTS/evidence/gate-1/gate-1-patch-log.txt`, `development/RME/ARTIFACTS/evidence/gate-1/gate-1-patch-log-20260210T205948Z.txt`
  - Commit: 306383b1e3fbc76280142800738ad53e637786ab

- [x] I-3 — Static validation passed
  - Date: 2026-02-10T21:00:34Z
  - Subagent: Executor
  - Evidence: `development/RME/ARTIFACTS/evidence/gate-1/gate-1-validate-output.txt`, `development/RME/ARTIFACTS/evidence/gate-1/gate-1-validate-output-20260210T210246Z.txt`
  - Commit: 4e69bbc72a62e4df8e31213f0ce506d48e41f7d9

- [x] I-4 — Validation evidence refreshed
  - Date: 2026-02-10T21:32:41Z
  - Subagent: Executor
  - Evidence: `development/RME/ARTIFACTS/evidence/gate-1/gate-1-refresh-output.txt`, `development/RME/ARTIFACTS/evidence/gate-1/gate-1-refresh-output-20260210-213241UTC.txt`, `development/RME/ARTIFACTS/evidence/gate-1/gate-1-manifest.txt`
  - Commit: 91a231b

- [x] I-5 — Patched data installed in app bundle and smoke test passed
  - Date: 2026-02-10T21:36:07Z
  - Subagent: Executor
  - Evidence: `development/RME/ARTIFACTS/evidence/gate-1/gate-1-install-log.txt`, `development/RME/ARTIFACTS/evidence/gate-1/gate-1-smoke-test.txt`, `development/RME/ARTIFACTS/evidence/gate-1/gate-1-manifest.txt`
  - Commit: 88eb4c0

---

## Recent Activity
- 2026-02-10 — automation — Created PROGRESS.md (this file)

- 2026-02-10T21:27:08Z — Executor — Installed `xdelta` via Homebrew and recorded verification.
  - Commands: `brew install xdelta`, `which xdelta3`, `xdelta3 --version`
  - Evidence: `development/RME/ARTIFACTS/evidence/gate-1/gate-1-install-xdelta.txt`, `development/RME/ARTIFACTS/evidence/gate-1/gate-1-manifest.txt`

- 2026-02-10T21:32:41Z — Executor — Re-ran refresh validation using Python 3.11 (PASS).
  - Commands: `PATH="$(brew --prefix python@3.11)/libexec/bin:$(brew --prefix python@3.11)/bin:$PATH" ./scripts/patch/rebirth-refresh-validation.sh --unpatched GOG/unpatchedfiles --patched GOG/patchedfiles --rme third_party/rme/source --out development/RME/ARTIFACTS/evidence/gate-1/`
  - Evidence: `development/RME/ARTIFACTS/evidence/gate-1/gate-1-refresh-output.txt`, `development/RME/ARTIFACTS/evidence/gate-1/gate-1-refresh-output-20260210-213241UTC.txt`, `development/RME/ARTIFACTS/evidence/gate-1/gate-1-manifest.txt`

- 2026-02-10T21:36:07Z — Executor — Installed patched DATs into app and performed smoke test (PASS).
  - Commands: `cp GOG/patchedfiles/master.dat $APP_RESOURCES/ && cp GOG/patchedfiles/critter.dat $APP_RESOURCES/ && rsync -av GOG/patchedfiles/data/ $APP_RESOURCES/data/ && open "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app" && pgrep -f fallout1-rebirth`
  - Evidence: `development/RME/ARTIFACTS/evidence/gate-1/gate-1-install-log.txt`, `development/RME/ARTIFACTS/evidence/gate-1/gate-1-smoke-test.txt`, `development/RME/ARTIFACTS/evidence/gate-1/gate-1-manifest.txt`
  - Commit: a1c6465

- 2026-02-10T21:55:25Z — Executor — Completed M-1 72-map runtime sweep (PASS).
  - Commands: `PATH="$(brew --prefix python@3.11)/libexec/bin:$(brew --prefix python@3.11)/bin:$PATH" python3 scripts/patch/rme-runtime-sweep.py --exe "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth" --timeout 90 --out-dir development/RME/ARTIFACTS/evidence/gate-2/runtime > development/RME/ARTIFACTS/evidence/gate-2/sweep-log.txt 2>&1`
  - Evidence: `development/RME/ARTIFACTS/evidence/gate-2/runtime/runtime_map_sweep.csv`, `development/RME/ARTIFACTS/evidence/gate-2/runtime/runtime_map_sweep_run.log`, `development/RME/ARTIFACTS/evidence/gate-2/runtime/runtime_map_sweep.md`, `development/RME/ARTIFACTS/evidence/gate-2/runtime/screenshots/`, `development/RME/ARTIFACTS/evidence/gate-2/gate-2-sweep-check.txt`
  - Commit: e3f2321

---

## Phase 2 Task Checklist (follow `TODO.maps.md`)
- [x] M-1 — 72-map runtime sweep (PASS)
  - Date: 2026-02-10T21:55:25Z
  - Subagent: Executor
  - Evidence: `development/RME/ARTIFACTS/evidence/gate-2/runtime/` (`runtime_map_sweep.csv`, `runtime_map_sweep_run.log`, `runtime_map_sweep.md`, `screenshots/`)

- [ ] M-2 — Patchlog sweep
  - Evidence: `development/RME/ARTIFACTS/evidence/gate-2/runtime/patchlogs/`

- [ ] M-3 — Analyze patchlogs
- [ ] M-4 — Review present-anomaly screenshots
- [ ] M-5 — Flaky map repeats
- [ ] M-6 — Big-endian map individual tests
- [ ] M-7 — Manual map verification

---

*Do not modify the format of this file unless you understand the update rules above.*

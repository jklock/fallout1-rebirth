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
- 2026-02-11T01:10:23Z — Executor — Re-ran M-5 CARAVAN (10 repeats, TIMEOUT=180) (FAIL).
  - Commands: `PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH" OUT_DIR=development/RME/ARTIFACTS/evidence/gate-2/runtime F1R_PATCHLOG=1 TIMEOUT=180 ./scripts/patch/rme-repeat-map.sh CARAVAN 10 > development/RME/ARTIFACTS/evidence/gate-2/repeats/CARAVAN-10-retry.txt 2>&1`
  - Evidence: `development/RME/ARTIFACTS/evidence/gate-2/repeats/CARAVAN-10-retry.txt`, `development/RME/ARTIFACTS/evidence/gate-2/repeats/CARAVAN-fail-01.patchlog.txt`, `development/RME/ARTIFACTS/evidence/gate-2/repeats/CARAVAN-fail-01.patchlog_analyze.txt`, `development/RME/ARTIFACTS/evidence/gate-2/repeats/CARAVAN-fail-01.run.log`, `development/RME/ARTIFACTS/evidence/gate-2/repeats/CARAVAN-fail-01.bmp`, `development/RME/ARTIFACTS/evidence/gate-2/repeats/CARAVAN-manual-run.log`, `development/RME/ARTIFACTS/evidence/gate-2/repeats/CARAVAN-manual-scr.bmp`
  - Commit: 19be36e
- 2026-02-11T01:10:23Z — Executor — Re-ran M-5 ZDESERT1 (10 repeats, TIMEOUT=180) (FAIL).
  - Commands: `PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH" OUT_DIR=development/RME/ARTIFACTS/evidence/gate-2/runtime F1R_PATCHLOG=1 TIMEOUT=180 ./scripts/patch/rme-repeat-map.sh ZDESERT1 10 > development/RME/ARTIFACTS/evidence/gate-2/repeats/ZDESERT1-10-retry.txt 2>&1`
  - Evidence: `development/RME/ARTIFACTS/evidence/gate-2/repeats/ZDESERT1-10-retry.txt`, `development/RME/ARTIFACTS/evidence/gate-2/repeats/ZDESERT1-fail-01.patchlog.txt`, `development/RME/ARTIFACTS/evidence/gate-2/repeats/ZDESERT1-fail-01.patchlog_analyze.txt`, `development/RME/ARTIFACTS/evidence/gate-2/repeats/ZDESERT1-fail-01.run.log`, `development/RME/ARTIFACTS/evidence/gate-2/repeats/ZDESERT1-fail-01.bmp`
  - Commit: 9a106e7
- 2026-02-11T01:10:23Z — Executor — Re-ran M-5 TEMPLAT1 (10 repeats, TIMEOUT=180) (FAIL).
  - Commands: `PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH" OUT_DIR=development/RME/ARTIFACTS/evidence/gate-2/runtime F1R_PATCHLOG=1 TIMEOUT=180 ./scripts/patch/rme-repeat-map.sh TEMPLAT1 10 > development/RME/ARTIFACTS/evidence/gate-2/repeats/TEMPLAT1-10-retry.txt 2>&1`
  - Evidence: `development/RME/ARTIFACTS/evidence/gate-2/repeats/TEMPLAT1-10-retry.txt`, `development/RME/ARTIFACTS/evidence/gate-2/repeats/TEMPLAT1-fail-01.patchlog.txt`, `development/RME/ARTIFACTS/evidence/gate-2/repeats/TEMPLAT1-fail-01.patchlog_analyze.txt`, `development/RME/ARTIFACTS/evidence/gate-2/repeats/TEMPLAT1-fail-01.run.log`, `development/RME/ARTIFACTS/evidence/gate-2/repeats/TEMPLAT1-fail-01.bmp`
  - Commit: d7b1baa
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

- 2026-02-10T22:09:46Z — Executor — Completed M-2 patchlog sweep (PASS).
  - Commands: `F1R_PATCHLOG=1 PATH="$(brew --prefix python@3.11)/libexec/bin:$(brew --prefix python@3.11)/bin:$PATH" python3 scripts/patch/rme-runtime-sweep.py --exe "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth" --timeout 90 --out-dir development/RME/ARTIFACTS/evidence/gate-2/runtime > development/RME/ARTIFACTS/evidence/gate-2/sweep-patchlog-log.txt 2>&1`
  - Evidence: `development/RME/ARTIFACTS/evidence/gate-2/runtime/patchlogs/` (72 patchlogs), `development/RME/ARTIFACTS/evidence/gate-2/gate-2-patchlog-count.txt`, `development/RME/ARTIFACTS/evidence/gate-2/gate-2-patchlog-warnings.txt`, `development/RME/ARTIFACTS/evidence/gate-2/sweep-patchlog-log.txt`
  - Commit: c3c580a

- 2026-02-10T22:30:15Z — Executor — Completed M-4 anomaly review (PASS).
  - Commands: `ls -1 development/RME/ARTIFACTS/evidence/gate-2/runtime/present-anomalies | wc -l && tail -n +2 development/RME/ARTIFACTS/evidence/gate-2/runtime/runtime_map_sweep.csv | wc -l && awk -F, '{sum += $2} END {print sum}' development/RME/ARTIFACTS/evidence/gate-2/gate-2-patchlog-map-warnings.csv`
  - Evidence: `development/RME/ARTIFACTS/evidence/gate-2/gate-2-anomaly-review.md`, `development/RME/ARTIFACTS/evidence/gate-2/runtime/runtime_map_sweep.md`, `development/RME/ARTIFACTS/evidence/gate-2/runtime/present-anomalies/`
  - Commit: 49a3a1b

- 2026-02-10T22:33:32Z — Executor — M-5 Flaky repeats (FAIL; stopped on CARAVAN run 1).
  - Commands: `PATH="$(brew --prefix python@3.11)/libexec/bin:$(brew --prefix python@3.11)/bin:$PATH" OUT_DIR=development/RME/ARTIFACTS/evidence/gate-2/runtime ./scripts/patch/rme-repeat-map.sh CARAVAN 10 > development/RME/ARTIFACTS/evidence/gate-2/repeats/CARAVAN-10.txt 2>&1`
  - Evidence: `development/RME/ARTIFACTS/evidence/gate-2/repeats/CARAVAN-10.txt`, `development/RME/ARTIFACTS/evidence/gate-2/gate-2-repeats-manifest.txt`, `development/RME/ARTIFACTS/evidence/gate-2/runtime/patchlogs/CARAVAN.iter01.patchlog_analyze.txt`
  - Commit: 328d51f

- 2026-02-10T22:39:20Z — Executor — Re-ran CARAVAN once with increased TIMEOUT=180 and patchlogging (FAIL).
  - Commands: `PATH="$(brew --prefix python@3.11)/libexec/bin:$(brew --prefix python@3.11)/bin:$PATH" F1R_PATCHLOG=1 TIMEOUT=180 OUT_DIR=development/RME/ARTIFACTS/evidence/gate-2/runtime ./scripts/patch/rme-repeat-map.sh CARAVAN 1 > development/RME/ARTIFACTS/evidence/gate-2/repeats/CARAVAN-1-timeout180.txt 2>&1`
  - Evidence: `development/RME/ARTIFACTS/evidence/gate-2/repeats/CARAVAN-1-timeout180.txt`, `development/RME/ARTIFACTS/evidence/gate-2/repeats/CARAVAN.iter01.patchlog_analyze.txt`, `development/RME/ARTIFACTS/evidence/gate-2/gate-2-caravan-rerun-summary.md`
  - Commit: 45ec8e4

- 2026-02-10T23:18:55Z — Executor — Re-ran M-5 CARAVAN (10 repeats) (FAIL; stopped on run 1).
  - Commands: `OUT_DIR="$(pwd)/development/RME/ARTIFACTS/evidence/gate-2/runtime" PATH="$(brew --prefix python@3.11)/libexec/bin:$(brew --prefix python@3.11)/bin:$PATH" ./scripts/patch/rme-repeat-map.sh CARAVAN 10 > development/RME/ARTIFACTS/evidence/gate-2/repeats/CARAVAN-10.txt 2>&1`
  - Evidence: `development/RME/ARTIFACTS/evidence/gate-2/repeats/CARAVAN-10.txt`, `development/RME/ARTIFACTS/evidence/gate-2/repeats/CARAVAN-fail-01.txt`, `development/RME/ARTIFACTS/evidence/gate-2/runtime/patchlogs/CARAVAN.iter01.patchlog_analyze.txt`, `development/RME/ARTIFACTS/evidence/gate-2/runtime/patchlogs/CARAVAN.iter01.patchlog.txt`, `development/RME/ARTIFACTS/evidence/gate-2/runtime/screenshots-individual/CARAVAN.iter01.bmp`
  - Commit: 1661bd5

- 2026-02-10T23:22:49Z — Executor — Re-ran M-5 ZDESERT1 (10 repeats) (FAIL; stopped on run 1).
  - Commands: `OUT_DIR="$(pwd)/development/RME/ARTIFACTS/evidence/gate-2/runtime" PATH="$(brew --prefix python@3.11)/libexec/bin:$(brew --prefix python@3.11)/bin:$PATH" ./scripts/patch/rme-repeat-map.sh ZDESERT1 10 > development/RME/ARTIFACTS/evidence/gate-2/repeats/ZDESERT1-10.txt 2>&1`
  - Evidence: `development/RME/ARTIFACTS/evidence/gate-2/repeats/ZDESERT1-10.txt`, `development/RME/ARTIFACTS/evidence/gate-2/repeats/ZDESERT1-fail-01.txt`, `development/RME/ARTIFACTS/evidence/gate-2/runtime/patchlogs/ZDESERT1.iter01.patchlog_analyze.txt`, `development/RME/ARTIFACTS/evidence/gate-2/runtime/patchlogs/ZDESERT1.iter01.patchlog.txt`, `development/RME/ARTIFACTS/evidence/gate-2/runtime/screenshots-individual/ZDESERT1.iter01.bmp`
  - Commit: 1661bd5

- 2026-02-10T23:24:40Z — Executor — Re-ran M-5 TEMPLAT1 (10 repeats) (FAIL; stopped on run 1).
  - Commands: `OUT_DIR="$(pwd)/development/RME/ARTIFACTS/evidence/gate-2/runtime" PATH="$(brew --prefix python@3.11)/libexec/bin:$(brew --prefix python@3.11)/bin:$PATH" ./scripts/patch/rme-repeat-map.sh TEMPLAT1 10 > development/RME/ARTIFACTS/evidence/gate-2/repeats/TEMPLAT1-10.txt 2>&1`
  - Evidence: `development/RME/ARTIFACTS/evidence/gate-2/repeats/TEMPLAT1-10.txt`, `development/RME/ARTIFACTS/evidence/gate-2/repeats/TEMPLAT1-fail-01.txt`, `development/RME/ARTIFACTS/evidence/gate-2/runtime/patchlogs/TEMPLAT1.iter01.patchlog_analyze.txt`, `development/RME/ARTIFACTS/evidence/gate-2/runtime/patchlogs/TEMPLAT1.iter01.patchlog.txt`, `development/RME/ARTIFACTS/evidence/gate-2/runtime/screenshots-individual/TEMPLAT1.iter01.bmp`
  - Commit: 1ab55b0

- 2026-02-10T23:40:00Z — Executor — M-5 triage completed (CARAVAN, ZDESERT1, TEMPLAT1).
  - Commands: Created triage reports and summary
  - Evidence: `development/RME/ARTIFACTS/evidence/gate-2/gate-2-triage-CARAVAN.md`, `development/RME/ARTIFACTS/evidence/gate-2/gate-2-triage-ZDESERT1.md`, `development/RME/ARTIFACTS/evidence/gate-2/gate-2-triage-TEMPLAT1.md`, `development/RME/ARTIFACTS/evidence/gate-2/gate-2-triage-summary.md`
  - Next: **Restore missing maps** (P0) and re-run M-5 repeats; if failures persist, collect `patchlog` + screenshot evidence and open render bug.

- 2026-02-11T00:51:11Z — Executor — Re-ran M-5 CARAVAN (10 repeats, TIMEOUT=180) (FAIL).
  - Commands: `PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH" OUT_DIR=development/RME/ARTIFACTS/evidence/gate-2/runtime F1R_PATCHLOG=1 TIMEOUT=180 ./scripts/patch/rme-repeat-map.sh CARAVAN 10 > development/RME/ARTIFACTS/evidence/gate-2/repeats/CARAVAN-10.txt 2>&1`
  - Evidence: `development/RME/ARTIFACTS/evidence/gate-2/repeats/CARAVAN-10.txt`, `development/RME/ARTIFACTS/evidence/gate-2/repeats/CARAVAN-fail-01.patchlog.txt`, `development/RME/ARTIFACTS/evidence/gate-2/repeats/CARAVAN-fail-01.run.log`, `development/RME/ARTIFACTS/evidence/gate-2/repeats/CARAVAN-fail-01.patchlog_analyze.txt`, `development/RME/ARTIFACTS/evidence/gate-2/repeats/CARAVAN-fail-01-present.bmp`, `development/RME/ARTIFACTS/evidence/gate-2/gate-2-triage-CARAVAN.md`
  - Commit: `a1e8b90`

- 2026-02-11T00:51:11Z — Executor — Re-ran M-5 ZDESERT1 (10 repeats, TIMEOUT=180) (FAIL).
  - Commands: `PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH" OUT_DIR=development/RME/ARTIFACTS/evidence/gate-2/runtime F1R_PATCHLOG=1 TIMEOUT=180 ./scripts/patch/rme-repeat-map.sh ZDESERT1 10 > development/RME/ARTIFACTS/evidence/gate-2/repeats/ZDESERT1-10.txt 2>&1`
  - Evidence: `development/RME/ARTIFACTS/evidence/gate-2/repeats/ZDESERT1-10.txt`, `development/RME/ARTIFACTS/evidence/gate-2/repeats/ZDESERT1-fail-01.patchlog.txt`, `development/RME/ARTIFACTS/evidence/gate-2/repeats/ZDESERT1-fail-01.run.log`, `development/RME/ARTIFACTS/evidence/gate-2/repeats/ZDESERT1-fail-01.patchlog_analyze.txt`, `development/RME/ARTIFACTS/evidence/gate-2/repeats/ZDESERT1-fail-01-present.bmp`, `development/RME/ARTIFACTS/evidence/gate-2/gate-2-triage-ZDESERT1.md`
  - Commit: `d13921f`

- 2026-02-11T00:51:11Z — Executor — Re-ran M-5 TEMPLAT1 (10 repeats, TIMEOUT=180) (FAIL).
  - Commands: `PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH" OUT_DIR=development/RME/ARTIFACTS/evidence/gate-2/runtime F1R_PATCHLOG=1 TIMEOUT=180 ./scripts/patch/rme-repeat-map.sh TEMPLAT1 10 > development/RME/ARTIFACTS/evidence/gate-2/repeats/TEMPLAT1-10.txt 2>&1`
  - Evidence: `development/RME/ARTIFACTS/evidence/gate-2/repeats/TEMPLAT1-10.txt`, `development/RME/ARTIFACTS/evidence/gate-2/repeats/TEMPLAT1-fail-01.patchlog.txt`, `development/RME/ARTIFACTS/evidence/gate-2/repeats/TEMPLAT1-fail-01.run.log`, `development/RME/ARTIFACTS/evidence/gate-2/repeats/TEMPLAT1-fail-01.patchlog_analyze.txt`, `development/RME/ARTIFACTS/evidence/gate-2/repeats/TEMPLAT1-fail-01-present.bmp`, `development/RME/ARTIFACTS/evidence/gate-2/gate-2-triage-TEMPLAT1.md`
  - Commit: `55cc8e7`


---

## Phase 2 Task Checklist (follow `TODO.maps.md`)
- [x] M-1 — 72-map runtime sweep (PASS)
  - Date: 2026-02-10T21:55:25Z
  - Subagent: Executor
  - Evidence: `development/RME/ARTIFACTS/evidence/gate-2/runtime/` (`runtime_map_sweep.csv`, `runtime_map_sweep_run.log`, `runtime_map_sweep.md`, `screenshots/`)

- [x] M-2 — Patchlog sweep (PASS)
  - Date: 2026-02-10T22:09:46Z
  - Subagent: Executor
  - Evidence: `development/RME/ARTIFACTS/evidence/gate-2/runtime/patchlogs/` (72 patchlogs), `development/RME/ARTIFACTS/evidence/gate-2/gate-2-patchlog-count.txt`, `development/RME/ARTIFACTS/evidence/gate-2/gate-2-patchlog-warnings.txt`, `development/RME/ARTIFACTS/evidence/gate-2/sweep-patchlog-log.txt`
  - Commit: TBD

- [x] M-3 — Analyze patchlogs (PASS)
  - Date: 2026-02-10T22:19:49Z
  - Subagent: Executor
  - Evidence: `development/RME/ARTIFACTS/evidence/gate-2/gate-2-patchlog-warn-counts.txt`, `development/RME/ARTIFACTS/evidence/gate-2/gate-2-patchlog-error-counts.txt`, `development/RME/ARTIFACTS/evidence/gate-2/gate-2-patchlog-map-warnings.csv`, `development/RME/ARTIFACTS/evidence/gate-2/gate-2-patchlog-top20.txt`, `development/RME/ARTIFACTS/evidence/gate-2/gate-2-patchlog-excerpts.txt`, `development/RME/ARTIFACTS/evidence/gate-2/gate-2-patchlog-summary.md`
  - Commands: `grep -rh "WARN" development/RME/ARTIFACTS/evidence/gate-2/runtime/patchlogs/ 2>/dev/null | sort | uniq -c | sort -rn > development/RME/ARTIFACTS/evidence/gate-2/gate-2-patchlog-warn-counts.txt`, `grep -rh "ERROR" development/RME/ARTIFACTS/evidence/gate-2/runtime/patchlogs/ 2>/dev/null | sort | uniq -c | sort -rn > development/RME/ARTIFACTS/evidence/gate-2/gate-2-patchlog-error-counts.txt`, `for f in development/RME/ARTIFACTS/evidence/gate-2/runtime/patchlogs/*.patchlog.txt; do n=$(grep -c "reason=missing\|DB_OPEN_FAIL" "$f" 2>/dev/null || echo 0); b=$(basename "$f" .patchlog.txt); echo "$b,$n"; done > development/RME/ARTIFACTS/evidence/gate-2/gate-2-patchlog-map-warnings.csv`, `grep -rh "reason=missing" development/RME/ARTIFACTS/evidence/gate-2/runtime/patchlogs/ 2>/dev/null | sed 's/^\[[^]]*\] //' | sort | uniq -c | sort -rn | head -n 40 > development/RME/ARTIFACTS/evidence/gate-2/gate-2-patchlog-top20.txt`, `# excerpts and summary generated (gate-2-patchlog-excerpts.txt, gate-2-patchlog-summary.md)`
  - Commit: 74d05e5
- [x] M-4 — Review present-anomaly screenshots (PASS)
  - Date: 2026-02-10T22:30:15Z
  - Subagent: Executor
  - Evidence: `development/RME/ARTIFACTS/evidence/gate-2/gate-2-anomaly-review.md`, `development/RME/ARTIFACTS/evidence/gate-2/runtime/runtime_map_sweep.md`, `development/RME/ARTIFACTS/evidence/gate-2/runtime/present-anomalies/`
  - Commit: 49a3a1b
- [x] M-5 — Flaky map repeats (FAIL)
  - Date: 2026-02-10T23:24:40Z
  - Subagent: Executor
  - Evidence: `development/RME/ARTIFACTS/evidence/gate-2/gate-2-repeats-manifest.txt`, `development/RME/ARTIFACTS/evidence/gate-2/repeats/CARAVAN-10.txt`, `development/RME/ARTIFACTS/evidence/gate-2/repeats/CARAVAN-fail-01.txt`, `development/RME/ARTIFACTS/evidence/gate-2/repeats/ZDESERT1-10.txt`, `development/RME/ARTIFACTS/evidence/gate-2/repeats/ZDESERT1-fail-01.txt`, `development/RME/ARTIFACTS/evidence/gate-2/repeats/TEMPLAT1-10.txt`, `development/RME/ARTIFACTS/evidence/gate-2/repeats/TEMPLAT1-fail-01.txt`, `development/RME/ARTIFACTS/evidence/gate-2/runtime/patchlogs/CARAVAN.iter01.patchlog_analyze.txt`
  - Commands: Re-ran `./scripts/patch/rme-repeat-map.sh` for CARAVAN, ZDESERT1, TEMPLAT1 with 10 repeats each, captured outputs in `development/RME/ARTIFACTS/evidence/gate-2/repeats/` and per-run artifacts in `development/RME/ARTIFACTS/evidence/gate-2/runtime/patchlogs/`
  - Commit: 1a085a8
- [ ] M-6 — Big-endian map individual tests
  - Note: NOT RUN (blocked by M-5 failure)
- [ ] M-7 — Manual map verification

---

*Do not modify the format of this file unless you understand the update rules above.*

- CARAVAN manual run: 2026-02-10T22:47:15Z - PATCHLOG SCREENSHOT - Next: retry under lldb if crash/hang persists.

- CARAVAN manual run: 2026-02-10T22:58:35Z - PATCHLOG SCREENSHOT - Next: retry under lldb if crash/hang persists.
- 2026-02-11T03:32:53Z — Executor — Automated ART tasks A-0..A-9 executed (file presence, LST integrity, and font checks). Evidence: development/RME/ARTIFACTS/evidence/gate-2/art/ (A-0..A-9 artifacts). Commits: ad332c7, 562c5be, 0b8b018, 4ffafe6, 5c1ece8, 3d913c8, a5667ba, a9e3d53, 03d4b46, 1c67cef, b7e371a

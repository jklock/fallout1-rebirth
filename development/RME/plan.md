# RME Integration — Plan (condensed)

Last updated: 2026-02-12
Status: In progress — static patching complete; runtime & gameplay verification pending

## Executive summary
- Static patch pipeline: 100% (1,126 files applied; checksums validated).
- Runtime verification: ~4% (3/72 maps swept). Several flaky maps (CARAVAN, ZDESERT1, TEMPLAT1) block the full sweep.
- Manual gameplay (macOS/iOS): 0% — required for final sign‑off.

Top 3 blockers
1. Flaky maps (M‑5): CARAVAN, ZDESERT1, TEMPLAT1 — need data/packaging or engine triage.
2. Missing/packaging assets in app bundle — verify patched files are installed by `rebi rth-patch-app`/install script.
3. No manual gameplay or iOS simulator validation done yet.

## Goal
Achieve: (A) 100% verified RME patch items (static + runtime) and (B) 100% game functionality on macOS and iOS.

## Acceptance criteria (short)
- Static: `rebirth-validate-data.sh` exits 0 and DAT checksums match.
- Runtime: `rme-runtime-sweep.py` produces a CSV with 72 rows; all flagged maps pass `rme-repeat-map.sh` retests.
- Gameplay: Gate‑3 (macOS) and Gate‑4 (iOS) checklists completed with evidence screenshots/logs.
- Packaging: DMG and IPA build and smoke tests pass.

## High-level milestones (priority)
1. Short (0–2 days): fix CARAVAN/ZDESERT1/TEMPLAT1 triage; re-run repeats; verify packaging scripts.
2. Week 1 (3–7 days): finish full 72‑map sweep; resolve any engine/data fixes from patchlog analysis.
3. Weeks 2–4: complete manual macOS gameplay, iOS simulator testing, package builds, and documentation/PR.

## Validation & primary commands
- Static validate: `./scripts/patch/rebirth-validate-data.sh --patched GOG/patchedfiles --base GOG/unpatchedfiles`
- Install patched data into app: `./scripts/test/test-install-game-data.sh --source GOG/patchedfiles --target "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app"`
- Full runtime sweep: `F1R_PATCHLOG=1 python3 scripts/patch/rme-runtime-sweep.py --exe "build-macos/RelWithDebInfo/.../fallout1-rebirth" --out-dir development/RME/ARTIFACTS/evidence/runtime`
- Flaky repeats: `./scripts/patch/rme-repeat-map.sh CARAVAN 10`

## Immediate next actions (owner + ETA)
- QA: Re-run CARAVAN repeat with patchlog (2–4 hrs).
- Engine: Triage GNW anomalies from `patchlog_analyze.py` (4–8 hrs if code fix required).
- Content: Confirm `GOG/patchedfiles` is fully present and packaging copies files into `.app` (1–2 hrs).

---

For detailed plan, gate definitions, and full validation checklist see `OUTCOME.md` and `todo.md` in this directory.
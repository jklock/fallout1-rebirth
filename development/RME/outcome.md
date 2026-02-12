# RME — Outcome summary & gate status

Last updated: 2026-02-12

Snapshot
- Static patching: 100% complete — all 1,126 RME files applied and checksummed (evidence in `development/RME/ARTIFACTS/evidence/gate-1/`).
- Runtime verification: partial — 3/72 maps swept; flaky maps blocking full sweep.
- Manual gameplay (macOS/iOS): not executed — Gate‑3 and Gate‑4 pending.

Gate status (short)
- Gate 1 — Static validation: PASSED ✅ (checksums, LST crossrefs, patch script)
- Gate 2 — Runtime sweep: PENDING ⚠️ (72‑map sweep not complete; flaky maps need triage)
- Gate 3 — macOS gameplay: PENDING ⬜ (manual evidence required)
- Gate 4 — iOS testing: PENDING ⬜ (simulator/device verification required)
- Gate 5 — Release packaging: PENDING ⬜ (DMG/IPA packaging + smoke)

Pass criteria (brief)
- 100% of patch items = static checks pass AND runtime sweep shows no map failures (CSV 72 rows) AND placeholder usage audited.
- 100% game functionality = Gate‑3 + Gate‑4 completed, manual gameplay evidence committed, DMG/IPA smoke tested.

Critical blockers (current)
1. CARAVAN/ZDESERT1/TEMPLAT1 flaky map failures — block full sweep and need engineering/content triage.
2. Some patched assets present in `GOG/patchedfiles` are not always copied to the app bundle — cause DB_OPEN_FAIL entries; fix install script or packaging.
3. No manual QA performed yet — must allocate a QA day for Gate‑3 evidence.

Required evidence for sign‑off
- Gate‑2: `runtime_map_sweep.csv` (72 data rows) + patchlogs + anomaly review
- Gate‑3: screenshots + per-criterion notes (see Gate‑3 checklist) under `ARTIFACTS/evidence/gate-3/`
- Gate‑4: simulator screenshots and `test-ios-simulator.sh` output under `ARTIFACTS/evidence/gate-4/`
- Gate‑5: DMG/IPA build logs under `ARTIFACTS/evidence/gate-5/`

Quick acceptance checks
- `./scripts/patch/rebirth-validate-data.sh` → exit 0 (static)
- `F1R_PATCHLOG=1 python3 scripts/patch/rme-runtime-sweep.py --exe "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth" --out-dir development/RME/ARTIFACTS/evidence/runtime` → CSV with 72 rows (runtime)
- `./scripts/test/test-rme-patchflow.sh --skip-build GOG/patchedfiles` → no new critical warnings

Next acceptance milestone
- Re-run M‑5 flaky map repeats and complete a 72-map sweep. Once sweep CSV = 72 rows and flaky maps pass 5/5, proceed with manual macOS gameplay verification.

Evidence locations (canonical)
- Static validation: `development/RME/ARTIFACTS/evidence/gate-1/`
- Runtime sweep & repeats: `development/RME/ARTIFACTS/evidence/gate-2/` and `/evidence/runtime/`
- Manual gameplay: `development/RME/ARTIFACTS/evidence/gate-3/`
- iOS: `development/RME/ARTIFACTS/evidence/gate-4/`
- Release: `development/RME/ARTIFACTS/evidence/gate-5/`

Status note
- The repo already contains detailed raw artifacts and triage docs (kept in archive). Outcome here is a short, verifiable snapshot; use the Plan file to run the next actions.
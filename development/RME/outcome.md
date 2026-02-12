# RME Integration — Outcome & Validation Gates

(derived and migrated from previous validation framework)

**Status:** All gates PENDING until evidence is committed for each criterion.

## Validation gates (summary)
- Gate 1 — Static Validation: data pipeline, LSTs, checksums, placeholder audit.
- Gate 2 — Runtime Map Sweep: 72/72 maps must load; all anomalies reviewed; flaky maps 5/5 pass.
- Gate 3 — macOS Gameplay: menu, new game, dialog, companions, animations, sound, save/load.
- Gate 4 — iOS Simulator: install, touch controls, map transitions, dialog.
- Gate 5 — Release Builds: DMG/IPA build and smoke tests.

Each gate has explicit, file-backed acceptance criteria; no gate may be marked PASSED without the required evidence (logs, CSVs, screenshots, patchlogs) committed under `development/RME/ARTIFACTS/evidence/`.

### Pass / fail rules (short)
- PASS = all gate criteria satisfied with evidence files committed.
- FAIL = any criterion fails.
- PENDING = not yet tested.

### Evidence locations (canonical)
- Gate 1: `ARTIFACTS/evidence/gate-1/`
- Gate 2: `ARTIFACTS/evidence/gate-2/`
- Gate 3: `ARTIFACTS/evidence/gate-3/`
- Gate 4: `ARTIFACTS/evidence/gate-4/`
- Gate 5: `ARTIFACTS/evidence/gate-5/`

---

For full gate tables, required files, and per-criterion checklists see the archived `development/RME_old/OUTCOME/OUTCOME.md` (copied content retained here). Update this `outcome.md` as evidence arrives.
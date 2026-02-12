# RME — Consolidated plan

Last updated: 2026-02-12
Status: In progress — static patch ✅, runtime verification partial (3/72 maps), manual gameplay not started

Purpose
- Provide a short, executable plan to finish RME integration: reach 100% patch coverage (static + runtime) and 100% game functionality (macOS + iOS verification).

Current top blockers
- Flaky maps: CARAVAN, ZDESERT1, TEMPLAT1 — these block the 72-map sweep.
- Packaging / missing assets: some patched files present in `GOG/patchedfiles` but not copied into the app bundle; causes DB_OPEN_FAIL and render anomalies.
- No manual QA or iOS simulator runs performed yet.

Goal (definition of done)
- Static: `rebirth-validate-data.sh` exit 0 + checksums match (already satisfied).
- Runtime: `rme-runtime-sweep.py` CSV contains 72 data rows; flaky maps pass 5/5 repeats.
- Gameplay: macOS gate‑3 checklist completed; iOS gate‑4 checklist completed; DMG/IPA built and smoke-tested.

Priority milestones (next 2 weeks)
1. P0 — Unblock M‑5: fix/triage CARAVAN, ZDESERT1, TEMPLAT1 and re-run 10× repeats (24–48h)
2. P0 — Full 72‑map runtime sweep with patchlog; triage and fix items discovered (48–72h)
3. P1 — Manual macOS gameplay smoke (main menu, new game, companions, save/load, 30m session) and capture evidence (1 day)
4. P1 — iOS simulator build + smoke test (1–2 days)
5. P2 — Resolve remaining art/script/proto issues and finalize Gate‑5 release packaging (2–7 days)

1‑Week plan (concrete)
- Day 0: Reproduce CARAVAN failure, run `./scripts/patch/rme-repeat-map.sh CARAVAN 10` with `F1R_PATCHLOG=1`.
- Day 1: If packaging issue — fix `scripts/test/test-install-game-data.sh` and re-install patched data into app; re-run CARAVAN.
- Day 2–3: Run full runtime sweep with `F1R_PATCHLOG=1` and triage patchlogs; fix high‑priority failures.
- Day 4: Manual macOS smoke & document Gate‑3 evidence.
- Day 5: Start iOS simulator test and fix platform-specific issues.

4‑Week plan (end state)
- Week 1: Complete runtime sweep + flaky-map fixes; close any engine-level blockers.
- Week 2: Script/dialog/proto runtime verification and fixes; automate basic autorun checks.
- Week 3: Art/prototype visual verification and fixes; finalize placeholder audit (replace `allnone.int`/`blank.frm` where needed).
- Week 4: iOS validation, packaging (DMG/IPA), docs, and final sign‑off.

Key acceptance tests (quick)
- Static: `./scripts/patch/rebirth-validate-data.sh --patched GOG/patchedfiles --base GOG/unpatchedfiles` → exit 0.
- Runtime sweep: `F1R_PATCHLOG=1 python3 scripts/patch/rme-runtime-sweep.py --exe "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth" --out-dir development/RME/ARTIFACTS/evidence/runtime` → CSV with 72 rows.
- Flaky map: `./scripts/patch/rme-repeat-map.sh CARAVAN 10` → 10/10 pass.
- macOS gameplay: complete Gate‑3 checklist (screenshots + notes).
- iOS: successful simulator install & 10‑minute play session.

Owners & rough effort estimates
- Engine dev: GNW/patchlog fixes, surf_pre/surf_post guards — Medium (1–3 days)
- Content dev: map/proto/art fixes — Medium (2–5 days)
- QA: full sweep + manual gameplay evidence — Medium (2–5 days)
- Release: packaging + sign‑off — Small (1–2 days)

Risks
- Engine-level GNW rendering bug; mitigation: isolate via patchlogs and add defensive guard.
- Case-fallback policy decision required (affects DB_OPEN_FAIL handling); mitigation: prefer data fixes and opt-in engine fallback if approved.

Immediate actions (do now)
1. F1R_PATCHLOG=1 ./scripts/patch/rme-repeat-map.sh CARAVAN 10
2. If that fails, verify `GOG/patchedfiles/data/maps/CARAVAN.MAP` is present and run `./scripts/test/test-install-game-data.sh`
3. Start full sweep with patchlog enabled and save results under `development/RME/ARTIFACTS/evidence/runtime`

Links & evidence locations
- Evidence root: `development/RME/ARTIFACTS/evidence/`
- Runtime scripts: `scripts/patch/rme-runtime-sweep.py`, `scripts/patch/rme-repeat-map.sh`
- Validation scripts: `./scripts/patch/rebirth-validate-data.sh`

---

If you want, I will convert the milestones above into GitHub issues and assign owners. Tell me to proceed.
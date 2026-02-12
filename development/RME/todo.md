# RME — Consolidated TODO (high-priority)

Last updated: 2026-02-12

## Top priority (P0)
- [ ] Re-run flaky repeats for CARAVAN, ZDESERT1, TEMPLAT1 with `F1R_PATCHLOG=1` and save outputs to `ARTIFACTS/evidence/gate-2/repeats/` (owner: QA, 2–4 hrs).
- [ ] Confirm `GOG/patchedfiles` is present and `scripts/test/test-install-game-data.sh` copies all map/font files into the `.app` bundle (owner: Content, 1–2 hrs).
- [ ] Review and accept/reject `development/RME/fixes-proposed/whitelist-proposed.diff` (owner: Maintainer, 1 hr).
- [ ] Start full runtime sweep (72 maps) after M‑5 resolved (owner: QA, 4–8 hrs).

## High priority (P1)
- [ ] Run full macOS manual gameplay checklist (Gate‑3) and commit evidence (owner: QA, 4–8 hrs).
- [ ] iOS simulator build + basic playtest (Gate‑4) — `./scripts/test/test-ios-simulator.sh` (owner: Mobile, 2–4 hrs).
- [ ] Patchlog analysis: run `scripts/dev/patchlog_analyze.py` on all new patchlogs and triage GNW anomalies (owner: Engine, 2–8 hrs).
- [ ] Placeholder audit: review `blank.frm` / `allnone.int` references and decide on fixes vs documented acceptance (owner: Content, 2–4 hrs).

## Medium priority (P2)
- [ ] Add unit/test coverage for case-fallback changes or accept policy (owner: Maintainer, 1–2 days).
- [ ] Improve `rme-runtime-sweep.py` robustness and retry handling for flaky maps (owner: Test Infra, 1–3 days).
- [ ] Update `development/RME/OUTCOME.md` and `plan.md` with gate progress after each major run (owner: QA, ongoing).

## Blocking notes (from prior TODOs)
- `20260212T030833Z` — missing `GOG/patchedfiles` path for patchflow orchestrator (supply patchedfiles or run `rebirth-patch-data.sh`).
- `20260212T042512Z` — whitelist proposals pending human approval.
- `20260212T050000Z` — case-fallback policy decision required (engine opt‑in vs data fix).

## Done criteria (for repository maintainer)
- All gate evidence files are present in `development/RME/ARTIFACTS/evidence/` and each gate table in `outcome.md` updated.
- `runtime_map_sweep.csv` contains 72 rows and any flagged maps have 5/5 retests passing.
- `GOG/patchedfiles` is canonical and used by the test harness.

---

If you want, I can split these into GitHub issues with assignees and estimates. Say “create issues” and I’ll prepare them.
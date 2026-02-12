# RME — Prioritized TODO (short, actionable)

Last updated: 2026-02-12

How to use
- Do tasks top → down. Each entry includes an exact command (when applicable), acceptance criteria, owner, and estimate.

P0 — Critical (blockers)
- [ ] Fix CARAVAN / ZDESERT1 / TEMPLAT1 flaky runs
  - Command: F1R_PATCHLOG=1 ./scripts/patch/rme-repeat-map.sh CARAVAN 10
  - Acceptance: 10/10 PASS for each map; failing patchlog explains root cause or a data/packaging fix applied
  - Owner: QA + Engine
  - Est: 4–8h

- [ ] Ensure patched data is installed into app bundle (packaging fix)
  - Command: ./scripts/test/test-install-game-data.sh && verify `ls build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/Resources/master.dat`
  - Acceptance: DATs and overlay files present in app Resources; DB_OPEN_FAIL no longer appears for packaged files
  - Owner: Release/Build
  - Est: 1–3h

- [ ] Run full 72‑map runtime sweep with patchlog
  - Command: F1R_PATCHLOG=1 python3 scripts/patch/rme-runtime-sweep.py --exe "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth" --timeout 120 --out-dir development/RME/ARTIFACTS/evidence/runtime
  - Acceptance: CSV contains 72 data rows; no untriaged CRITICAL errors in patchlogs
  - Owner: QA
  - Est: 3–8h (triage additional)

P1 — High priority
- [ ] Manual macOS gameplay smoke & evidence capture (Gate‑3)
  - Checklist: main menu, start new game, recruit companion, equip armor, dialog check, save+load, 30‑min session
  - Evidence: screenshots + notes in `development/RME/ARTIFACTS/evidence/gate-3/`
  - Owner: QA / Content
  - Est: 1 day

- [ ] iOS simulator build + smoke (Gate‑4)
  - Command: ./scripts/build/build-ios.sh && ./scripts/test/test-ios-simulator.sh
  - Acceptance: app installs + 10‑minute smoke test in simulator; evidence saved
  - Owner: Mobile / QA
  - Est: 1–2 days

- [ ] Approve or reject `development/RME/fixes-proposed/whitelist-proposed.diff`
  - Acceptance: whitelist applied or rejected and `test-rme-patchflow.sh` run to verify suppression of known warnings
  - Owner: Maintainer / Release
  - Est: 1–2h (review)

P2 — Medium priority
- [ ] Placeholder audit: list all `blank.frm` / `allnone.int` usages and decide fix vs accept
  - Command: grep -Ri "allnone\|blank.frm" development/RME || true
  - Acceptance: each placeholder has an owner and remediation plan documented
  - Owner: Content
  - Est: 1–2 days

- [ ] GNW / render anomaly diagnostics and guard (if required)
  - Files: `src/plib/gnw/svga.cc`, `src/plib/gnw/gnw.cc`, `src/plib/db/patchlog.cc`
  - Acceptance: surf_pre>0 && surf_post==0 case handled or data fix applied; patchlog false-positives suppressed
  - Owner: Engine
  - Est: 1–3 days

- [ ] Big‑endian maps: per-map validation (BROHD12, CHILDRN1/2, HUBDWNTN, HUBMIS1, HUBOLDTN, HUBWATER, JUNKCSNO, JUNKKILL)
  - Command: F1R_PATCHLOG=1 TIMEOUT=120 ./scripts/patch/rme-repeat-map.sh <MAP> 3
  - Acceptance: 3/3 PASS per map
  - Owner: Content + QA
  - Est: 1–2 days total

P3 — Low / follow-up
- [ ] Complete dialog/script runtime checks (select high‑impact NPCs and quest scripts)
- [ ] Sound + fonts visual/audio verification
- [ ] Final DMG/IPA packaging + smoke

Quick wins (do these first)
- [ ] Re-run `./scripts/patch/rebirth-validate-data.sh` (confirm static validation still passes)
- [ ] Run `python3 scripts/dev/patchlog_analyze.py development/RME/ARTIFACTS/evidence/runtime/patchlogs/*.patchlog.txt` after sweep
- [ ] Archive older repeat logs (done) and keep only current triage artifacts

Notes
- Evidence must be committed to `development/RME/ARTIFACTS/evidence/*` using the naming conventions in `OUTCOME.md`.
- If you want these TODOs converted to issues with assignees, say the word and I’ll create issue templates for each high‑priority item.

---

Ready to execute the top P0 items. Tell me which one to start (I can run the CARAVAN repeats or archive/cleanup the legacy files next).
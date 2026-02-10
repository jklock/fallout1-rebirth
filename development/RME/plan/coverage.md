# RME Coverage Plan (detailed)

## Goal
Prove the shipped RME payload matches GOG/patchedfiles, patches cleanly into user data, and runs crash-free with all RME content functional. Finish with archived evidence and clear pass/fail gates.

## Definition of Done (100%)
- Data integrity: `rebirth-validate-data.sh` → missing=0, mismatched=0; base DAT re-xdelta hashes match patched DATs.
- Crossref/LST clean: `08_lst_missing.md` empty; no unresolved references in rme-crossref outputs.
- Runtime clean: `runtime_map_sweep.csv` lists all maps (72) with zero failures/suspicious; `patchlog_summary.csv` all `suspicious=0`; present-anomalies empty; flaky-map repeats clean.
- Functional: per-mod spot checks in [../todo/validation_todo.md](../todo/validation_todo.md) pass (dialogs, NPC mod behaviors, restored content, fonts/SFX/art) with no crashes.
- Artifacts archived under development/RME/validation/ (and mirrored to GOG/validation/<timestamp>/) with command lines used.

## Prereqs
- Base data: `GOG/unpatchedfiles` (master.dat, critter.dat, data/).
- Canonical patched tree: `GOG/patchedfiles/`.
- RME payload: `third_party/rme/source/` (+ manifest.json, checksums.txt).
- Tools: `python3`, `xdelta3`, `rsync` (or `cp` fallback).
- Scripts used: `scripts/patch/rebirth-patch-data.sh`, `rebirth-patch-app.sh`, `rebirth-patch-ipa.sh`, `rebirth-validate-data.sh`, `rebirth-refresh-validation.sh`, `scripts/patch/rme-crossref.py`, `scripts/patch/rme-run-validation.sh`, `scripts/patch/rme-full-coverage.sh`, `scripts/patch/rme-repeat-map.sh`.

## Ordered Execution (ready-to-run)

0) Prep
- Verify base files exist; fail fast if `master.dat`, `critter.dat`, `data/` missing.
- Optionally clear old runtime artifacts: `rm -rf development/RME/validation/runtime && mkdir -p development/RME/validation/runtime`.

1) Inventory & reconcile (diffs, hashes, crossref, LST)
- Command:
  ```bash
  ./scripts/patch/rebirth-refresh-validation.sh \
    --unpatched GOG/unpatchedfiles \
    --patched GOG/patchedfiles \
    --rme third_party/rme/source \
    --out development/RME/validation
  ```
- Outputs: diffs (`unpatched_vs_patched.diff`, raw/01_*, 02_*), DAT hashes (master_*.sha256, critter_*.sha256, raw/04_dat_shasums.txt), crossref/LST (`raw/rme-crossref-patched.csv`, `raw/08_lst_missing.md`, `raw/lst_candidates.csv`, added_files/ext_counts), mirrors under GOG/rme_xref_patched.
- Pass: 08_lst_missing.md empty; unexpected deltas investigated/resolved.

2) Patch data (mac/iOS neutral)
- Command:
  ```bash
  ./scripts/patch/rebirth-patch-data.sh \
    --base GOG/unpatchedfiles \
    --out GOG/patchedfiles \
    --config-dir gameconfig/macos \
    --rme third_party/rme/source \
    --force | tee development/RME/validation/raw/patch_data.log
  ```
- Outputs: refreshed GOG/patchedfiles with master.dat, critter.dat, data/ (lowercase), configs copied.
- Pass: exit 0; no collision warnings; structure present.

3) Validate patched payload
- Command:
  ```bash
  ./scripts/patch/rebirth-validate-data.sh \
    --patched GOG/patchedfiles \
    --base GOG/unpatchedfiles \
    --rme third_party/rme/source | tee development/RME/validation/raw/validate_data.log
  ```
- Outputs: validate_data.log; missing=0, mismatched=0; DAT re-xdelta hashes checked.
- Pass: missing=0, mismatched=0.

4) Runtime sweep (one full pass)
- Command:
  ```bash
  PATCHED_DIR=GOG/patchedfiles BASE_DIR=GOG/unpatchedfiles RME_DIR=third_party/rme/source \
  OUT_DIR=development/RME/validation/runtime TIMEOUT=90 \
  F1R_PATCHLOG=1 F1R_PATCHLOG_VERBOSE=1 \
  ./scripts/patch/rme-run-validation.sh
  ```
- Outputs: runtime_map_sweep.{csv,md,run.log}, patchlogs/ + patchlog_summary.csv, screenshots/ (fail-only), present-anomalies/ (should be empty), per-map *_analyze.txt.
- Pass: 72 maps, failures=0, suspicious=0, no present anomalies.

5) Flaky-map repeats (only if needed)
- For CARAVAN, ZDESERT1/2/3, TEMPLAT1:
  ```bash
  OUT_DIR=development/RME/validation/runtime TIMEOUT=120 ./scripts/patch/rme-repeat-map.sh CARAVAN.MAP 5
  ```
- Outputs: per-iter patchlogs, run logs, analyzer outputs, optional screenshots.
- Pass: analyzer says “No suspicious GNW_SHOW_RECT surf_pre>0 && surf_post==0 found”; no `[TIMEOUT]`.

6) Functional spot checks (manual)
- Use patched macOS app (install via scripts/test/test-install-game-data.sh).
- Scenarios (log results to development/RME/validation/manual/functional_checks.md): dialogs (Killian, Aradesh, Hub merchant), NPC Mod recruit + combat, Restoration/Lou + ending slides, dialog fixes, art/sound (FO2 font, pistol SFX, mutant/Lou anims, childkiller icon).
- Pass: no crashes or missing assets/lines.

7) Archive
- Command:
  ```bash
  ts=$(date -u +%Y%m%dT%H%MZ); mkdir -p GOG/validation/$ts && rsync -av development/RME/validation/ GOG/validation/$ts/
  ```
- Pass: archive contains raw + runtime artifacts and manual notes; commands recorded.

8) Optional iOS sanity
- Patch iOS payload: `./scripts/patch/rebirth-patch-ipa.sh --base GOG/unpatchedfiles --out GOG/patchedfiles --rme third_party/rme/source --force`
- Optional tests: `./scripts/test/test-ios-headless.sh`, `./scripts/test/test-ios-simulator.sh --build-only`
- Pass: scripts exit 0; no missing data errors.

## Pass/Fail gates (all must be green)
- Crossref/LST clean (08_lst_missing.md empty; rme-crossref-patched.csv has no missing rows).
- Data validate: missing=0, mismatched=0; DAT hashes match re-xdelta.
- Runtime sweep: 72 maps, failures=0, suspicious=0, present-anomalies empty.
- Flaky repeats (if run): all targeted maps clean.
- Functional checks: all scenarios succeed; no crashes/missing dialogs/assets.
- Artifacts archived with commands.

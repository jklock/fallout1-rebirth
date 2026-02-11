# TODO: Maps — Runtime Sweep, Patchlog, Visual Verification

> **Purpose**: Validate all 72 game maps load correctly at runtime, with special focus on the 9 RME-modified maps and 21 GAM files.
> **Prerequisite**: Complete ALL tasks in `TODO.infrastructure.md` first.
> All commands run from the repo root: `cd /Volumes/Storage/GitHub/fallout1-rebirth`

---

## Background

### 9 RME-Modified Maps (Big-Endian MAP Files)

These maps were modified by RME and stored in big-endian format. The engine handles byte-swapping at load time via `src/game/map.cc`.

| Map | Location | What Changed |
|-----|----------|-------------|
| BROHD12 | Brotherhood of Steel L2 | Layout changes |
| CHILDRN1 | Children of the Cathedral 1 | Child NPC restoration |
| CHILDRN2 | Children of the Cathedral 2 | Child NPC restoration |
| HUBDWNTN | Hub Downtown | NPC/encounter changes |
| HUBMIS1 | Hub Missing Caravans | Quest-related changes |
| HUBOLDTN | Hub Old Town | NPC placement |
| HUBWATER | Hub Water Merchants | NPC/merchant changes |
| JUNKCSNO | Junktown Casino | NPC changes |
| JUNKKILL | Junktown Killian's | NPC changes |

### 21 RME GAM Files

GAM files store map-specific global variables. These were modified for quest/encounter logic:

DESCRVN1, DESCRVN2, DESCRVN3, DESCRVN4, HUBDWNTN, HUBENT, HUBHEIGT, HUBOLDTN, HUBWATER, JUNKCSNO, JUNKENT, JUNKKILL, LAADYTUM, LABLADES, LAFOLLWR, LAGUNRUN, MBENT, MNTCRVN1, MNTCRVN2, MNTCRVN4, SHADYE, SHADYW, VAULT13

---

## Task M-1: Complete 72-Map Runtime Sweep

**This is the #1 critical gap.** The previous sweep attempt crashed at map 4, producing only 3 CSV rows. A full sweep of all 72 maps is required to prove runtime stability.

- [ ] **Clean previous runtime evidence**
  ```bash
  rm -rf development/RME/ARTIFACTS/evidence/runtime/screenshots
  rm -f development/RME/ARTIFACTS/evidence/runtime/*.csv
  rm -f development/RME/ARTIFACTS/evidence/runtime/*.log
  mkdir -p development/RME/ARTIFACTS/evidence/runtime/screenshots
  ```

- [ ] **Run the full 72-map sweep**
  ```bash
  python3 scripts/patch/rme-runtime-sweep.py \
    --exe "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth" \
    --timeout 90 \
    --out-dir development/RME/ARTIFACTS/evidence/runtime
  ```
  **Expected**: Script iterates over all 72 maps, launching the engine for each. Each map gets a row in the CSV and a screenshot in the screenshots/ directory. Exit code 0.

- [ ] **Verify CSV completeness**
  ```bash
  wc -l development/RME/ARTIFACTS/evidence/runtime/*.csv
  ```
  **Expected**: 73 lines (1 header + 72 data rows).

- [ ] **Check for failures**
  ```bash
  grep -i "FAIL\|TIMEOUT\|ERROR\|CRASH" development/RME/ARTIFACTS/evidence/runtime/*.csv || echo "No failures found"
  ```
  **Expected**: "No failures found" — all maps should have PASS status.

- [ ] **Verify screenshots generated**
  ```bash
  ls development/RME/ARTIFACTS/evidence/runtime/screenshots/ | wc -l
  ```
  **Expected**: 72 screenshots (one per map).

- [ ] **Verify RME maps specifically loaded**
  ```bash
  grep -E "BROHD12|CHILDRN1|CHILDRN2|HUBDWNTN|HUBMIS1|HUBOLDTN|HUBWATER|JUNKCSNO|JUNKKILL" \
    development/RME/ARTIFACTS/evidence/runtime/*.csv
  ```
  **Expected**: All 9 RME maps appear with PASS status.

**If the sweep crashes or hangs**:
1. **Check which map crashed**: Look at the last row in the CSV. The map after that is the culprit.
2. **Run that map individually**: `python3 scripts/patch/rme-runtime-sweep.py --exe "..." --timeout 120 --limit 1`
3. **Check the engine log**: Look in `development/RME/ARTIFACTS/evidence/runtime/` for `.log` files.
4. **If a specific map crashes consistently**: Check patchlog diagnosis (Task M-2). The crash is likely a malformed MAP/GAM file or a missing art/proto reference.
5. **If timeout**: Increase `--timeout` to 120 or 180. Some maps with many scripts take longer.
6. **If crash at map load**: Check endianness handling in `src/game/map.cc` — the 9 RME maps are big-endian. Grep for `byteSwap` or endian-related code.

---

## Task M-2: Patchlog Sweep (F1R_PATCHLOG=1)

Run the sweep again with patchlogging enabled to capture per-map diagnostic output from the engine.

- [ ] **Run sweep with patchlogging**
  ```bash
  mkdir -p development/RME/ARTIFACTS/evidence/runtime/patchlogs
  F1R_PATCHLOG=1 python3 scripts/patch/rme-runtime-sweep.py \
    --exe "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth" \
    --timeout 90 \
    --out-dir development/RME/ARTIFACTS/evidence/runtime
  ```
  **Expected**: Same as M-1 but with additional patchlog files per map in the output directory.

- [ ] **Verify patchlogs were generated**
  ```bash
  ls development/RME/ARTIFACTS/evidence/runtime/patchlogs/ | wc -l
  ```
  **Expected**: 72 patchlog files (or a combined log).

- [ ] **Check for patchlog warnings**
  ```bash
  grep -rli "WARN\|ERROR\|missing\|not found" \
    development/RME/ARTIFACTS/evidence/runtime/patchlogs/ || echo "No warnings found"
  ```
  **Expected**: "No warnings found" (or only benign warnings).

**If patchlogs show issues**:
1. `missing FRM` → Art file not in critter.dat or data/art/ overlay. Check Task A-1 in `TODO.art.md`.
2. `missing PRO` → Prototype file missing. Check Task P-1 in `TODO.prototypes.md`.
3. `LST index out of range` → An LST file doesn't have enough entries. Check CRITTERS.LST or ITEMS.LST.
4. `map load failed` → Corrupted MAP file. Re-extract from RME source and re-patch.

---

## Task M-3: Analyze All Patchlogs

Aggregate patchlog data to identify patterns across all maps.

- [ ] **Count unique warnings**
  ```bash
  grep -rh "WARN" development/RME/ARTIFACTS/evidence/runtime/patchlogs/ 2>/dev/null | sort | uniq -c | sort -rn | head -20
  ```
  **Expected**: Zero warnings, or a small number of known-benign warnings.

- [ ] **Count unique errors**
  ```bash
  grep -rh "ERROR" development/RME/ARTIFACTS/evidence/runtime/patchlogs/ 2>/dev/null | sort | uniq -c | sort -rn | head -20
  ```
  **Expected**: Zero errors.

- [ ] **Check for missing asset references**
  ```bash
  grep -rh "not found\|missing\|cannot open\|failed to load" \
    development/RME/ARTIFACTS/evidence/runtime/patchlogs/ 2>/dev/null | sort | uniq -c | sort -rn | head -20
  ```
  **Expected**: No missing asset references.

- [ ] **Summarize results**
  ```bash
  echo "=== Patchlog Summary ==="
  echo "Total patchlogs: $(ls development/RME/ARTIFACTS/evidence/runtime/patchlogs/ 2>/dev/null | wc -l)"
  echo "Files with warnings: $(grep -rl 'WARN' development/RME/ARTIFACTS/evidence/runtime/patchlogs/ 2>/dev/null | wc -l)"
  echo "Files with errors: $(grep -rl 'ERROR' development/RME/ARTIFACTS/evidence/runtime/patchlogs/ 2>/dev/null | wc -l)"
  ```

**Remediation**: If significant errors appear, cross-reference the map name with the RME modification list above. Each error should be traceable to a specific file in `GOG/patchedfiles/data/` or inside the DATs.

---

## Task M-4: Review Present-Anomaly Screenshots

Check screenshots from the runtime sweep for visual anomalies (purple/pink tiles, black patches, missing sprites).

- [ ] **List screenshots**
  ```bash
  ls -la development/RME/ARTIFACTS/evidence/runtime/screenshots/
  ```
  **Expected**: 72 PNG/BMP files, each >0 bytes.

- [ ] **Check for zero-byte screenshots (indicates crash before render)**
  ```bash
  find development/RME/ARTIFACTS/evidence/runtime/screenshots/ -size 0 -print
  ```
  **Expected**: No output (no empty files).

- [ ] **Copy present-anomalies for review**
  ```bash
  mkdir -p development/RME/ARTIFACTS/evidence/runtime/present-anomalies
  # Manually inspect each screenshot. Move any with visual issues:
  # cp development/RME/ARTIFACTS/evidence/runtime/screenshots/MAPNAME.* \
  #    development/RME/ARTIFACTS/evidence/runtime/present-anomalies/
  ```

- [ ] **Visual inspection checklist** (manual — view each screenshot):
  - [ ] No magenta/pink placeholder tiles (indicates missing FRM)
  - [ ] No solid black patches (indicates missing tile data)
  - [ ] No obviously glitched geometry
  - [ ] RME maps (CHILDRN1, CHILDRN2, etc.) show expected NPCs/objects

**If anomalies detected**:
1. Pink/magenta tiles → FRM file missing from critter.dat or data/art/ overlay. Cross-reference with `TODO.art.md`.
2. Black patches → MAP tile references an art index that doesn't exist in the tileset.
3. Missing NPCs on CHILDRN maps → Child critter prototypes not loaded. Check CRITTERS.LST and PRO files in `TODO.prototypes.md`.

---

## Task M-5: Flaky Map Repeats

Three maps showed inconsistent behavior in prior testing. Run each 10 times to verify stability.

- [ ] **CARAVAN — 10 iterations**
  ```bash
  ./scripts/patch/rme-repeat-map.sh CARAVAN 10
  ```
  **Expected**: 10/10 PASS. Exit code 0.

  - **Result:** **FAIL** — stopped on run 1
    - Date: 2026-02-11T00:51:11Z
    - Evidence: `development/RME/ARTIFACTS/evidence/gate-2/repeats/CARAVAN-10.txt`, `development/RME/ARTIFACTS/evidence/gate-2/repeats/CARAVAN-fail-01.patchlog.txt`, `development/RME/ARTIFACTS/evidence/gate-2/repeats/CARAVAN-fail-01.run.log`, `development/RME/ARTIFACTS/evidence/gate-2/repeats/CARAVAN-fail-01.patchlog_analyze.txt`, `development/RME/ARTIFACTS/evidence/gate-2/repeats/CARAVAN-fail-01-present.bmp`, `development/RME/ARTIFACTS/evidence/gate-2/gate-2-triage-CARAVAN.md`
    - Commit: `19be36e`
    - Triage commit: `98ddc41`
    - Commit: `19be36e`

- [ ] **ZDESERT1 — 10 iterations**
  ```bash
  ./scripts/patch/rme-repeat-map.sh ZDESERT1 10
  ```
  **Expected**: 10/10 PASS. Exit code 0.

  - **Result:** **FAIL** — stopped on run 1
    - Date: 2026-02-11T00:51:11Z
    - Evidence: `development/RME/ARTIFACTS/evidence/gate-2/repeats/ZDESERT1-10.txt`, `development/RME/ARTIFACTS/evidence/gate-2/repeats/ZDESERT1-fail-01.patchlog.txt`, `development/RME/ARTIFACTS/evidence/gate-2/repeats/ZDESERT1-fail-01.run.log`, `development/RME/ARTIFACTS/evidence/gate-2/repeats/ZDESERT1-fail-01.patchlog_analyze.txt`, `development/RME/ARTIFACTS/evidence/gate-2/repeats/ZDESERT1-fail-01-present.bmp`, `development/RME/ARTIFACTS/evidence/gate-2/gate-2-triage-ZDESERT1.md`
    - Commit: `9a106e7`
    - Triage commit: `c54aa94`

- [ ] **TEMPLAT1 — 10 iterations**
  ```bash
  ./scripts/patch/rme-repeat-map.sh TEMPLAT1 10
  ```
  **Expected**: 10/10 PASS. Exit code 0.

  - **Result:** **FAIL** — stopped on run 1
    - Date: 2026-02-11T00:51:11Z
    - Evidence: `development/RME/ARTIFACTS/evidence/gate-2/repeats/TEMPLAT1-10.txt`, `development/RME/ARTIFACTS/evidence/gate-2/repeats/TEMPLAT1-fail-01.patchlog.txt`, `development/RME/ARTIFACTS/evidence/gate-2/repeats/TEMPLAT1-fail-01.run.log`, `development/RME/ARTIFACTS/evidence/gate-2/repeats/TEMPLAT1-fail-01.patchlog_analyze.txt`, `development/RME/ARTIFACTS/evidence/gate-2/repeats/TEMPLAT1-fail-01-present.bmp`, `development/RME/ARTIFACTS/evidence/gate-2/gate-2-triage-TEMPLAT1.md`
    - Commit: `d7b1baa`
    - Triage commit: `c2355fe`

- [ ] **Verify results**
  ```bash
  ls development/RME/ARTIFACTS/evidence/runtime/screenshots-individual/ | grep -c "CARAVAN"
  ls development/RME/ARTIFACTS/evidence/runtime/screenshots-individual/ | grep -c "ZDESERT1"
  ls development/RME/ARTIFACTS/evidence/runtime/screenshots-individual/ | grep -c "TEMPLAT1"
  ```
  **Expected**: 10 screenshots each.

**If flaky**:
1. If <10 PASS: Note which iterations fail.
2. Check patchlogs for failing iterations: `ls development/RME/ARTIFACTS/evidence/runtime/patchlogs/ | grep MAPNAME`
3. Random encounter maps (CARAVAN, ZDESERT1) may have timing sensitivity. Try increasing `TIMEOUT=120`.
4. TEMPLAT1 is a template map — if it consistently fails, it may be an unused placeholder.

---

## Task M-6: Test Each Big-Endian Map Individually

If the sweep (M-1) flags any of the 9 RME maps, test each individually with extended timeout and patchlogging.

- [ ] **BROHD12**
  ```bash
  F1R_PATCHLOG=1 TIMEOUT=120 ./scripts/patch/rme-repeat-map.sh BROHD12 3
  ```

- [ ] **CHILDRN1**
  ```bash
  F1R_PATCHLOG=1 TIMEOUT=120 ./scripts/patch/rme-repeat-map.sh CHILDRN1 3
  ```

- [ ] **CHILDRN2**
  ```bash
  F1R_PATCHLOG=1 TIMEOUT=120 ./scripts/patch/rme-repeat-map.sh CHILDRN2 3
  ```

- [ ] **HUBDWNTN**
  ```bash
  F1R_PATCHLOG=1 TIMEOUT=120 ./scripts/patch/rme-repeat-map.sh HUBDWNTN 3
  ```

- [ ] **HUBMIS1**
  ```bash
  F1R_PATCHLOG=1 TIMEOUT=120 ./scripts/patch/rme-repeat-map.sh HUBMIS1 3
  ```

- [ ] **HUBOLDTN**
  ```bash
  F1R_PATCHLOG=1 TIMEOUT=120 ./scripts/patch/rme-repeat-map.sh HUBOLDTN 3
  ```

- [ ] **HUBWATER**
  ```bash
  F1R_PATCHLOG=1 TIMEOUT=120 ./scripts/patch/rme-repeat-map.sh HUBWATER 3
  ```

- [ ] **JUNKCSNO**
  ```bash
  F1R_PATCHLOG=1 TIMEOUT=120 ./scripts/patch/rme-repeat-map.sh JUNKCSNO 3
  ```

- [ ] **JUNKKILL**
  ```bash
  F1R_PATCHLOG=1 TIMEOUT=120 ./scripts/patch/rme-repeat-map.sh JUNKKILL 3
  ```

**Expected**: All 9 maps pass 3/3 iterations each.

**If a big-endian map fails**:
1. Check patchlog output for the map name in `development/RME/ARTIFACTS/evidence/runtime/patchlogs/`.
2. Verify the MAP file is correctly byte-swapped: the engine reads big-endian headers in `src/game/map.cc`.
   ```bash
   # Check the first 4 bytes of the MAP file for endianness marker:
   xxd -l 16 "GOG/patchedfiles/data/maps/MAPNAME.MAP"
   ```
3. Verify the corresponding GAM file exists (if applicable):
   ```bash
   ls "GOG/patchedfiles/data/maps/MAPNAME.GAM" 2>/dev/null || echo "No GAM file"
   ```
4. Cross-reference LST file:
   ```bash
   grep -in "MAPNAME" GOG/patchedfiles/data/maps.txt 2>/dev/null
   ```
5. If the issue is a missing NPC reference, check `CRITTERS.LST` and the PRO files in `TODO.prototypes.md`.
6. Grep the engine source for endianness handling:
   ```bash
   grep -n "byteSwap\|big.endian\|BE_\|swap.*bytes" src/game/map.cc
   ```

---

## Task M-7: Manual Map Verification (Gameplay)

Load the game and manually visit each of the 9 RME-modified map areas. This verifies NPCs, tiles, and scripts are working in actual gameplay context.

- [ ] **Launch the game**
  ```bash
  open "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app"
  ```

- [ ] **CHILDRN1 / CHILDRN2 — Children of the Cathedral**
  - Navigate to: Cathedral area
  - **Look for**: Child NPCs visible and walking around
  - **Broken looks like**: Empty area where children should be, crash on area entry
  - **Notes**: These maps are the core children restoration content

- [ ] **HUBDWNTN — Hub Downtown**
  - Navigate to: Hub → Downtown area
  - **Look for**: All NPCs present, merchants accessible, no floating objects
  - **Broken looks like**: Missing NPC sprites, inaccessible areas

- [ ] **HUBOLDTN — Hub Old Town**
  - Navigate to: Hub → Old Town area
  - **Look for**: Correct NPC placement, no overlapping sprites
  - **Broken looks like**: NPCs in wrong positions, missing objects

- [ ] **HUBWATER — Hub Water Merchants**
  - Navigate to: Hub → Water Merchants area
  - **Look for**: Water merchant NPCs, correct dialog triggers
  - **Broken looks like**: Missing merchants, dialog doesn't trigger

- [ ] **HUBMIS1 — Hub Missing Caravans**
  - Navigate to: Hub → Caravan quest area
  - **Look for**: Quest-related NPCs and objects
  - **Broken looks like**: Quest NPCs absent, broken quest flow

- [ ] **JUNKCSNO — Junktown Casino**
  - Navigate to: Junktown → Casino
  - **Look for**: Casino NPCs, Gizmo, proper interior layout
  - **Broken looks like**: Missing interior objects, wrong NPC positions

- [ ] **JUNKKILL — Junktown Killian's**
  - Navigate to: Junktown → Killian's store
  - **Look for**: Killian NPC, store inventory accessible
  - **Broken looks like**: Missing Killian or broken store dialog

- [ ] **BROHD12 — Brotherhood of Steel Level 2**
  - Navigate to: Brotherhood bunker → Level 2
  - **Look for**: Correct layout, NPCs in expected positions
  - **Broken looks like**: Layout changes visible, missing objects

---

## Completion Checklist

| Step | Task | Status |
|------|------|--------|
| M-1 | 72-map runtime sweep complete (73-line CSV) | [x] |
| M-2 | Patchlog sweep complete | [x] |
| M-3 | Patchlog analysis — 0 errors | [x] |
| M-4 | Screenshot review — no visual anomalies | [x] |
| M-5 | Flaky map repeats — FAIL (see per-map triage) | [ ] |
| M-6 | 9 RME maps individually tested (27/27 PASS) | [ ] |
| M-7 | 9 RME maps manually verified in gameplay | [ ] |

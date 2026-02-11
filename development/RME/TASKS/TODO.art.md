# TODO: Art / FRM Validation

> **Purpose**: Verify all RME art assets (FRM files, LST indexes, PAL palettes) are intact and render correctly at runtime.
> **Prerequisite**: Complete ALL tasks in `TODO.infrastructure.md` first.
> All commands run from the repo root: `cd /Volumes/Storage/GitHub/fallout1-rebirth`

---

## Background

RME adds or modifies **387 art-related files** across two categories:

### Critter Art (375 files in `data/art/critters/`)

| Prefix | Count | Description |
|--------|-------|-------------|
| HANPWR* | ~153 | Power Armor Male (Hardened) — full animation set |
| HAPWR* | ~29 | Power Armor variant animations |
| HFCMBT* | 8 | Female Combat Armor animations |
| HMCMBT* | 8 | Male Combat Armor animations |
| HMMAXX* | 1 | Male character animation fix |
| HMMETL* | 1 | Metal Armor animation fix |
| MALIEU* | ~41 | Super Mutant (Lou/Lieutenant) — unique NPC art |
| MAMTNT* | ~31 | Mutant variant animations |
| NACHLD* | ~103 | Child NPC — full animation set (walk, idle, death, etc.) |
| CRITTERS.LST | 1 | Master index file for all critter art |

### Master Art (12 files spread across `data/art/` subdirectories)

| Path | File | Description |
|------|------|-------------|
| `art/intrface/` | BOSHARRY.FRM | Boss Harry dialog portrait |
| `art/intrface/` | BOSHARRY.PAL | Boss Harry palette |
| `art/intrface/` | INTRFACE.LST | Interface art index |
| `art/inven/` | INVEN.LST | Inventory art index |
| `art/inven/` | PARMOR2.FRM | Hardened Power Armor inventory sprite |
| `art/inven/` | ROCK2.FRM | Rock2 inventory sprite |
| `art/items/` | ITEMS.LST | Items art index |
| `art/items/` | PARMOR2.FRM | Hardened Power Armor ground sprite |
| `art/items/` | ROCK2.FRM | Rock2 ground sprite |
| `art/skilldex/` | ADDICT.FRM | Addict reputation image |
| `art/skilldex/` | DRUGREST.FRM | Drug restriction image |
| `art/skilldex/` | REPCHILD.FRM | Childkiller reputation image |

---

## Task A-0: Verify interface fonts (font*.aaf)

**Purpose**: Ensure interface font files are present in the app Resources so FMInit can load fonts successfully and UI text renders correctly.

- [x] **Check for font files in app Resources** — automation complete (2026-02-11); see `development/RME/ARTIFACTS/evidence/gate-2/art/A-0-fonts-in-resources.txt`
  ```bash
  ls "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/Resources" | grep -Ei "font[0-9]+\.aaf" || echo "No interface fonts found"
  ```

- [x] **Install fonts from patched data** — automation complete (2026-02-11); installed/verified SHA256s recorded in `development/RME/ARTIFACTS/evidence/gate-2/art/A-0-fonts-installed-sha256.txt`
  ```bash
  mkdir -p "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/Resources"
  cp GOG/patchedfiles/data/font*.aaf "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/Resources/"
  ```

- [x] **Verify FMInit success in runtime logs** — automation complete (2026-02-11); see `development/RME/ARTIFACTS/evidence/gate-2/art/A-0-fonts-runtime-misses.txt` (note: DB_OPEN_FAIL entries found in runtime patchlogs)
  ```bash
  # Look for errors indicating fonts could not be loaded
  grep -R "Couldn't find/load text fonts" -n development/RME/ARTIFACTS/evidence/gate-2 || echo "No font errors found"
  ```

## Task A-1: Verify Critter FRM File Presence

- [x] **Automated checks:** counts and prefix inventory run (2026-02-11) — automation complete; manual visual verification still required. Evidence: `development/RME/ARTIFACTS/evidence/gate-2/art/A-1-critter-counts.txt`

Confirm all expected critter art files were patched into the game data.

- [ ] **Total critter art file count**
  ```bash
  ls GOG/patchedfiles/data/art/critters/ | wc -l
  ```
  **Expected**: 375+ files (exact count depends on base data; the overlay adds 375 files).

- [ ] **HANPWR (Hardened Power Armor Male) — ~153 files**
  ```bash
  ls GOG/patchedfiles/data/art/critters/ | grep -ci "hanpwr"
  ```
  **Expected**: ~153

- [ ] **HAPWR (Power Armor variant) — ~29 files**
  ```bash
  ls GOG/patchedfiles/data/art/critters/ | grep -ci "hapwr"
  ```
  **Expected**: ~29 (note: `grep -ci "hapwr"` may include HANPWR matches; use more precise pattern if needed)
  ```bash
  # More precise:
  ls GOG/patchedfiles/data/art/critters/ | grep -ci "^hapwr"
  ```

- [ ] **HFCMBT (Female Combat Armor) — 8 files**
  ```bash
  ls GOG/patchedfiles/data/art/critters/ | grep -ci "hfcmbt"
  ```
  **Expected**: 8

- [ ] **HMCMBT (Male Combat Armor) — 8 files**
  ```bash
  ls GOG/patchedfiles/data/art/critters/ | grep -ci "hmcmbt"
  ```
  **Expected**: 8

- [ ] **HMMAXX (Male anim fix) — 1 file**
  ```bash
  ls GOG/patchedfiles/data/art/critters/ | grep -ci "hmmaxx"
  ```
  **Expected**: 1

- [ ] **HMMETL (Metal Armor fix) — 1 file**
  ```bash
  ls GOG/patchedfiles/data/art/critters/ | grep -ci "hmmetl"
  ```
  **Expected**: 1

- [ ] **MALIEU (Super Mutant / Lieutenant) — ~41 files**
  ```bash
  ls GOG/patchedfiles/data/art/critters/ | grep -ci "malieu"
  ```
  **Expected**: ~41

- [ ] **MAMTNT (Mutant variant) — ~31 files**
  ```bash
  ls GOG/patchedfiles/data/art/critters/ | grep -ci "mamtnt"
  ```
  **Expected**: ~31

- [ ] **NACHLD (Child NPC) — ~103 files**
  ```bash
  ls GOG/patchedfiles/data/art/critters/ | grep -ci "nachld"
  ```
  **Expected**: ~103

- [ ] **CRITTERS.LST present**
  ```bash
  ls -la GOG/patchedfiles/data/art/critters/CRITTERS.LST 2>/dev/null || \
  ls -la GOG/patchedfiles/data/art/critters/critters.lst 2>/dev/null || \
  echo "CRITTERS.LST NOT FOUND"
  ```
  **Expected**: File present, non-zero size.

**If files are missing**:
1. Re-run patching: `./scripts/patch/rebirth-patch-app.sh --base GOG/unpatchedfiles --out GOG/patchedfiles --force`
2. Check the RME source payload: `ls third_party/rme/source/data/art/critters/ | wc -l`
3. Check for case sensitivity issues: `ls GOG/patchedfiles/data/art/critters/ | sort -f | uniq -di` (duplicates ignoring case)

---

## Task A-2: Verify CRITTERS.LST Integrity

- [x] **Automated checks:** LST integrity and cross-reference run (2026-02-11) — automation complete; manual visual verification still required where applicable. Evidence: `development/RME/ARTIFACTS/evidence/gate-2/art/A-2-critter-lst-wc.txt`, `development/RME/ARTIFACTS/evidence/gate-2/art/A-2-critter-lst-snippet.txt`, `development/RME/ARTIFACTS/evidence/gate-2/art/A-2-lst-entries.txt`, `development/RME/ARTIFACTS/evidence/gate-2/art/A-2-frm-vs-lst-diff.txt`

CRITTERS.LST is the master index that maps FID (Frame ID) numbers to FRM filenames. If entries are wrong or missing, critters appear as invisible or cause crashes.

- [ ] **Count entries in CRITTERS.LST**
  ```bash
  # Find the file (case-insensitive)
  CRITTERS_LST=$(find GOG/patchedfiles/data/art/critters/ -iname "critters.lst" -print -quit)
  wc -l "$CRITTERS_LST"
  ```
  **Expected**: 400+ lines (base game has ~312 entries; RME adds ~90 for armored companion variants).

- [ ] **Check that RME NPC entries are indexed**
  ```bash
  # New critter PROs are 313-402, so LST should have entries at those line numbers
  CRITTERS_LST=$(find GOG/patchedfiles/data/art/critters/ -iname "critters.lst" -print -quit)
  sed -n '310,405p' "$CRITTERS_LST"
  ```
  **Expected**: Lines 313-402 should contain FRM filename references (not blank or placeholder).

- [ ] **Check for NACHLD entry**
  ```bash
  CRITTERS_LST=$(find GOG/patchedfiles/data/art/critters/ -iname "critters.lst" -print -quit)
  grep -in "nachld" "$CRITTERS_LST"
  ```
  **Expected**: At least one entry referencing NACHLD art files.

- [ ] **Check for HANPWR entry**
  ```bash
  CRITTERS_LST=$(find GOG/patchedfiles/data/art/critters/ -iname "critters.lst" -print -quit)
  grep -in "hanpwr" "$CRITTERS_LST"
  ```
  **Expected**: At least one entry referencing HANPWR art files.

- [ ] **Check for MALIEU entry (Lieutenant)**
  ```bash
  CRITTERS_LST=$(find GOG/patchedfiles/data/art/critters/ -iname "critters.lst" -print -quit)
  grep -in "malieu" "$CRITTERS_LST"
  ```
  **Expected**: Entry present for the Lieutenant's unique art.

- [ ] **Cross-reference: are there FRM files not listed in LST?**
  ```bash
  # Extract base filenames from LST (first field before comma/space)
  CRITTERS_LST=$(find GOG/patchedfiles/data/art/critters/ -iname "critters.lst" -print -quit)
  awk -F'[, ]' '{print tolower($1)}' "$CRITTERS_LST" | sort > /tmp/lst_entries.txt
  # List FRM files in directory
  ls GOG/patchedfiles/data/art/critters/*.FRM GOG/patchedfiles/data/art/critters/*.frm 2>/dev/null \
    | xargs -I{} basename {} | tr '[:upper:]' '[:lower:]' | sort > /tmp/dir_frms.txt
  # Show FRMs not in LST (these are overlay files; some may be loaded by FID from PRO)
  comm -23 /tmp/dir_frms.txt /tmp/lst_entries.txt | head -20
  ```
  **Expected**: Most FRM files should be referenced in the LST. Some overlay files may exist as loose overrides.

**If CRITTERS.LST is wrong**:
1. Compare with RME source: `diff <CRITTERS_LST> third_party/rme/source/data/art/critters/CRITTERS.LST`
2. Re-patch data (Task I-2 in `TODO.infrastructure.md`).
3. The engine resolves critter art via FID → LST line number → FRM filename. Wrong LST = wrong sprite.

---

## Task A-3: Visual Test — Children NPCs (Hub / Junktown)

The NACHLD art set is the children restoration content — the core purpose of RME.

- [ ] **Launch the game**
  ```bash
  open "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app"
  ```

- [ ] **Navigate to Hub Downtown** (HUBDWNTN map)
  - **Look for**: Small child NPC sprites walking around
  - **Correct**: Children are visible, have proper walk/idle animations (not T-posing or frozen)
  - **Broken looks like**: No children visible, or children appear as adult sprites, or pink/magenta placeholder art
  - **Critical**: If children are invisible, check that CRITTERS.LST has NACHLD entries AND the child PRO FID points to the correct LST line

- [ ] **Navigate to Junktown** (JUNKCSNO, JUNKKILL areas)
  - **Look for**: Child NPCs if they should appear in these areas
  - **Correct**: Any child NPCs have proper animations
  - **Broken looks like**: Same as above

- [ ] **Navigate to Children of the Cathedral** (CHILDRN1, CHILDRN2 maps)
  - **Look for**: Child NPCs restored to the cathedral area
  - **Correct**: Children visible with animations
  - **Broken looks like**: Empty cathedral areas, crash on map entry

**Remediation if children don't appear**:
1. Check CRITTERS.LST has NACHLD entries (Task A-2).
2. Check the child PRO files reference the correct FID: `xxd -s 28 -l 4 GOG/patchedfiles/data/proto/critters/00000XXX.pro` (FID is at offset 0x1C in PRO header).
3. Verify NACHLD FRM files exist in `GOG/patchedfiles/data/art/critters/`.
4. Check the MAP file's object list references the correct PRO PID for children.

---

## Task A-4: Visual Test — Super Mutant Walking (Necropolis / Military Base)

MAMTNT art provides mutant walking animations.

- [ ] **Navigate to Necropolis** (via world map)
  - **Look for**: Super mutant NPCs patrolling, walking animations smooth
  - **Correct**: Mutants walk with full 6-direction animation frames
  - **Broken looks like**: Mutants frozen in place, single-frame animation, wrong sprite (human appearing as mutant)

- [ ] **Navigate to Military Base entrance** (MBENT map)
  - **Look for**: Mutant guards with proper animations
  - **Correct**: Guards animate when alerted, combat animations play
  - **Broken looks like**: Guards T-pose, combat causes crash

**Remediation**:
1. Check MAMTNT FRM files: `ls GOG/patchedfiles/data/art/critters/ | grep -ci mamtnt`
2. Verify CRITTERS.LST has MAMTNT entry: `grep -in mamtnt <CRITTERS_LST>`
3. If wrong animation plays: the FID in the mutant PRO points to wrong LST line. Compare with original.

---

## Task A-5: Visual Test — Lou/Lieutenant Animations (Military Base)

MALIEU art provides the Lieutenant's unique sprite set.

- [ ] **Navigate to Military Base — Lieutenant's room**
  - **Look for**: The Lieutenant NPC with unique appearance (not generic super mutant)
  - **Correct**: Lieutenant has distinct sprite, dialog portrait works, combat animations play
  - **Broken looks like**: Lieutenant uses generic mutant sprite, or is invisible, or dialog has missing portrait

**Remediation**:
1. Check MALIEU FRM files: `ls GOG/patchedfiles/data/art/critters/ | grep -ci malieu`
2. Verify CRITTERS.LST has MALIEU entry: `grep -in malieu <CRITTERS_LST>`
3. Check the Lieutenant's PRO file FID matches the MALIEU LST line number.

---

## Task A-6: Visual Test — Boss Harry Dialog Portrait

BOSHARRY.FRM + BOSHARRY.PAL in `art/intrface/`.

- [ ] **Navigate to an encounter with Harry** (Super Mutant at Necropolis watershed or Military Base)
  - **Look for**: Dialog portrait showing a unique NPC face (not generic)
  - **Correct**: Harry's portrait renders with proper palette colors
  - **Broken looks like**: Black/corrupted portrait, wrong colors (palette issue), missing portrait frame

- [ ] **Verify art file integrity**
  ```bash
  ls -la GOG/patchedfiles/data/art/intrface/BOSHARRY.FRM \
        GOG/patchedfiles/data/art/intrface/BOSHARRY.PAL 2>/dev/null || \
  ls -la GOG/patchedfiles/data/art/intrface/bosharry.frm \
        GOG/patchedfiles/data/art/intrface/bosharry.pal 2>/dev/null || \
  echo "BOSHARRY files NOT FOUND"
  ```
  **Expected**: Both `.FRM` and `.PAL` files present, non-zero size.

- [ ] **Verify INTRFACE.LST references BOSHARRY**
  ```bash
  INTRFACE_LST=$(find GOG/patchedfiles/data/art/intrface/ -iname "intrface.lst" -print -quit)
  grep -in "bosharry" "$INTRFACE_LST" || echo "BOSHARRY not in INTRFACE.LST"
  ```
  **Expected**: Entry present.

**Remediation**:
1. Missing PAL file causes wrong colors → Verify both FRM and PAL are present.
2. Missing LST entry causes engine to not find the art → Add entry to INTRFACE.LST.
3. Wrong palette → Compare PAL file with RME source: `diff GOG/patchedfiles/data/art/intrface/BOSHARRY.PAL third_party/rme/source/data/art/intrface/BOSHARRY.PAL`

---

## Task A-7: Visual Test — Death Animations

Several critter art sets include death animations (DA, DB suffix in FRM filenames). These play when an NPC dies in combat.

- [ ] **Verify death animation FRMs exist**
  ```bash
  ls GOG/patchedfiles/data/art/critters/ | grep -ciE "(hanpwr|nachld|mamtnt|malieu).*(da|db|dc)" 
  ```
  **Expected**: Multiple death animation files found.

- [ ] **In-game test**: Enter combat with a child NPC area (may require save editing) or with mutants
  - **Look for**: Death animation plays (NPC falls, blood splatter)
  - **Correct**: Full animation sequence, no freeze
  - **Broken looks like**: NPC disappears instantly (no animation), or game crashes on death

**Remediation**:
1. Missing death animation FRM → Check if DA/DB/DC suffix files exist for that critter prefix.
2. Crash on death → FID for death anim frame references beyond LST bounds. Check CRITTERS.LST line count.

---

## Task A-8: Visual Test — Reputation / Skilldex Art

Three skilldex FRM files: ADDICT.FRM, DRUGREST.FRM, REPCHILD.FRM.

- [ ] **Verify files present**
  ```bash
  ls -la GOG/patchedfiles/data/art/skilldex/ADDICT.FRM \
        GOG/patchedfiles/data/art/skilldex/DRUGREST.FRM \
        GOG/patchedfiles/data/art/skilldex/REPCHILD.FRM 2>/dev/null || \
  # Try lowercase:
  ls -la GOG/patchedfiles/data/art/skilldex/addict.frm \
        GOG/patchedfiles/data/art/skilldex/drugrest.frm \
        GOG/patchedfiles/data/art/skilldex/repchild.frm 2>/dev/null || \
  echo "Skilldex FRM files NOT FOUND"
  ```
  **Expected**: All three files present, non-zero size.

- [ ] **In-game test — REPCHILD (Childkiller reputation)**
  - **How to trigger**: Kill a child NPC (requires children restoration to work)
  - **Look for**: "Childkiller" reputation entry in character screen with REPCHILD image
  - **Correct**: Image renders in reputation list
  - **Broken looks like**: Blank space or missing image in reputation entry

- [ ] **In-game test — ADDICT (Addiction)**
  - **How to trigger**: Use drugs repeatedly (Buffout, Mentats, etc.)
  - **Look for**: Addiction status with ADDICT image
  - **Correct**: Image renders in status effects

- [ ] **In-game test — DRUGREST (Drug restriction)**
  - **How to trigger**: Related to Followers drug quest
  - **Correct**: Image renders when relevant quest/status active

**Remediation**: If images don't display, check the corresponding LST file indexes the FRM correctly. The engine loads skilldex art by LST index.

---

## Task A-9: Visual Test — NPC Armor Sprites (Companion Equipping Armor)

The NPC Mod adds armored variants for companions (Ian, Tycho, Katja, etc.). This requires working HFCMBT, HMCMBT, HANPWR, HAPWR, HMMETL art sets.

- [ ] **Recruit Ian** (Shady Sands → Hub)
  - Equip Ian with **Leather Armor**
  - **Look for**: Ian's sprite changes to leather armor variant
  - **Correct**: Sprite updates, walking/combat animations work with new sprite

- [ ] **Equip Ian with Metal Armor**
  - **Look for**: Sprite changes to metal armor variant (HMMETL prefix)
  - **Correct**: Full animation set works

- [ ] **Equip Ian with Combat Armor**
  - **Look for**: Sprite changes to combat armor variant (HMCMBT prefix)
  - **Correct**: Full animation set works

- [ ] **Equip Ian with Power Armor**
  - **Look for**: Sprite changes to power armor variant (HAPWR/HANPWR prefix)
  - **Correct**: Full animation set works

- [ ] **Test female companion (Katja)**
  - Equip with Combat Armor
  - **Look for**: Female combat armor sprite (HFCMBT prefix)
  - **Correct**: Sprite updates correctly

**Remediation if sprite doesn't change**:
1. The companion's PRO file must have the armored variant PRO references. Check `TODO.prototypes.md` Task P-5 through P-8.
2. The armored PRO must reference the correct FID → CRITTERS.LST line → FRM prefix.
3. Verify art files exist:
   ```bash
   ls GOG/patchedfiles/data/art/critters/ | grep -ci "hmcmbt"  # male combat armor
   ls GOG/patchedfiles/data/art/critters/ | grep -ci "hfcmbt"  # female combat armor
   ls GOG/patchedfiles/data/art/critters/ | grep -ci "hanpwr"  # hardened power armor
   ```

---

## Task A-10: Verify INTRFACE.LST

INTRFACE.LST in the RME version is **smaller** than the original — some entries were removed and replaced with `blank.frm` placeholders. This is intentional but must be verified.

- [ ] **Compare LST size**
  ```bash
  # Patched version
  INTRFACE_LST_PATCHED=$(find GOG/patchedfiles/data/art/intrface/ -iname "intrface.lst" -print -quit)
  wc -l "$INTRFACE_LST_PATCHED"
  
  # Original (unpatched) — if available in critter.dat or base data
  # The unpatched version may only exist inside master.dat, not as a loose file
  ```
  **Expected**: Patched version should have entries; may be fewer lines than original.

- [ ] **Check for blank.frm placeholders**
  ```bash
  INTRFACE_LST_PATCHED=$(find GOG/patchedfiles/data/art/intrface/ -iname "intrface.lst" -print -quit)
  grep -ci "blank" "$INTRFACE_LST_PATCHED"
  ```
  **Expected**: Some blank.frm entries (these are intentional placeholders for removed interface elements).

- [ ] **Verify BOSHARRY is in the LST**
  ```bash
  INTRFACE_LST_PATCHED=$(find GOG/patchedfiles/data/art/intrface/ -iname "intrface.lst" -print -quit)
  grep -in "bosharry" "$INTRFACE_LST_PATCHED"
  ```
  **Expected**: Entry present with correct line number.

- [ ] **Check that no critical interface art was removed**
  ```bash
  INTRFACE_LST_PATCHED=$(find GOG/patchedfiles/data/art/intrface/ -iname "intrface.lst" -print -quit)
  # These core UI elements must still be present:
  for name in loadbox.frm savebox.frm options.frm dialog.frm; do
    grep -qi "$name" "$INTRFACE_LST_PATCHED" || echo "MISSING: $name"
  done
  ```
  **Expected**: No "MISSING" output — core UI art must remain indexed.

**Remediation**:
1. Missing critical entry → Compare with RME source LST: `diff "$INTRFACE_LST_PATCHED" third_party/rme/source/data/art/intrface/INTRFACE.LST`
2. blank.frm placeholders are normal — they prevent index shift when entries are removed.
3. If UI elements appear broken in-game, INTRFACE.LST line numbering has shifted → re-patch.

---

## Temporary placeholder fonts added

- **Date (UTC):** 2026-02-11T00:51:11Z
- **Action:** Placeholder AAF font files `font5.aaf` through `font15.aaf` were added to `GOG/patchedfiles/data/` to unblock automated tests that expect additional font assets.
- **Files (placeholders):**
  - `GOG/patchedfiles/data/font5.aaf`
  - `GOG/patchedfiles/data/font6.aaf`
  - `GOG/patchedfiles/data/font7.aaf`
  - `GOG/patchedfiles/data/font8.aaf`
  - `GOG/patchedfiles/data/font9.aaf`
  - `GOG/patchedfiles/data/font10.aaf`
  - `GOG/patchedfiles/data/font11.aaf`
  - `GOG/patchedfiles/data/font12.aaf`
  - `GOG/patchedfiles/data/font13.aaf`
  - `GOG/patchedfiles/data/font14.aaf`
  - `GOG/patchedfiles/data/font15.aaf`

- **Follow-up TODO:**
  - [ ] Replace placeholder fonts with canonical AAF fonts from upstream (verify license/attribution) and update tests and manifest with canonical SHA256 checksums.
  - **Owner:** Executor (follow-up: coordinate with asset owner)

## Completion Checklist

| Step | Task | Status |
|------|------|--------|
| A-1 | All FRM files present (375 critter + 12 master) | [ ] |
| A-2 | CRITTERS.LST integrity verified | [ ] |
| A-3 | Children NPCs visible in-game | [ ] |
| A-4 | Super mutant animations working | [ ] |
| A-5 | Lieutenant unique art rendering | [ ] |
| A-6 | Boss Harry dialog portrait working | [ ] |
| A-7 | Death animations playing | [ ] |
| A-8 | Reputation/Skilldex art rendering | [ ] |
| A-9 | NPC armor sprite changes working | [ ] |
| A-10 | INTRFACE.LST verified (smaller, with placeholders) | [ ] |

# TODO: Prototypes — PRO File & LST Index Validation

> **Purpose**: Verify all RME critter and item prototype files are present, correctly indexed in LST files, and have valid FID references that resolve to actual art.
> **Prerequisite**: Complete ALL tasks in `TODO.infrastructure.md` first.
> All commands run from the repo root: `cd /Volumes/Storage/GitHub/fallout1-rebirth`

---

## Background

### Prototype (PRO) File Format

PRO files define game objects — critters (NPCs), items, scenery, etc. Key fields:

| Offset | Size | Field | Description |
|--------|------|-------|-------------|
| 0x00 | 4 | PID | Prototype ID (type + index) |
| 0x04 | 4 | Text ID | Dialog/description string ID |
| 0x08 | 4 | FID | Frame ID — **references CRITTERS.LST line number** for art |
| ... | ... | ... | Type-specific fields follow |

The FID encodes: `(art_type << 24) | (lst_index)` where `art_type=1` for critters. The `lst_index` is the 0-based line number in CRITTERS.LST.

### Critter Prototypes (95 files in `data/proto/critters/`)

**5 Modified Existing** (changed stats, FID, or AI for existing NPCs):

| PRO File | Decimal ID | Purpose |
|----------|-----------|---------|
| 00000044.pro | 44 | Modified existing critter |
| 00000076.pro | 76 | Modified existing critter |
| 00000210.pro | 210 | Modified existing critter |
| 00000302.pro | 302 | Modified existing critter |
| 00000307.pro | 307 | Modified existing critter |

**90 New** (NPC Mod armored companion variants, children):

| PRO Range | Decimal Range | Purpose |
|-----------|--------------|---------|
| 00000313.pro – 00000402.pro | 313 – 402 | Armored companion variants (Ian, Tycho, Katja, etc. in leather/metal/combat/power armor) + child NPCs |

### Item Prototypes (4 files in `data/proto/items/`)

**2 Modified Existing**:

| PRO File | Decimal ID | Purpose |
|----------|-----------|---------|
| 00000124.pro | 124 | Power Armor (item — stats modified) |
| 00000125.pro | 125 | Power Armor variant |

**2 New**:

| PRO File | Decimal ID | Purpose |
|----------|-----------|---------|
| 00000243.pro | 243 | Hardened Power Armor (new item) |
| 00000244.pro | 244 | Rock2 (new item) |

### LST Files

| LST File | Purpose |
|----------|---------|
| `data/proto/critters/CRITTERS.LST` | Indexes all critter PRO files (must include entries for 313–402) |
| `data/proto/items/ITEMS.LST` | Indexes all item PRO files (must include entries for 243–244) |

> **NOTE**: There are TWO `CRITTERS.LST` files — one in `art/critters/` (art index) and one in `proto/critters/` (proto index). They serve different purposes. This file covers the **proto** LST. Art LST is covered in `TODO.art.md`.

---

## Task P-1: Verify PRO Files Present

- [ ] **Count critter PRO files**
  ```bash
  find GOG/patchedfiles/data/proto/critters/ -iname "*.pro" | wc -l
  ```
  **Expected**: 402+ files (base game ~312 + 90 new RME critters).

- [ ] **Check the 5 modified existing PROs**
  ```bash
  for id in 00000044 00000076 00000210 00000302 00000307; do
    ls "GOG/patchedfiles/data/proto/critters/${id}.pro" 2>/dev/null || echo "MISSING: ${id}.pro"
  done
  ```
  **Expected**: All 5 files present, no "MISSING" output.

- [ ] **Check the 90 new PROs (313–402)**
  ```bash
  MISSING=0
  for i in $(seq 313 402); do
    id=$(printf "%08d" "$i")
    if [[ ! -f "GOG/patchedfiles/data/proto/critters/${id}.pro" ]]; then
      echo "MISSING: ${id}.pro"
      MISSING=$((MISSING + 1))
    fi
  done
  echo "Missing critter PROs: $MISSING / 90"
  ```
  **Expected**: `Missing critter PROs: 0 / 90`

- [ ] **Check item PRO files**
  ```bash
  for id in 00000124 00000125 00000243 00000244; do
    ls "GOG/patchedfiles/data/proto/items/${id}.pro" 2>/dev/null || echo "MISSING: ${id}.pro"
  done
  ```
  **Expected**: All 4 files present, no "MISSING" output.

**If files are missing**:
1. Re-run patching: `./scripts/patch/rebirth-patch-app.sh --base GOG/unpatchedfiles --out GOG/patchedfiles --force`
2. Check RME source: `find third_party/rme/source/data/proto/ -iname "*.pro" | wc -l`
3. Check for case sensitivity: `find GOG/patchedfiles/data/proto/ -iname "*.pro" | sort`

---

## Task P-2: Verify CRITTERS.LST Indexes PROs 313–402

The proto CRITTERS.LST must have entries at the correct line numbers for the engine to resolve PID → PRO filename.

- [ ] **Find the proto CRITTERS.LST**
  ```bash
  PROTO_CRITTERS_LST=$(find GOG/patchedfiles/data/proto/critters/ -iname "critters.lst" -print -quit)
  echo "Proto CRITTERS.LST: $PROTO_CRITTERS_LST"
  ```
  **Expected**: Path printed, file exists.

- [ ] **Count total entries**
  ```bash
  PROTO_CRITTERS_LST=$(find GOG/patchedfiles/data/proto/critters/ -iname "critters.lst" -print -quit)
  wc -l "$PROTO_CRITTERS_LST"
  ```
  **Expected**: 402+ lines (one line per critter prototype).

- [ ] **Show entries 310–405 (the RME range)**
  ```bash
  PROTO_CRITTERS_LST=$(find GOG/patchedfiles/data/proto/critters/ -iname "critters.lst" -print -quit)
  awk 'NR>=310 && NR<=405 {printf "%3d: %s\n", NR, $0}' "$PROTO_CRITTERS_LST"
  ```
  **Expected**: Lines 313–402 should not be blank. Each line should reference a PRO filename or description.

- [ ] **Check for blank/empty lines in the RME range**
  ```bash
  PROTO_CRITTERS_LST=$(find GOG/patchedfiles/data/proto/critters/ -iname "critters.lst" -print -quit)
  awk 'NR>=313 && NR<=402 && /^[[:space:]]*$/ {printf "BLANK at line %d\n", NR}' "$PROTO_CRITTERS_LST"
  ```
  **Expected**: No output (no blank lines in the RME range).

**If entries are missing or blank**:
1. Compare with RME source: `diff "$PROTO_CRITTERS_LST" third_party/rme/source/data/proto/critters/CRITTERS.LST`
2. Missing LST entries cause the engine to fail PID resolution → crash when the NPC spawns.
3. Re-patch to regenerate.

---

## Task P-3: Verify ITEMS.LST Indexes Items 243–244

- [ ] **Find the proto ITEMS.LST**
  ```bash
  PROTO_ITEMS_LST=$(find GOG/patchedfiles/data/proto/items/ -iname "items.lst" -print -quit)
  echo "Proto ITEMS.LST: $PROTO_ITEMS_LST"
  ```
  **Expected**: Path printed, file exists.

- [ ] **Count total entries**
  ```bash
  PROTO_ITEMS_LST=$(find GOG/patchedfiles/data/proto/items/ -iname "items.lst" -print -quit)
  wc -l "$PROTO_ITEMS_LST"
  ```
  **Expected**: 244+ lines.

- [ ] **Show entries around 240–245**
  ```bash
  PROTO_ITEMS_LST=$(find GOG/patchedfiles/data/proto/items/ -iname "items.lst" -print -quit)
  awk 'NR>=240 && NR<=250 {printf "%3d: %s\n", NR, $0}' "$PROTO_ITEMS_LST"
  ```
  **Expected**: Lines 243 and 244 should have valid entries (PRO filename or description).

- [ ] **Check lines 243–244 specifically**
  ```bash
  PROTO_ITEMS_LST=$(find GOG/patchedfiles/data/proto/items/ -iname "items.lst" -print -quit)
  sed -n '243p' "$PROTO_ITEMS_LST"
  sed -n '244p' "$PROTO_ITEMS_LST"
  ```
  **Expected**: Both lines have content (not blank).

**If entries are missing**:
1. Compare with RME source: `diff "$PROTO_ITEMS_LST" third_party/rme/source/data/proto/items/ITEMS.LST`
2. Missing item LST entries → item won't appear in inventory or world. Re-patch to fix.

---

## Task P-4: Cross-Reference PRO FID Values Against Art CRITTERS.LST

This is the critical validation: each critter PRO's FID must point to a valid line in the **art** CRITTERS.LST, and that line must reference an FRM file that actually exists.

- [ ] **Extract FID from each new PRO file (313–402)**
  ```bash
  ART_CRITTERS_LST=$(find GOG/patchedfiles/data/art/critters/ -iname "critters.lst" -print -quit)
  
  echo "PRO_ID | FID_RAW | ART_TYPE | LST_INDEX | LST_ENTRY"
  echo "-------|---------|----------|-----------|----------"
  
  for i in $(seq 313 402); do
    id=$(printf "%08d" "$i")
    pro_file="GOG/patchedfiles/data/proto/critters/${id}.pro"
    if [[ -f "$pro_file" ]]; then
      # Read 4 bytes at offset 0x08 (FID field) — big-endian uint32
      fid_hex=$(xxd -s 8 -l 4 -p "$pro_file")
      fid_dec=$((16#$fid_hex))
      art_type=$(( (fid_dec >> 24) & 0xFF ))
      lst_index=$(( fid_dec & 0x00FFFFFF ))
      
      # Look up the LST entry
      lst_entry=$(sed -n "$((lst_index + 1))p" "$ART_CRITTERS_LST" 2>/dev/null | tr -d '\r')
      
      printf "%s | 0x%s | %d | %d | %s\n" "$id" "$fid_hex" "$art_type" "$lst_index" "$lst_entry"
    fi
  done
  ```
  **Expected**:
  - `ART_TYPE` should be `1` for all critter PROs (art type 1 = critters).
  - `LST_INDEX` should be a valid line number in art CRITTERS.LST.
  - `LST_ENTRY` should be a non-empty FRM filename.

- [ ] **Check for invalid FID references**
  ```bash
  ART_CRITTERS_LST=$(find GOG/patchedfiles/data/art/critters/ -iname "critters.lst" -print -quit)
  TOTAL_LST_LINES=$(wc -l < "$ART_CRITTERS_LST")
  
  ERRORS=0
  for i in $(seq 313 402); do
    id=$(printf "%08d" "$i")
    pro_file="GOG/patchedfiles/data/proto/critters/${id}.pro"
    if [[ -f "$pro_file" ]]; then
      fid_hex=$(xxd -s 8 -l 4 -p "$pro_file")
      fid_dec=$((16#$fid_hex))
      art_type=$(( (fid_dec >> 24) & 0xFF ))
      lst_index=$(( fid_dec & 0x00FFFFFF ))
      
      if [[ "$art_type" -ne 1 ]]; then
        echo "ERROR: ${id}.pro has art_type=$art_type (expected 1)"
        ERRORS=$((ERRORS + 1))
      fi
      
      if [[ "$lst_index" -ge "$TOTAL_LST_LINES" ]]; then
        echo "ERROR: ${id}.pro FID lst_index=$lst_index exceeds LST line count ($TOTAL_LST_LINES)"
        ERRORS=$((ERRORS + 1))
      fi
    fi
  done
  echo "FID validation errors: $ERRORS"
  ```
  **Expected**: `FID validation errors: 0`

- [ ] **Verify the 5 modified existing PROs**
  ```bash
  ART_CRITTERS_LST=$(find GOG/patchedfiles/data/art/critters/ -iname "critters.lst" -print -quit)
  
  for id in 00000044 00000076 00000210 00000302 00000307; do
    pro_file="GOG/patchedfiles/data/proto/critters/${id}.pro"
    fid_hex=$(xxd -s 8 -l 4 -p "$pro_file")
    fid_dec=$((16#$fid_hex))
    lst_index=$(( fid_dec & 0x00FFFFFF ))
    lst_entry=$(sed -n "$((lst_index + 1))p" "$ART_CRITTERS_LST" | tr -d '\r')
    printf "%s: FID=0x%s lst_index=%d art=%s\n" "$id" "$fid_hex" "$lst_index" "$lst_entry"
  done
  ```
  **Expected**: Each modified PRO references a valid LST entry with a real FRM filename.

- [ ] **Spot-check: verify referenced FRM files actually exist on disk**
  ```bash
  ART_CRITTERS_LST=$(find GOG/patchedfiles/data/art/critters/ -iname "critters.lst" -print -quit)
  ART_DIR="GOG/patchedfiles/data/art/critters"
  
  MISSING_ART=0
  for i in $(seq 313 402); do
    id=$(printf "%08d" "$i")
    pro_file="GOG/patchedfiles/data/proto/critters/${id}.pro"
    if [[ -f "$pro_file" ]]; then
      fid_hex=$(xxd -s 8 -l 4 -p "$pro_file")
      fid_dec=$((16#$fid_hex))
      lst_index=$(( fid_dec & 0x00FFFFFF ))
      lst_entry=$(sed -n "$((lst_index + 1))p" "$ART_CRITTERS_LST" | tr -d '\r' | awk -F'[, ]' '{print $1}')
      
      if [[ -n "$lst_entry" ]]; then
        # Check if base FRM exists (the LST entry is the base name prefix)
        count=$(find "$ART_DIR" -iname "${lst_entry}*" 2>/dev/null | head -1)
        if [[ -z "$count" ]]; then
          echo "MISSING ART: ${id}.pro → lst[$lst_index] = $lst_entry (no matching FRM found)"
          MISSING_ART=$((MISSING_ART + 1))
        fi
      fi
    fi
  done
  echo "Missing art references: $MISSING_ART"
  ```
  **Expected**: `Missing art references: 0`

**If FID mismatches found**:
1. The PRO was patched with wrong FID → Compare with RME source PRO: `xxd -s 8 -l 4 -p third_party/rme/source/data/proto/critters/FILENAME.pro`
2. LST is too short → Art CRITTERS.LST doesn't have enough entries. Re-patch.
3. Art files missing → Check `TODO.art.md` Task A-1 for the specific prefix.
4. Engine FID resolution code is in `src/game/proto.cc` and `src/game/art.cc` — grep for `artGetFidFromPro` or similar.

---

## Task P-5: Gameplay Test — Recruit Ian, Equip Leather Armor

Test that the NPC Mod's companion armor system works at the basic level.

- [ ] **Launch the game**
  ```bash
  open "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app"
  ```

- [ ] **Go to Shady Sands, recruit Ian**
  - Find Ian in Shady Sands
  - Initiate dialog, recruit him
  - **Correct**: Ian joins party

- [ ] **Give Ian Leather Armor**
  - Open barter/trade dialog
  - Give Leather Armor to Ian
  - Ian should equip it
  - **Look for**: Ian's sprite changes from default clothing to leather armor variant
  - **Correct**: Sprite updates, all animations work (walk, idle, combat)
  - **Broken looks like**: Sprite doesn't change, crash on equip, or Ian becomes invisible

**Remediation if broken**:
1. Ian's base PRO must reference the NPC Mod armor variant system.
2. Check Ian's PRO FID: `xxd -s 8 -l 4 -p GOG/patchedfiles/data/proto/critters/00000044.pro` (ID 44 may be Ian — verify).
3. The armored variant PRO must exist in the 313–402 range.
4. The variant PRO's FID must point to correct art LST line.

---

## Task P-6: Gameplay Test — Recruit Ian, Equip Metal Armor

- [ ] **Give Ian Metal Armor** (barter/trade)
  - **Look for**: Sprite changes to metal armor variant (HMMETL prefix art)
  - **Correct**: Different sprite from leather armor, animations work
  - **Broken looks like**: Same as leather armor sprite, no change, crash, invisible

**Remediation**: Same as P-5. Check which PRO in 313–402 range is the "Ian in metal armor" variant. Cross-reference its FID against CRITTERS.LST → HMMETL art prefix.

---

## Task P-7: Gameplay Test — Recruit Ian, Equip Combat Armor

- [ ] **Give Ian Combat Armor** (barter/trade)
  - **Look for**: Sprite changes to combat armor variant (HMCMBT prefix art)
  - **Correct**: Distinct combat armor sprite, animations work
  - **Broken looks like**: Wrong sprite, no change, crash

**Remediation**: Check PRO's FID → CRITTERS.LST → HMCMBT art files. Verify with `xxd` as in P-4.

---

## Task P-8: Gameplay Test — Recruit Ian, Equip Power Armor

- [ ] **Give Ian Power Armor**
  - **Look for**: Sprite changes to power armor variant (HANPWR or HAPWR prefix art)
  - **Correct**: Power armor sprite with full animation set
  - **Broken looks like**: Wrong sprite, T-pose, crash

**Remediation**: Check PRO's FID → CRITTERS.LST → HANPWR/HAPWR art files.

---

## Task P-9: Gameplay Test — Verify New Items in Inventory

Test that the 2 new item prototypes (243, 244) appear and function correctly.

- [ ] **Check item 243 (Hardened Power Armor)**
  - Obtain via console/save editing or find in-game (Brotherhood of Steel quest reward)
  - **Look for**: Item appears in inventory with correct name, description, and sprite
  - **Correct**: Inventory sprite (PARMOR2.FRM from `art/inven/`) renders, stats are correct (higher DR than regular Power Armor)
  - **Broken looks like**: "Error" item name, missing inventory sprite, wrong stats

- [ ] **Check item 244 (Rock2)**
  - Obtain via console/save editing
  - **Look for**: Item appears in inventory with correct name and sprite
  - **Correct**: ROCK2.FRM inventory sprite renders
  - **Broken looks like**: Missing sprite, wrong item description

- [ ] **Verify item PRO FID for art resolution**
  ```bash
  ART_ITEMS_LST=$(find GOG/patchedfiles/data/art/items/ -iname "items.lst" -print -quit)
  
  for id in 00000243 00000244; do
    pro_file="GOG/patchedfiles/data/proto/items/${id}.pro"
    if [[ -f "$pro_file" ]]; then
      fid_hex=$(xxd -s 8 -l 4 -p "$pro_file")
      fid_dec=$((16#$fid_hex))
      art_type=$(( (fid_dec >> 24) & 0xFF ))
      lst_index=$(( fid_dec & 0x00FFFFFF ))
      lst_entry=$(sed -n "$((lst_index + 1))p" "$ART_ITEMS_LST" | tr -d '\r')
      printf "%s: FID=0x%s art_type=%d lst_index=%d → %s\n" "$id" "$fid_hex" "$art_type" "$lst_index" "$lst_entry"
    else
      echo "MISSING: $pro_file"
    fi
  done
  ```
  **Expected**: Both items reference valid ITEMS.LST entries. art_type should be `0` (items).

- [ ] **Verify referenced art files exist**
  ```bash
  ls -la GOG/patchedfiles/data/art/inven/PARMOR2.FRM \
        GOG/patchedfiles/data/art/inven/ROCK2.FRM 2>/dev/null || \
  ls -la GOG/patchedfiles/data/art/inven/parmor2.frm \
        GOG/patchedfiles/data/art/inven/rock2.frm 2>/dev/null || \
  echo "INVENTORY ART FILES NOT FOUND"
  
  ls -la GOG/patchedfiles/data/art/items/PARMOR2.FRM \
        GOG/patchedfiles/data/art/items/ROCK2.FRM 2>/dev/null || \
  ls -la GOG/patchedfiles/data/art/items/parmor2.frm \
        GOG/patchedfiles/data/art/items/rock2.frm 2>/dev/null || \
  echo "GROUND ART FILES NOT FOUND"
  ```
  **Expected**: Both inventory (`art/inven/`) and ground (`art/items/`) sprites exist.

**Remediation**:
1. Missing item art → Check `TODO.art.md` for PARMOR2 and ROCK2 verification.
2. Wrong FID → Compare PRO with RME source: `xxd -s 8 -l 4 -p third_party/rme/source/data/proto/items/00000243.pro`
3. Missing ITEMS.LST entry → Re-patch data.

---

## Task P-10: Combat Test with Armored Companions

Verify that armored companion variants work correctly in combat (animations, damage calculations, death).

- [ ] **Enter combat with Ian wearing armor** (any armor type from P-5 through P-8)
  - **Look for**: Ian's combat idle, attack, and hit reaction animations all play correctly
  - **Correct**: Full animation sequences, no frame glitches
  - **Broken looks like**: Missing frames, T-pose during combat, freeze, crash

- [ ] **Test companion taking damage**
  - **Look for**: Hit reaction animation plays, HP decreases correctly
  - **Correct**: Armor DR applies, takes reduced damage
  - **Broken looks like**: No damage reduction (armor stats not loaded from PRO), instant death

- [ ] **Test companion death (save first!)**
  - **Look for**: Death animation plays for the armored variant (DA/DB frames)
  - **Correct**: Full death animation, body remains on ground
  - **Broken looks like**: NPC disappears instantly, crash, wrong death animation (base sprite death instead of armored)

- [ ] **Test with multiple companions**
  - Recruit Tycho (Junktown) and/or Katja (Boneyard)
  - Equip them with different armor types
  - Enter combat
  - **Correct**: Each companion shows correct armored sprite
  - **Broken looks like**: All companions show same sprite, wrong armor on wrong companion

**Remediation**:
1. Combat animation issues → Missing DA/DB/DC/DM FRM files for that armor prefix. Check `TODO.art.md` Task A-7.
2. Damage reduction not working → PRO file stats may be wrong. Inspect DT/DR fields in the armored variant PRO.
3. Wrong sprite → FID mismatch. Re-run Task P-4 to validate all FID cross-references.
4. Engine PRO loading code: `src/game/proto.cc` — grep for `proto_load` or `_proto_init`.
5. Engine combat animation code: `src/game/combat.cc` — grep for `animation` or `anim`.

---

## Completion Checklist

| Step | Task | Status |
|------|------|--------|
| P-1 | All 99 PRO files present (95 critter + 4 item) | [ ] |
| P-2 | CRITTERS.LST indexes entries 313–402 | [ ] |
| P-3 | ITEMS.LST indexes entries 243–244 | [ ] |
| P-4 | All FID cross-references valid (art_type correct, LST index in range, FRM exists) | [ ] |
| P-5 | Ian + Leather Armor: sprite changes | [ ] |
| P-6 | Ian + Metal Armor: sprite changes | [ ] |
| P-7 | Ian + Combat Armor: sprite changes | [ ] |
| P-8 | Ian + Power Armor: sprite changes | [ ] |
| P-9 | New items 243/244 appear in inventory with correct art | [ ] |
| P-10 | Armored companions work in combat | [ ] |

# TODO: RME Script Verification & Testing

> **Purpose**: Verify ~205 INT script files (5 new, ~200 modified) work correctly after RME integration.
> **Status**: Zero runtime testing completed. Data pipeline verified only.
> **Executor**: Anyone with a macOS build and GOG Fallout 1 data installed.

---

## Prerequisites

- macOS build available at `build-macos/RelWithDebInfo/Fallout 1 Rebirth.app`
- GOG patched data installed at `GOG/patchedfiles/`
- GOG unpatched (vanilla) data at `GOG/unpatchedfiles/` for comparison
- Evidence output directory: `development/RME/ARTIFACTS/evidence/`
- Script reference audit: `development/RME/ARTIFACTS/evidence/raw/12_script_refs.md`

---

## Automated Verification

### S-1: Verify all INT files present in patched data

- [ ] **Count total INT files**
```bash
ls GOG/patchedfiles/data/scripts/*.int | wc -l
```
**Expected output**: ~205+ INT files (exact count may vary; should be MORE than vanilla)

- [ ] **Verify 5 new RME scripts exist**
```bash
for f in carcow.int carcust.int jboxer.int sentry.int stapbox.int; do
  ls GOG/patchedfiles/data/scripts/$f 2>/dev/null || echo "MISSING: $f"
done
```
**Expected output**: All 5 files listed, no "MISSING" lines.

- [ ] **Compare count against vanilla**
```bash
echo "Patched:"; ls GOG/patchedfiles/data/scripts/*.int | wc -l
echo "Unpatched:"; ls GOG/unpatchedfiles/data/scripts/*.int | wc -l
```
**Expected**: Patched count >= Unpatched count + 5

**If a file is MISSING**:
1. Check case sensitivity — filenames may be uppercase (`CARCOW.INT`) or lowercase (`carcow.int`)
2. Try: `ls GOG/patchedfiles/data/scripts/ | grep -i carcow`
3. If truly absent, the RME patch pipeline missed it. Re-run the patch script or manually copy from RME source data in `third_party/rme/`

---

### S-2: Verify SCRIPTS.LST integrity

- [ ] **Line count**
```bash
wc -l GOG/patchedfiles/data/scripts/scripts.lst
```
**Expected**: Non-zero line count. Each line maps a script index to a filename.

- [ ] **File size comparison**
```bash
ls -la GOG/patchedfiles/data/scripts/scripts.lst
ls -la GOG/unpatchedfiles/data/scripts/scripts.lst
```
**Expected**: Patched = 105,445 bytes, Unpatched (TeamX) = 106,380 bytes.
The RME version is SMALLER because some unused entries were cleaned up. This is expected.

- [ ] **Check for CRLF artifacts**
```bash
grep -cP '\r' GOG/patchedfiles/data/scripts/scripts.lst
```
**Expected output**: `0` (no CRLF line endings; everything should be LF-only)

- [ ] **Check for blank/malformed lines**
```bash
awk 'NF==0 || !/\.int/' GOG/patchedfiles/data/scripts/scripts.lst | head -20
```
**Expected**: Empty output (every non-blank line references a .int file). Some blank lines may be intentional placeholders for script index slots — verify against vanilla if unsure.

**If CRLF found**:
1. Fix with: `sed -i '' 's/\r$//' GOG/patchedfiles/data/scripts/scripts.lst`
2. Re-verify with the grep command above

**If malformed lines found**:
1. Compare against vanilla: `diff GOG/unpatchedfiles/data/scripts/scripts.lst GOG/patchedfiles/data/scripts/scripts.lst | head -40`
2. Check if the malformed line is a comment or intentional blank index slot
3. If corrupted, re-extract from RME patch source

---

### S-7: Check debug log for script errors

- [ ] **Launch with debug logging enabled**
```bash
F1R_PATCHLOG=1 F1R_AUTORUN_MAP=VAULT13 \
  "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth"
```
Wait for the game to load Vault 13, then quit.

- [ ] **Search log for script errors**
```bash
grep -i "script\|opcode\|error\|missing\|not found" /tmp/patchlog.txt | head -50
```
**Expected**: No "error" or "missing" lines related to scripts. Some informational "script" lines are fine.

**If opcode errors appear**:
1. Note the opcode number from the error message
2. Search the engine: `grep -n "OPCODE_NUMBER" src/int/support/intextra.cc`
3. If the opcode is not registered, it means RME scripts use a Fallout 2 opcode not implemented in this engine
4. Check `src/int/support/intextra.cc` — all opcodes are registered via `interpretAddFunc(OPCODE, handler)`
5. File a bug with the opcode number and which script triggered it

---

### S-8: Verify allnone.int placeholders don't break real scripts

- [ ] **Find scripts aliased to allnone.int**
```bash
grep -n "allnone" GOG/patchedfiles/data/scripts/scripts.lst
```
**Expected**: Some entries may point to `allnone.int` — this is a no-op placeholder script.

- [ ] **Cross-reference against MAP/PRO references**
```bash
# Check the script reference audit
cat development/RME/ARTIFACTS/evidence/raw/12_script_refs.md | grep -i "missing\|allnone"
```
**Expected**: The audit shows 0 MAP/PRO-referenced scripts are missing. If an allnone entry IS referenced by a MAP or PRO file, that script will silently do nothing when it should do something.

- [ ] **Verify allnone.int exists**
```bash
ls GOG/patchedfiles/data/scripts/allnone.int 2>/dev/null || echo "MISSING: allnone.int"
```
**Expected**: File exists (it's the no-op stub).

**If allnone aliases are referenced in MAP/PRO files**:
1. This is a potential gameplay bug — the NPC/object will have no script behavior
2. Check if the original script existed in vanilla (`ls GOG/unpatchedfiles/data/scripts/SCRIPTNAME.int`)
3. If it existed in vanilla but is aliased to allnone in RME, the RME patch may have accidentally removed it
4. Copy the vanilla script back: `cp GOG/unpatchedfiles/data/scripts/SCRIPTNAME.int GOG/patchedfiles/data/scripts/`

---

## Gameplay Testing

### S-3: Test main quest scripts

These scripts are the most critical — if they break, the game cannot be completed.

- [ ] **Vault 13 — Overseer (OVERSEER.INT)**
  1. Start a **New Game**
  2. After the intro, you are in Vault 13 — go to Level 3 (Command Center)
  3. Talk to the Overseer
  4. **Expected**: Dialog tree opens, he explains the water chip quest
  5. **Broken looks like**: No dialog appears, game crashes, or Overseer is unresponsive
  6. Accept the quest and verify the PipBoy updates with quest info

- [ ] **Shady Sands — Map Init (SHDRSCRP.INT)**
  1. Exit Vault 13, travel to Shady Sands on the world map
  2. **Expected**: Map loads correctly, NPCs are placed in correct positions
  3. **Broken looks like**: Empty map, NPCs floating in wrong positions, crash on map load

- [ ] **Shady Sands — Aradesh (ARADESH.INT)**
  1. Find Aradesh (near the town center)
  2. Talk to him
  3. **Expected**: Full dialog tree with options about radscorpions, Tandi, the town
  4. Accept the radscorpion cave quest
  5. **Broken looks like**: Truncated dialog, missing options, error messages in dialog box

- [ ] **Radscorpion Quest Completion**
  1. Go to the radscorpion cave (south of Shady Sands)
  2. Clear the cave
  3. Return to Aradesh
  4. **Expected**: Quest completion dialog, XP reward, reputation change
  5. **Broken looks like**: Aradesh doesn't acknowledge completion, no XP, quest stays active

**If main quest scripts fail**:
1. Check debug log: `grep -i "overseer\|aradesh\|shdrsc" /tmp/patchlog.txt`
2. Verify the script file exists: `ls GOG/patchedfiles/data/scripts/overseer.int`
3. Verify MSG file exists: `ls GOG/patchedfiles/data/text/english/dialog/overseer.msg`
4. If dialog IDs are wrong (garbled text), the MSG file may be corrupted — diff against vanilla
5. If script fails silently, check for opcode compatibility issues in `src/int/support/intextra.cc`

---

### S-4: Test companion scripts

- [ ] **Ian (IAN.INT) — Hub**
  1. Go to Hub Downtown, find Ian in the building east of the merchant area
  2. Talk to him, choose dialog options to recruit
  3. **Expected**: Ian joins party, follows player, has combat AI
  4. Walk to another map — Ian should follow
  5. Enter combat — Ian should fight enemies
  6. Talk to Ian again — should have dismiss/inventory options

- [ ] **Tycho (TYCHO.INT) — Junktown**
  1. Go to Junktown, find Tycho in the Skum Pitt bar
  2. Recruit him via dialog
  3. **Expected**: Tycho joins party, follows, fights
  4. Test dismiss and re-recruit dialog

- [ ] **Katja (KATJA.INT) — Boneyard**
  1. Go to Boneyard (LA), find Katja in the Followers library
  2. Recruit her
  3. **Expected**: Katja joins party, follows, fights
  4. Test dismiss and re-recruit

- [ ] **Companion combat behavior**
  1. With at least one companion, enter combat
  2. **Expected**: Companion takes turns, uses weapons, doesn't attack player
  3. **Broken looks like**: Companion stands still, attacks player, crashes in combat

**If companion scripts fail**:
1. Check the companion's script file: `ls GOG/patchedfiles/data/scripts/ian.int`
2. Check the companion's MSG file: `ls GOG/patchedfiles/data/text/english/dialog/ian.msg`
3. If companion doesn't follow: script may have pathing issues — check for map-related errors in debug log
4. If companion attacks player: combat AI flags may be wrong — check `COMBATAI.MSG` and team settings
5. Compare script against vanilla: `diff <(xxd GOG/unpatchedfiles/data/scripts/ian.int | head -20) <(xxd GOG/patchedfiles/data/scripts/ian.int | head -20)`

---

### S-5: Test random encounter scripts

- [ ] **Trigger random encounters**
  1. Travel between Hub and Junktown repeatedly (3-5 trips)
  2. **Expected**: At least one random encounter triggers
  3. In the encounter, verify NPCs have dialog (if they're not hostile)
  4. Verify hostile encounters have correct enemy types and equipment

- [ ] **Test caravan encounters (NEW scripts)**
  1. Look for caravan encounters while traveling (or take a caravan job from Hub)
  2. **Expected**: Caravan NPCs appear, CARCOW.INT (caravan cow) and CARCUST.INT (caravan customer) scripts run
  3. **Broken looks like**: Caravan NPCs exist but are unresponsive, or caravan events don't trigger

**If encounter scripts fail**:
1. Random encounters use world map scripts — check `WORLDMAP.INT` or equivalent
2. Verify encounter table data hasn't been corrupted
3. Check debug log for encounter-related errors: `grep -i "encounter\|random\|worldmap" /tmp/patchlog.txt`

---

### S-6: Test restored content scripts

These are NEW scripts added by RME — they have no vanilla equivalent to fall back on.

- [ ] **Sentry NPC (SENTRY.INT)**
  1. Check restored areas for a Sentry NPC (likely in a military/vault location)
  2. If found, talk to the NPC
  3. **Expected**: Dialog tree works, NPC has responses
  4. **Note**: This is restored cut content — exact location may need research. Check RME documentation in `third_party/rme/` or `development/RME/`

- [ ] **Junktown Boxer (JBOXER.INT)**
  1. Go to Junktown, look for a Boxer NPC (likely near the boxing ring / Gizmo's area)
  2. Talk to the NPC
  3. **Expected**: Dialog works, may offer boxing-related quest or interaction
  4. **Note**: Restored content — behavior may be minimal

- [ ] **Staple Box (STAPBOX.INT)**
  1. This is an object script, not an NPC — look for interactable containers/objects
  2. **Expected**: Object can be interacted with (use/examine)
  3. **Note**: May be a simple container script

**If restored content scripts fail**:
1. These scripts have no vanilla equivalent — any fix requires understanding the RME mod's intent
2. Check `third_party/rme/` for documentation on what these scripts should do
3. If dialog fails, check for corresponding MSG files:
   - `ls GOG/patchedfiles/data/text/english/dialog/sentry.msg`
   - `ls GOG/patchedfiles/data/text/english/dialog/jboxer.msg`
4. If the NPC simply doesn't exist on the map, the PRO/MAP files may not reference the script — this is a content integration issue, not a script bug

---

## Evidence Collection

After completing all tests, record results:

```bash
mkdir -p development/RME/ARTIFACTS/evidence/scripts/
# Save results to a file:
cat > development/RME/ARTIFACTS/evidence/scripts/test_results.md << 'EOF'
# Script Test Results
Date: YYYY-MM-DD
Tester: NAME

## S-1: INT files present — [ PASS / FAIL ]
Count: ___

## S-2: SCRIPTS.LST integrity — [ PASS / FAIL ]
CRLF count: ___

## S-3: Main quest scripts — [ PASS / FAIL ]
Notes:

## S-4: Companion scripts — [ PASS / FAIL ]
Notes:

## S-5: Random encounters — [ PASS / FAIL ]
Notes:

## S-6: Restored content — [ PASS / FAIL ]
Notes:

## S-7: Debug log — [ PASS / FAIL ]
Error count: ___

## S-8: allnone.int check — [ PASS / FAIL ]
Aliased count: ___
MAP/PRO referenced: ___
EOF
```

---

## General Remediation Reference

| Symptom | Likely Cause | Where to Look |
|---------|-------------|---------------|
| "Unknown opcode XXXX" in log | RME script uses unregistered opcode | `src/int/support/intextra.cc` — search for the opcode, add handler |
| Dialog box shows `Error` or `{xxx}{}{}` | MSG file missing or malformed | `GOG/patchedfiles/data/text/english/dialog/SCRIPTNAME.msg` |
| NPC does nothing when clicked | Script not assigned in MAP/PRO file | Check `12_script_refs.md` audit, verify PRO file references correct script index |
| Game crashes on map load | Script references invalid memory/variable | Run with ASAN: `cmake -B build-macos-asan -DASAN=ON`, rebuild, reproduce |
| Script runs but wrong behavior | Variable overflow or init issue | Scripts use global/local vars; check VAULT13.GAM for global var init |
| Companion won't follow | Pathing or team assignment bug | Check script's team assignment code, verify map exit grids work |
| Text garbled/wrong language | Wrong MSG file or encoding issue | Verify file is CP1252 encoded, check `{id}{}{text}` format |

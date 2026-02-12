# TODO: RME Dialog & Text Verification

> **Purpose**: Verify ~370 modified MSG dialog files, 2 new MSG files, 14 game text files, 9 cutscene files, and QUOTES.TXT all work correctly after RME integration.
> **Status**: Zero runtime testing completed. Data pipeline verified only.
> **Executor**: Anyone with a macOS build and GOG Fallout 1 data installed.

---

## Prerequisites

- macOS build available at `build-macos/RelWithDebInfo/Fallout 1 Rebirth.app`
- GOG patched data installed at `GOG/patchedfiles/`
- GOG unpatched (vanilla) data at `GOG/unpatchedfiles/` for comparison
- Evidence output directory: `development/RME/ARTIFACTS/evidence/`

## MSG File Format Reference

All dialog files use this format:
```
{message_id}{}{message_text}
```
- `{message_id}` — integer ID referenced by scripts
- `{}` — empty audio reference field (always empty in this game)
- `{message_text}` — the actual dialog text, CP1252 encoded

Lines starting with `#` are comments. Blank lines are ignored.
**Any line that doesn't match this pattern (and isn't a comment or blank) will cause the game to fail to load that dialog.**

---

## Automated Verification

### D-1: Verify MSG file format integrity

- [ ] **Run format validation on all dialog MSG files**
```bash
python3 -c "
import os, re, sys
errors = []
dialog_dir = 'GOG/patchedfiles/data/text/english/dialog'
for f in sorted(os.listdir(dialog_dir)):
    if not f.endswith('.msg'): continue
    path = os.path.join(dialog_dir, f)
    with open(path, 'rb') as fh:
        data = fh.read()
    lines = data.decode('cp1252', errors='replace').split('\n')
    for i, line in enumerate(lines, 1):
        line = line.strip()
        if line and not line.startswith('#') and not line.startswith('{'):
            errors.append(f'{f}:{i}: {line[:60]}')
if errors:
    print(f'ERRORS FOUND: {len(errors)}')
    for e in errors[:20]:
        print(f'  {e}')
    sys.exit(1)
else:
    print('All dialog MSG files OK')
"
```
**Expected output**: `All dialog MSG files OK`

- [ ] **Run format validation on game text MSG files**
```bash
python3 -c "
import os, re, sys
errors = []
game_dir = 'GOG/patchedfiles/data/text/english/game'
for f in sorted(os.listdir(game_dir)):
    if not f.endswith('.msg'): continue
    path = os.path.join(game_dir, f)
    with open(path, 'rb') as fh:
        data = fh.read()
    lines = data.decode('cp1252', errors='replace').split('\n')
    for i, line in enumerate(lines, 1):
        line = line.strip()
        if line and not line.startswith('#') and not line.startswith('{'):
            errors.append(f'{f}:{i}: {line[:60]}')
if errors:
    print(f'ERRORS FOUND: {len(errors)}')
    for e in errors[:20]:
        print(f'  {e}')
    sys.exit(1)
else:
    print('All game MSG files OK')
"
```
**Expected output**: `All game MSG files OK`

**If format errors found**:
1. Open the file and line number reported
2. Look for: unclosed braces, missing `{}` empty field, text outside braces, encoding corruption
3. Fix the line to match format: `{id}{}{text}`
4. Common issues: merged lines (missing newline between entries), stray characters from patch application
5. Compare against vanilla if available: `diff GOG/unpatchedfiles/data/text/english/dialog/FILENAME.msg GOG/patchedfiles/data/text/english/dialog/FILENAME.msg`

---

### D-2: Check for CRLF contamination in MSG files

- [ ] **Dialog files**
```bash
find GOG/patchedfiles/data/text/english/dialog/ -name "*.msg" -exec grep -Pl '\r' {} \; | wc -l
```
**Expected output**: `0`

- [ ] **Game text files**
```bash
find GOG/patchedfiles/data/text/english/game/ -name "*.msg" -exec grep -Pl '\r' {} \; | wc -l
```
**Expected output**: `0`

- [ ] **Cutscene/ending files**
```bash
find GOG/patchedfiles/data/text/english/cuts/ -exec grep -Pl '\r' {} \; 2>/dev/null | wc -l
```
**Expected output**: `0`

**If CRLF found**:
```bash
# Fix all at once:
find GOG/patchedfiles/data/text/ -name "*.msg" -exec sed -i '' 's/\r$//' {} \;
find GOG/patchedfiles/data/text/ -name "*.sve" -exec sed -i '' 's/\r$//' {} \;
find GOG/patchedfiles/data/text/ -name "*.txt" -exec sed -i '' 's/\r$//' {} \;
```

---

### D-3: Verify new MSG files exist

- [ ] **CRVNTEAM.MSG (caravan team dialog — NEW)**
```bash
ls -la GOG/patchedfiles/data/text/english/dialog/crvnteam.msg
```
**Expected**: File exists, non-zero size.

- [ ] **SENTRY.MSG (restored sentry NPC dialog — NEW)**
```bash
ls -la GOG/patchedfiles/data/text/english/dialog/sentry.msg
```
**Expected**: File exists, non-zero size.

- [ ] **Quick content check of new files**
```bash
echo "=== CRVNTEAM.MSG ===" && head -5 GOG/patchedfiles/data/text/english/dialog/crvnteam.msg
echo "=== SENTRY.MSG ===" && head -5 GOG/patchedfiles/data/text/english/dialog/sentry.msg
```
**Expected**: Lines in `{id}{}{text}` format.

**If missing**:
1. Check case: `ls GOG/patchedfiles/data/text/english/dialog/ | grep -i crvnteam`
2. If truly absent, the patch pipeline missed this file — check `third_party/rme/` for the source

---

### D-4: Verify game text MSG files (14 files)

- [ ] **Check all 14 game text MSG files exist**
```bash
for f in combatai.msg editor.msg intrface.msg lsgame.msg misc.msg perk.msg pipboy.msg proto.msg pro_item.msg script.msg scrname.msg skill.msg stat.msg trait.msg; do
  if [ -f "GOG/patchedfiles/data/text/english/game/$f" ]; then
    echo "OK: $f ($(wc -c < "GOG/patchedfiles/data/text/english/game/$f") bytes)"
  else
    echo "MISSING: $f"
  fi
done
```
**Expected**: All 14 files present, all non-zero size.

- [ ] **Compare sizes against vanilla**
```bash
for f in combatai.msg editor.msg intrface.msg lsgame.msg misc.msg perk.msg pipboy.msg proto.msg pro_item.msg script.msg scrname.msg skill.msg stat.msg trait.msg; do
  PATCHED=$(wc -c < "GOG/patchedfiles/data/text/english/game/$f" 2>/dev/null || echo "0")
  VANILLA=$(wc -c < "GOG/unpatchedfiles/data/text/english/game/$f" 2>/dev/null || echo "0")
  echo "$f: vanilla=${VANILLA} patched=${PATCHED}"
done
```
**Expected**: Most files should be same size or slightly larger (RME adds/fixes text).

**If a game text file is MISSING**:
1. This will break major UI features (character screen, PipBoy, combat messages, etc.)
2. As a stopgap, copy from vanilla: `cp GOG/unpatchedfiles/data/text/english/game/FILENAME.msg GOG/patchedfiles/data/text/english/game/`
3. Then investigate why the patch pipeline didn't include it

---

### D-5: Verify ending/cutscene files (9 files)

- [ ] **Check all cutscene/ending files exist**
```bash
for f in boil1.sve boil2.sve boil3.sve narrate.txt nar_8.txt nar_10.txt nar_13.txt ovrintro.sve ovrintro.txt; do
  if [ -f "GOG/patchedfiles/data/text/english/cuts/$f" ]; then
    echo "OK: $f ($(wc -c < "GOG/patchedfiles/data/text/english/cuts/$f") bytes)"
  else
    echo "MISSING: $f"
  fi
done
```
**Expected**: All 9 files present and non-zero.

- [ ] **Verify QUOTES.TXT exists**
```bash
ls -la GOG/patchedfiles/data/text/english/game/quotes.txt 2>/dev/null || \
ls -la GOG/patchedfiles/data/quotes.txt 2>/dev/null || \
echo "QUOTES.TXT not found — check alternate locations"
```
**Expected**: File exists somewhere in the data tree.

**If cutscene files missing**:
1. Endings won't display properly — player sees blank/error screens at game end
2. Copy from vanilla as stopgap
3. These files use a simpler format than MSG — mostly plain text with some markup

---

## Gameplay Testing — NPC Dialog

For each test below:
- **What to do**: Exact steps to reach the NPC and trigger dialog
- **What to look for**: Correct behavior
- **What broken looks like**: Error symptoms
- **Remediation**: Steps to diagnose and fix

---

### D-6: Dialog gameplay test — Killian Darkwater (Junktown)

- [ ] **Test Killian's dialog tree**
  1. Travel to Junktown (west of Hub on world map)
  2. Go to Killian's store (Darkwaters General Store, central area)
  3. Talk to Killian
  4. **Expected**: Full dialog tree with options about Gizmo, the town, buying/selling, the assassination plot
  5. **Look for**: All dialog options present, no garbled text, no `Error` messages in dialog box
  6. Choose different dialog branches — each should lead to coherent responses
  7. If the assassination event triggers (Kenji attacks), verify that cutscene dialog works

**What broken looks like**:
- Dialog box opens but is empty or shows `{101}{}{}`-style raw format
- Only some options appear, others are missing
- Text is garbled or shows wrong characters (encoding issue)
- Game crashes when selecting a dialog option

**Remediation**:
1. Check MSG file: `cat GOG/patchedfiles/data/text/english/dialog/killian.msg | head -30`
2. Verify format: every content line must be `{id}{}{text}`
3. Check script references correct IDs: the script calls `message_str(KILLIAN_MSG, id)` — if the ID doesn't exist in the MSG file, you get errors
4. Compare against vanilla: `diff GOG/unpatchedfiles/data/text/english/dialog/killian.msg GOG/patchedfiles/data/text/english/dialog/killian.msg | head -40`

---

### D-7: Dialog gameplay test — Aradesh (Shady Sands)

- [ ] **Test Aradesh's dialog tree**
  1. Travel to Shady Sands (south of Vault 13)
  2. Find Aradesh in the central area of town
  3. Talk to him
  4. **Expected**: Dialog about radscorpions, Tandi, water, town defense
  5. Test all main dialog branches
  6. Accept a quest and verify quest log updates

**What broken looks like**: Same symptoms as D-6 above.

**Remediation**:
1. Check: `cat GOG/patchedfiles/data/text/english/dialog/aradesh.msg | head -30`
2. Compare: `diff GOG/unpatchedfiles/data/text/english/dialog/aradesh.msg GOG/patchedfiles/data/text/english/dialog/aradesh.msg | head -40`

---

### D-8: Dialog gameplay test — Hub merchants

- [ ] **Test Hub merchant dialogs**
  1. Travel to Hub (large city, multiple areas)
  2. Go to Hub Downtown
  3. Talk to various merchants: weapon dealer, general store, water merchants
  4. **Expected**: Buy/sell dialogs work, prices display correctly, inventory exchange functions
  5. **Key test**: Buy an item, verify it appears in your inventory with correct name and description

**What broken looks like**:
- Merchant dialog opens but no buy/sell options
- Item names are garbled or show as raw IDs
- Prices are zero or absurdly high (game state issue, not MSG)

**Remediation**:
1. Merchant dialogs use both NPC MSG files AND `PRO_ITEM.MSG` for item names
2. Check both: `ls GOG/patchedfiles/data/text/english/game/pro_item.msg`
3. If item names are wrong, `PRO_ITEM.MSG` may be corrupted

---

### D-9: Dialog gameplay test — Harold (Hub Old Town)

- [ ] **Test Harold's dialog tree**
  1. Go to Hub Old Town area
  2. Find Harold (mutant NPC near the east side)
  3. Talk to him
  4. **Expected**: Dialog about the mutants, the Master, Mariposa, his backstory
  5. Harold has extensive dialog — test multiple branches
  6. This is one of the most dialog-heavy NPCs and a good stress test

**What broken looks like**: Same symptoms as D-6.

**Remediation**:
1. Check: `cat GOG/patchedfiles/data/text/english/dialog/harold.msg | wc -l` (should be 100+ lines)
2. Compare: `diff GOG/unpatchedfiles/data/text/english/dialog/harold.msg GOG/patchedfiles/data/text/english/dialog/harold.msg`

---

### D-10: Dialog gameplay test — Decker (Hub)

- [ ] **Test Decker's dialog tree**
  1. Go to Hub, find the Maltese Falcon bar
  2. Go to the back room, talk to Decker
  3. **Expected**: Dialog about underground jobs, assassination quests
  4. Accept a job and verify quest log updates
  5. Test refusing Decker's offers

**What broken looks like**: Same symptoms as D-6.

**Remediation**: Same approach — check `decker.msg` format and content.

---

### D-11: Dialog gameplay test — Brotherhood NPCs

- [ ] **Test High Elder Maxson**
  1. Travel to Brotherhood of Steel bunker (far south)
  2. Gain entry (may need to complete the quest to enter)
  3. Find Maxson on Level 4
  4. Talk to him
  5. **Expected**: Dialog about the Brotherhood, the threat, missions

- [ ] **Test Vree**
  1. Find Vree in the Brotherhood library (Level 2)
  2. Talk to her
  3. **Expected**: Dialog about research, can get the mutant autopsy holodisk
  4. **Key test**: Receiving holodisk items through dialog — verifies script-to-item handoff works

**What broken looks like**: Dialog fails, holodisk isn't received, quest doesn't trigger.

**Remediation**:
1. Check: `ls GOG/patchedfiles/data/text/english/dialog/maxson.msg`
2. Check: `ls GOG/patchedfiles/data/text/english/dialog/vree.msg`
3. If holodisk isn't given: the script's `add_obj_to_inven` call may be failing — check debug log

---

### D-12: PipBoy quest text verification

- [ ] **Test PipBoy text display**
  1. After accepting at least one quest, press the PipBoy button (or hotkey)
  2. Go to Status → Quests tab
  3. **Expected**: Quest names and descriptions display correctly
  4. Check the Archives section for holodisk text
  5. Check the Maps section for location labels
  6. Check the Date/Time display

**What broken looks like**:
- Quest text is garbled or missing
- Section headers show raw IDs
- Dates show incorrectly

**Remediation**:
1. PipBoy text comes from `PIPBOY.MSG`: `cat GOG/patchedfiles/data/text/english/game/pipboy.msg | head -20`
2. Quest descriptions come from individual quest MSG files and the script system
3. If only PipBoy chrome (headers, labels) is wrong, it's a `PIPBOY.MSG` issue
4. If quest text specifically is wrong, check the quest's NPC dialog MSG file

---

### D-13: Character screen text verification

- [ ] **Test PERK.MSG**
  1. Open character screen, click on a perk
  2. **Expected**: Perk name and description display correctly
  3. Level up and pick a perk — verify selection screen text

- [ ] **Test SKILL.MSG**
  1. Open character screen, look at skills list
  2. **Expected**: All skill names display correctly (Small Guns, Big Guns, Energy Weapons, etc.)
  3. Click on a skill for description

- [ ] **Test STAT.MSG**
  1. Open character screen, look at S.P.E.C.I.A.L. stats
  2. **Expected**: Strength, Perception, Endurance, Charisma, Intelligence, Agility, Luck all display

- [ ] **Test TRAIT.MSG**
  1. During character creation, look at trait selection
  2. **Expected**: All trait names and descriptions display correctly

**What broken looks like**: Stats/skills/perks show as numbers or garbled text.

**Remediation**:
1. Each has its own MSG file in `GOG/patchedfiles/data/text/english/game/`
2. Check the specific file that's broken: `perk.msg`, `skill.msg`, `stat.msg`, `trait.msg`
3. Compare against vanilla versions

---

### D-14: Combat AI messages

- [ ] **Test COMBATAI.MSG during combat**
  1. Enter any combat encounter
  2. Watch the message log during combat
  3. **Expected**: Messages like "You hit X for Y damage", "X misses", critical hit descriptions
  4. Verify combat feedback text is readable and correct

**What broken looks like**: Combat messages are garbled, missing, or show raw IDs.

**Remediation**:
1. Check: `cat GOG/patchedfiles/data/text/english/game/combatai.msg | head -20`
2. Combat messages also use `MISC.MSG` — check both files
3. Critical hit descriptions are in the combat MSG files — verify format

---

### D-15: Ending narration test

- [ ] **Test ending narration (requires late-game save)**
  1. If a save near the endgame is available, load it and complete the game
  2. **Expected**: Ending narration plays with correct text for each location/faction
  3. Verify the narrator text matches the slides

  If no late-game save is available, at minimum verify the files are well-formed:
  ```bash
  for f in GOG/patchedfiles/data/text/english/cuts/*.sve GOG/patchedfiles/data/text/english/cuts/*.txt; do
    echo "=== $(basename $f) ==="
    head -3 "$f"
    echo "---"
  done
  ```
  **Expected**: Each file has readable English text, no garbled content.

**What broken looks like**: End slides show no text, wrong text, or garbled characters.

**Remediation**:
1. SVE/TXT files are simpler than MSG — mostly plain text
2. If garbled, likely an encoding issue — verify CP1252 encoding
3. Compare against vanilla: `diff GOG/unpatchedfiles/data/text/english/cuts/narrate.txt GOG/patchedfiles/data/text/english/cuts/narrate.txt`

---

## Evidence Collection

After completing all tests, record results:

```bash
mkdir -p development/RME/ARTIFACTS/evidence/dialog/
cat > development/RME/ARTIFACTS/evidence/dialog/test_results.md << 'EOF'
# Dialog & Text Test Results
Date: YYYY-MM-DD
Tester: NAME

## Automated Checks
- D-1: MSG format validation — [ PASS / FAIL ] (errors: ___)
- D-2: CRLF check — [ PASS / FAIL ] (contaminated files: ___)
- D-3: New MSG files — [ PASS / FAIL ]
- D-4: Game text files — [ PASS / FAIL ] (missing: ___)
- D-5: Cutscene files — [ PASS / FAIL ] (missing: ___)

## Gameplay Tests
- D-6: Killian dialog — [ PASS / FAIL / SKIP ]
- D-7: Aradesh dialog — [ PASS / FAIL / SKIP ]
- D-8: Hub merchants — [ PASS / FAIL / SKIP ]
- D-9: Harold dialog — [ PASS / FAIL / SKIP ]
- D-10: Decker dialog — [ PASS / FAIL / SKIP ]
- D-11: Brotherhood NPCs — [ PASS / FAIL / SKIP ]
- D-12: PipBoy text — [ PASS / FAIL / SKIP ]
- D-13: Character screen — [ PASS / FAIL / SKIP ]
- D-14: Combat AI messages — [ PASS / FAIL / SKIP ]
- D-15: Ending narration — [ PASS / FAIL / SKIP ]

## Notes
(Record any issues, screenshots, or observations here)
EOF
```

---

## General Remediation Reference

| Symptom | Likely Cause | Where to Look |
|---------|-------------|---------------|
| Dialog box empty | MSG file missing entirely | `GOG/patchedfiles/data/text/english/dialog/` — check file exists |
| Shows `{101}{}{}` raw text | MSG file present but not loaded | Check file path and name match what script expects |
| Garbled characters (ÃƒÂ etc.) | UTF-8/CP1252 encoding mismatch | Verify file is CP1252: `file GOG/patchedfiles/data/text/english/dialog/FILE.msg` |
| Wrong dialog text | MSG IDs shifted or overwritten | `diff` against vanilla MSG file to find changed IDs |
| Missing dialog options | Script expects MSG ID that doesn't exist | Check script's `message_str()` calls vs MSG file IDs |
| Game text (skills etc.) wrong | Game MSG file corrupted | Check `GOG/patchedfiles/data/text/english/game/` files |
| PipBoy text wrong | `PIPBOY.MSG` issues | Check format and content of `pipboy.msg` |
| Ending text wrong | SVE/TXT file issues | Check `GOG/patchedfiles/data/text/english/cuts/` files |
| All text wrong everywhere | `data/text/english/` path not found by engine | Check `fallout.cfg` language setting and data path |

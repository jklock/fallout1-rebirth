# TODO: RME Sound, Fonts & Config Verification

> **Purpose**: Verify 2 ACM sound files, 2 AAF font files, game config, and supporting data files work correctly after RME integration.
> **Status**: Zero runtime testing completed. Data pipeline verified only.
> **Executor**: Anyone with a macOS build and GOG Fallout 1 data installed.

---

## Prerequisites

- macOS build available at `build-macos/RelWithDebInfo/Fallout 1 Rebirth.app`
- GOG patched data installed at `GOG/patchedfiles/`
- GOG unpatched (vanilla) data at `GOG/unpatchedfiles/` for comparison
- Evidence output directory: `development/RME/ARTIFACTS/evidence/`
- Speakers or headphones connected (for sound tests)

---

## Sound Assets

RME adds/modifies 2 ACM sound files:
| File | Description | Type |
|------|-------------|------|
| WAE1XXX1.ACM | Weapon sound override | Modified |
| WAE1XXX2.ACM | Fallout 2 Big Pistol Sound | **NEW** |

ACM files are decoded by `src/audio_engine.cc`. File path resolution happens in the DB layer (`src/game/db.cc`).

---

## Sound Verification

### SF-1: Verify sound files present

- [ ] **Check both ACM files exist**
```bash
ls -la GOG/patchedfiles/data/sound/sfx/wae1xxx1.acm
ls -la GOG/patchedfiles/data/sound/sfx/wae1xxx2.acm
```
**Expected**: Both files present, non-zero size.

- [ ] **Compare against vanilla**
```bash
echo "=== WAE1XXX1 ==="
ls -la GOG/unpatchedfiles/data/sound/sfx/wae1xxx1.acm 2>/dev/null || echo "Not in vanilla"
ls -la GOG/patchedfiles/data/sound/sfx/wae1xxx1.acm
echo "=== WAE1XXX2 ==="
ls -la GOG/unpatchedfiles/data/sound/sfx/wae1xxx2.acm 2>/dev/null || echo "Not in vanilla (NEW)"
ls -la GOG/patchedfiles/data/sound/sfx/wae1xxx2.acm
```
**Expected**: WAE1XXX1 exists in both (different sizes = modified). WAE1XXX2 only in patched (NEW file).

- [ ] **Count total SFX files for sanity check**
```bash
echo "Patched SFX:"; ls GOG/patchedfiles/data/sound/sfx/*.acm 2>/dev/null | wc -l
echo "Vanilla SFX:"; ls GOG/unpatchedfiles/data/sound/sfx/*.acm 2>/dev/null | wc -l
```
**Expected**: Patched count >= Vanilla count.

**If sound files MISSING**:
1. Check case sensitivity: `ls GOG/patchedfiles/data/sound/sfx/ | grep -i wae1xxx`
2. If truly absent, the patch pipeline missed them — check RME source in `third_party/rme/`
3. Verify the `data/sound/sfx/` directory exists at all

---

### SF-2: Gameplay sound test — pistol fire

- [ ] **Test weapon sound override**
  1. Launch the game: `open "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app"`
  2. Start a new game or load a save
  3. Acquire a 10mm Pistol (starting weapon in Vault 13) or Desert Eagle
  4. Enter combat, fire the pistol at an enemy
  5. **Expected**: Pistol fire sound plays — should sound like the "Fallout 2 Big Pistol Sound" (deeper, more resonant than vanilla Fallout 1 pistol sound)
  6. **Compare**: If you have vanilla Fallout 1 experience, the sound should be noticeably different (Fallout 2 style)

**What broken looks like**:
- No sound plays when firing
- Sound plays but is distorted, static, or garbled
- Sound plays but is clearly the vanilla Fallout 1 sound (override didn't apply)

**Remediation**:
1. **No sound at all**:
   - Check system audio: are other sounds (music, UI clicks) playing?
   - Check `fallout.cfg` for sound settings: `grep -i "sound" GOG/patchedfiles/fallout.cfg`
   - If all sound is broken, the issue is in `src/audio_engine.cc` — run with debug logging
2. **Distorted/garbled sound**:
   - The ACM decoder may have issues — check `src/audio_engine.cc` and `third_party/adecode/`
   - Try comparing: `xxd GOG/patchedfiles/data/sound/sfx/wae1xxx1.acm | head -5` (should start with ACM header bytes)
   - If the file header is wrong, it may be corrupted during patch — re-extract from RME source
3. **Wrong sound (vanilla plays instead of override)**:
   - The game may be loading from master.dat instead of the loose file
   - Verify file path resolution: loose files in `data/` should override DAT archives
   - Check `src/game/db.cc` for file resolution order

---

### SF-3: General sound test

- [ ] **Door sounds**
  1. In any area with doors (Vault 13, Hub, etc.), open and close a door
  2. **Expected**: Door open/close sound effects play

- [ ] **Combat SFX**
  1. Enter combat
  2. **Expected**: Hit sounds, miss sounds, critical hit sounds all play
  3. Listen for variety — different weapons should have different sounds

- [ ] **Ambient/Music**
  1. Walk through Hub or another town area
  2. **Expected**: Background music plays, ambient sounds (if any) play
  3. Music should loop without gaps or glitches

- [ ] **UI sounds**
  1. Open/close inventory, PipBoy, character screen
  2. **Expected**: UI click/open/close sounds play

**If general sounds work but weapon override doesn't**: The issue is specifically with the WAE1XXX files, not the audio system. Focus on file path and ACM format.

**If NO sounds work at all**:
1. Check `fallout.cfg` sound settings
2. Check macOS audio permissions — the app may need microphone/audio permission
3. Run from terminal to see error output: `"build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth" 2>&1 | grep -i "audio\|sound\|acm"`

---

## Font Assets

RME replaces 2 font files with Fallout 2 versions:
| File | Size | Description |
|------|------|-------------|
| FONT3.AAF | 19,303 bytes | Fallout 2 replacement (dialog/general text) |
| FONT4.AAF | 33,469 bytes | Fallout 2 replacement (larger text/headers) |

AAF (Aleph Anti-aliased Font) files contain character width tables and glyph data. Font rendering is handled by the engine's text system in `src/plib/gnw/text.cc` (or similar).

---

## Font Verification

### SF-4: Verify font files present

- [ ] **Check both AAF files exist with correct sizes**
```bash
ls -la GOG/patchedfiles/data/font3.aaf
ls -la GOG/patchedfiles/data/font4.aaf
```
**Expected**:
- `font3.aaf` = 19,303 bytes
- `font4.aaf` = 33,469 bytes

- [ ] **Compare against vanilla**
```bash
echo "=== FONT3 ==="
ls -la GOG/unpatchedfiles/data/font3.aaf 2>/dev/null
ls -la GOG/patchedfiles/data/font3.aaf
echo "=== FONT4 ==="
ls -la GOG/unpatchedfiles/data/font4.aaf 2>/dev/null
ls -la GOG/patchedfiles/data/font4.aaf
```
**Expected**: Both files exist in vanilla and patched, but with DIFFERENT sizes (patched = Fallout 2 fonts).

- [ ] **Verify AAF file headers**
```bash
xxd GOG/patchedfiles/data/font3.aaf | head -3
xxd GOG/patchedfiles/data/font4.aaf | head -3
```
**Expected**: Valid binary data starting with AAF format header (first 4 bytes should be the font signature).

**If font files MISSING**:
1. Check case: `ls GOG/patchedfiles/data/ | grep -i font`
2. Game will fall back to built-in fonts or crash depending on which font is missing
3. Copy from vanilla as stopgap: `cp GOG/unpatchedfiles/data/font3.aaf GOG/patchedfiles/data/`

---

### SF-5: Font rendering test — dialog

- [ ] **Talk to any NPC and check text rendering**
  1. Start game, talk to any NPC (easiest: Vault 13 NPCs at game start)
  2. **Expected**: Dialog text renders cleanly, characters properly formed
  3. Look for:
     - Characters not clipped at top or bottom
     - Consistent spacing between letters
     - No overlapping characters
     - Special characters render (commas, periods, quotes, apostrophes)
  4. Test a LONG dialog entry — scroll through multiple pages

**What broken looks like**:
- Characters cut off at top/bottom of each line
- Letters overlap each other horizontally
- Some characters render as blank/missing glyphs
- Text extends outside the dialog box boundaries

**Remediation**:
1. If characters clip: The AAF character height metadata may be wrong for the UI's expected font height
2. Check if the game has hardcoded font height expectations in `src/plib/gnw/text.cc` or `src/game/`
3. If only specific characters are wrong: the AAF glyph table may have gaps — compare against vanilla font
4. If text overflows dialog box: the Fallout 2 font may be wider than Fallout 1 font — the dialog box width is fixed
5. Quickest fix: revert to vanilla font to unblock: `cp GOG/unpatchedfiles/data/font3.aaf GOG/patchedfiles/data/font3.aaf`

---

### SF-6: Font rendering test — character screen

- [ ] **Open character screen and verify text**
  1. Press the character button or hotkey
  2. **Expected**: All text renders correctly:
     - S.P.E.C.I.A.L. stat names and values
     - Skill names and percentages
     - Derived stats (HP, AC, etc.)
     - Perk names and descriptions
  3. Look for text overlap — the character screen has TIGHT layout with fixed-width areas
  4. Click on individual stats/skills to see descriptions — verify those render too

**What broken looks like**:
- Text overlaps adjacent columns (e.g., skill name overlaps skill value)
- Stat descriptions cut off or wrap incorrectly
- Some areas show no text at all

**Remediation**:
1. Character screen uses fixed pixel widths for each text area
2. If Fallout 2 fonts are wider, text may not fit — this is a known issue with font replacements
3. Check: are vanilla fonts narrower? `ls -la GOG/unpatchedfiles/data/font3.aaf` (smaller file often = narrower glyphs)
4. If overlap is severe, may need to keep vanilla fonts or adjust UI code in `src/game/editor.cc`

---

### SF-7: Font rendering test — PipBoy

- [ ] **Open PipBoy and verify text**
  1. Press the PipBoy button
  2. Check each section:
     - **Status**: Quest text, condition text
     - **Maps**: Location labels
     - **Archives**: Holodisk text (if any collected)
     - **Date/Time**: Verify date format renders correctly
  3. **Expected**: All text readable, no clipping, scrolling works
  4. Scroll through long quest descriptions to verify multi-line rendering

**What broken looks like**:
- Text cut off at right edge of PipBoy screen
- Scrolling text disappears or jumps
- Date/time shows garbled numbers

**Remediation**:
1. PipBoy has its own text rendering area — check `src/game/pipboy.cc`
2. If text is too wide, the Fallout 2 font's character width is the issue
3. Holodisk text rendering may have different code path — test separately if PipBoy chrome is fine but holodisk text isn't

---

### SF-8: Font rendering test — inventory

- [ ] **Open inventory and verify text**
  1. Open inventory screen
  2. Check:
     - Item names display correctly
     - Item descriptions (examine) display correctly
     - Weight and quantity numbers display correctly
     - Tooltip/hover text (if any) renders correctly
  3. **Expected**: All item text readable, no overlap or clipping

- [ ] **Test long item names**
  1. Look for items with long names (e.g., "Vault 13 Water Flask", "Super Sledge")
  2. **Expected**: Names fit within their display area or are truncated gracefully

**What broken looks like**:
- Item names overlap each other in the list
- Examine text overflows its box
- Numbers (weight, count) garbled

**Remediation**:
1. Item names come from `PRO_ITEM.MSG` — check that file first
2. If names are correct but don't fit, it's a font width issue
3. Check `src/game/inventory.cc` for text rendering bounds

---

## Config Verification

### SF-9: Config file verification

- [ ] **Verify SCALE_2X setting in f1_res.ini**
```bash
grep -i "scale_2x" GOG/patchedfiles/f1_res.ini
```
**Expected**: `SCALE_2X=1`
**Critical**: If `SCALE_2X=0`, the game will show BLACK TILES — this was a known bug that was fixed. Verify it stays at 1.

- [ ] **Verify IFACE settings**
```bash
grep -i "iface" GOG/patchedfiles/f1_res.ini
```
**Expected**: `IFACE_BAR_WIDTH=800` (or appropriate value for higher resolution)

- [ ] **Verify game config templates**
```bash
echo "=== macOS config ==="
grep -i "scale_2x" gameconfig/macos/f1_res.ini
echo "=== iOS config ==="
grep -i "scale_2x" gameconfig/ios/f1_res.ini
```
**Expected**: Both templates have `SCALE_2X=1`

- [ ] **Full f1_res.ini review**
```bash
cat GOG/patchedfiles/f1_res.ini
```
**Expected**: Well-formed INI file, no syntax errors, reasonable values for all settings.

**If SCALE_2X=0**:
1. This MUST be fixed — set to 1
2. Edit: `sed -i '' 's/SCALE_2X=0/SCALE_2X=1/' GOG/patchedfiles/f1_res.ini`
3. Also fix templates if they're wrong:
   - `sed -i '' 's/SCALE_2X=0/SCALE_2X=1/' gameconfig/macos/f1_res.ini`
   - `sed -i '' 's/SCALE_2X=0/SCALE_2X=1/' gameconfig/ios/f1_res.ini`

---

### SF-10: VAULT13.GAM test

- [ ] **Verify VAULT13.GAM exists**
```bash
ls -la GOG/patchedfiles/data/vault13.gam
```
**Expected**: File exists, non-zero size.

- [ ] **Compare against vanilla**
```bash
ls -la GOG/unpatchedfiles/data/vault13.gam
ls -la GOG/patchedfiles/data/vault13.gam
```
**Expected**: Different sizes (RME modifies initial game state).

- [ ] **Gameplay verification — start new game**
  1. Start a completely new game
  2. Check initial conditions:
     - **Water chip timer**: Should be ~150 days (check PipBoy date vs. quest deadline)
     - **Starting equipment**: 10mm Pistol, ammo, stimpaks (standard Vault 13 kit)
     - **Starting stats**: Should match what you selected at character creation
     - **Quest log**: Should show water chip quest as active
  3. **Expected**: All initial conditions are correct and match expected Fallout 1 start

**What broken looks like**:
- Timer is wrong (too short = almost impossible game, too long = no urgency)
- Missing starting equipment
- Unexpected items or skills
- Global flags set that shouldn't be (e.g., quests already completed)

**Remediation**:
1. VAULT13.GAM sets global variables for the entire game — it's critical
2. If initial state is wrong, compare against vanilla: `diff <(xxd GOG/unpatchedfiles/data/vault13.gam) <(xxd GOG/patchedfiles/data/vault13.gam) | head -60`
3. RME modifications to VAULT13.GAM should be documented in `third_party/rme/` or `development/RME/`
4. If completely broken, revert to vanilla as stopgap: `cp GOG/unpatchedfiles/data/vault13.gam GOG/patchedfiles/data/vault13.gam`

---

### SF-11: Config comparison (patched vs. vanilla)

- [ ] **Compare fallout.cfg**
```bash
diff GOG/unpatchedfiles/fallout.cfg GOG/patchedfiles/fallout.cfg
```
**Expected**: Minimal differences. Document what changed and why.

Typical expected differences:
- Resolution settings may differ
- Sound/music settings may differ
- Path settings may differ

- [ ] **Compare f1_res.ini**
```bash
diff GOG/unpatchedfiles/f1_res.ini GOG/patchedfiles/f1_res.ini
```
**Expected**: `SCALE_2X` change (0→1), possible `IFACE_BAR_WIDTH` change.

- [ ] **Document all config differences**
```bash
mkdir -p development/RME/ARTIFACTS/evidence/config/
diff GOG/unpatchedfiles/fallout.cfg GOG/patchedfiles/fallout.cfg > development/RME/ARTIFACTS/evidence/config/fallout_cfg_diff.txt
diff GOG/unpatchedfiles/f1_res.ini GOG/patchedfiles/f1_res.ini > development/RME/ARTIFACTS/evidence/config/f1_res_ini_diff.txt
echo "Config diffs saved to development/RME/ARTIFACTS/evidence/config/"
```

---

### SF-12: BADWORDS.TXT verification

- [ ] **Verify BADWORDS.TXT exists**
```bash
ls -la GOG/patchedfiles/data/badwords.txt 2>/dev/null || \
  find GOG/patchedfiles/ -iname "badwords.txt" | head -1
```
**Expected**: File exists. This is the profanity filter used when the player names their character.

- [ ] **Quick format check**
```bash
head -10 GOG/patchedfiles/data/badwords.txt 2>/dev/null
```
**Expected**: One word per line, plain text.

**If missing**: Non-critical — game runs without it, but character name profanity filter won't work. Copy from vanilla if needed.

---

## Evidence Collection

After completing all tests, record results:

```bash
mkdir -p development/RME/ARTIFACTS/evidence/sound-fonts-config/
cat > development/RME/ARTIFACTS/evidence/sound-fonts-config/test_results.md << 'EOF'
# Sound, Fonts & Config Test Results
Date: YYYY-MM-DD
Tester: NAME

## Sound
- SF-1: Sound files present — [ PASS / FAIL ]
- SF-2: Pistol sound test — [ PASS / FAIL / SKIP ]
  - Sounds like Fallout 2 Big Pistol? [ YES / NO / UNSURE ]
- SF-3: General sound test — [ PASS / FAIL / SKIP ]
  - Doors: [ OK / BROKEN ]
  - Combat: [ OK / BROKEN ]
  - Music: [ OK / BROKEN ]
  - UI: [ OK / BROKEN ]

## Fonts
- SF-4: Font files present — [ PASS / FAIL ]
  - font3.aaf size: ___ bytes (expected: 19,303)
  - font4.aaf size: ___ bytes (expected: 33,469)
- SF-5: Dialog text rendering — [ PASS / FAIL / SKIP ]
- SF-6: Character screen text — [ PASS / FAIL / SKIP ]
- SF-7: PipBoy text — [ PASS / FAIL / SKIP ]
- SF-8: Inventory text — [ PASS / FAIL / SKIP ]
  - Any clipping observed? [ YES / NO ]
  - Any overlap observed? [ YES / NO ]

## Config
- SF-9: Config verification — [ PASS / FAIL ]
  - SCALE_2X=1? [ YES / NO ]
  - IFACE_BAR_WIDTH=800? [ YES / NO ]
- SF-10: VAULT13.GAM test — [ PASS / FAIL / SKIP ]
  - Water chip timer correct? [ YES / NO / UNTESTED ]
  - Starting equipment correct? [ YES / NO / UNTESTED ]
- SF-11: Config diff documented — [ PASS / FAIL ]
- SF-12: BADWORDS.TXT — [ PASS / FAIL ]

## Notes
(Record any issues, screenshots, or observations here)
EOF
```

---

## General Remediation Reference

| Symptom | Likely Cause | Where to Look |
|---------|-------------|---------------|
| No sound at all | Audio system init failure | `src/audio_engine.cc` — check SDL audio init |
| Distorted/garbled sound | ACM decoder issue | `third_party/adecode/` — ACM format parser |
| Wrong sound plays | File not overriding DAT archive | `src/game/db.cc` — check file resolution order (loose files should win) |
| Sound file not found | Case sensitivity or wrong path | `ls -la GOG/patchedfiles/data/sound/sfx/ \| grep -i wae` |
| Font characters clipped | AAF height mismatch with UI | `src/plib/gnw/text.cc` — font rendering, check line height |
| Text overlaps in UI | Fallout 2 font wider than F1 | Character width table in AAF file, fixed-width UI areas |
| Missing glyphs | AAF glyph table incomplete | Compare AAF file against vanilla, check extended ASCII chars |
| Black tiles on map | SCALE_2X=0 in f1_res.ini | Set `SCALE_2X=1` in config |
| Wrong initial game state | VAULT13.GAM corrupted/wrong | Compare against vanilla, check global variable init |
| Config not applied | Wrong config file loaded | Check which `fallout.cfg`/`f1_res.ini` the app actually reads at runtime |
| Music doesn't play | Missing music files or wrong path | Check `data/sound/music/` directory, verify `fallout.cfg` music path |

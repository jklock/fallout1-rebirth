# RME Integration — Master Plan

> **Last updated:** 2026-02-10
> **Status:** In Progress — Pipeline solid, runtime validation ~4%
> **Related:** [OUTCOME.md](../OUTCOME/OUTCOME.md) · [TASKS/](../TASKS/) · [ARTIFACTS/](../ARTIFACTS/)

---

## 1. Executive Summary

**RME (Restoration Mod Enhanced) 1.1e** bundles 22 community mods into a single overlay of **1,126 data files** (750 over `master.dat`, 376 over `critter.dat`). These mods restore cut content, fix bugs, add companion armor variants, improve animations, and include quality-of-life changes accumulated over 25 years of community patching.

The Fallout 1 Rebirth project integrates RME so that patched macOS (.app/DMG) and iOS (.ipa) builds ship with all 22 mods active by default.

### Current Honest Status

| Area | Status | Detail |
|------|--------|--------|
| Data pipeline (patch/checksum/crossref) | **SOLID** | `rebirth-patch-data.sh` applies all 1,126 files correctly |
| Static validation | **SOLID** | `rebirth-validate-data.sh` passes — LST refs, checksums, case normalization |
| Runtime map sweep | **~4%** | 3 of 72 maps completed; sweep crashed at map 4; CSV has 3 rows |
| macOS gameplay testing | **ZERO** | No manual gameplay sessions performed |
| iOS testing | **ZERO** | No simulator or device testing performed |
| Dialog/script runtime | **ZERO** | No runtime verification of ~570 MSG/INT files |
| Sound/font/art runtime | **ZERO** | No runtime verification of ACM/AAF/FRM files |
| Anomaly review | **ZERO** | 105+ present-anomaly BMPs unreviewed |
| Release builds | **NOT TESTED** | DMG/IPA packaging not validated with RME data |

### What "~4%" Means

The runtime map sweep (`rme-runtime-sweep.py`) is designed to load all 72 game maps and log tile/object/script anomalies. It completed exactly **3 maps** before crashing. The summary report falsely claimed "72/0/0" (72 maps, 0 failures, 0 suspicious) — this was generated from the summary template, not from actual data. The CSV evidence file contains only 3 rows.

---

## 2. What RME Changes — Complete File Inventory

**Total: 1,126 files** (750 in `master.dat` overlay, 376 in `critter.dat` overlay)

### Category 1: Maps (30 files)

| Type | Count | Location | Purpose |
|------|-------|----------|---------|
| MAP files | 9 | `maps/*.MAP` | Modified map data (restored areas, fixed scripts) |
| GAM files | 21 | `maps/*.GAM` | Global/local variable state per map |

**Key detail:** 9 MAP files have big-endian headers (standard Fallout 1 format). The engine's map loader handles this natively.

**Maps modified:** ARTEMPLE, BROKEN1, DESERT1, DESERT2, DESERT3, HUBDWNTN, JUNKCSNO, JUNKENT, LAADYTUM, LAFOLLWR, LANECROP, MBCLOSE, MBENT, MBSTRG12, MBVATS12, MBVATS22, NEWR1, RAIDERS, REDDOWN, SHADY, V13ENT, V15ENT, V15SENT, and others.

### Category 2: Art (387 files)

| Type | Count | Location | Purpose |
|------|-------|----------|---------|
| Critter FRMs | 375 | `art/critters/*.FRM` | NPC armor variants, death anims, walk fixes |
| Master art FRMs | 12 | `art/inven/*.FRM`, `art/misc/*.FRM` | Inventory art, reputation icon, Lou fix |

**Mods contributing art:**
- NPC Mod 3.5: Companion armor appearance variants (bulk of 375 critter FRMs)
- Improved Death Animations Fix (mod #14)
- Mutant Walk Fix (mod #12)
- Lou Animations Offset Fix (mod #13)
- Combat Armor Rocket Launcher Fix (mod #15)
- Metal Armor Hammer Thrust Fix (mod #16)
- Original Childkiller Reputation Art (mod #17)

### Category 3: Prototypes (99 files)

| Type | Count | Location | Purpose |
|------|-------|----------|---------|
| Critter PROs | 95 | `proto/critters/*.PRO` | NPC definitions (90 are NPC Mod armor variants) |
| Item PROs | 4 | `proto/items/*.PRO` | Modified item stats/properties |

**Key detail:** The 90 NPC Mod PROs define armor-wearing variants of companions (Ian, Tycho, Katja, Tandi, Dogmeat). Each variant references specific critter FRM art.

### Category 4: Scripts (~205 files)

| Type | Count | Location | Purpose |
|------|-------|----------|---------|
| New INT scripts | ~5 | `scripts/*.INT` | New script logic (restoration mod) |
| Modified INT scripts | ~200 | `scripts/*.INT` | TeamX patches, NPC mod, restoration, fixes |

**Mods contributing scripts:**
- TeamX Patches 1.2/1.2.1/1.3.5 (mods #1–3): Bug fixes across ~150 scripts
- Restoration Mod 1.0b1 (mod #7): Restored cut content scripts
- NPC Mod 3.5 (mod #4): Companion armor management scripts
- Lenore Script Fix (mod #10), Morbid Behavior Fix (mod #11)
- Dialog Fixes by Nimrod (mod #9)

### Category 5: Sound (2 files)

| Type | Count | Location | Purpose |
|------|-------|----------|---------|
| ACM files | 2 | `sound/sfx/*.ACM` | Fallout 2 big pistol sound (mod #18) |

### Category 6: Dialog (~384 files)

| Type | Count | Location | Purpose |
|------|-------|----------|---------|
| NPC MSG files | ~370 | `dialog/*.MSG` | Dialog text for all NPCs |
| Game text MSG files | ~14 | `text/english/game/*.MSG` | UI strings, system messages |
| Cutscene/ending subtitles | 9 | `cuts/*.SVE` or `text/english/cuts/*.MSG` | Endgame slides, cutscene text |

**Mods contributing dialog:**
- TeamX Patches (typo/logic fixes across most MSG files)
- Restoration Mod (restored cut dialog lines)
- Dialog Fixes by Nimrod (mod #9)
- Restored Good Endings 2.0 (mod #8): New ending slide text
- NPC Mod 3.5: Companion armor dialog options

### Category 7: Fonts (2 files)

| Type | Count | Location | Purpose |
|------|-------|----------|---------|
| AAF files | 2 | `font*.AAF` | Fallout 2 fonts (mod #19) — improved readability |

### Category 8: LST Files (7 files)

| Type | Count | Location | Purpose |
|------|-------|----------|---------|
| LST files | 7 | Various | Index/registry files for art, protos, scripts |

**LST files are the spine of the data system.** They map numeric IDs to filenames. If an LST references a file that doesn't exist, the engine may crash or show corrupt data.

**Known issue:** Some LST entries reference files not included in RME. These were "fixed" by aliasing to placeholder files (`blank.frm`, `allnone.int`). This masks the problem rather than solving it — the placeholders will produce invisible sprites or no-op scripts at runtime.

### Category 9: Configs (2 files)

| Type | Count | Location | Purpose |
|------|-------|----------|---------|
| fallout.cfg | 1 | Root | Game configuration |
| f1_res.ini | 1 | Root | Resolution/display settings |

**Handled by:** Project's `gameconfig/` templates (`gameconfig/macos/`, `gameconfig/ios/`). RME's configs are not used directly — the project generates platform-appropriate configs.

### Category 10: Data (2 files)

| Type | Count | Location | Purpose |
|------|-------|----------|---------|
| VAULT13.GAM | 1 | `data/` | Global game variables (initial state) |
| BADWORDS.TXT | 1 | `data/` | Profanity filter word list |

### Summary Table

| # | Category | Files | master.dat | critter.dat |
|---|----------|-------|------------|-------------|
| 1 | Maps | 30 | 30 | — |
| 2 | Art | 387 | 12 | 375 |
| 3 | Prototypes | 99 | 4 | 95 |
| 4 | Scripts | ~205 | ~205 | — |
| 5 | Sound | 2 | 2 | — |
| 6 | Dialog | ~384 | ~384 | — |
| 7 | Fonts | 2 | 2 | — |
| 8 | LSTs | 7 | 7 | — |
| 9 | Configs | 2 | 2 | — |
| 10 | Data | 2 | 2 | — |
| | **Total** | **~1,126** | **~750** | **~376** |

---

## 3. Engine Changes

### Required Changes (MUST have for RME to work)

| File | Change | Why |
|------|--------|-----|
| `src/game/proto.cc` | CRLF line-ending fix | RME LST files use Windows line endings; parser choked on `\r` |
| `src/game/main.cc` / `winmain.cc` | Boot path hardening | Ensure data paths resolve correctly on macOS/iOS bundles |
| `src/plib/gnw/svga.cc` | Bounds clipping | Prevent out-of-bounds rendering with modded art dimensions |

### Fix Changes (defensive improvements)

| File | Change | Why |
|------|--------|-----|
| `src/plib/gnw/gnw.cc` | Composite fill fix | Prevent visual artifacts when compositing modded art layers |
| `src/plib/gnw/svga.cc` | Zero-source skip | Defensive null-pointer guard for missing/placeholder art |

### Debug Instrumentation (opt-in via `F1R_PATCHLOG`)

| File | Change | Why |
|------|--------|-----|
| Various | Patchlog facility | Structured logging of file loads, map loads, tile/object state |
| Various | Map/tile/object instrumentation | Per-map dump of all loaded objects for anomaly detection |
| Various | Autorun hooks | Enable automated map sweep without user interaction |

All debug instrumentation is **compile-time opt-in** via `F1R_PATCHLOG` define and has zero impact on release builds.

---

## 4. What Has Been Validated (with evidence)

### 4.1 Static Data Pipeline

| Check | Status | Evidence |
|-------|--------|----------|
| Patch script applies all 1,126 files | ✅ PASS | `ARTIFACTS/prior-validation/` — patch logs |
| SHA-256 checksums match expected | ✅ PASS | `ARTIFACTS/prior-validation/` — checksum files |
| LST cross-references resolve | ✅ PASS | `ARTIFACTS/prior-validation/` — crossref output |
| Case normalization (macOS HFS+) | ✅ PASS | `rebirth-validate-data.sh` output |
| `rebirth-validate-data.sh` exits 0 | ✅ PASS | Repeatable — run anytime |

### 4.2 Runtime Map Sweep (partial)

| Check | Status | Evidence |
|-------|--------|----------|
| Map 1 (ARTEMPLE) loads | ✅ PASS | `ARTIFACTS/evidence/` — CSV row 1 |
| Map 2 loads | ✅ PASS | `ARTIFACTS/evidence/` — CSV row 2 |
| Map 3 loads | ✅ PASS | `ARTIFACTS/evidence/` — CSV row 3 |
| Maps 4–72 | ❌ NOT TESTED | Sweep crashed at map 4 |

### 4.3 Build Verification

| Check | Status | Evidence |
|-------|--------|----------|
| macOS Makefile build compiles | ✅ PASS | `./scripts/build/build-macos.sh` succeeds |
| iOS Xcode build compiles | ✅ PASS | `./scripts/build/build-ios.sh` succeeds |
| macOS app launches (unpatched) | ✅ PASS | App starts, shows main menu |

---

## 5. What Has NOT Been Validated

### 5.1 Runtime Map Sweep — 69 of 72 maps untested

The sweep script (`scripts/patch/rme-runtime-sweep.py`) crashed after map 3. **69 maps have never been loaded with RME data.** Any of them could crash, show corrupt tiles, or trigger script errors.

### 5.2 Art Runtime — 387 files untested

No critter FRM, inventory art, or misc art file has been verified at runtime. Issues that would only appear visually:
- Wrong animation frames (NPC Mod armor variants)
- Offset errors (Lou fix, death anims)
- Missing frames causing invisible NPCs
- Placeholder `blank.frm` producing invisible sprites

### 5.3 Prototype Runtime — 99 files untested

No PRO file has been verified in gameplay. Potential issues:
- NPC stats/HP/AP incorrect
- Item damage/range values wrong
- Critter-to-FRM mapping broken (wrong PRO → FRM reference)

### 5.4 Script Runtime — ~205 files untested

No INT script has been verified in gameplay. Potential issues:
- TeamX bug fixes may reference opcodes differently
- Restoration mod scripts may depend on specific global variables in `VAULT13.GAM`
- NPC Mod scripts may fail if companion PRO IDs don't match expectations
- Placeholder `allnone.int` scripts do nothing — any NPC/tile relying on them has no behavior

### 5.5 Sound Runtime — 2 files untested

The Fallout 2 pistol sound ACM files have never been played in-game.

### 5.6 Dialog Runtime — ~384 files untested

No dialog MSG file has been verified in conversation. Potential issues:
- Line numbering mismatches (script expects line N, MSG has different line N)
- Encoding issues (extended ASCII / special characters)
- Missing lines that scripts reference
- Cut content dialog that has no triggering script

### 5.7 Font Runtime — 2 files untested

The Fallout 2 AAF fonts have never been rendered in-game. Visual issues (spacing, glyph corruption, size mismatch) would only be visible during gameplay.

### 5.8 Anomaly BMP Review — 105+ unreviewed

The map sweep generates BMP screenshots of anomalous tiles/objects. Over 105 "present-anomaly" BMPs were generated from the 3 completed maps. **None have been reviewed.** They may show:
- Visual glitches requiring art fixes
- False positives from the detection algorithm
- Real issues that need engine or data fixes

### 5.9 macOS Gameplay — zero sessions

No one has played the RME-patched game on macOS. Zero verification of:
- Main menu rendering with modded fonts
- New game start with modified `VAULT13.GAM`
- Any NPC conversation
- Any quest completion
- Any companion recruitment or armor change
- Any combat with modified weapons/NPCs
- Sound effects
- Endgame slides
- Save/load with modded data

### 5.10 iOS — zero testing

No iOS simulator or device testing has been performed with RME data. Zero verification of:
- App launch with patched data
- Touch controls with modded UI
- Any gameplay functionality

### 5.11 Release Builds — not tested

Neither DMG nor IPA packaging has been tested with RME data included.

---

## 6. Previous False Claims

| Claim | Source | Reality | How We Know |
|-------|--------|---------|-------------|
| "72 maps, 0 failures, 0 suspicious" | Sweep summary report | **3 maps completed, sweep crashed at map 4** | CSV file has exactly 3 data rows |
| "Runtime sweep complete" | Prior documentation | **Sweep is ~4% complete** | Script logs show crash after map 3 |
| "All LST references resolved" | Validation output | **Resolved via placeholders** — `blank.frm` and `allnone.int` mask missing files | Placeholder files exist in RME overlay |
| "RME integration validated" | Prior status claims | **Only static pipeline validated** — zero runtime, zero gameplay | No gameplay evidence exists |

---

## 7. Five-Phase Validation Plan

### Phase A: Infrastructure (build, patch, install)

**Goal:** Confirm the patching pipeline produces a working macOS app with all RME data.

| Step | Command | Pass Criteria |
|------|---------|---------------|
| A1. Clean build | `./scripts/dev/dev-clean.sh && ./scripts/build/build-macos.sh` | Exit 0, app bundle exists |
| A2. Static validate | `./scripts/patch/rebirth-validate-data.sh` | Exit 0, no ERROR lines |
| A3. Patch macOS app | `./scripts/patch/rebirth-patch-app.sh` | Exit 0, patched app bundle exists |
| A4. Launch patched app | Open `build-macos/Fallout 1 Rebirth.app` | Main menu appears |
| A5. Verify data paths | Check patchlog for file load paths | All 1,126 overlay files load from correct locations |

**Estimated time:** 30 minutes
**Dependencies:** None
**Evidence:** Terminal output screenshots/logs → `ARTIFACTS/evidence/phase-a/`

### Phase B: Automated Testing

**Goal:** Complete the 72-map runtime sweep and review all anomalies.

| Step | Command | Pass Criteria |
|------|---------|---------------|
| B1. Fix sweep crash | Debug `rme-runtime-sweep.py` crash at map 4 | Script runs past map 4 |
| B2. Full 72-map sweep | `python3 scripts/patch/rme-runtime-sweep.py` | 72/72 maps load, CSV has 72 rows |
| B3. Flaky map retest | `./scripts/patch/rme-repeat-map.sh <map> 5` for any suspicious maps | 5/5 passes per map |
| B4. Patchlog analysis | `python3 scripts/dev/patchlog_analyze.py` | No CRITICAL errors |
| B5. Anomaly BMP review | Manual review of all anomaly BMPs in sweep output | Each anomaly categorized as: OK / cosmetic / blocker |
| B6. Placeholder audit | Grep for `blank.frm` / `allnone.int` loads in patchlog | Document which NPCs/tiles use placeholders, assess gameplay impact |

**Estimated time:** 2–4 hours
**Dependencies:** Phase A complete
**Evidence:** CSV, patchlog, anomaly review notes → `ARTIFACTS/evidence/phase-b/`

### Phase C: Manual macOS Gameplay

**Goal:** Verify all 10 RME data categories work correctly during actual gameplay.

| Step | What to Test | Pass Criteria |
|------|-------------|---------------|
| C1. Menu + fonts | Launch game, observe main menu | Fallout 2 fonts render correctly, no glyph corruption |
| C2. New game | Start new game, complete Vault 13 tutorial | Game starts, dialog works, can leave vault |
| C3. Children NPCs | Visit Shady Sands or Hub | Children visible (childkiller reputation art mod active) |
| C4. NPC recruitment | Recruit Ian in Shady Sands | Ian joins party, dialog options correct |
| C5. Companion armor | Give Ian armor | Ian's appearance changes (NPC Mod FRMs load) |
| C6. Mutant walk | Encounter super mutants | Walk animation plays correctly (no sliding/glitching) |
| C7. Lou animations | Encounter Lou (Lieutenant) | Animations display without offset errors |
| C8. Combat + sound | Enter combat, fire pistol | Fallout 2 pistol sound plays |
| C9. Dialog tree | Talk to 3+ NPCs with modified dialog | Dialog renders correctly, no missing lines or format errors |
| C10. Quest completion | Complete at least 1 quest with TeamX-patched scripts | Quest updates correctly, XP awarded |
| C11. 30-min session | Play for 30 continuous minutes | No crashes, no visual glitches, no softlocks |
| C12. Save/load | Save game, quit, reload | Save loads correctly, game state preserved |
| C13. Restored content | Access at least 1 piece of Restoration Mod content | Content is present and functional |
| C14. Endings | Complete game or use debug to trigger ending slides | Ending slides display with correct text (Restored Good Endings) |

**Estimated time:** 4–8 hours (requires game data files)
**Dependencies:** Phase A complete; game data (`master.dat`, `critter.dat`) available
**Evidence:** Screenshots, notes per step → `ARTIFACTS/evidence/phase-c/`

### Phase D: iOS Testing

**Goal:** Verify RME-patched game works on iOS Simulator.

| Step | Command / Action | Pass Criteria |
|------|-----------------|---------------|
| D1. Build iOS | `./scripts/build/build-ios.sh` | Exit 0 |
| D2. Simulator setup | `./scripts/test/test-ios-simulator.sh --shutdown && ./scripts/test/test-ios-simulator.sh` | Simulator boots, app installs |
| D3. Launch + menu | App opens in simulator | Main menu appears with correct fonts |
| D4. Touch new game | Tap "New Game" | Game starts, Vault 13 loads |
| D5. Touch dialog | Interact with NPC via touch | Dialog renders, touch selection works |
| D6. Map transition | Walk to map exit | Map transition succeeds, no crash |
| D7. 10-min session | Play for 10 minutes | No crashes, touch controls responsive |

**Estimated time:** 2–3 hours
**Dependencies:** Phase A complete; Xcode with simulator; game data
**Evidence:** Simulator screenshots → `ARTIFACTS/evidence/phase-d/`

### Phase E: Release Builds

**Goal:** Verify distribution packages build and work.

| Step | Command | Pass Criteria |
|------|---------|---------------|
| E1. macOS DMG | `./scripts/build/build-macos.sh` then `cd build-macos && cpack -C RelWithDebInfo` | DMG file created |
| E2. DMG install test | Mount DMG, copy app, launch | App launches from DMG-installed location |
| E3. iOS IPA | `./scripts/build/build-ios.sh` then `cd build-ios && cpack -C RelWithDebInfo` | IPA file created |
| E4. IPA size check | `ls -lh build-ios/*.ipa` | IPA size is reasonable (< 50 MB without game data) |

**Estimated time:** 1–2 hours
**Dependencies:** Phase C and D complete (we want to package a validated build)
**Evidence:** Build logs, file listings → `ARTIFACTS/evidence/phase-e/`

---

## 8. Risk Matrix

| # | Risk | Likelihood | Impact | Mitigation |
|---|------|-----------|--------|------------|
| R1 | Sweep crash is a fundamental engine bug | Medium | HIGH | Debug crash at map 4 first; may need engine fix |
| R2 | NPC Mod armor FRMs cause visual corruption | Medium | Medium | Manual gameplay testing (Phase C step C5) |
| R3 | Placeholder scripts (`allnone.int`) break NPC behavior | HIGH | Medium | Placeholder audit (Phase B step B6); document affected NPCs |
| R4 | Placeholder art (`blank.frm`) makes NPCs invisible | HIGH | Medium | Placeholder audit; search for invisible entities during gameplay |
| R5 | TeamX script patches conflict with Restoration Mod | Low | HIGH | 30-min gameplay session will surface crashes/softlocks |
| R6 | Dialog MSG line numbering mismatches | Medium | Medium | Talk to multiple NPCs during gameplay (Phase C step C9) |
| R7 | iOS touch controls break with modded UI elements | Low | Medium | iOS touch testing (Phase D steps D5–D6) |
| R8 | Endgame slides missing or garbled | Medium | Low | Trigger endings during gameplay or via debug (Phase C step C14) |
| R9 | Font AAF causes text overlap or truncation | Low | Medium | Observe all text rendering during gameplay (Phase C step C1) |
| R10 | Save/load corrupts with modified VAULT13.GAM | Low | HIGH | Save/load test (Phase C step C12) |
| R11 | Release DMG/IPA missing patched data | Medium | HIGH | Release build tests (Phase E) |
| R12 | Fallout 2 pistol sound doesn't play or sounds wrong | Low | Low | Combat test (Phase C step C8) |

---

## 9. Definition of Done

RME integration is **DONE** when all of the following are true:

### Infrastructure
- [ ] `./scripts/patch/rebirth-validate-data.sh` passes (exit 0)
- [ ] `./scripts/patch/rebirth-patch-app.sh` produces working patched app
- [ ] Patched app launches to main menu

### Automated Verification
- [ ] 72/72 maps load in runtime sweep (CSV has 72 rows)
- [ ] 0 maps flagged as "suspicious" in sweep
- [ ] All anomaly BMPs reviewed and categorized
- [ ] Flaky maps (if any) pass 5/5 repeats
- [ ] Patchlog analysis shows no CRITICAL errors
- [ ] Placeholder usage documented with gameplay impact assessment

### macOS Gameplay
- [ ] New game starts and completes Vault 13 tutorial
- [ ] Fallout 2 fonts render correctly
- [ ] Children NPCs visible
- [ ] Companions recruitable with correct dialog
- [ ] Companion armor changes appearance (NPC Mod)
- [ ] Mutant walk animation correct
- [ ] Combat works, Fallout 2 pistol sound plays
- [ ] At least 1 quest with TeamX patches completes correctly
- [ ] Restored content accessible
- [ ] 30-minute play session without crashes
- [ ] Save/load works correctly

### iOS
- [ ] App launches on simulator
- [ ] New game starts via touch
- [ ] Dialog interaction works via touch
- [ ] Map transition succeeds
- [ ] 10-minute play session without crashes

### Release
- [ ] macOS DMG builds successfully
- [ ] DMG-installed app launches and plays
- [ ] iOS IPA builds successfully

---

## 10. Cross-References

| Document | Location | Purpose |
|----------|----------|---------|
| OUTCOME.md | `development/RME/OUTCOME/OUTCOME.md` | Validation gates, pass/fail criteria, sign-off |
| TODO files | `development/RME/TASKS/TODO.*.md` | Individual task breakdowns |
| Prior validation artifacts | `development/RME/ARTIFACTS/prior-validation/` | Evidence from static validation |
| Evidence archive | `development/RME/ARTIFACTS/evidence/` | Runtime evidence (CSVs, logs, BMPs) |
| Old TODO archive | `development/RME/ARTIFACTS/old-todo/` | Previous task lists (historical) |
| RME source data | `third_party/rme/` | RME 1.1e mod files |
| Patch scripts | `scripts/patch/` | All patching and validation scripts |
| Game configs | `gameconfig/` | Platform-specific config templates |
| Project journal | `development/RME/JOURNAL.md` | Running log of decisions and progress |

### Key Scripts Quick Reference

| Script | Purpose | Run From |
|--------|---------|----------|
| `scripts/patch/rebirth-patch-data.sh` | Core patcher — applies RME overlay | Project root |
| `scripts/patch/rebirth-patch-app.sh` | macOS app patcher (wraps core) | Project root |
| `scripts/patch/rebirth-patch-ipa.sh` | iOS IPA patcher (wraps core) | Project root |
| `scripts/patch/rebirth-validate-data.sh` | Static validation (LST, checksums, case) | Project root |
| `scripts/patch/rme-runtime-sweep.py` | 72-map automated sweep | Project root |
| `scripts/patch/rme-full-coverage.sh` | Full pipeline (patch + validate + sweep) | Project root |
| `scripts/patch/rme-repeat-map.sh` | Flaky map retester | Project root |
| `scripts/dev/patchlog_analyze.py` | Patchlog structured analysis | Project root |
| `scripts/build/build-macos.sh` | macOS build | Project root |
| `scripts/build/build-ios.sh` | iOS build | Project root |
| `scripts/test/test-ios-simulator.sh` | iOS Simulator test flow | Project root |
| `scripts/dev/dev-clean.sh` | Clean all build artifacts | Project root |
| `scripts/dev/dev-check.sh` | Pre-commit format + lint | Project root |
| `scripts/dev/dev-verify.sh` | Full build verification | Project root |

---

*This plan will be updated as validation progresses. All status changes must cite evidence files.*

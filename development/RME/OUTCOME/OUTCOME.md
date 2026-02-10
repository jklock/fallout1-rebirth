# RME Integration — Outcome & Validation Gates

> **Last updated:** 2026-02-10
> **Status:** All gates PENDING
> **Related:** [PLAN.md](../PLAN/PLAN.md) · [TASKS/](../TASKS/) · [ARTIFACTS/](../ARTIFACTS/)

---

## 1. Validation Gates

RME integration is **COMPLETE** when all 5 gates show **PASSED**.

Each gate has specific, measurable pass/fail criteria. No gate may be marked PASSED without evidence on file.

---

### Gate 1: Static Validation

**Purpose:** Confirm the data pipeline correctly patches all 1,126 RME files and all references resolve.

| # | Criterion | Pass Condition | Fail Condition |
|---|-----------|---------------|----------------|
| 1.1 | Validate script | `./scripts/patch/rebirth-validate-data.sh` exits 0 | Any non-zero exit code |
| 1.2 | LST references | All LST entries resolve to real files (not placeholders) OR placeholder usage is documented with assessed gameplay impact | Unaccounted placeholder references |
| 1.3 | Script references | All INT files referenced by maps/LSTs exist in overlay or base data | Missing INT files without documented reason |
| 1.4 | Case normalization | All filenames case-normalized for macOS HFS+/APFS | Case mismatches in overlay files |
| 1.5 | Checksums | SHA-256 checksums for all 1,126 files match expected values | Any checksum mismatch |
| 1.6 | Patch application | `./scripts/patch/rebirth-patch-app.sh` exits 0 and produces valid app bundle | Patch script fails or app bundle is incomplete |

**Evidence required:**
- Terminal output of `rebirth-validate-data.sh` (full output, not summary only)
- Placeholder audit document listing every `blank.frm` / `allnone.int` reference with gameplay impact
- Checksum comparison log

**Evidence location:** `ARTIFACTS/evidence/gate-1/`

**Current status:** ⬜ PENDING

---

### Gate 2: Runtime Map Sweep

**Purpose:** Confirm all 72 game maps load correctly with RME data overlay active.

| # | Criterion | Pass Condition | Fail Condition |
|---|-----------|---------------|----------------|
| 2.1 | Map completion | 72 of 72 maps load successfully; CSV file has 72 data rows | Any map fails to load; CSV has fewer than 72 rows |
| 2.2 | Suspicious maps | 0 maps flagged "suspicious" by sweep | Any map flagged suspicious without documented explanation |
| 2.3 | Anomaly review | All generated anomaly BMPs reviewed and categorized (OK / cosmetic / blocker) | Unreviewed anomaly BMPs remain |
| 2.4 | Flaky maps | Any map that failed on first attempt passes 5/5 consecutive runs via `rme-repeat-map.sh` | Flaky map fails any of 5 retries |

**Evidence required:**
- Complete CSV from `rme-runtime-sweep.py` with 72 rows (file: `sweep-results.csv`)
- Sweep script stdout/stderr log (file: `sweep-log.txt`)
- Anomaly review spreadsheet or markdown (file: `anomaly-review.md`) documenting disposition of each BMP
- For flaky maps: `rme-repeat-map.sh` output showing 5/5 passes (file: `flaky-retest-<mapname>.txt`)
- Patchlog analysis output from `patchlog_analyze.py` (file: `patchlog-analysis.txt`)

**Evidence location:** `ARTIFACTS/evidence/gate-2/`

**Current status:** ⬜ PENDING

**Previous false claim:** A prior summary reported "72/0/0" (72 maps, 0 failures, 0 suspicious). The CSV actually contains **3 rows**. The sweep crashed at map 4. This gate cannot be marked PASSED until a CSV with 72 genuine data rows exists.

---

### Gate 3: macOS Gameplay

**Purpose:** Verify all 10 RME data categories function correctly during actual gameplay on macOS.

| # | Criterion | Pass Condition | Fail Condition |
|---|-----------|---------------|----------------|
| 3.1 | Main menu | Game launches to main menu; UI renders correctly | Crash on launch, garbled UI |
| 3.2 | New game | New game starts; Vault 13 loads; initial dialog plays | Crash, black screen, or missing dialog |
| 3.3 | Fonts | Fallout 2 font (AAF) renders in all text — menus, dialog, pip-boy | Text garbled, overlapping, or truncated |
| 3.4 | Children NPCs | Children visible in Shady Sands or Hub (Childkiller art mod active) | Children invisible or crash |
| 3.5 | Mutant animations | Super mutant walk animation correct (Mutant Walk Fix) | Sliding, t-posing, or animation glitches |
| 3.6 | Companion recruitment | Recruit at least 1 companion (Ian, Tycho, or Katja) with correct dialog | Companion can't be recruited, dialog broken |
| 3.7 | Companion armor | Give companion armor; visual appearance changes (NPC Mod) | No visual change, crash, or wrong art |
| 3.8 | Dialog | Talk to 3+ NPCs with modified dialog; no missing lines, no format errors | Missing dialog lines, `Error` in dialog window, encoding issues |
| 3.9 | Quest | Complete at least 1 quest affected by TeamX patches; XP awarded correctly | Quest breaks, wrong XP, softlock |
| 3.10 | Sound | Fire pistol in combat; hear Fallout 2 big pistol sound | No sound, wrong sound, audio glitch |
| 3.11 | 30-min session | Play for 30 continuous minutes without crashes or softlocks | Any crash or softlock |
| 3.12 | Save/load | Save game, quit, reload; game state preserved | Save fails, load fails, state corruption |
| 3.13 | Restored content | Access at least 1 piece of Restoration Mod restored content | Content absent or broken |
| 3.14 | Endings | Trigger at least 1 ending slide (Restored Good Endings) | Ending slide missing, garbled text, wrong art |

**Evidence required per criterion:**
- Screenshot(s) showing the criterion being met
- Brief written note describing what was tested and observed
- For crashes/issues: full console output and crash log

**Evidence files (one per criterion):**
- `gate-3-01-menu.png` + `gate-3-01-menu.md`
- `gate-3-02-newgame.png` + `gate-3-02-newgame.md`
- `gate-3-03-fonts.png` + `gate-3-03-fonts.md`
- `gate-3-04-children.png` + `gate-3-04-children.md`
- `gate-3-05-mutants.png` + `gate-3-05-mutants.md`
- `gate-3-06-companion.png` + `gate-3-06-companion.md`
- `gate-3-07-armor.png` + `gate-3-07-armor.md`
- `gate-3-08-dialog.png` + `gate-3-08-dialog.md`
- `gate-3-09-quest.png` + `gate-3-09-quest.md`
- `gate-3-10-sound.md` (audio — describe what was heard)
- `gate-3-11-session.md` (30-min session log with timestamps)
- `gate-3-12-saveload.png` + `gate-3-12-saveload.md`
- `gate-3-13-restored.png` + `gate-3-13-restored.md`
- `gate-3-14-endings.png` + `gate-3-14-endings.md`

**Evidence location:** `ARTIFACTS/evidence/gate-3/`

**Current status:** ⬜ PENDING — zero macOS gameplay testing has been performed.

---

### Gate 4: iOS Testing

**Purpose:** Verify RME-patched game works on iOS Simulator with touch controls.

| # | Criterion | Pass Condition | Fail Condition |
|---|-----------|---------------|----------------|
| 4.1 | App launch | App launches on iPad simulator; main menu appears | Crash on launch, black screen |
| 4.2 | New game | Tap "New Game"; Vault 13 loads | Touch doesn't register, crash, black screen |
| 4.3 | Touch interaction | Navigate menus, move character, interact with objects via touch | Touch coordinates wrong, no response |
| 4.4 | Dialog | Talk to NPC via touch; dialog text renders correctly | Dialog broken, touch selection fails |
| 4.5 | Map transition | Walk to map edge; transition to new map succeeds | Crash on transition, infinite load |

**Evidence required:**
- Simulator screenshot for each criterion
- `test-ios-simulator.sh` terminal output log
- Brief notes on touch behavior

**Evidence files:**
- `gate-4-01-launch.png` + `gate-4-01-launch.md`
- `gate-4-02-newgame.png` + `gate-4-02-newgame.md`
- `gate-4-03-touch.md` (describe touch behavior)
- `gate-4-04-dialog.png` + `gate-4-04-dialog.md`
- `gate-4-05-transition.png` + `gate-4-05-transition.md`

**Evidence location:** `ARTIFACTS/evidence/gate-4/`

**Current status:** ⬜ PENDING — zero iOS testing has been performed.

**Script to use:**
```bash
# Shutdown any running simulators first
./scripts/test/test-ios-simulator.sh --shutdown

# Full flow: build, install, launch
./scripts/test/test-ios-simulator.sh
```

---

### Gate 5: Release Builds

**Purpose:** Verify distribution packages (DMG for macOS, IPA for iOS) build and function correctly.

| # | Criterion | Pass Condition | Fail Condition |
|---|-----------|---------------|----------------|
| 5.1 | DMG builds | `cd build-macos && cpack -C RelWithDebInfo` produces `.dmg` file | cpack fails, no DMG produced |
| 5.2 | DMG works | Mount DMG, copy app to /Applications (or temp), launch — game plays | App doesn't launch from installed location |
| 5.3 | IPA builds | `cd build-ios && cpack -C RelWithDebInfo` produces `.ipa` file | cpack fails, no IPA produced |

**Evidence required:**
- Terminal output of cpack commands (file: `gate-5-build-log.txt`)
- `ls -lh` of DMG and IPA files showing sizes (file: `gate-5-file-sizes.txt`)
- Screenshot of DMG-installed app running (file: `gate-5-02-dmg-running.png`)

**Evidence location:** `ARTIFACTS/evidence/gate-5/`

**Current status:** ⬜ PENDING

**Build commands:**
```bash
# macOS DMG
./scripts/build/build-macos.sh
cd build-macos && cpack -C RelWithDebInfo

# iOS IPA
./scripts/build/build-ios.sh
cd build-ios && cpack -C RelWithDebInfo
```

---

## 2. Evidence Requirements Summary

Every criterion in every gate requires **specific, verifiable evidence** on file. Acceptable evidence types:

| Evidence Type | Format | When to Use |
|---------------|--------|-------------|
| Terminal log | `.txt` | Script output, build logs, exit codes |
| Screenshot | `.png` | Visual verification (menus, gameplay, art) |
| Written note | `.md` | Describing observed behavior, audio, session logs |
| CSV data | `.csv` | Map sweep results, structured data |
| Patchlog | `.txt` or `.log` | Engine patchlog output |

**Rules:**
1. Evidence files must be committed to the repository (not just described)
2. Each evidence file must be named following the convention shown in each gate
3. Evidence must be timestamped (either in filename or in file content)
4. Screenshots must show enough context to verify the criterion (not just a cropped fragment)
5. "It worked" without a file on disk is **not evidence**

---

## 3. Evidence File Locations

```
development/RME/ARTIFACTS/
├── prior-validation/          ← Static validation from earlier work
│   ├── (checksum files)
│   ├── (crossref output)
│   └── (patch logs)
├── evidence/
│   ├── gate-1/                ← Gate 1: Static validation evidence
│   │   ├── validate-output.txt
│   │   ├── placeholder-audit.md
│   │   └── checksum-comparison.txt
│   ├── gate-2/                ← Gate 2: Runtime map sweep evidence
│   │   ├── sweep-results.csv
│   │   ├── sweep-log.txt
│   │   ├── anomaly-review.md
│   │   ├── patchlog-analysis.txt
│   │   └── flaky-retest-*.txt
│   ├── gate-3/                ← Gate 3: macOS gameplay evidence
│   │   ├── gate-3-01-menu.png
│   │   ├── gate-3-01-menu.md
│   │   ├── gate-3-02-newgame.png
│   │   ├── gate-3-02-newgame.md
│   │   ├── ... (through gate-3-14)
│   │   └── gate-3-14-endings.md
│   ├── gate-4/                ← Gate 4: iOS testing evidence
│   │   ├── gate-4-01-launch.png
│   │   ├── gate-4-01-launch.md
│   │   ├── ... (through gate-4-05)
│   │   └── gate-4-05-transition.md
│   └── gate-5/                ← Gate 5: Release builds evidence
│       ├── gate-5-build-log.txt
│       ├── gate-5-file-sizes.txt
│       └── gate-5-02-dmg-running.png
├── archive/                   ← Historical artifacts
└── old-todo/                  ← Previous task lists
```

---

## 4. Sign-Off Checklist

| Gate | Description | Status | Date Passed | Evidence Location | Notes |
|------|-------------|--------|-------------|-------------------|-------|
| 1 | Static Validation | ⬜ PENDING | — | `ARTIFACTS/evidence/gate-1/` | |
| 2 | Runtime Map Sweep | ⬜ PENDING | — | `ARTIFACTS/evidence/gate-2/` | Previously falsely claimed complete |
| 3 | macOS Gameplay | ⬜ PENDING | — | `ARTIFACTS/evidence/gate-3/` | Zero testing performed |
| 4 | iOS Testing | ⬜ PENDING | — | `ARTIFACTS/evidence/gate-4/` | Zero testing performed |
| 5 | Release Builds | ⬜ PENDING | — | `ARTIFACTS/evidence/gate-5/` | |

### Status Legend

| Symbol | Meaning |
|--------|---------|
| ⬜ PENDING | Not yet attempted |
| 🔄 IN PROGRESS | Testing underway, not all criteria met |
| ✅ PASSED | All criteria met, evidence on file |
| ❌ FAILED | One or more criteria failed, needs remediation |
| ⏸️ BLOCKED | Cannot proceed due to dependency |

---

## 5. Known Risks Accepted

Document any items deliberately skipped or accepted as known limitations.

| # | Item | Risk Level | Decision | Rationale |
|---|------|-----------|----------|-----------|
| | *(none yet — populate during validation)* | | | |

**Template for adding accepted risks:**

| # | Item | Risk Level | Decision | Rationale |
|---|------|-----------|----------|-----------|
| K1 | Example: Ending slide X not testable without full playthrough | Low | ACCEPTED | Would require 10+ hour playthrough; other endings verified |

---

## 6. Previous Claims vs Reality

This table provides an honest accounting of claims made before this validation framework was established.

| # | Previous Claim | What Was Actually True | Gap | How We Fix |
|---|---------------|----------------------|-----|-----------|
| 1 | "72 maps swept, 0 failures, 0 suspicious" | 3 maps completed; sweep crashed at map 4; CSV has 3 rows | 69 maps untested | Gate 2: Complete full sweep with 72-row CSV |
| 2 | "Runtime sweep complete" | ~4% complete | 96% remaining | Gate 2: Fix crash, complete sweep |
| 3 | "All LST references resolved" | References resolve to placeholder files (`blank.frm`, `allnone.int`) | Placeholders mask missing files | Gate 1 criterion 1.2: Audit and document all placeholder usage |
| 4 | "RME integration validated" | Only static pipeline validated | Zero runtime, zero gameplay | Gates 2–5: All runtime validation |
| 5 | "Map sweep summary: 72/0/0" | Summary template generated these numbers, not actual data | Summary contradicts CSV | Gate 2: Summary must match CSV row count exactly |
| 6 | "Art validated" | Art files exist and have correct checksums | Zero visual verification | Gate 3: Manual gameplay visual checks |
| 7 | "Scripts validated" | INT files exist in overlay | Zero runtime execution verification | Gate 2 (automated) + Gate 3 (gameplay) |
| 8 | "Dialog validated" | MSG files exist and pass format checks | Zero in-conversation verification | Gate 3 criterion 3.8: Talk to 3+ NPCs |

---

## 7. Final Definition

> **RME integration is COMPLETE when all 5 gates in Section 4 (Sign-Off Checklist) show ✅ PASSED, with evidence files committed to the repository at the locations specified in Section 3.**

No gate may be marked PASSED by assertion alone. Each requires:
1. All criteria within the gate met (per the tables in Section 1)
2. Evidence files present at the specified paths
3. Evidence files committed to the repository

A single ❌ FAILED or ⬜ PENDING gate means RME integration is **NOT COMPLETE**.

---

## Appendix: Gate Dependencies

```
Gate 1 (Static) ──► Gate 2 (Runtime Sweep) ──► Gate 3 (macOS Gameplay) ──► Gate 5 (Release)
                                                        │
                                                        ▼
                                               Gate 4 (iOS Testing) ──► Gate 5 (Release)
```

- **Gate 1** has no dependencies (can run anytime)
- **Gate 2** requires Gate 1 (need valid patched data before runtime testing)
- **Gate 3** requires Gate 1 (need patched app) — can run in parallel with Gate 2
- **Gate 4** requires Gate 1 (need patched iOS build) — can run in parallel with Gates 2–3
- **Gate 5** should follow Gates 3 and 4 (package only after gameplay verified)

---

*This document is the single source of truth for RME validation completion. Update the Sign-Off Checklist as gates are completed.*

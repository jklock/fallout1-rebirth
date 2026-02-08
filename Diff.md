# Diff: `GOG/unpatchedfiles` → `GOG/patchedfiles` ✅

This document summarizes the differences between the original (unpatched) GOG data and the patched output found in `GOG/patchedfiles`. It includes actionable findings (file-level and feature-level) and where to look for more detail.

---

## Key stats 🔢
- Full unified diff: `GOG/unpatched_vs_patched.diff` — **16 MB**, **371,523 lines**. (Created with `diff -ruN`.)
- RME cross-ref (generated):
  - `GOG/rme_xref_unpatched/rme-crossref.md`
  - `GOG/rme_xref_patched/rme-crossref.md`
- Validation run: `./scripts/patch/rebirth-validate-data.sh --patched GOG/patchedfiles --base GOG/unpatchedfiles --rme third_party/rme/source` — **Result: Validation passed** (DATs match expected xdelta output).

From cross-reference output:
- Total RME files scanned: **1126**
- Unpatched base: **636** files found in `master.dat`, **87** in `critter.dat`, **403** new files (not in DATs).
- Patched base: **750** files in `master.dat`, **376** in `critter.dat`, **0** new files (RME payload fully integrated into DATs).
- LST heuristic: **117** missing references (see LST report)
- MAP files flagged as **big-endian header**: 9 maps (see section below)

---

## High-level plain-English summary (what changed & why it matters) 💡
- Master changes: `master.dat` was rewritten in the patched set to include many RME files that were previously loose or absent. In short: **the patch embeds the RME payload into the DATs** rather than leaving everything as loose files only. This breaks the assumption of a "drop-in" patch that would only replace loose files (it *also* replaces DATs).

- Critter changes: `critter.dat` similarly gained many frames and critter data that were previously only in the RME payload or missing.

- Data folder: The patched `data/` tree is much larger (**~1,237 files vs ~135 in unpatched**). It contains `.pro`, `.map`, `.gam`, `.frm`, etc. The patched package therefore contains both an updated `data/` overlay and updated DATs.

- Naming (case-only changes): Many interface/art files changed case or were added in lowercase (e.g., `HR_ALLTLK.FRM` → `hr_alltlk.frm`, `MAINMENU.FRM` → `mainmenu.frm`, `grid000.FRM` → `grid000.frm`). On case-sensitive filesystems this is a real rename; on case-insensitive macOS defaults it can be invisible but still cause resource lookup issues depending on how code references names.

- Map endianness: RME includes a small set of maps with a particular header byte-order (script reports 9 `map` files with `map_endian=big`). The engine's DB reader interprets integers **big-endian**, so these maps are in the expected encoding (no automatic byte-flip needed). However, mixing map endianness or having little-endian maps would break the reader — so this is an item to watch for.

- Config updates: `f1_res.ini` and `fallout.cfg` contain deliberate changes (resolution defaults, windowed mode, interface offsets, and reorganization of debug/sound/system keys). These will change defaults (windowing, clip offsets, where the engine looks for patches), so the patched package effectively expects these new defaults.

- LST references: The LST (file listing) validation found many references that were not found in the overlay or DATs; these are **missing or renamed** assets referenced by LSTs (see `GOG/rme_xref_unpatched/rme-lst-report.md`). This can cause missing art / script lookup problems at runtime.

---

## File-level & feature-level breakdown 🔍

### DATs (`master.dat`, `critter.dat`) — what actually changed
- Sizes & checksums differ:
  - `master.dat` — unpatched: 339,379,746 bytes (SHA256: a7909...); patched: 333,848,925 bytes (SHA256: fbfa0...)
  - `critter.dat` — unpatched: 157,085,138 bytes (SHA256: 668008...); patched: 167,296,448 bytes (SHA256: 69cdf6...)
- The patched DATs are the expected **xdelta** application of RME (script verified with `rebrev-validate-data.sh`), therefore the patched DATs **intentionally include** many RME files.
- Practical implication: Replacing only `data/` may _not_ be equivalent to replacing both DATs — you must either use the patched DATs that match the RME xdelta output, or keep DATs and apply a different overlay.

### Data folder contents & counts
- Unpatched `data/`: ~135 files (mostly `.edg`, `.int`, `.acm`, `.frm`, `.msg`).
- Patched `data/`: ~1,237 files (many `PROTO/`, `MAPS/` `.map` and `.gam` files, `.pro` entries, fonts, scripts, etc.)
- New/added directories in patched: `data/maps`, `data/proto`, `data/font3.aaf`, `data/font4.aaf`, `data/savegame`, `data/scripts`, `data/sound`, `data/text`, plus new `data/art` subfolders like `inven`, `items`, `skilldex`, `critters`.

### Case-only renames (potentially problematic) — sample
(Full list saved to `GOG/case_renames.txt`)
- `HR_ALLTLK.FRM`  <->  `hr_alltlk.frm`
- `HR_IFACE_800.FRM`  <->  `hr_iface_800.frm`
- `MAINMENU.FRM`  <->  `mainmenu.frm`
- `grid000.FRM`  <->  `grid000.frm`
- `MAPS/`  <->  `maps/` (directory case change)
- `SAVEGAME/`  <->  `savegame/`
- `SCRIPTS/`  <->  `scripts/`
- `SOUND/`  <->  `sound/` and `TEXT/` ↔ `text/`

Why it matters: If code or LSTs reference a name with the wrong case on a case-sensitive filesystem, the asset will be missing at runtime. The repo and validation tools normalize case in some checks, but runtime code may not.

### Map files & endianness (technical)
- RME payload includes map binaries that `rme-crossref.py` flagged as `map_endian=big` for these maps:
  - `MAPS/BROHD12.MAP`, `MAPS/CHILDRN1.MAP`, `MAPS/CHILDRN2.MAP`, `MAPS/HUBDWNTN.MAP`, `MAPS/HUBMIS1.MAP`, `MAPS/HUBOLDTN.MAP`, `MAPS/HUBWATER.MAP`, `MAPS/JUNKCSNO.MAP`, `MAPS/JUNKKILL.MAP`
- Engine map reader calls `db_freadInt32`/`db_freadShort`, which reads bytes as high<<8|low (i.e., **big-endian interpretation**). Therefore the flagged maps match engine expectations; if any map were little-endian, it would be an obvious problem.

### LST checks and missing assets
- `GOG/rme_xref_unpatched/rme-lst-report.md` lists LST files with references that were not resolved in either the RME overlay or base DATs — this includes many interface frames and script names.
- These missing references are likely the root cause for missing UI assets or script failures during runtime; they may be missing entirely or present under a different name/case.

### Config changes (brief)
- `f1_res.ini` changes: defaulted to `WINDOWED=1`, `SCR_WIDTH=1280`, `SCR_HEIGHT=960` (previously set for iPad/fullscreen). Added `IFACE` and `INPUT` offset options.
- `fallout.cfg` changes: preferences and debug blocks restructured; patches keys present: `critter_patches=data`, `master_patches=data`. This changes how the engine searches for patch files and default runtime options.

---

## Concrete evidence & artifacts (where to look) 📂
- Full unified diff: `GOG/unpatched_vs_patched.diff` (16 MB)
- Cross-reference reports (CSV + summary):
  - `GOG/rme_xref_unpatched/rme-crossref.csv` & `rme-crossref.md` & `rme-lst-report.md`
  - `GOG/rme_xref_patched/rme-crossref.csv` & `rme-crossref.md` & `rme-lst-report.md`
- Case-rename list: `GOG/case_renames.txt`
- Extracted master/critter file lists: `GOG/unpatched_master_files.txt`, `GOG/patched_master_files.txt`, `GOG/unpatched_critter_files.txt`, `GOG/patched_critter_files.txt`

---

## Recommendations & next steps ✅
1. If you expected a pure **data-only drop-in** patch, note that the provided `GOG/patchedfiles` replaces both `data/` and **master.dat/critter.dat** (it is not data-only). Decide whether you want:
   - The full DAT-replacement (use patched DATs + data/), or
   - A data-only overlay (rebuild a package that keeps original DATs and only provides the loose data files).

2. Fix case naming issues where possible. On case-sensitive filesystems run the case rename list and standardize to the engine's canonical case (or update LST/refs). `GOG/case_renames.txt` has the pairs.

3. Validate LST references: inspect `GOG/rme_xref_unpatched/rme-lst-report.md` and resolve missing assets or update lists to match actual file names.

4. If you need to *verify* the patched output again (or on CI): use `./scripts/patch/rebirth-validate-data.sh --patched <patched-dir> --base <base-dir> --rme third_party/rme/source` (it runs checksums, CRLF normalization and DAT xdelta verification).

5. If you want, I can produce a shorter "data-only" patch list (exclude binary DAT changes) or generate a shell script that applies the patched `data/` only (skip DATs) so you can test drop-in behavior — tell me which option you prefer.

---

If you'd like, I can now:
- Add more per-file notes (e.g., list *all* files added to `master.dat` and `critter.dat`), or
- Generate a data-only patch (textual diff skipping binaries), or
- Start a PR with the safe textual config changes only.

Tell me which next step you'd like. 🔧

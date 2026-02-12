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

5. Use `GOG/validation/LLM_fix_mapping.md` as the canonical prioritized action map for fixes. The mapping doc includes helper scripts and an actionable roadmap (case renames, LST fixes, overlay generation). The machine-readable mapping is available at `GOG/validation/patch_mapping.csv` (useful for an automated LLM pipeline). If you want, I can start a trial PR for a chosen ISSUE (recommended: `ISSUE-LST-002` or `ISSUE-CASE-001`).

---

## Full per-file lists — files added to DATs 📋

**Finding:** I found full lists of added files and saved them as plain text files. **114** files were added to `master.dat` and **289** files were added to `critter.dat`.

- Raw lists (text files): `GOG/master_added_files.txt` (114 lines), `GOG/critter_added_files.txt` (289 lines)

### Added to master.dat (114)

```text
ART\INTRFACE\BOSHARRY.FRM
ART\INTRFACE\BOSHARRY.PAL
ART\INVEN\PARMOR2.FRM
ART\INVEN\ROCK2.FRM
ART\ITEMS\PARMOR2.FRM
ART\ITEMS\ROCK2.FRM
MAPS\DESCRVN1.GAM
MAPS\DESCRVN2.GAM
MAPS\DESCRVN4.GAM
MAPS\LABLADES.GAM
MAPS\MNTCRVN1.GAM
MAPS\MNTCRVN2.GAM
MAPS\MNTCRVN4.GAM
MAPS\SHADYE.GAM
PROTO\CRITTERS\00000313.PRO
PROTO\CRITTERS\00000314.PRO
PROTO\CRITTERS\00000315.PRO
PROTO\CRITTERS\00000316.PRO
PROTO\CRITTERS\00000317.PRO
PROTO\CRITTERS\00000318.PRO
PROTO\CRITTERS\00000319.PRO
PROTO\CRITTERS\00000320.PRO
PROTO\CRITTERS\00000321.PRO
PROTO\CRITTERS\00000322.PRO
PROTO\CRITTERS\00000323.PRO
PROTO\CRITTERS\00000324.PRO
PROTO\CRITTERS\00000325.PRO
PROTO\CRITTERS\00000326.PRO
PROTO\CRITTERS\00000327.PRO
PROTO\CRITTERS\00000328.PRO
PROTO\CRITTERS\00000329.PRO
PROTO\CRITTERS\00000330.PRO
PROTO\CRITTERS\00000331.PRO
PROTO\CRITTERS\00000332.PRO
PROTO\CRITTERS\00000333.PRO
PROTO\CRITTERS\00000334.PRO
PROTO\CRITTERS\00000335.PRO
PROTO\CRITTERS\00000336.PRO
PROTO\CRITTERS\00000337.PRO
PROTO\CRITTERS\00000338.PRO
PROTO\CRITTERS\00000339.PRO
PROTO\CRITTERS\00000340.PRO
PROTO\CRITTERS\00000341.PRO
PROTO\CRITTERS\00000342.PRO
PROTO\CRITTERS\00000343.PRO
PROTO\CRITTERS\00000344.PRO
PROTO\CRITTERS\00000345.PRO
PROTO\CRITTERS\00000346.PRO
PROTO\CRITTERS\00000347.PRO
PROTO\CRITTERS\00000348.PRO
PROTO\CRITTERS\00000349.PRO
PROTO\CRITTERS\00000350.PRO
PROTO\CRITTERS\00000351.PRO
PROTO\CRITTERS\00000352.PRO
PROTO\CRITTERS\00000353.PRO
PROTO\CRITTERS\00000354.PRO
PROTO\CRITTERS\00000355.PRO
PROTO\CRITTERS\00000356.PRO
PROTO\CRITTERS\00000357.PRO
PROTO\CRITTERS\00000358.PRO
PROTO\CRITTERS\00000359.PRO
PROTO\CRITTERS\00000360.PRO
PROTO\CRITTERS\00000361.PRO
PROTO\CRITTERS\00000362.PRO
PROTO\CRITTERS\00000363.PRO
PROTO\CRITTERS\00000364.PRO
PROTO\CRITTERS\00000365.PRO
PROTO\CRITTERS\00000366.PRO
PROTO\CRITTERS\00000367.PRO
PROTO\CRITTERS\00000368.PRO
PROTO\CRITTERS\00000369.PRO
PROTO\CRITTERS\00000370.PRO
PROTO\CRITTERS\00000371.PRO
PROTO\CRITTERS\00000372.PRO
PROTO\CRITTERS\00000373.PRO
PROTO\CRITTERS\00000374.PRO
PROTO\CRITTERS\00000375.PRO
PROTO\CRITTERS\00000376.PRO
PROTO\CRITTERS\00000377.PRO
PROTO\CRITTERS\00000378.PRO
PROTO\CRITTERS\00000379.PRO
PROTO\CRITTERS\00000380.PRO
PROTO\CRITTERS\00000381.PRO
PROTO\CRITTERS\00000382.PRO
PROTO\CRITTERS\00000383.PRO
PROTO\CRITTERS\00000384.PRO
PROTO\CRITTERS\00000385.PRO
PROTO\CRITTERS\00000386.PRO
PROTO\CRITTERS\00000387.PRO
PROTO\CRITTERS\00000388.PRO
PROTO\CRITTERS\00000389.PRO
PROTO\CRITTERS\00000390.PRO
PROTO\CRITTERS\00000391.PRO
PROTO\CRITTERS\00000392.PRO
PROTO\CRITTERS\00000393.PRO
PROTO\CRITTERS\00000394.PRO
PROTO\CRITTERS\00000395.PRO
PROTO\CRITTERS\00000396.PRO
PROTO\CRITTERS\00000397.PRO
PROTO\CRITTERS\00000398.PRO
PROTO\CRITTERS\00000399.PRO
PROTO\CRITTERS\00000400.PRO
PROTO\CRITTERS\00000401.PRO
PROTO\CRITTERS\00000402.PRO
PROTO\ITEMS\00000243.PRO
PROTO\ITEMS\00000244.PRO
SCRIPTS\CARCOW.INT
SCRIPTS\CARCUST.INT
SCRIPTS\JBOXER.INT
SCRIPTS\SENTRY.INT
SCRIPTS\STAPBOX.INT
SOUND\SFX\WAE1XXX2.ACM
TEXT\ENGLISH\DIALOG\CRVNTEAM.MSG
TEXT\ENGLISH\DIALOG\SENTRY.MSG
```

### Added to critter.dat (289)

```text
ART\CRITTERS\HANPWRAA.FRM
ART\CRITTERS\HANPWRAB.FRM
ART\CRITTERS\HANPWRAE.FRM
ART\CRITTERS\HANPWRAK.FRM
ART\CRITTERS\HANPWRAL.FRM
ART\CRITTERS\HANPWRAN.FRM
ART\CRITTERS\HANPWRAO.FRM
ART\CRITTERS\HANPWRAP.FRM
ART\CRITTERS\HANPWRAQ.FRM
ART\CRITTERS\HANPWRAR.FRM
ART\CRITTERS\HANPWRAS.FRM
ART\CRITTERS\HANPWRAT.FRM
ART\CRITTERS\HANPWRBA.FR0
ART\CRITTERS\HANPWRBA.FR1
ART\CRITTERS\HANPWRBA.FR2
ART\CRITTERS\HANPWRBA.FR3
ART\CRITTERS\HANPWRBA.FR4
ART\CRITTERS\HANPWRBA.FR5
ART\CRITTERS\HANPWRBB.FR0
ART\CRITTERS\HANPWRBB.FR1
ART\CRITTERS\HANPWRBB.FR2
ART\CRITTERS\HANPWRBB.FR3
ART\CRITTERS\HANPWRBB.FR4
ART\CRITTERS\HANPWRBB.FR5
ART\CRITTERS\HANPWRBD.FR0
ART\CRITTERS\HANPWRBD.FR1
ART\CRITTERS\HANPWRBD.FR2
ART\CRITTERS\HANPWRBD.FR3
ART\CRITTERS\HANPWRBD.FR4
ART\CRITTERS\HANPWRBD.FR5
ART\CRITTERS\HANPWRBG.FR0
ART\CRITTERS\HANPWRBG.FR1
ART\CRITTERS\HANPWRBG.FR2
ART\CRITTERS\HANPWRBG.FR3
ART\CRITTERS\HANPWRBG.FR4
ART\CRITTERS\HANPWRBG.FR5
ART\CRITTERS\HANPWRBI.FR0
ART\CRITTERS\HANPWRBI.FR1
ART\CRITTERS\HANPWRBI.FR2
ART\CRITTERS\HANPWRBI.FR3
ART\CRITTERS\HANPWRBI.FR4
ART\CRITTERS\HANPWRBI.FR5
ART\CRITTERS\HANPWRBL.FR0
ART\CRITTERS\HANPWRBL.FR1
ART\CRITTERS\HANPWRBL.FR2
ART\CRITTERS\HANPWRBL.FR3
ART\CRITTERS\HANPWRBL.FR4
ART\CRITTERS\HANPWRBL.FR5
ART\CRITTERS\HANPWRBM.FR0
ART\CRITTERS\HANPWRBM.FR1
ART\CRITTERS\HANPWRBM.FR2
ART\CRITTERS\HANPWRBM.FR3
ART\CRITTERS\HANPWRBM.FR4
ART\CRITTERS\HANPWRBM.FR5
ART\CRITTERS\HANPWRBO.FR0
ART\CRITTERS\HANPWRBO.FR1
ART\CRITTERS\HANPWRBO.FR2
ART\CRITTERS\HANPWRBO.FR3
ART\CRITTERS\HANPWRBO.FR4
ART\CRITTERS\HANPWRBO.FR5
ART\CRITTERS\HANPWRBP.FR0
ART\CRITTERS\HANPWRBP.FR1
ART\CRITTERS\HANPWRBP.FR2
ART\CRITTERS\HANPWRBP.FR3
ART\CRITTERS\HANPWRBP.FR4
ART\CRITTERS\HANPWRBP.FR5
ART\CRITTERS\HANPWRCH.FRM
ART\CRITTERS\HANPWRCJ.FRM
ART\CRITTERS\HANPWRDA.FRM
ART\CRITTERS\HANPWRDB.FRM
ART\CRITTERS\HANPWRDC.FRM
ART\CRITTERS\HANPWRDD.FRM
ART\CRITTERS\HANPWRDE.FRM
ART\CRITTERS\HANPWRDF.FRM
ART\CRITTERS\HANPWRDG.FRM
ART\CRITTERS\HANPWRDM.FRM
ART\CRITTERS\HANPWREA.FRM
ART\CRITTERS\HANPWREB.FRM
ART\CRITTERS\HANPWREC.FRM
ART\CRITTERS\HANPWRED.FRM
ART\CRITTERS\HANPWREE.FRM
ART\CRITTERS\HANPWREF.FRM
ART\CRITTERS\HANPWREG.FRM
ART\CRITTERS\HANPWRFA.FRM
ART\CRITTERS\HANPWRFB.FRM
ART\CRITTERS\HANPWRFC.FRM
ART\CRITTERS\HANPWRFD.FRM
ART\CRITTERS\HANPWRFE.FRM
ART\CRITTERS\HANPWRFF.FRM
ART\CRITTERS\HANPWRFG.FRM
ART\CRITTERS\HANPWRGA.FRM
ART\CRITTERS\HANPWRGB.FRM
ART\CRITTERS\HANPWRGC.FRM
ART\CRITTERS\HANPWRGD.FRM
ART\CRITTERS\HANPWRGE.FRM
ART\CRITTERS\HANPWRGF.FRM
ART\CRITTERS\HANPWRGM.FRM
ART\CRITTERS\HANPWRHA.FRM
ART\CRITTERS\HANPWRHB.FRM
ART\CRITTERS\HANPWRHC.FRM
ART\CRITTERS\HANPWRHD.FRM
ART\CRITTERS\HANPWRHE.FRM
ART\CRITTERS\HANPWRHH.FRM
ART\CRITTERS\HANPWRHI.FRM
ART\CRITTERS\HANPWRHJ.FRM
ART\CRITTERS\HANPWRIA.FRM
ART\CRITTERS\HANPWRIB.FRM
ART\CRITTERS\HANPWRIC.FRM
ART\CRITTERS\HANPWRID.FRM
ART\CRITTERS\HANPWRIE.FRM
ART\CRITTERS\HANPWRIH.FRM
ART\CRITTERS\HANPWRII.FRM
ART\CRITTERS\HANPWRIJ.FRM
ART\CRITTERS\HANPWRIK.FRM
ART\CRITTERS\HANPWRJA.FRM
ART\CRITTERS\HANPWRJB.FRM
ART\CRITTERS\HANPWRJC.FRM
ART\CRITTERS\HANPWRJD.FRM
ART\CRITTERS\HANPWRJE.FRM
ART\CRITTERS\HANPWRJH.FRM
ART\CRITTERS\HANPWRJI.FRM
ART\CRITTERS\HANPWRJJ.FRM
ART\CRITTERS\HANPWRJK.FRM
ART\CRITTERS\HANPWRKA.FRM
ART\CRITTERS\HANPWRKB.FRM
ART\CRITTERS\HANPWRKC.FRM
ART\CRITTERS\HANPWRKD.FRM
ART\CRITTERS\HANPWRKE.FRM
ART\CRITTERS\HANPWRKH.FRM
ART\CRITTERS\HANPWRKI.FRM
ART\CRITTERS\HANPWRKJ.FRM
ART\CRITTERS\HANPWRKK.FRM
ART\CRITTERS\HANPWRKL.FRM
ART\CRITTERS\HANPWRLA.FRM
ART\CRITTERS\HANPWRLB.FRM
ART\CRITTERS\HANPWRLC.FRM
ART\CRITTERS\HANPWRLD.FRM
ART\CRITTERS\HANPWRLE.FRM
ART\CRITTERS\HANPWRLH.FRM
ART\CRITTERS\HANPWRLI.FRM
ART\CRITTERS\HANPWRLK.FRM
ART\CRITTERS\HANPWRMA.FRM
ART\CRITTERS\HANPWRMB.FRM
ART\CRITTERS\HANPWRMC.FRM
ART\CRITTERS\HANPWRMD.FRM
ART\CRITTERS\HANPWRME.FRM
ART\CRITTERS\HANPWRMH.FRM
ART\CRITTERS\HANPWRMI.FRM
ART\CRITTERS\HANPWRMJ.FRM
ART\CRITTERS\HANPWRRA.FRM
ART\CRITTERS\HANPWRRB.FRM
ART\CRITTERS\HANPWRRD.FRM
ART\CRITTERS\HANPWRRF.FRM
ART\CRITTERS\HANPWRRG.FRM
ART\CRITTERS\HANPWRRI.FRM
ART\CRITTERS\HANPWRRL.FRM
ART\CRITTERS\HANPWRRM.FRM
ART\CRITTERS\HANPWRRO.FRM
ART\CRITTERS\HANPWRRP.FRM
ART\CRITTERS\HAPOWRBE.FR0
ART\CRITTERS\HAPOWRBE.FR1
ART\CRITTERS\HAPOWRBE.FR2
ART\CRITTERS\HAPOWRBE.FR3
ART\CRITTERS\HAPOWRBE.FR4
ART\CRITTERS\HAPOWRBE.FR5
ART\CRITTERS\HAPOWRBH.FR0
ART\CRITTERS\HAPOWRBH.FR1
ART\CRITTERS\HAPOWRBH.FR2
ART\CRITTERS\HAPOWRBH.FR3
ART\CRITTERS\HAPOWRBH.FR4
ART\CRITTERS\HAPOWRBH.FR5
ART\CRITTERS\HAPOWRBJ.FR0
ART\CRITTERS\HAPOWRBJ.FR1
ART\CRITTERS\HAPOWRBJ.FR2
ART\CRITTERS\HAPOWRBJ.FR3
ART\CRITTERS\HAPOWRBJ.FR4
ART\CRITTERS\HAPOWRBJ.FR5
ART\CRITTERS\HAPOWRBK.FR0
ART\CRITTERS\HAPOWRBK.FR1
ART\CRITTERS\HAPOWRBK.FR2
ART\CRITTERS\HAPOWRBK.FR3
ART\CRITTERS\HAPOWRBK.FR4
ART\CRITTERS\HAPOWRBK.FR5
ART\CRITTERS\HAPOWRBN.FRM
ART\CRITTERS\HAPOWRRE.FRM
ART\CRITTERS\HAPOWRRH.FRM
ART\CRITTERS\HAPOWRRJ.FRM
ART\CRITTERS\HAPOWRRK.FRM
ART\CRITTERS\NACHLDAA.FRM
ART\CRITTERS\NACHLDAB.FRM
ART\CRITTERS\NACHLDAK.FRM
ART\CRITTERS\NACHLDAL.FRM
ART\CRITTERS\NACHLDAN.FRM
ART\CRITTERS\NACHLDAO.FRM
ART\CRITTERS\NACHLDAP.FRM
ART\CRITTERS\NACHLDAQ.FRM
ART\CRITTERS\NACHLDAR.FRM
ART\CRITTERS\NACHLDAS.FRM
ART\CRITTERS\NACHLDAT.FRM
ART\CRITTERS\NACHLDBA.FR0
ART\CRITTERS\NACHLDBA.FR1
ART\CRITTERS\NACHLDBA.FR2
ART\CRITTERS\NACHLDBA.FR3
ART\CRITTERS\NACHLDBA.FR4
ART\CRITTERS\NACHLDBA.FR5
ART\CRITTERS\NACHLDBB.FR0
ART\CRITTERS\NACHLDBB.FR1
ART\CRITTERS\NACHLDBB.FR2
ART\CRITTERS\NACHLDBB.FR3
ART\CRITTERS\NACHLDBB.FR4
ART\CRITTERS\NACHLDBB.FR5
ART\CRITTERS\NACHLDBD.FR0
ART\CRITTERS\NACHLDBD.FR1
ART\CRITTERS\NACHLDBD.FR2
ART\CRITTERS\NACHLDBD.FR3
ART\CRITTERS\NACHLDBD.FR4
ART\CRITTERS\NACHLDBD.FR5
ART\CRITTERS\NACHLDBF.FR0
ART\CRITTERS\NACHLDBF.FR1
ART\CRITTERS\NACHLDBF.FR2
ART\CRITTERS\NACHLDBF.FR3
ART\CRITTERS\NACHLDBF.FR4
ART\CRITTERS\NACHLDBF.FR5
ART\CRITTERS\NACHLDBG.FR0
ART\CRITTERS\NACHLDBG.FR1
ART\CRITTERS\NACHLDBG.FR2
ART\CRITTERS\NACHLDBG.FR3
ART\CRITTERS\NACHLDBG.FR4
ART\CRITTERS\NACHLDBG.FR5
ART\CRITTERS\NACHLDBH.FR0
ART\CRITTERS\NACHLDBH.FR1
ART\CRITTERS\NACHLDBH.FR2
ART\CRITTERS\NACHLDBH.FR3
ART\CRITTERS\NACHLDBH.FR4
ART\CRITTERS\NACHLDBH.FR5
ART\CRITTERS\NACHLDBI.FR0
ART\CRITTERS\NACHLDBI.FR1
ART\CRITTERS\NACHLDBI.FR2
ART\CRITTERS\NACHLDBI.FR3
ART\CRITTERS\NACHLDBI.FR4
ART\CRITTERS\NACHLDBI.FR5
ART\CRITTERS\NACHLDBJ.FR0
ART\CRITTERS\NACHLDBJ.FR1
ART\CRITTERS\NACHLDBJ.FR2
ART\CRITTERS\NACHLDBJ.FR3
ART\CRITTERS\NACHLDBJ.FR4
ART\CRITTERS\NACHLDBJ.FR5
ART\CRITTERS\NACHLDBK.FR0
ART\CRITTERS\NACHLDBK.FR1
ART\CRITTERS\NACHLDBK.FR2
ART\CRITTERS\NACHLDBK.FR3
ART\CRITTERS\NACHLDBK.FR4
ART\CRITTERS\NACHLDBK.FR5
ART\CRITTERS\NACHLDBL.FR0
ART\CRITTERS\NACHLDBL.FR1
ART\CRITTERS\NACHLDBL.FR2
ART\CRITTERS\NACHLDBL.FR3
ART\CRITTERS\NACHLDBL.FR4
ART\CRITTERS\NACHLDBL.FR5
ART\CRITTERS\NACHLDBM.FR0
ART\CRITTERS\NACHLDBM.FR1
ART\CRITTERS\NACHLDBM.FR2
ART\CRITTERS\NACHLDBM.FR3
ART\CRITTERS\NACHLDBM.FR4
ART\CRITTERS\NACHLDBM.FR5
ART\CRITTERS\NACHLDBO.FR0
ART\CRITTERS\NACHLDBO.FR1
ART\CRITTERS\NACHLDBO.FR2
ART\CRITTERS\NACHLDBO.FR3
ART\CRITTERS\NACHLDBO.FR4
ART\CRITTERS\NACHLDBO.FR5
ART\CRITTERS\NACHLDBP.FR0
ART\CRITTERS\NACHLDBP.FR1
ART\CRITTERS\NACHLDBP.FR2
ART\CRITTERS\NACHLDBP.FR3
ART\CRITTERS\NACHLDBP.FR4
ART\CRITTERS\NACHLDBP.FR5
ART\CRITTERS\NACHLDCH.FRM
ART\CRITTERS\NACHLDCJ.FRM
ART\CRITTERS\NACHLDRA.FRM
ART\CRITTERS\NACHLDRB.FRM
ART\CRITTERS\NACHLDRD.FRM
ART\CRITTERS\NACHLDRF.FRM
ART\CRITTERS\NACHLDRG.FRM
ART\CRITTERS\NACHLDRI.FRM
ART\CRITTERS\NACHLDRL.FRM
ART\CRITTERS\NACHLDRM.FRM
ART\CRITTERS\NACHLDRO.FRM
ART\CRITTERS\NACHLDRP.FRM
```

## Deep dive — filenames & extensions (detailed) 🔬

**Quick finding:** The patched output promotes many loose assets into `master.dat`/`critter.dat` and also introduces a lot of case-only renames and new files (scripts, protos, map metadata). This changes how the engine finds assets: patch lookup (filesystem) is case-sensitive on some systems while DAT lookup is case-insensitive — that mismatch explains many of the "not drop-in" failures.

### How the engine looks up files (short)
- Order: 1) patches directory (loose file at `master_patches` / `critter_patches`), 2) fallback to DAT (`master.dat` / `critter.dat`).
- Patches: the code attempts to open the exact path on disk (so **case matters on case-sensitive filesystems**). A hash table (built from basenames) is used as a presence hint, but it only hashes basenames (risk: false positives if same basename exists elsewhere).
- DATs: path is normalized (slashes/backslashes) and uppercased; DAT lookup is effectively **case-insensitive** (assoc search uses case-insensitive compare). This makes DAT a safer fallback for case/name mismatches.

### Per-extension analysis (what they are, engine expectations, patch vs unpatched)
- .PRO — Prototypes (items, critters) ✅
  - Role: Fixed-data descriptors used by the game to define prototypes.
  - Engine: Read at startup/when requested; names stored in DAT index (backslash-separated, case-insensitive).
  - Diff: **92** `.PRO` files were added into `master.dat` (promoted by RME). Examples: `PROTO/CRITTERS/00000313.PRO` ... `00000402.PRO`.
  - Impact: New/changed prototypes can change gameplay (new critters/items) and explain why simply overlaying `data/` without DAT replacements doesn't reproduce patched behavior.

- .FRM / .FR0..FR5 — Art frames & chunked animation files ✅
  - Role: Sprites / UI images / critter animations. Chunked frames (.FR0..FR5) are used for large animations.
  - Engine: Loaded via `art_ptr_lock` → DB open (tries patch then DAT). Rendering functions read the Art structures.
  - Diff: **~289** files promoted into `critter.dat` (lots of `ART/CRITTERS/HANPWR*` and multi-part `.FR0`..`.FR5`). Master got a few FRM additions too.
  - Impact: Missing/renamed FRM files cause UI or animation breakage; DAT inclusion in patched mitigates runtime misses where loose patch files differ in case.

- .LST — Asset lists (e.g., `intrface.lst`) ✅
  - Role: Lists of filenames used by code (UI lists, script lists). Parsed by engines/tools; RME provides new lists.
  - Diff: `ART/INTRFACE/INTRFACE.LST` appears in patched data; `scripts.lst` expanded massively in patched.
  - Impact: Mismatches inside .LST (e.g., case or missing items) lead to missing assets at runtime; `rme-lst-report.md` lists unresolved entries.

- .INT — Compiled scripts (game behavior) ✅
  - Role: Map & NPC scripts that control game logic.
  - Engine: Opened as binary via DB; interpreter runs opcodes (see `src/int/`).
  - Diff: Many `.INT` files differ (patched includes updated scripts/fixes). This is a gameplay-level change (not a pure asset rename).

- .MAP / .GAM — Maps & map-global variables ✅
  - .MAP = binary map used by engine; .GAM = textual map global variable definitions (RME adds many `.gam` files).
  - Endianness: rme-crossref flagged **9** maps as `map_endian=big`. Engine map reader uses db_freadInt* (big-endian interpretation expected). If a map were little-endian the map loader would produce wrong values/garbage.
  - Diff: Patched includes many `.map` binaries and newly added `.gam` metadata files for map globals.
  - Impact: Always verify map header endianness; RME maps are big-endian (compatible) but mixing endianness across sources is risky.

- .MSG / .TXT — Text / message files ✅
  - Role: UI/game messages. Engine opens them as text (`mode="rt"` in logs).
  - Diff: Patched has added/changed `.MSG` files (localization and script text updates).

- .ACM — Sound/music files ✅
  - Role: Background music / SFX (engine loads `.ACM` via `gsound`).
  - Diff: Some `.ACM` files were added or moved into DAT (e.g., `WAE1XXX2.ACM`).

- .AAF — Fonts (patch added `font3.aaf`, `font4.aaf`) ✅
  - Role: Font assets (patched includes extra/override fonts).

- .PAL — Palette files (e.g., `boshharry.pal`) ✅
  - Role: Color palettes for FRM images.

- .EDG — Map edge files (unchanged in bulk)
  - Role: Small metadata used along with maps; present in both sets.

### Naming & case notes (practical)
- Case-only renames found (20 pairs): e.g., `HR_ALLTLK.FRM` ⇄ `hr_alltlk.frm`, `MAINMENU.FRM` ⇄ `mainmenu.frm`, `grid000.FRM` ⇄ `grid000.frm`, and directory renames `MAPS` ⇄ `maps`, `SCRIPTS` ⇄ `scripts`.
- On macOS default (case-insensitive HFS/APFS) these lookups rarely break; on Linux or case-sensitive mac volumes they will — unless DAT fallback is present.
- The engine does: try patch file (exact filesystem case), else DAT (case-insensitive), so if you replace loose `data/` only and not DATs, a case change can cause missing assets on case-sensitive systems.

### Key runtime risks & recommendations ✅
- Risk: **Drop-in fails** if you expect to only swap `data/`. Patched output changes DATs and adds many assets into DATs — so a true drop-in requires replacing both `data/` and the DATs or building a data-only overlay that maps exactly to expected names/cases.
- Risk: **Case mismatches** on case-sensitive FS (validate by running the game on a case-sensitive volume or CI job to catch missing assets).
- Risk: **LST mismatches** — run `scripts/patch/rme-crossref.py` to find unresolved LST references and fix names or add assets.
- Risk: **Map endianness** — verify `rme-crossref` map reports (9 maps flagged big-endian; confirm those remain consistent).

### Useful checks & commands
- Validate RME overlay and DAT xdelta: 
  ./scripts/patch/rebirth-validate-data.sh --patched GOG/patchedfiles --base GOG/unpatchedfiles --rme third_party/rme/source
- Cross-reference RME payload vs DATs: 
  python3 scripts/patch/rme-crossref.py --base-dir GOG/unpatchedfiles --rme-dir third_party/rme/source --out-dir GOG/rme_xref_unpatched
- Check case-only renames: `GOG/case_renames.txt`
- Lists of promoted files (already generated): `GOG/master_added_files.txt` (114 entries), `GOG/critter_added_files.txt` (289 entries).

---

If you'd like, I can now:
- also add a concise CSV mapping (`path,ext,added_to`) summarizing all promoted files, or
- generate a **data-only overlay** (patch script that copies only `data/` files and leaves DATs alone) so you can test drop-in behavior, or
- run a small case-sensitive test (create a case-sensitive test container and run the validation command to reproduce missing file failures).

Tell me which next step you'd like. 🔧


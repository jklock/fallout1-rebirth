# RME Game Data Todo (Patch-in-Place)

## Goal
Produce a deterministic patch process that takes clean Fallout 1 data and outputs a fully RME-patched folder ready for app install.

## Tasks
1. Add third-party payload location:
   - `third_party/rme/source/` (RME payload)
   - `third_party/rme/manifest.json`
   - `third_party/rme/checksums.txt`
2. Generate a full RME cross-reference mapping against base DATs:
   - Output: `development/RME/summary/rme-crossref.csv`
   - Output: `development/RME/summary/rme-crossref.md`
   - Output: `development/RME/summary/rme-lst-report.md`
   - Script: `scripts/patch/rme-crossref.py`
3. Review crossref results and identify hard blockers:
   - MAP header endian anomalies
   - Files that are new vs. override
   - Any missing or malformed data categories
4. Create `third_party/rme/README.md` with:
   - RME version info
   - expected input DAT versions
5. Generate checksum list:
   - Base `master.dat` and `critter.dat` (pre-patch)
   - RME payload files
6. Define manifest fields:
   - file count
   - required top-level folders
   - version string
7. Validate that RME content is NPC Mod 3.5 + Fix (No Armor excluded).
8. Ensure patch output layout matches:
   - `master.dat`, `critter.dat`, `data/`, `fallout.cfg`, `f1_res.ini`
9. Add data-level validation gates based on crossref:
   - MAP header sanity check (version = 19 in engine read format)
   - LST heuristic report (do not fail build, but warn)
   - New file count + directory distribution matches mapping
## Done Criteria
- RME payload stored in `third_party/rme/source/`.
- Checksums and manifest are present and referenced by scripts.
- Patch output structure matches the plan.
- Cross-reference mapping generated and reviewed.

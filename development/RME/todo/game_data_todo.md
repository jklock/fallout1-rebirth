# RME Game Data Todo (Patch-in-Place)

## Goal
Produce a deterministic patch process that takes clean Fallout 1 data and outputs a fully RME-patched folder ready for app install.

## Tasks
1. Add third-party payload location:
   - `third_party/rme/source/` (RME payload)
   - `third_party/rme/manifest.json`
   - `third_party/rme/checksums.txt`
2. Create `third_party/rme/README.md` with:
   - RME version info
   - expected input DAT versions
3. Generate checksum list:
   - Base `master.dat` and `critter.dat` (pre-patch)
   - RME payload files
4. Define manifest fields:
   - file count
   - required top-level folders
   - version string
5. Validate that RME content is NPC Mod 3.5 + Fix (No Armor excluded).
6. Ensure patch output layout matches:
   - `master.dat`, `critter.dat`, `data/`, `fallout.cfg`, `f1_res.ini`

## Done Criteria
- RME payload stored in `third_party/rme/source/`.
- Checksums and manifest are present and referenced by scripts.
- Patch output structure matches the plan.

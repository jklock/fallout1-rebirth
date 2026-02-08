# RME Engine Todo (Backend)

## Goal
Confirm the engine requires no code changes for in-place patched data and that config defaults match the plan.

## Tasks
1. Confirm working directory resolution on macOS:
   - Verify the engine checks:
     - `/Applications/Fallout 1 Rebirth.app/Contents/MacOS/`
     - `/Applications/Fallout 1 Rebirth.app/Contents/Resources/`
     - `/Applications/` (parent of the app)
   - File: `src/plib/gnw/winmain.cc`
2. Confirm iOS working directory is Documents:
   - File: `src/plib/gnw/winmain.cc`
3. Verify config defaults in `gconfig.cc`:
   - `master_patches=data`
   - `critter_patches=data`
4. Verify config templates:
   - `gameconfig/macos/fallout.cfg`
   - `gameconfig/ios/fallout.cfg`
5. Document the exact data install paths in docs (if not already):
   - macOS: `/Applications/Fallout 1 Rebirth.app/Contents/Resources/`
   - iOS: `Files > Fallout 1 Rebirth > Documents/`

## Done Criteria
- All checks above confirmed and noted in summary.
- No engine code changes required.

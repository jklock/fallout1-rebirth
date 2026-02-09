# Patch Coverage Test Plan (RME)

## Goal
Provide end-to-end, repeatable testing coverage for all patched files by combining static evidence regeneration, data validation, script/LST integrity checks, and runtime map loading with screenshots.

## Full Coverage Pipeline (Ordered)
1. Build the macOS app bundle.
   - Command: `./scripts/build/build-macos.sh`
   - Purpose: ensures runtime harness and logging changes are compiled.

2. (Optional) Rebuild patched data from base + RME payload.
   - Command: `./scripts/patch/rebirth-patch-data.sh --base <unpatched> --out <patched> --config-dir gameconfig/macos --rme third_party/rme/source`
   - Purpose: regenerates `GOG/patchedfiles` to match current patch logic.

3. Regenerate validation evidence (diffs, checksums, LST reports, crossrefs).
   - Command: `./scripts/patch/rebirth-refresh-validation.sh --unpatched <unpatched> --patched <patched> --rme third_party/rme/source --out development/RME/validation`
   - Purpose: updates canonical validation artifacts and coverage evidence.

4. Audit script references against shipped MAP/PRO content.
   - Command: `python3 scripts/patch/rme-audit-script-refs.py --patched-dir <patched> --out-dir development/RME/validation/raw`
   - Purpose: ensures scripts referenced by MAP/PRO content exist in DATs or overlay.

5. Validate patched data overlay (RME payload integrity + DAT patch correctness).
   - Command: `./scripts/patch/rebirth-validate-data.sh --patched <patched> --base <unpatched> --rme third_party/rme/source`
   - Purpose: verifies all RME payload files exist and match expected checksums.

6. Install patched data into the app bundle.
   - Command: `./scripts/test/test-install-game-data.sh --source <patched> --target <app bundle>`
   - Purpose: ensures app bundle contains patched data for runtime tests.

7. Run macOS headless smoke test.
   - Command: `./scripts/test/test-macos-headless.sh`
   - Purpose: quick runtime sanity check (3s launch).

8. Runtime map sweep (autorun map load + autoscreenshot + black-map heuristic).
   - Command: `python3 scripts/patch/rme-runtime-sweep.py --exe <app exe> --out-dir development/RME/validation/runtime --timeout 60`
   - Purpose: loads all maps, flags timeouts, and detects black-screen failures.

## Optional Platform Coverage
9. Patch IPA payload (iOS packaging).
   - Command: `./scripts/patch/rebirth-patch-ipa.sh --base <unpatched> --out <patched> --rme third_party/rme/source`

10. iOS headless + simulator tests.
   - Commands: `./scripts/test/test-ios-headless.sh`, `./scripts/test/test-ios-simulator.sh`

## One-Command Runner
Use this script to run everything above in sequence:
- Script: `scripts/patch/rme-full-coverage.sh`
- Defaults: `GOG/unpatchedfiles`, `GOG/patchedfiles`, `third_party/rme/source`, `development/RME/validation`, `TIMEOUT=60`.
- Optional env flags:
  - `REBUILD_PATCHED=1` to rebuild `GOG/patchedfiles`.
  - `FORCE_PATCH=1` to overwrite output when rebuilding.
  - `SKIP_CHECKSUMS=1` to skip base DAT checks during rebuild.
  - `RUN_IOS=1` to run iOS tests.
  - `RUN_IPA_PATCH=1` to patch IPA payload.

# Subagent orchestration prompt — Infrastructure (Gate‑1)

Subagent prompt (EXACT — pass this to the infra subagent):

"Run the non-interactive Infrastructure validation for RME. Steps (run from repo root):

1) Build macOS app (non-interactive):
   - ./scripts/build/build-macos.sh
   - Save stdout/stderr to `development/RME/ARTIFACTS/evidence/gate-1/gate-1-build-log.txt`.

2) Create patched data (non-interactive):
   - ./scripts/patch/rebirth-patch-app.sh --base GOG/unpatchedfiles --out GOG/patchedfiles --force
   - Save output to `development/RME/ARTIFACTS/evidence/gate-1/gate-1-patch-log.txt`.

3) Install patched game data into app Resources:
   - ./scripts/test/test-install-game-data.sh
   - Save output to `development/RME/ARTIFACTS/evidence/gate-1/gate-1-install-log.txt`.

4) Static validation:
   - ./scripts/patch/rebirth-validate-data.sh --patched GOG/patchedfiles --base GOG/unpatchedfiles
   - Save output to `development/RME/ARTIFACTS/evidence/gate-1/gate-1-validate-output.txt`.

5) Non-interactive engine selftest (RME_SELFTEST):
   - export RME_WORKING_DIR="build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/Resources"
   - export RME_SELFTEST=1
   - "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth"
   - Save produced `rme-selftest.json` to `development/RME/ARTIFACTS/evidence/gate-1/rme-selftest.json` and stdout/stderr to `gate-1-selftest-log.txt`.

Return JSON (exact schema):
{
  "build_ok": true|false,
  "patch_ok": true|false,
  "install_ok": true|false,
  "static_validate_ok": true|false,
  "selftest_ok": true|false,
  "artifacts": [ "paths..." ],
  "errors": [ "text..." ]
}

Fail behavior: if any required binary or `GOG/unpatchedfiles/master.dat` is missing, return `build_ok=false` with `errors` containing the diagnostic outputs. Do not modify git history."
# Subagent: Infrastructure — automated build, patch, install, static validation

Purpose
- Fully automated, non-interactive validation of the build + patched data pipeline. Produces canonical evidence for Gate‑1.

Non-interactive commands (exact)
- Build macOS:
  - ./scripts/build/build-macos.sh
- Generate patched game data:
  - ./scripts/patch/rebirth-patch-app.sh --base GOG/unpatchedfiles --out GOG/patchedfiles --force
- Install patched data into app bundle (copy DATs + overlay into app Resources):
  - ./scripts/test/test-install-game-data.sh
- Static validation:
  - ./scripts/patch/rebirth-validate-data.sh --patched GOG/patchedfiles --base GOG/unpatchedfiles
- Quick executable selftest (non-interactive):
  - export RME_WORKING_DIR="build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/Resources"
  - export RME_SELFTEST=1
  - "$PWD/build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth"

Where outputs land (evidence)
- development/RME/ARTIFACTS/evidence/gate-1/
  - gate-1-validate-output.txt
  - gate-1-install-log.txt
  - rme-selftest.json (created by RME_SELFTEST run)

Acceptance criteria (pass/fail)
- build-macos.sh exits 0 and binary exists at `build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth`.
- rebirth-patch-app.sh exits 0 and `GOG/patchedfiles/master.dat` + `critter.dat` exist.
- test-install-game-data.sh exits 0 and patched DATs + data/ overlay are present under the app Resources.
- rebirth-validate-data.sh exits 0 (no ERROR lines).
- RME_SELFTEST run exits 0 and writes `rme-selftest.json` with an empty `failures` array.

Estimated runtime: 15–45 minutes (machine dependent)

Subagent prompt (use this EXACT prompt when launching a subagent to run the infra tasks)

"Run the full non-interactive infrastructure validation for RME. Steps:
1) Run `./scripts/build/build-macos.sh` and capture stdout/stderr.
2) Run `./scripts/patch/rebirth-patch-app.sh --base GOG/unpatchedfiles --out GOG/patchedfiles --force`.
3) Run `./scripts/test/test-install-game-data.sh` to copy patched data into the built app Resources.
4) Run `./scripts/patch/rebirth-validate-data.sh --patched GOG/patchedfiles --base GOG/unpatchedfiles`.
5) Set `RME_WORKING_DIR=build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/Resources` and `RME_SELFTEST=1` then run the executable; save `rme-selftest.json` that the engine produces.\
Return a JSON summary with keys: `build_ok` (bool), `patch_ok` (bool), `install_ok` (bool), `static_validate_ok` (bool), `selftest_ok` (bool), `artifacts` (paths to generated logs/files), and include the last 200 lines of each run log. If any step fails, include exact stderr and the git status. Do not prompt the user during execution—terminate with nonzero exit and include logs."
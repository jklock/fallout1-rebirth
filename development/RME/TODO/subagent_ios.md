# Subagent: iOS — non-interactive simulator build, install, and smoke test

Purpose
- Fully automated iOS simulator test: build for simulator, install app, copy patched game data into app container, launch and perform short automated smoke checks.

Non-interactive commands (exact)
- Build & install (non-interactive):
  - export GAME_DATA="GOG/patchedfiles"  # MUST point to patched files
  - ./scripts/test/test-ios-simulator.sh --build-only
  - ./scripts/test/test-ios-simulator.sh --launch
- Headless workflow (build-only + copy data + launch) is supported by the script; `GAME_DATA` will be copied into the app data container.

Notes / Requirements
- Xcode + simulator runtimes installed on the host machine.
- The script is non-interactive when run with `--build-only` and `--launch`.
- SIMULATOR_NAME can be overridden using env var (default iPad Pro 13-inch (M5)).

Evidence to collect
- `development/RME/ARTIFACTS/evidence/gate-4/`:
  - build log, install log, simulator launch log, and screenshots

Acceptance criteria
- `test-ios-simulator.sh --build-only` completes with exit 0 and produces an app bundle under `build-ios-sim/`.
- `test-ios-simulator.sh --launch` installs the app, copies `GAME_DATA`, launches the app, and the simulator shows the app running.
- Minimal smoke: app launches, main menu visible (screenshot saved).

Subagent prompt (use this EXACT prompt when launching a subagent to run iOS tasks)

"Run a fully automated iOS simulator validation. Steps:
1) Ensure `GOG/patchedfiles` exists and contains `master.dat` + `critter.dat` + `data/`.
2) Set `GAME_DATA=GOG/patchedfiles` and run `./scripts/test/test-ios-simulator.sh --build-only`.
3) If build succeeds, run `./scripts/test/test-ios-simulator.sh --launch` (use default `SIMULATOR_NAME` unless overridden).
4) Wait for simulator to be ready and capture at least one screenshot of the app main menu.

Return a JSON summary: `build_ok` (bool), `install_ok` (bool), `launched` (bool), `screenshot_path` (if produced), and `artifacts` (paths to logs). If simulator is unavailable, return `skipped=true` with diagnostic messages."
# Subagent orchestration prompt — iOS simulator (Gate‑4)

Subagent prompt (EXACT — pass this to the iOS subagent):

"Run the automated iOS simulator validation (non-interactive). Steps:

Prereq: Xcode + simulator runtimes installed and `GOG/patchedfiles` populated with `master.dat` + `critter.dat` + `data/`.

1) Build for simulator (non-interactive):
   - export GAME_DATA="GOG/patchedfiles"
   - ./scripts/test/test-ios-simulator.sh --build-only
   - Save build log to `development/RME/ARTIFACTS/evidence/gate-4/build-log.txt`.

2) Install + copy data + launch (non-interactive):
   - export GAME_DATA="GOG/patchedfiles"
   - ./scripts/test/test-ios-simulator.sh --launch
   - Save simulator install logs and any screenshot to `development/RME/ARTIFACTS/evidence/gate-4/`.

Return JSON (exact schema):
{
  "build_ok": true|false,
  "install_ok": true|false,
  "launched": true|false,
  "screenshot": "path-or-null",
  "artifacts": ["paths..."],
  "errors": ["text..."]
}

Failure handling:
- If simulator runtime not available, return `skipped=true` with diagnostic messages.
- If app fails to install or launch, include `xcrun simctl` error output.

Do not interactively accept dialogs in simulator; only build, install, copy data, launch, and capture evidence."
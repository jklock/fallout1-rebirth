# scripts/build

Last updated (UTC): 2026-02-14

Build entrypoints.

## Files
- `build-macos.sh`: Single macOS build entrypoint (`-test` or `-prod`).
- `build-ios.sh`: Single iOS build entrypoint (`-test` or `-prod`), supports device/simulator/both targets.
- `install-game-data.sh`: Install patched game data into an existing macOS app bundle.

## Inputs
- Source tree in this repo.
- Xcode/SDK toolchains.
- For RME validation steps, set `GAME_DATA` or `FALLOUT_GAMEFILES_ROOT`.
- Optional build mode file: `.f1r-build.env` (auto-sourced by build scripts).

## Outputs
- `build-*` directories.
- `build-outputs/iOS/*.ipa` artifacts.

## Logging Build Flag
- `F1R_DISABLE_RME_LOGGING=1` compiles out Rebirth diagnostic logging hooks.
- Set this via env or `scripts/test/test-rebirth-toggle-logging.sh`.

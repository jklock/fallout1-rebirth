# scripts/build

Last updated (UTC): 2026-02-14

Build and packaging entrypoints.

## Files
- `build-macos.sh`: Build macOS app bundle.
- `build-macos-dmg.sh`: Package macOS DMG.
- `build-ios.sh`: Build iOS app.
- `build-ios-ipa.sh`: Package iOS IPA.
- `build-releases.sh`: End-to-end local release build flow.

## Inputs
- Source tree in this repo.
- Xcode/SDK toolchains.
- For RME validation steps, set `GAME_DATA` or `FALLOUT_GAMEFILES_ROOT`.
- Optional build mode file: `.f1r-build.env` (auto-sourced by build scripts).

## Outputs
- `build-*` directories.
- `build-outputs/` artifacts.
- `releases/` copied release artifacts.

## Logging Build Flag
- `F1R_DISABLE_RME_LOGGING=1` compiles out Rebirth diagnostic logging hooks.
- Set this via env or `scripts/patch/rebirth-toggle-logging.sh`.

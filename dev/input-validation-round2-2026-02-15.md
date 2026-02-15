# Input Validation Round 2 - 2026-02-15

## Scope
- Deterministic SDL3 input translation validation for:
- macOS mouse/trackpad path.
- iOS/iPadOS touch-to-mouse semantics (single-finger left, two-finger right, Pencil left-only).

## Commands Run
```bash
scripts/test/test-input-layer.sh
GAME_DATA=/Volumes/Storage/GitHub/fallout1-rebirth-gamefiles/patchedfiles scripts/test/test-macos-headless.sh
GAME_DATA=/Volumes/Storage/GitHub/fallout1-rebirth-gamefiles/patchedfiles scripts/test/test-ios-headless.sh
```

## Results
- `input_layer_tests`: PASS
- `test-macos-headless.sh`: PASS
- `test-ios-headless.sh`: PASS (includes scripted touch autotest markers, archived patchlog, and screenshot capture)

## Evidence
- `dev/state/latest-summary.tsv`
- `dev/state/history.tsv`
- `dev/state/logs/round-2-input-input_layer-rerun.log`
- `dev/state/logs/round-2-input-macos_headless-rerun.log`
- `dev/state/logs/round-2-input-ios_headless-rerun.log`
- `dev/state/logs/screens/ios-headless-com-fallout1rebirth-game-20260215T204510Z.png`
- `dev/state/logs/ios-touch-autotest-20260215T204516Z.patchlog.txt`

## Notes
- Round 2 represents current automated proof point for input track 100%.
- Release packaging refreshed:
- `releases/prod/macOS/Fallout 1 Rebirth.app`
- `releases/prod/iOS/fallout1-rebirth.ipa`

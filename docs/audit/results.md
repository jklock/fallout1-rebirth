# Audit Results

Last updated: 2026-02-15

## Status Legend

- `PASS`: check succeeded
- `FAIL`: check failed and requires remediation
- `BLOCKED`: check could not run due to environment prerequisites
- `INFO`: informational evidence capture

## Execution Log

- `2026-02-15` `PASS` `scripts/test/test-rme-config-surface.py`
  - Baseline key manifests present in platform templates.
  - Platform defaults enforced (`macOS WINDOWED=1`, `iOS WINDOWED=0`).
- `2026-02-15` `PASS` `scripts/test/test-rme-config-compat.sh`
  - Per-key parse/apply/runtime-effect matrix passed: `61/61`.
  - Evidence artifacts:
    - `docs/audit/config-key-coverage-matrix-2026-02-15.md`
    - `tmp/rme/config-compat/coverage-matrix.tsv`
- `2026-02-15` `PASS` `scripts/test/test-rme-config-packaging.sh`
  - `gameconfig/*` and `dist/*` templates are aligned for macOS and iOS.
  - Release artifacts carry matching platform config files:
    - `releases/prod/macOS/Fallout 1 Rebirth.app`
    - `releases/prod/iOS/fallout1-rebirth.ipa`
  - Audit note: `docs/audit/config-packaging-alignment-2026-02-15.md`
- `2026-02-15` `PASS` `dev/run-unattended-until-100.sh --track both --max-rounds 1`
  - History row: `1	both	2	2	100	PASS	2026-02-15T16:03:04Z`
  - Latest summary includes:
    - `config/rme_quick: PASS`
    - `config/rme_full: PASS`
    - `config/config_compat_gate: PASS`
    - `input/macos_headless: PASS`
    - `input/ios_headless: PASS`
- `2026-02-15` `PASS` `scripts/test/test-input-layer.sh`
  - Deterministic input layer scenarios passed (gesture semantics, stale-click prevention, drag stability, mapping invariants).
  - Evidence log:
    - `dev/state/logs/round-1-input-input_layer.log`
- `2026-02-15` `PASS` `scripts/test/test-macos-headless.sh`
  - macOS mouse/trackpad execution path validated via bundle + launch checks.
  - Evidence log:
    - `dev/state/logs/round-1-input-macos_headless.log`
- `2026-02-15` `PASS` `scripts/test/test-ios-headless.sh`
  - iOS simulator launch/input-path validation passed; automated screenshot captured.
  - Evidence log:
    - `dev/state/logs/round-1-input-ios_headless.log`
  - Screenshot evidence:
    - `dev/state/logs/screens/round-1-ios_headless/ios-headless-com-fallout1rebirth-game-20260215T172516Z.png`
- `2026-02-15` `PASS` `dev/run-unattended-until-100.sh --track input`
  - History row: `1	input	1	1	100	PASS	2026-02-15T17:25:24Z`
  - Latest summary includes:
    - `input/input_layer: PASS`
    - `input/macos_headless: PASS`
    - `input/ios_headless: PASS`
- `2026-02-15` `INFO` release artifact fingerprints
  - `releases/prod/macOS/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth`
    - mtime: `2026-02-15 11:26:32`
    - sha256: `6294c3431ec9f1d3448ebd840353a266717f02056bc82fbce72a963eb3ce8192`
  - `releases/prod/iOS/fallout1-rebirth.ipa`
    - mtime: `2026-02-15 10:59:59`
    - sha256: `68c27a63ee58ad6c4385614dcc02bfd68d47505e23c8562ddab62d185e8b2f7f`

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
- `2026-02-15` `INFO` release artifact fingerprints
  - `releases/prod/macOS/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth`
    - mtime: `2026-02-15 09:46:07`
    - sha256: `8f90a81f2a8e7b31a1aaa6bf46048d1c07d65ffd195846c65f0f6bce882b9392`
  - `releases/prod/iOS/fallout1-rebirth.ipa`
    - mtime: `2026-02-15 09:48:47`
    - sha256: `d0a6eb8f354f1db5b66fb39e7c5a25a7e2ef926d67a1fde54f1307f1e87f608f`

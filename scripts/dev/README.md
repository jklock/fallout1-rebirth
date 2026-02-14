# scripts/dev

Last updated (UTC): 2026-02-14

Developer workflow and diagnostic utilities.

## Files
- `dev-clean.sh`: Remove local build artifacts.
- `dev-format.sh`: Apply/check formatting.
- `dev-check.sh`: Pre-build checks (`dev-format` + static validations, no build).
- `dev-verify.sh`: Existing build artifact verification (no build).

## Notes
- Input/output paths are configurable through script flags and/or environment variables.
- RME-specific analyzers/extractors live under `scripts/test/` as `test-rme-*`.
- Development ignore toggling now lives at `scripts/hideall.sh`.

# scripts/dev

Last updated (UTC): 2026-02-14

Developer workflow and diagnostic utilities.

## Files
- `dev-clean.sh`: Remove local build artifacts.
- `dev-format.sh`: Apply/check formatting.
- `dev-check.sh`: Fast local validation.
- `dev-verify.sh`: Full verification pipeline.
- `dev-toggle-dev-files.sh`: Toggle development-only ignore rules in `.gitignore`.

## Notes
- Input/output paths are configurable through script flags and/or environment variables.
- RME-specific analyzers/extractors live under `scripts/test/` as `test-rme-*`.
- Temp output dirs are configurable:
  - `DEV_CHECK_TMP_DIR` for `dev-check.sh`.
  - `DEV_VERIFY_IOS_TMP_DIR` for `dev-verify.sh`.

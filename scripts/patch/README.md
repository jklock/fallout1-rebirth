# scripts/patch

Last updated (UTC): 2026-02-14

Patching and patch-validation orchestration scripts.

## Files
- `rebirth-patch-data.sh`: Apply xdelta + DATA overlay into target data directory.
- `rebirth-validate-data.sh`: Validate patched output integrity.
- `rebirth-patch-app.sh`: Patch macOS app resources.
- `rebirth-patch-ipa.sh`: Patch iOS payload.
- `rebirth-refresh-validation.sh`: Generate evidence artifacts from patched/unpatched comparisons.
- `rebirth-toggle-logging.sh`: Toggle compile-time logging mode for release vs diagnostics.

## Notes
- `rebirth-refresh-validation.sh` now requires explicit `--patched/--unpatched` or `FALLOUT_GAMEFILES_ROOT`.
- Cross-reference and audit helpers are called from `scripts/test/`.
- Logging mode toggle writes `.f1r-build.env` consumed by `scripts/build/build-*.sh`.

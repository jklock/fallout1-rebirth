# scripts/patch

Last updated (UTC): 2026-02-14

Patching scripts only.

## Files
- `patch-rebirth-data.sh`: Apply xdelta + DATA overlay into target data directory.
- `patch-rebirth-app.sh`: Patch macOS-targeted payload output (uses macOS config templates).
- `patch-rebirth-ipa.sh`: Patch iOS-targeted payload output (uses iOS config templates).

## Notes
- Rebirth validation/refresh/toggle scripts were moved to `scripts/test/` because they are verification workflows, not patch-application flows.

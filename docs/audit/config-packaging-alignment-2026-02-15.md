# Config Packaging Alignment - 2026-02-15

## Scope

Validated alignment across:
- `gameconfig/macos/*`
- `gameconfig/ios/*`
- `dist/macos/*`
- `dist/ios/*`
- `releases/prod/macOS/Fallout 1 Rebirth.app`
- `releases/prod/iOS/fallout1-rebirth.ipa`

## Automated Gate

- Command: `scripts/test/test-rme-config-packaging.sh`
- Result: `PASS`
- Check types:
  - template parity (`gameconfig/*` vs `dist/*`)
  - release artifact parity (macOS app + iOS IPA config files vs platform templates)

## Artifact Evidence

- `releases/prod/macOS/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth`
  - mtime: `2026-02-15 09:46:07`
  - sha256: `8f90a81f2a8e7b31a1aaa6bf46048d1c07d65ffd195846c65f0f6bce882b9392`
- `releases/prod/iOS/fallout1-rebirth.ipa`
  - mtime: `2026-02-15 09:48:47`
  - sha256: `d0a6eb8f354f1db5b66fb39e7c5a25a7e2ef926d67a1fde54f1307f1e87f608f`

## iOS Payload Check

The production IPA now includes both platform config files:
- `Payload/fallout1-rebirth.app/fallout.cfg`
- `Payload/fallout1-rebirth.app/f1_res.ini`

Both match `gameconfig/ios/` exactly.

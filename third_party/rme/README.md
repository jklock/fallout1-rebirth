# Restoration Mod Enhanced (RME) Payload

This folder contains the RME 1.1e payload used by the patch scripts.

Last updated: 2026-02-07

## Contents

| File/Directory | Description |
|----------------|-------------|
| `source/` | Raw RME payload (DATA overrides + xdelta patches) |
| `manifest.json` | File count and expected top-level layout |
| `checksums.txt` | SHA256 checksums for payload validation |

## About RME

Restoration Mod Enhanced restores cut content, fixes bugs, and improves the original Fallout experience. This fork integrates RME 1.1e data via a patch pipeline.

## Patch Pipeline

The RME data is applied using scripts in `scripts/patch/`:

| Script | Purpose |
|--------|---------|
| `rebirth_patch_data.sh` | Patch game data files |
| `rebirth_patch_app.sh` | Patch application bundle |
| `rebirth_patch_ipa.sh` | Patch iOS IPA archive |

## Notes

- The patch scripts use `source/` as the source of truth
- Windows-only executables have been removed
- Original RME data sourced from TeamX and community contributors

## See Also

- [scripts/patch/](../../scripts/patch/) - Patch scripts
- [development/RME/](../../development/RME/) - RME integration documentation

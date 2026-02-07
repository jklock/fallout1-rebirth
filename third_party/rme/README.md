# Restoration Mod Enhanced (RME) Payload

This folder contains the RME payload used by the patch scripts.

## Contents
- `source/` - Raw RME payload (DATA overrides + xdelta patches)
- `manifest.json` - File count and expected top-level layout
- `checksums.txt` - SHA256 checksums for payload validation

## Notes
- The patch scripts use `source/` as the source of truth.
- Windows-only executables have been removed.

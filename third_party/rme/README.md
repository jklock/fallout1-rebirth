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
| `rebirth-patch-data.sh` | Patch game data files |
| `rebirth-patch-app.sh` | Patch application bundle |
| `rebirth-patch-ipa.sh` | Patch iOS IPA archive |

## Included Mods (from upstream RME readme)

- Patch 1.2 (by TeamX)
- Patch 1.2.1 (by TeamX)
- Patch 1.3.5 (by TeamX)
- NPC Mod 3.5 (by TeamX)
- NPC Mod Fix (by TeamX)
- NPC Mod No Armor (by TeamX)
- Restoration Mod 1.0b1 (by TeamX)
- Restored Good Endings 2.0 (by Sduibek)
- Dialog Fixes (by Nimrod)
- Lenore Script Fix (by Winterheart)
- Morbid Behavior Fix (by Foxx)
- Mutant Walk Fix (by Jotisz)
- Lou Animations Offset Fix (by Lexx)
- Improved Death Animations Fix (by Lexx)
- Combat Armor Rocket Launcher Fix (by Lexx)
- Metal Armor Hammer Thrust Fix (by x'il)
- Original Childkiller Reputation Art (by Skynet)
- Fallout 2 Big Pistol Sound
- Fallout 2 Font
- Restored Good Endings Compatibility Fix for Restoration Mod 1.0b1 (by Kyojinmaru)
- Dialog Fixes Compatibility Fix for Patch 1.3.5 and Restoration Mod 1.0b1 (by Kyojinmaru)
- Further Dialog Fixes (by _Pyran_ and Kyojinmaru)

## Validation

Use the validation script to confirm the patched output matches the RME payload:

```bash
./scripts/patch/rebirth-validate-data.sh --patched /path/to/Fallout1-RME --base /path/to/FalloutData
```

## Notes

- The patch scripts use `source/` as the source of truth
- Windows-only executables have been removed
- Original RME data sourced from TeamX and community contributors
- NPC Mod No Armor is an alternate variant; the patch pipeline uses NPC Mod 3.5 + Fix

## See Also

- [scripts/patch/](../../scripts/patch/) - Patch scripts
- [development/RME/](../../development/RME/) - RME integration documentation

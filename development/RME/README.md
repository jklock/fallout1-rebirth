# RME (Restoration Mod Enhanced) Integration Documentation

**Last Updated:** 2026-02-08

## Purpose

Documentation and planning materials for integrating the Restoration Mod Enhanced (RME) data payload into Fallout 1 Rebirth. RME is a curated data pack (TeamX patches + restoration content) applied on top of user-supplied Fallout 1 assets.

## Contents

| Directory | Purpose |
|-----------|---------|
| `plan/` | Integration planning documents and approach |
| `summary/` | Summary reports of integration work |
| `todo/` | Outstanding tasks and work items |
| `validation/` | Testing and validation procedures |

## About RME

Restoration Mod Enhanced (RME) bundles:
- TeamX Patch 1.2 / 1.2.1 / 1.3.5
- NPC Mod 3.5 (+ Fix, with optional No Armor variant)
- Restoration Mod 1.0b1
- Restored Good Endings 2.0
- Dialog and assorted fix packs

## Integration Status

Patch pipeline is implemented and validated at the data/script level. In-game visual verification and variant selection (NPC Mod No Armor) are pending. See the following for details:
- `third_party/rme/` - RME payload
- `summary/` - Integration summary reports

## Related Files

- `third_party/rme/README.md` - RME payload documentation
- `scripts/patch/` - Patch pipeline scripts
- `.github/copilot-instructions.md` - Project phases overview

## See Also

- [Features Documentation](../../docs/features.md)
- [Architecture Overview](../../docs/architecture.md)

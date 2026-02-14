# JOURNAL: RME (Restoration Mod Enhanced) Data

Last Updated: 2026-02-14

## Purpose

RME 1.1e data payload for the Restoration Mod Enhanced integration. Contains patch files that restore cut content, fix bugs, and improve the Fallout 1 experience.

## Directory Structure

| File/Directory | Purpose |
|----------------|---------|
| `source/` | Raw RME payload (DATA overrides + xdelta patches) |
| `manifest.json` | File count and expected top-level layout |
| `checksums.txt` | SHA256 checksums for payload validation |
| `README.md` | RME payload documentation |

## Recent Activity

### 2026-02-14
- Added/updated `patchvalidation.md` to map every listed upstream patch to concrete payload evidence and apply/validate code references.
- Aligned validation guidance with external game-data roots (`FALLOUT_GAMEFILES_ROOT`/`GAME_DATA`) used by active scripts.

### 2026-02-07
- Created JOURNAL.md to track RME integration
- Patch pipeline operational with scripts in scripts/patch/
- Manifest and checksums validated against source payload
- Windows-only executables removed from source/

### Previous
- RME 1.1e data sourced from TeamX and community contributors
- Initial integration completed as part of Phase 3 (RME Integration)

## Key Files

| File | Purpose |
|------|---------|
| `source/` | RME data files to be patched over base game |
| `manifest.json` | Defines expected payload structure |
| `checksums.txt` | SHA256 hashes for validation |

## Patch Pipeline

The RME data is applied using scripts in `scripts/patch/`:

| Script | Purpose |
|--------|---------|
| `rebirth-patch-data.sh` | Patch game data files in a directory |
| `rebirth-patch-app.sh` | Patch macOS .app bundle |
| `rebirth-patch-ipa.sh` | Patch iOS .ipa archive |

### Usage

```bash
# Patch game data directory
./scripts/patch/rebirth-patch-data.sh /path/to/game/data

# Patch macOS app bundle
./scripts/patch/rebirth-patch-app.sh Fallout1-Rebirth.app

# Patch iOS IPA
./scripts/patch/rebirth-patch-ipa.sh Fallout1-Rebirth.ipa
```

## Development Notes

### For AI Agents

1. **Source Directory**: `source/` contains the actual RME payload files
2. **Validation**: Use checksums.txt to verify payload integrity
3. **No Windows Files**: Windows executables have been removed from source/
4. **Documentation**: See development/RME/ for integration research and plans

### RME Features

RME 1.1e includes:
- Restored cut content (quests, NPCs, dialogue)
- Bug fixes from TeamX Patch 1.3.5
- Enhanced game data

### Related Documentation

- [scripts/patch/](../../scripts/patch/) - Patch scripts
- [development/RME/](../../development/RME/) - RME integration documentation
- [development/RME/validation/](../../development/RME/validation/) - Validation testing

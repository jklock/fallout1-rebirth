# JOURNAL: src/game/

Last Updated: 2026-02-14

## Purpose

Core game logic for Fallout 1. Contains all gameplay systems including combat, character management, world map, dialogue, inventory, and save/load functionality.

## Recent Activity

### 2026-02-14
- Added compile-time no-op logging macros in `rme_log.h` under `F1R_DISABLE_RME_LOGGING` so release builds can strip diagnostics without rewriting callsites.
- Documented deterministic log-file overwrite behavior in `rme_log.cc` for reproducible validation runs.
- Added explicit `F1R AUDIT NOTE` rationale comments in `main.cc` and `map.cc` for runtime harness and map diagnostics changes.

### 2026-02-07
- Survivalist perk fix verified working
- Vault 15 self-attack bug fix applied (combat targeting)
- TeamX Patch 1.3.5 compatibility maintained

### Previous
- RME 1.1e data integration complete
- Various combat AI improvements from upstream

## Key Files

| File | Purpose |
|------|---------|
| `main.cc` | Entry point, main loop initialization |
| `game.cc` | Game state management, startup/shutdown |
| `actions.cc` | Combat actions, movement, item use |
| `combat.cc` | Combat system, turn management |
| `combatai.cc` | AI combat decisions |
| `critter.cc` | Character/creature management |
| `worldmap.cc` | World map travel, encounters |
| `loadsave.cc` | Save/load game functionality |
| `perk.cc` | Perk system (Survivalist fix here) |
| `scripts.cc` | Script execution hooks |
| `map.cc` | Map loading, tile management |
| `gdialog.cc` | Dialogue system |
| `inventry.cc` | Inventory management |
| `intface.cc` | Main game interface/HUD |

## Development Notes

### For AI Agents

1. **Bug Fixes**: Most gameplay bugs fixed in `actions.cc`, `combat.cc`, or `perk.cc`
2. **Opcode Handlers**: Script functions registered in `int/support/intextra.cc`
3. **Global State**: Heavy use of `extern` globals - be careful with initialization order
4. **Save Compatibility**: Changes to structures may break save games

### Combat System

- `actions.cc` - Player/NPC action execution
- `combat.cc` - Combat loop, damage calculation
- `combatai.cc` - NPC decision making
- Self-attack bug was in targeting validation in `actions.cc`

### Key Bug Fix Locations

| Bug | File | Function |
|-----|------|----------|
| Survivalist perk | `perk.cc` | Perk effect calculation |
| Vault 15 self-attack | `actions.cc` | Target validation |

### Testing Combat Changes

Combat changes require manual testing with game assets. Load a save near combat encounters and verify:
- Targeting works correctly
- Damage calculations match expected values
- AI behaves appropriately

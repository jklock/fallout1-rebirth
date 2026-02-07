# src/game/

Core game logic and mechanics for Fallout 1.

Last updated: 2026-02-07

## Entry Points

- `main.cc/h` - Application entry, main game loop
- `game.cc/h` - Game initialization, state management, global variables

## Major Subsystems

### Combat
- `combat.cc/h` - Turn-based combat system
- `combatai.cc/h` - NPC AI and targeting
- `actions.cc/h` - Combat actions and animations

### World and Maps
- `map.cc/h` - Map loading and management
- `tile.cc/h` - Hex tile system
- `worldmap.cc/h` - Overworld travel system
- `object.cc/h` - Game object management
- `light.cc/h` - Lighting calculations

### Characters and Items
- `critter.cc/h` - Character/creature handling
- `item.cc/h` - Item definitions and usage
- `inventry.cc/h` - Inventory management
- `stat.cc/h` - SPECIAL stats system
- `skill.cc/h` - Skills system
- `perk.cc/h` - Perks system
- `trait.cc/h` - Traits system

### UI and Interface
- `intface.cc/h` - Main game interface
- `gdialog.cc/h` - Dialog system
- `mainmenu.cc/h` - Main menu
- `options.cc/h` - Options screen
- `pipboy.cc/h` - Pip-Boy interface
- `automap.cc/h` - Automap display

### Data and Resources
- `proto.cc/h` - Prototype definitions
- `art.cc/h` - Art/sprite loading
- `message.cc/h` - Message file handling
- `cache.cc/h` - Resource caching
- `gconfig.cc/h` - Game configuration

### Save/Load
- `loadsave.cc/h` - Save game system

### Scripts
- `scripts.cc/h` - Script attachment and execution

### Audio/Video
- `gsound.cc/h` - Game sound management
- `gmovie.cc/h` - Cutscene playback

## Type Definitions

- `*_defs.h` files contain enums and constants (e.g., `perk_defs.h`, `stat_defs.h`)
- `*_types.h` files contain struct definitions (e.g., `proto_types.h`, `object_types.h`)

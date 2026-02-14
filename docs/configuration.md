# Configuration Reference

Runtime-accurate configuration reference for Fallout 1 Rebirth.

## Overview

The game reads two files from the game data directory:

| File | Purpose |
|---|---|
| `fallout.cfg` | Core game/system/audio/input/debug settings |
| `f1_res.ini` | Display mode, scaling, and click-offset calibration |

Platform templates live in:

- `gameconfig/macos/`
- `gameconfig/ios/`

## `f1_res.ini` (Runtime-Consumed Keys)

Only the keys below are consumed by current runtime code (`src/game/game.cc`, `src/plib/gnw/mouse.cc`).

### `[MAIN]`

| Key | Type | Effect |
|---|---|---|
| `SCR_WIDTH` | int | Requested output width (minimum effective logical width is clamped to 640) |
| `SCR_HEIGHT` | int | Requested output height (minimum effective logical height is clamped to 480) |
| `WINDOWED` | bool/int | `1` windowed, `0` fullscreen (iOS forces fullscreen in renderer) |
| `EXCLUSIVE` | bool/int | Fullscreen exclusivity hint when fullscreen is used |
| `SCALE_2X` | int | `0` = scale 1x, `1` = scale 2x (`video_scale = SCALE_2X + 1`) |

### `[INPUT]`

| Key | Type | Effect |
|---|---|---|
| `CLICK_OFFSET_X` | int | Touch click X calibration (game pixels) |
| `CLICK_OFFSET_Y` | int | Touch click Y calibration (game pixels) |
| `CLICK_OFFSET_MOUSE_X` | int | Mouse/trackpad click X calibration |
| `CLICK_OFFSET_MOUSE_Y` | int | Mouse/trackpad click Y calibration |

## Resolution Behavior Actually Applied

### Engine Rules

1. Start from `SCR_WIDTH`/`SCR_HEIGHT`.
2. Apply scale divisor: `logical = requested / (SCALE_2X + 1)`.
3. Clamp logical resolution to a minimum of `640x480`.
4. Render to that logical surface.

### Platform Behavior

- **macOS**: `WINDOWED` is honored (`1` default in template).
- **iOS/iPadOS**: Renderer forces fullscreen regardless of `WINDOWED`, but key is still parsed.

### Recommended Defaults

These are the shipped template defaults and are fully respected:

| Platform | `SCR_WIDTH` | `SCR_HEIGHT` | `SCALE_2X` | `WINDOWED` | Effective logical resolution |
|---|---:|---:|---:|---:|---:|
| macOS | 1280 | 960 | 1 | 1 | 640x480 |
| iOS/iPadOS | 1280 | 960 | 1 | 0 | 640x480 |

## `fallout.cfg` (Runtime-Consumed Keys)

The keys below are consumed by current runtime code paths.

### `[system]`

| Key |
|---|
| `art_cache_size` |
| `color_cycling` |
| `critter_dat` |
| `critter_patches` |
| `cycle_speed_factor` |
| `executable` |
| `hashing` |
| `interrupt_walk` |
| `language` |
| `master_dat` |
| `master_patches` |
| `splash` |

### `[sound]`

| Key |
|---|
| `cache_size` |
| `debug` |
| `initialize` |
| `master_volume` |
| `music` |
| `music_path1` |
| `music_path2` |
| `music_volume` |
| `sndfx_volume` |
| `sounds` |
| `speech` |
| `speech_volume` |

### `[preferences]`

| Key |
|---|
| `brightness` |
| `combat_difficulty` |
| `combat_messages` |
| `combat_speed` |
| `combat_taunts` |
| `game_difficulty` |
| `item_highlight` |
| `language_filter` |
| `mouse_sensitivity` |
| `player_speedup` |
| `running` |
| `running_burning_guy` |
| `subtitles` |
| `target_highlight` |
| `text_base_delay` |
| `text_line_delay` |
| `violence_level` |

### `[debug]`

| Key |
|---|
| `mode` |
| `rme_log` |
| `output_map_data_info` |
| `show_load_info` |
| `show_script_messages` |
| `show_tile_num` |

### `[input]`

| Key |
|---|
| `map_scroll_delay` |
| `pencil_right_click` |

## Legacy Key Compatibility

`gconfig_init` now backfills these legacy names when newer keys are missing:

- `preferences.player_speed` -> `preferences.player_speedup`
- `preferences.combat_looks` -> `preferences.running_burning_guy`

## Template Policy

`gameconfig/macos/` and `gameconfig/ios/` are intentionally limited to runtime-consumed keys so every exposed option is actually respected.

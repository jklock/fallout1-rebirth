# Configuration Reference

Complete reference for all configuration options in Fallout 1 Rebirth.

## Overview

Fallout 1 Rebirth uses two configuration files:

| File | Purpose |
|------|---------|
| `fallout.cfg` | Game settings (difficulty, sound, input, debug) |
| `f1_res.ini` | Display settings (resolution, scaling, interface, visual effects) |

### File Locations

Both files must be placed alongside the game data files:

- **macOS**: Inside the app bundle at `Fallout 1 Rebirth.app/Contents/Resources/app/`
- **iOS/iPadOS**: In the app's Files container (accessible via Finder when device is connected)

### Template Files

Pre-configured templates optimized for each platform are available in the `gameconfig/` folder:
- `gameconfig/macos/` — Templates for macOS
- `gameconfig/ios/` — Templates for iOS/iPadOS

Copy and rename `fallout.ini` to `f1_res.ini` when deploying.

---

## fallout.cfg Reference

This file uses INI format with `[section]` headers and `key=value` pairs.

### [system]

Core game engine settings.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `master_dat` | string | `master.dat` | Filename for the main game archive |
| `critter_dat` | string | `critter.dat` | Filename for the creature graphics archive |
| `master_patches` | string | `data` | Override folder for loose master files |
| `critter_patches` | string | `data` | Override folder for loose critter files |
| `language` | string | `english` | Language folder under `data/text/` |
| `art_cache_size` | int | `8` | Number of art files kept in memory (performance vs RAM tradeoff) |
| `color_cycling` | int | `1` | Enable palette cycling effects (water, lights). 0=off, 1=on |
| `cycle_speed_factor` | int | `1` | Animation speed multiplier. 1=normal |
| `executable` | string | `game` | Internal game name; keep as `game` |
| `hashing` | int | `1` | Enable file hashing for cache integrity |
| `interrupt_walk` | int | `1` | Allow interrupting queued movement. 0=off, 1=on |
| `splash` | int | `0` | Show intro splash screen. 0=skip, 1=show |
| `scroll_lock` | int | `0` | Enable edge scrolling with mouse at screen edges |
| `free_space` | int | `0` | Legacy disk check (ignored on Apple platforms) |
| `times_run` | int | `0` | Internal counter; safe to leave 0 |

### [sound]

Audio system configuration.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `initialize` | int | `1` | Enable the audio system. 0=disabled, 1=enabled |
| `music` | int | `1` | Enable music playback. 0=off, 1=on |
| `sounds` | int | `1` | Enable sound effects. 0=off, 1=on |
| `speech` | int | `1` | Enable voiced dialogue. 0=off, 1=on |
| `master_volume` | int | `22281` | Overall volume (0-32767) |
| `music_volume` | int | `22281` | Music volume (0-32767) |
| `sndfx_volume` | int | `22281` | Sound effects volume (0-32767) |
| `speech_volume` | int | `22281` | Speech volume (0-32767) |
| `music_path1` | string | `data/sound/music/` | Primary path to music files |
| `music_path2` | string | `data/sound/music/` | Secondary path to music files |
| `cache_size` | int | `448` | Sound cache size in KB |
| `device` | int | `-1` | Legacy audio setting (ignored on Apple platforms) |
| `dma` | int | `-1` | Legacy audio setting (ignored on Apple platforms) |
| `irq` | int | `-1` | Legacy audio setting (ignored on Apple platforms) |
| `port` | int | `-1` | Legacy audio setting (ignored on Apple platforms) |

### [preferences]

Gameplay preferences and options.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `game_difficulty` | int | `1` | 0=easy, 1=normal, 2=hard. Impacts skill checks |
| `combat_difficulty` | int | `1` | 0=easy, 1=normal, 2=hard. Impacts combat rolls |
| `violence_level` | int | `3` | 0=none, 1=minimal, 2=normal, 3=maximum gore |
| `brightness` | float | `1.0` | Display brightness. 0.0 (dark) to 2.0 (bright) |
| `combat_speed` | int | `0` | 0=normal, 5=fastest. Controls combat animation delay |
| `combat_messages` | int | `1` | Combat log text. 0=off, 1=on |
| `combat_taunts` | int | `1` | Enemy taunt lines. 0=off, 1=on |
| `item_highlight` | int | `1` | Highlight interactive items. 0=off, 1=on |
| `target_highlight` | int | `2` | 0=off, 1=on, 2=on+targeting line |
| `subtitles` | int | `0` | Subtitles for voiced dialogue. 0=off, 1=on |
| `language_filter` | int | `0` | Profanity filter. 0=off, 1=on |
| `running` | int | `0` | Start in running mode. 0=walk, 1=run |
| `player_speedup` | int | `0` | Enable running. 0=walk only, 1=running enabled |
| `running_burning_guy` | int | `1` | Allow running while on fire (legacy behavior) |
| `mouse_sensitivity` | float | `1.0` | Pointer speed multiplier for mouse/trackpad/touch |
| `text_base_delay` | float | `3.5` | Base delay before text scroll (seconds) |
| `text_line_delay` | float | `1.4` | Delay per line in dialogue text (seconds) |

### [debug]

Developer and debugging options.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `mode` | string | `environment` | Log output mode. `environment` logs to stdout/stderr |
| `show_script_messages` | int | `0` | Enable script debug output. 0=off, 1=on |
| `show_load_info` | int | `0` | Print asset load timing and cache info |
| `show_tile_num` | int | `0` | Overlay tile numbers on the map |
| `output_map_data_info` | int | `0` | Write additional map diagnostics |

### [input]

Input device configuration.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `map_scroll_delay` | int | `66` | Minimum delay between map scroll updates (ms). 33=fast, 66=default, 100+=slow |
| `pencil_right_click` | int | `0` | **iOS only.** Apple Pencil right-click behavior. See below |

#### Apple Pencil Right-Click (`pencil_right_click`)

Controls whether Apple Pencil gestures can trigger right-click actions.

| Value | Behavior |
|-------|----------|
| `0` (default) | **Disabled** — Pencil acts as precise left-click only. Use finger touch for right-click |
| `1` | **Enabled** — Pencil long-press, double-tap, and squeeze trigger right-click |

**Recommendation**: Leave disabled (0). Use your finger for right-click and Apple Pencil for precision pointing.

---

## f1_res.ini Reference

High-resolution patch settings controlling display, interface, and visual effects.

### [MAIN]

Primary display settings.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `SCR_WIDTH` | int | 1024 (iOS) / 1280 (macOS) | Logical screen width in pixels. Minimum: 640 |
| `SCR_HEIGHT` | int | 768 (iOS) / 960 (macOS) | Logical screen height in pixels. Minimum: 480 |
| `SCALE_2X` | int | 1 (iOS) / 0 (macOS) | Double internal 640x480 to 1280x960 before output |
| `WINDOWED` | int | 0 (iOS) / 1 (macOS) | 0=fullscreen, 1=windowed. **Ignored on iOS** |
| `WINDOWED_FULLSCREEN` | int | `0` | Borderless fullscreen (requires WINDOWED=1). **Ignored on iOS** |
| `COLOUR_BITS` | int | `32` | Legacy color depth; Apple platforms use 32-bit |
| `REFRESH_RATE` | int | `0` | 0=use display default. Other values ignored on Apple platforms |
| `GRAPHICS_MODE` | int | `2` | Legacy renderer selector (ignored) |
| `UAC_AWARE` | int | `1` | Legacy Windows setting (ignored) |
| `WIN_DATA` | int | `0` | Internal window placement data |

**Resolution Minimums**: The game enforces a minimum resolution of **640×480** to ensure interface assets (which are 640 pixels wide) display correctly. Values lower than this are automatically increased to 640×480.

#### Resolution Recommendations

| Platform | Recommended | Notes |
|----------|-------------|-------|
| iPad Pro 13" | 1024×768 | Native 4:3 ratio, SCALE_2X=1 for sharp pixels |
| iPad Pro 11" | 1024×768 | Slight letterboxing on 4.3:3 display |
| MacBook | 1280×960 | Windowed mode, classic 4:3 |
| iMac/External | 1280×960+ | Higher resolutions supported |

### [DISPLAY]

Frame rate and synchronization settings.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `VSYNC` | int | `1` | Vertical sync. 0=off (may tear), 1=on (recommended) |
| `FPS_LIMIT` | int | `-1` | Frame rate limit. -1=match display, 0=unlimited, 60/120=cap |

**VSync** eliminates screen tearing and is strongly recommended. With VSync enabled, FPS_LIMIT is mostly redundant.

**FPS_LIMIT values:**
- `-1` — Match display refresh rate (60Hz or 120Hz ProMotion)
- `0` — Unlimited (not recommended, wastes battery/power)
- `60` — Cap at 60fps (saves battery on 120Hz displays)
- `120` — Cap at 120fps

### [INPUT]

Input handling and click calibration settings.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `CLICK_OFFSET_X` | int | `0` | Horizontal click position adjustment in game pixels. Positive shifts clicks RIGHT, negative shifts LEFT. Use to calibrate if clicks don't align with cursor |
| `CLICK_OFFSET_Y` | int | `0` (macOS/iOS) | Vertical click position adjustment in game pixels. Positive shifts clicks DOWN, negative shifts UP |
| `ALT_MOUSE_INPUT` | int | `0` | Alternate mouse input path. Keep 0 unless experiencing input issues |
| `SCROLLWHEEL_FOCUS_PRIMARY_MENU` | int | `1` | Focus scroll wheel on primary list by default |
| `EXTRA_WIN_MSG_CHECKS` | int | `1` | Legacy loop checks; keep 1 for stability |

#### Click Offset Calibration

The click offset settings allow fine-tuning where clicks register relative to the cursor position. This is particularly useful on iOS where touch input may have a slight offset from where the cursor tip appears.

**iOS**: Default is `0`. If your clicks seem off, adjust these values:
- If clicks register too far **right**, decrease `CLICK_OFFSET_X` (use negative value)
- If clicks register too far **left**, increase `CLICK_OFFSET_X` (use positive value)
- If clicks register too far **down**, decrease `CLICK_OFFSET_Y` (use more negative value)
- If clicks register too far **up**, increase `CLICK_OFFSET_Y` (use positive value)

**macOS**: Usually no adjustment needed. Set both to `0`

### [MOVIES]

Movie/cutscene display settings.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `MOVIE_SIZE` | int | `1` | 0=original size, 1=fit with aspect ratio, 2=fill (may crop) |

### [MAPS]

Map rendering and navigation settings.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `EDGE_CLIPPING_ON` | int | `1` | Hide tiles beyond map edges |
| `IGNORE_MAP_EDGES` | int | `0` | Allow scrolling past map edges |
| `IGNORE_PLAYER_SCROLL_LIMITS` | int | `1` | Ignore SCROLL_DIST limits around the player |
| `SCROLL_DIST_X` | string | `HALF_SCRN` | Camera follow distance X. Use `HALF_SCRN` or pixel value |
| `SCROLL_DIST_Y` | string | `HALF_SCRN` | Camera follow distance Y. Use `HALF_SCRN` or pixel value |
| `NumPathNodes` | int | `1` | Pathfinding nodes. 1=2000, 2=4000, etc. Higher=better pathing, more CPU |
| `FOG_OF_WAR` | int | `0` | Enable fog of war. 0=off, 1=on |
| `FOG_LIGHT_LEVEL` | int | `4` | Fog brightness. 0=off, 1=darkest, 10=brightest |

### [IFACE]

Interface bar settings.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `IFACE_BAR_WIDTH` | int | `800` | Interface bar width. 640=classic, 800=wide |
| `IFACE_BAR_MODE` | int | `0` | 0=map stops at bar, 1=map extends under bar |
| `IFACE_BAR_SIDE_ART` | int | `1` | 0=black, 1=metal, 2=leather |
| `IFACE_BAR_SIDES_ORI` | int | `0` | 0=bar→edges, 1=edges→bar |
| `ALTERNATE_AMMO_METRE` | int | `0` | 0=off, 1=single color, 2=dynamic, 3=segmented |
| `ALTERNATE_AMMO_LIGHT` | hex | `0xC4` | Palette index for ammo meter light color (mode 1) |
| `ALTERNATE_AMMO_DARK` | hex | `0x4B` | Palette index for ammo meter dark color (mode 1) |

### [MAINMENU]

Main menu display settings.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `MAIN_MENU_SIZE` | int | `1` | 0=original, 1=fit, 2=fill |
| `USE_HIRES_IMAGES` | int | `1` | Use high-res menu art when available |
| `SCALE_BUTTONS_AND_TEXT_MENU` | int | `1` | Scale menu buttons/text for readability |
| `MENU_BG_OFFSET_X` | int | `-24` | X offset for hi-res background alignment |
| `MENU_BG_OFFSET_Y` | int | `-24` | Y offset for hi-res background alignment |

### [STATIC_SCREENS]

Static screen sizing (death, help, splash screens).

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `DEATH_SCRN_SIZE` | int | `1` | 0=original, 1=fit, 2=fill |
| `END_SLIDE_SIZE` | int | `1` | 0=original, 1=fit, 2=fill |
| `HELP_SCRN_SIZE` | int | `1` | 0=original, 1=fit, 2=fill |
| `SPLASH_SCRN_SIZE` | int | `1` | 0=original, 1=fit, 2=fill |

### [OTHER_SETTINGS]

Miscellaneous gameplay and performance settings.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `DIALOG_SCRN_BACKGROUND` | int | `0` | 0=show map behind dialog, 1=hide map |
| `DIALOG_SCRN_ART_FIX` | int | `1` | Enable updated dialog background art |
| `SPLASH_SCRN_TIME` | int | `0` | Seconds to display splash. 0=instant |
| `DOUBLE_CLICK_RUNNING` | int | `1` | Double-click to run. 0=off, 1=on |
| `INV_ADD_ITEMS_AT_TOP` | int | `0` | Insert new items at top of inventory (experimental) |
| `CPU_USAGE_FIX` | int | `1` | Yield CPU to reduce heat/battery use |
| `BARTER_PC_INV_DROP_FIX` | int | `1` | Improve barter inventory drop accuracy |
| `FADE_TIME_MODIFIER` | int | `60` | Fade transition speed. Lower=faster fades |
| `FADE_TIME_RECALCULATE_ON_FADE` | int | `0` | Recalculate fade length each time |

### [EFFECTS]

Visual effect settings.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `IS_GRAY_SCALE` | int | `0` | Render game in grayscale. 0=color, 1=grayscale |

### [HI_RES_PANEL]

High-resolution panel settings.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `DISPLAY_LIST_DESCENDING` | int | `1` | Show resolution list from high to low |

### [PENCIL] (iOS Only)

Apple Pencil configuration. This section only applies to iOS/iPadOS.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `ENABLE_PENCIL` | int | `1` | Enable Apple Pencil-specific handling |
| `CLICK_RADIUS` | int | `40` | Click radius in pixels (at 640x480 base resolution) |
| `LONG_PRESS_ACTION` | int | `2` | Long press gesture. 0=disabled, 1=left-click+drag, 2=right-click |
| `LONG_PRESS_DURATION` | int | `500` | Long press duration in milliseconds |
| `DOUBLE_TAP_ACTION` | int | `2` | Pencil body double-tap. 0=disabled, 1=left-click, 2=right-click |
| `SQUEEZE_ACTION` | int | `2` | Squeeze gesture (Pro only). 0=disabled, 1=left-click, 2=right-click |

#### Click Radius Explained

The click radius separates positioning from clicking, similar to a mouse:
- Taps **within** the radius of the current cursor position trigger a click
- Taps **outside** the radius only move the cursor (no click)

This allows precise cursor positioning before clicking, which is essential for the small targets in Fallout's interface.

---

## Platform Differences

### iOS/iPadOS

| Setting | Behavior |
|---------|----------|
| `WINDOWED` | Always ignored — app is always fullscreen |
| `WINDOWED_FULLSCREEN` | Ignored |
| `scroll_lock` | Edge scrolling disabled (no mouse cursor at edges) |
| `[PENCIL]` section | Fully functional |
| `pencil_right_click` | Controls Apple Pencil gestures |

### macOS

| Setting | Behavior |
|---------|----------|
| `WINDOWED` | Functional — 0=fullscreen, 1=windowed |
| `WINDOWED_FULLSCREEN` | Functional with WINDOWED=1 |
| `scroll_lock` | Edge scrolling with mouse at screen edges |
| `[PENCIL]` section | Ignored (no Apple Pencil on macOS) |
| `pencil_right_click` | Ignored |

### Legacy Options (Ignored on Apple Platforms)

These settings exist for compatibility with the original f1_res.ini but have no effect:

- `device`, `dma`, `irq`, `port` — DOS audio hardware settings
- `GRAPHICS_MODE` — DirectX/OpenGL renderer selection
- `UAC_AWARE` — Windows UAC compatibility
- `COLOUR_BITS` — Always 32-bit on Apple platforms
- `REFRESH_RATE` — Uses display default
- `free_space` — Disk space checking

---

## Recommended Configurations

### iPad Pro 13" / iPad Air 13"

```ini
; f1_res.ini
[MAIN]
SCR_WIDTH=1024
SCR_HEIGHT=768
SCALE_2X=1
WINDOWED=0

[DISPLAY]
VSYNC=1
FPS_LIMIT=-1

[IFACE]
IFACE_BAR_WIDTH=800
```

```ini
; fallout.cfg
[input]
pencil_right_click=0
map_scroll_delay=66
```

### iPad Pro 11" / iPad Air 11"

Same as 13" — the 1024×768 resolution will have slight letterboxing on the 4.3:3 aspect ratio.

### MacBook Air/Pro (Windowed)

```ini
; f1_res.ini
[MAIN]
SCR_WIDTH=1280
SCR_HEIGHT=960
SCALE_2X=0
WINDOWED=1

[DISPLAY]
VSYNC=1
FPS_LIMIT=-1

[IFACE]
IFACE_BAR_WIDTH=800
```

### iMac / External Display (Fullscreen)

```ini
; f1_res.ini
[MAIN]
SCR_WIDTH=1280
SCR_HEIGHT=960
SCALE_2X=0
WINDOWED=0
WINDOWED_FULLSCREEN=1

[DISPLAY]
VSYNC=1
FPS_LIMIT=-1
```

---

## Troubleshooting

### Game runs slowly or stutters
- Enable `CPU_USAGE_FIX=1` in [OTHER_SETTINGS]
- Enable `VSYNC=1` in [DISPLAY]
- On iOS with ProMotion, try `FPS_LIMIT=60` to save battery

### Mouse/touch input feels wrong
- Adjust `mouse_sensitivity` in [preferences]
- Adjust `map_scroll_delay` in [input] (higher = slower scrolling)
- Try `ALT_MOUSE_INPUT=1` if experiencing input issues

### Apple Pencil not responding correctly
- Ensure `ENABLE_PENCIL=1` in [PENCIL] section
- Adjust `CLICK_RADIUS` if clicks are registering incorrectly
- Check `pencil_right_click` setting in fallout.cfg

### Resolution looks wrong
- Verify `SCR_WIDTH` and `SCR_HEIGHT` use 4:3 ratio
- Try `SCALE_2X=1` for sharper rendering at lower resolutions
- On iOS, `WINDOWED=0` is required (always fullscreen)

### No sound
- Check `initialize=1` in [sound]
- Check `music=1`, `sounds=1`, `speech=1`
- Verify volume levels are above 0

### Colors flickering
- Check `color_cycling=1` in [system] (disable with 0 if problematic)
- Ensure `VSYNC=1` is enabled
---

## Proof of Work

- **Timestamp**: February 5, 2026
- **Files verified**:
  - `gameconfig/ios/fallout.cfg` - Confirmed configuration structure
  - `gameconfig/macos/fallout.cfg` - Confirmed configuration structure
  - `gameconfig/ios/f1_res.ini` - Confirmed display settings
  - `src/plib/gnw/svga.cc` - Confirmed VSync implementation uses SDL3
- **Updates made**: No updates needed - content verified accurate. Configuration options, platform differences, and troubleshooting guidance are all current.

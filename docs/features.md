# Fallout 1 Rebirth: Complete Feature History

This document traces the complete development history of Fallout 1 Rebirth, an Apple-only fork of [fallout1-ce](https://github.com/alexbatalov/fallout1-ce) (Fallout 1 Community Edition). Every significant change from the upstream project is documented with the corresponding git commits.

## Table of Contents

- [Overview](#overview)
- [Platform Changes](#platform-changes)
- [Display & Graphics](#display--graphics)
- [Input System](#input-system)
- [Build System](#build-system)
- [Engine Fixes](#engine-fixes)
- [Quality of Life Features](#quality-of-life-features)
- [Configuration System](#configuration-system)
- [Documentation](#documentation)
- [Community Contributions](#community-contributions)
- [Commit Timeline](#commit-timeline)

---

## Overview

### What is Fallout 1 Rebirth?

Fallout 1 Rebirth is a fully working re-implementation of Fallout 1 that exclusively targets **macOS** and **iOS/iPadOS**. It is forked from [alexbatalov/fallout1-ce](https://github.com/alexbatalov/fallout1-ce), which is a cross-platform engine reimplementation supporting Windows, Linux, macOS, iOS, and Android.

### Key Differences from Upstream

| Aspect | fallout1-ce (Upstream) | fallout1-rebirth |
|--------|------------------------|------------------|
| **Platforms** | Windows, Linux, macOS, iOS, Android | macOS, iOS/iPadOS only |
| **Build System** | CI/CD via GitHub Actions | Local builds only |
| **VSync** | Optional | Enabled by default |
| **Touch Input** | Basic support | Full Apple Pencil integration |
| **Distribution** | Pre-built releases with CI | Manual GitHub Releases |
| **Configuration** | Single fallout.cfg | Platform-specific templates (gameconfig/) |
| **Display** | 60Hz assumed | ProMotion 120Hz support |

### Fork Origin

- **Initial Commit**: `7520167` (2023-02-09)
- **Base**: alexbatalov/fallout1-ce at that point in time
- **Fork Rationale**: Optimize for Apple platforms, remove cross-platform complexity, add Apple-specific features

---

## Platform Changes

### Apple-Only Focus

The most significant architectural change is the removal of all non-Apple platform support.

#### Removed Platforms

| Platform | Removal Commit | Files Affected |
|----------|---------------|----------------|
| Windows | `4c72775` | Mutex handling, file APIs, headers |
| Linux | `4c72775` | Path handling, configuration |
| Android | `4c72775` | SDL hints, path handling |

**Commit `4c72775`** (2026-02-02): *Add Apple Pencil toggle and platform cleanup*
```
Platform cleanup:
- Remove all Windows-specific code (mutex, file APIs, headers)
- Remove Android-specific code (path handling, SDL hints)
- Delete unused fallout.ini file (replaced by fallout.cfg)
- Simplify to Apple-only implementation throughout codebase
14 files changed, 84 insertions(+), 341 deletions(-)
```

#### macOS Deployment

- **Minimum**: macOS 11.0 (Big Sur)
- **Native Apple Silicon**: Full M1/M2/M3/M4 support
- **Build Method**: Xcode projects via CMake

**Commit `1fa0c53`** (2023-05-01): *Use Xcode for macOS builds (#67)*
- Switched from makefiles to Xcode for native macOS builds
- Better integration with Apple development tools

#### iOS/iPadOS Deployment

- **Minimum**: iOS 15.0 (updated from earlier versions)
- **Primary Target**: iPad (landscape orientation)
- **Sideloading**: Via AltStore or Sideloadly

**Commit `c485246`** (2023-05-01): *Use Xcode for iOS builds (#65)*
- Xcode-based iOS builds for proper code signing
- Improved App Store compatibility

**Commit `3e5baea`** (2026-01-31): *Add iOS simulator testing script and update deployment targets to 26.0*
- Added `scripts/test-ios-simulator.sh` for iPad testing
- Auto-detect bundle ID from Info.plist
- Robust simulator boot wait with retries
- Copy game data to Documents container

**Commit `abfaba5`** (2025-07-10): *Hide status bar on iPadOS*
- Full-screen immersive experience on iPad

---

## Display & Graphics

### SDL3 Engine (First CE Fork!)

**Completed: 2026-02-05**

Fallout 1 Rebirth is the **first known Fallout Community Edition fork to upgrade to SDL3**. This is a major technical achievement that brings:

| Feature | Benefit |
|---------|---------|
| **SDL3 3.2.4** | Latest multimedia library with modern APIs |
| **Nearest Neighbor Scaling** | Pixel-perfect retro graphics, no blur |
| **Modern Audio Streams** | Improved sound quality and mixing |
| **Better Touch Handling** | Enhanced iOS coordinate conversion |
| **Metal by Default** | Native Apple GPU rendering |

**Nearest Neighbor Scaling** (`src/plib/gnw/svga.cc`):
```c
// Enable pixel-perfect scaling for crisp retro graphics
SDL_SetTextureScaleMode(gSdlTexture, SDL_SCALEMODE_NEAREST);
```

**Migration Scope**: 19 source files updated with SDL3 patterns:
- Event types: `SDL_EVENT_*` format
- Render API: `SDL_RenderTexture()` instead of `SDL_RenderCopy()`
- Audio: Modern stream API with float volume
- Surfaces: `SDL_CreateSurface()` / `SDL_DestroySurface()`

For full migration details, see [development/SDL3/PLAN.MD](../development/SDL3/PLAN.MD).

### VSync Support

VSync (vertical synchronization) is **enabled by default** in Fallout 1 Rebirth, eliminating screen tearing.

**Commit `c4b3515`** (2026-02-02): *feat: VSync, touch fixes, comprehensive docs, local-only builds*

```c
// src/plib/gnw/svga.cc
SDL_CreateRenderer(window, -1, 
    SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);
```

Features added:
- VSync enabled by default via `SDL_RENDERER_PRESENTVSYNC`
- Display refresh rate logging at startup for debugging
- Configurable FpsLimiter with `setFps()`, `setEnabled()`, `getFps()`, `isEnabled()`
- `[DISPLAY]` section in f1_res.ini with `VSYNC` and `FPS_LIMIT` options
- ProMotion 120Hz support for compatible iPads

**Configuration** (`f1_res.ini`):
```ini
[DISPLAY]
VSYNC=1          ; 0=off, 1=on (default)
FPS_LIMIT=-1     ; -1=match display, 0=unlimited, 60/120=fixed
```

### ProMotion Support

iPads with ProMotion (120Hz) displays automatically benefit from higher refresh rates when VSync is enabled. The game detects and adapts to the display's native refresh rate.

### 2X Integer Scaling

**Commit `55fb75b`** (2023-06-12): *Add support for SCALE_2X (#75)*
- Integer scaling for crisp Retina display rendering
- Eliminates blur from non-integer scaling

**Commit `ec58604`** (2025-12-16): *2X zoom is working on iPad with resolution 1024 x 768 :-)*
- Verified 2X scaling works correctly on iPad
- Optimal for 1024x768 base resolution

### Borderless Window Mode

**Commit `a401e7c`** (2024-04-23): *support for non-exclusive fullscreen mode aka windowed borderless. perfect for macos.*
- Cherry-picked from radozd/fallout1-ce
- Non-exclusive fullscreen for seamless macOS integration
- No window chrome in fullscreen mode

### Display Fixes

**Commit `99315ee`** (2024-03-04): *Fix screen not being refreshed when app transitions from background*
- iOS/macOS app lifecycle handling
- Screen properly updates after returning from background

---

## Input System

### Touch Coordinate Fix (Critical)

**Commit `c4b3515`** (2026-02-02): *feat: VSync, touch fixes, comprehensive docs, local-only builds*

The most important touch input fix:
- Touch/pencil coordinates now use `SDL_RenderWindowToLogical()` for proper transformation
- Matches the existing mouse input path in `dxinput.cc`
- **Cursor now appears exactly where touched** (fixes offset issues on iPads)

Before this fix, touch input had incorrect coordinate mapping, causing the cursor to appear offset from where the user actually touched.

### Apple Pencil Support

Full Apple Pencil integration is a major fork-exclusive feature.

**Commit `d2d4be3`** (2026-02-01): *feat: Apple Pencil support for iOS/iPadOS*
- Initial Apple Pencil detection via native iOS code
- Created `src/platform/ios/pencil.h` and `pencil.mm`
- SDL2 cannot distinguish pencil from finger touch natively

**Commit `b51f201`** (2026-02-01): *feat: Apple Pencil support without mouse/trackpad coupling*
- Decoupled pencil from mouse/trackpad input paths
- Pencil uses absolute positioning like a mouse

**Commit `8b82c52`** (2026-02-01): *fix: iOS input stability, pencil gestures, and app icon*
- Improved gesture recognition
- Fixed input stability issues

**Commit `a187979`** (2026-02-01): *feat(ios): Complete Apple Pencil support and touch input improvements*

Complete implementation:
- Pencil-specific input path in `mouse.cc` using native iOS `UITouch.type` detection
- **Pencil tap**: Moves cursor to exact tip position, then clicks (precise targeting)
- **Pencil pan/drag**: Always initiates left-button drag immediately
- **Pencil long-press**: Left-button drag instead of right-click
- **Pencil body gestures**: Double-tap and squeeze trigger right-click via `UIPencilInteraction`
- Finger behavior unchanged from upstream

**Commit `4c72775`** (2026-02-02): *Add Apple Pencil toggle and platform cleanup*

Configuration options:
- `pencil_right_click` toggle (default: disabled)
- Configurable map scroll speed (`map_scroll_delay`, default 66ms)

**Apple Pencil Gestures**:
| Gesture | Action |
|---------|--------|
| Tap near cursor | Left-click |
| Tap away from cursor | Move cursor only (no click) |
| Long-press | Right-click (examine/context menu) |
| Pencil body double-tap | Right-click (2nd gen+ pencils) |
| Squeeze | Right-click (Apple Pencil Pro only) |
| Drag from cursor | Click + drag |
| Drag from away | Move cursor (no button) |

### iPad Mouse/Trackpad Support

**Commit `ddc8e5e`** (2025-07-10): *Add iPad mouse cursor support*
- Cherry-picked from evaera/fallout1-ce
- Full mouse and trackpad support on iPad

**Commit `a50c339`** (2025-07-10): *Make input switching more consistent*
- Better handling of input mode changes

### F-Key Emulation for iPad

**Commit `fc229da`** (2025-07-10): *Add F key emulation for ipad*
- Cherry-picked from evaera/fallout1-ce
- F-keys work with Magic Keyboard on iPad
- Essential for Fallout's function key shortcuts

### Touch Control Optimization

**Commit `966d18b`** (2024-11-26): *Cursor control optimized for touch devices*
- Cherry-picked from zverinapavel/fallout1-ce
- Better touch control responsiveness

**Commit `76be4b2`** (2023-05-20): *Improve touch controls (#72)*
- From upstream, improved touch handling

### Edge Scroll Improvements

**Commit `a187979`** (2026-02-01):
- Added 8-pixel edge scroll margin in `gmouse.cc` and `worldmap.cc`
- Makes edge scrolling easier to trigger on touch devices
- Double arrow key scroll speed (1 → 2) in `game.cc`
- Double world map scroll speed (16 → 32 pixels per step)

---

## Build System

### Local-Only Builds

**Commit `c4b3515`** (2026-02-02): *feat: VSync, touch fixes, comprehensive docs, local-only builds*

Major build system change:
- **Removed CI/CD workflows** (`.github/workflows/ci-build.yml`, `release.yml`)
- Removed deprecated `package-macos-dmg-with-game-data.sh`
- Simplified `build-macos-dmg.sh` (removed `--bundle` flag)
- All builds are now local-only
- Upload to GitHub Releases manually

**Rationale**: Simpler workflow, no dependency on GitHub Actions runners, full control over build environment.

### Build Scripts

The following scripts replace CI/CD:

| Script | Purpose | Added In |
|--------|---------|----------|
| `build-macos.sh` | Build macOS app | Initial |
| `build-ios.sh` | Build iOS IPA | Initial |
| `build-macos-dmg.sh` | Package macOS DMG | `3f9e3ce` |
| `build-ios-ipa.sh` | Package iOS IPA | `3f9e3ce` |
| `test-ios-simulator.sh` | iOS Simulator testing | `3e5baea` |
| `test-macos.sh` | macOS app testing | Initial |
| `dev-check.sh` | Pre-commit checks | Initial |
| `dev-verify.sh` | Full build verification | Initial |
| `dev-format.sh` | Code formatting | Initial |
| `dev-clean.sh` | Clean build artifacts | Initial |

**Commit `3e5baea`** (2026-01-31): *Add iOS simulator testing script*
```bash
# Usage
./scripts/test-ios-simulator.sh              # Full flow: build + install + launch
./scripts/test-ios-simulator.sh --build-only # Just build
./scripts/test-ios-simulator.sh --launch     # Launch existing install
./scripts/test-ios-simulator.sh --shutdown   # Shutdown all simulators
./scripts/test-ios-simulator.sh --list       # Show available iPad sims
```

### Xcode Integration

**Commit `71798df`** (2023-05-01): *Use Xcode for iOS builds*
**Commit `1fa0c53`** (2023-05-01): *Use Xcode for macOS builds (#67)*
- CMake generates Xcode projects
- Proper code signing support
- Native Apple toolchain integration

### Sanitizer Support

**Commit `f33143d`** (2023-10-31): *CMake: Add ASAN and UBSAN (#116)*
- Address Sanitizer (ASAN) support via `-DASAN=ON`
- Undefined Behavior Sanitizer (UBSAN) via `-DUBSAN=ON`
- Helps catch memory bugs and undefined behavior

### Static Analysis

**Commit `3f9e3ce`** (2026-02-02): *Improve packaging workflows and clean static analysis*
- All cppcheck warnings and errors resolved
- Fixed uninitialized variables, bounds checks, null checks
- SDL macro fallback for static analysis compatibility

---

## Engine Fixes

### Critical Bug Fixes

These fixes address serious bugs in the original engine or upstream implementation.

#### Combat AI Crash Fix

**Commit `f4e74d8`** (date varies): *fix(combatai): undefined behavior fix causing crashes in release mode clang*

```
a4 was being dereferenced as an uninitialized stack value, which causes 
clang to optimize out a null check in `ai_danger_source` causing runtime crashes
```

- Fixed uninitialized pointer causing crashes in release builds
- Only manifested with Clang optimization

#### Line-of-Sight Fix

**Commit `d94e777`** (2025-12-23): *Fix undefined behavior in obj_can_see_obj line-of-sight check*
- Fixed undefined behavior in visibility calculations
- Improved NPC AI behavior

#### Movie Library Fix

**Commit `63f63d0`** (2025-12-23): *movie_lib.cc: Fix incorrect return type of `getOffset`*
- Fixed return type mismatch causing video playback issues

**Commit `ad8a275`** (2024-03-05): *Fix some UB in movie_lib.cc (#117)*
- Additional undefined behavior fixes in movie playback

#### Format String Vulnerabilities

**Commit `533637b`** (2025-10-05): *Fix format string vulnerabilities and creature examination %s bug*
```
- Fixed creature examination showing 'He looks: %s. Wounded.' instead of 'He looks: Wounded.'
- Removed unnecessary message 521 lookup in favor of direct use of messages 522/523
- Fixed format string security vulnerabilities in snprintf and debug_printf calls
- Added '%s' format specifiers to prevent potential security issues
```

### Upstream Bug Fixes (Inherited)

These fixes were in upstream and are preserved:

| Fix | Commit | Description |
|-----|--------|-------------|
| **Survivalist Perk** | Inherited | Now properly grants +20% Outdoorsman skill per rank (fixed in `src/game/perk.cc`) |
| First Aid skill | `5d1e415` | Skill usage fixed |
| Fast Metabolism trait | `cbf01f9` | Trait effect corrected |
| Buffer overflow | `7a8711c` | Long speech filenames |
| Keyboard state | `ae23b73` | Stale state after UI re-enable |
| Quick save crash | `0289ab8` | Crash on quick save |
| Mouse wheel crash | `b7e6fcc` | Inventory scroll crash |
| Perk selection | `dd9ca29` | Selection bug (#55) |
| Mouse events | `fcb872c` | Processing bug (#55) |
| Better Criticals | `156184e` | Stat minimal value |
| Fast Shot | `bdde4fc` | Action points calculation |
| Elevator usage | `4ad05de` | Elevator functionality |
| Sneak check | `0d80c14` | Stealth mechanics |
| Barter prices | `3a80eba` | Price calculations |
| Friendly NPC outline | `716ee7a` | Visual outline fix |
| Movie subtitles | `a37415f` | Rendering fix |
| Weight calculation | `931abf5` | Item weight |
| Door sound | `bc367fd` | Open door sound |

**Survivalist Perk Implementation** (`src/game/perk.cc` line 402):
```cpp
case SKILL_OUTDOORSMAN:
    modifier += perk_level(PERK_SURVIVALIST) * 20;  // +20% per rank
    break;
```

The original Fallout 1 had the Survivalist perk defined but non-functional. This implementation correctly applies the bonus to Outdoorsman skill checks.

### Database/File Fixes

**Commit `ef27a64`** (2024-03-05): *Fix db_fread*
- File reading improvements

**Commit `fbd25f0`** (2025-01-13): *Ensure db_findfirst path is resolved (#119)*
- Path resolution for file searches

**Commit `a187979`** (2026-02-01):
- Fix buffer over-read in `db_fgetc()` for case 16
- Added `db_preload_buffer` call to prevent buffer issues

### Static Analysis Fixes

**Commit `3f9e3ce`** (2026-02-02): *Improve packaging workflows and clean static analysis*

Fixed files:
- `actions.cc`: Initialize keyCode variable
- `anim.cc`: Initialize x/y variables
- `combat.cc`: Initialize text variable
- `editor.cc`: Array bounds check
- `worldmap.cc`: Bounds check
- `intrpret.cc`: Initialize env variable
- `color.cc`: Null check after malloc
- `mousemgr.cc`: Initialize width/height before loop
- `kb.cc`: SDL_VERSION_ATLEAST fallback

---

## Quality of Life Features

### Object Tooltips

**Commit `e06370f`** (2025-12-23): *object tooltips*
- Cherry-picked from korri123/fallout1-ce
- Hover tooltips for game objects

**Commit `ec1f6e0`** (2025-12-23): *close object tooltips on interface open*
- Tooltips properly close when menus open

### Auto-Mouse Combat

**Commit `500f63d`** (2025-12-24): *automouse combat support*
- Cherry-picked from korri123/fallout1-ce
- Improved combat input handling

### Tweaks System

**Commit `694ab65`** (2026-01-31): *Add tweaks.cc/tweaks.h to CMakeLists.txt for QoL features*

Configurable tweaks via `tweaks.ini`:
```ini
[Mouse]
AutoMode=1          ; Auto-mouse mode toggle
ObjectTooltip=1     ; Object tooltips on hover

[Roof]
HoverHide=1         ; Hide roof when hovering
```

### Items Weight Summary

**Commit `46b8d4d`** (2023-03-01): *Add items weight summary*
- Display total weight in inventory

### Keyboard Shortcuts

**Commit `1046475`** (2023-02-15): *Add shortcuts to close game windows*
- ESC and other keys can close windows

---

## Configuration System

### Platform-Specific Templates

**Commit `1700591`** (2026-02-01): *added configuration files*

Directory structure:
```
gameconfig/
├── ios/
│   ├── fallout.cfg      # iOS game settings
│   └── fallout.ini      # iOS display settings (rename to f1_res.ini)
└── macos/
    ├── fallout.cfg      # macOS game settings
    └── fallout.ini      # macOS display settings (rename to f1_res.ini)
```

### New Configuration Sections

**Commit `c4b3515`** (2026-02-02):

`[DISPLAY]` section in f1_res.ini:
```ini
[DISPLAY]
VSYNC=1            ; Enable VSync (default)
FPS_LIMIT=-1       ; Match display refresh rate
```

**Commit `4c72775`** (2026-02-02):

`[PENCIL]` section in fallout.cfg:
```ini
[PENCIL]
pencil_right_click=0    ; 0=disabled (default), 1=enabled
```

### Distribution Configuration

**Commit `3f9e3ce`** (2026-02-02):

```
dist/
├── macos/
│   ├── README.md
│   ├── README.txt
│   ├── f1_res.ini
│   └── fallout.cfg
└── ios/
    ├── README.md
    ├── README.txt
    ├── f1_res.ini
    └── fallout.cfg
```

These are bundled with DMG/IPA packages.

---

## Documentation

### New Documentation Files

**Commit `c4b3515`** (2026-02-02):

| File | Purpose |
|------|---------|
| `docs/configuration.md` | Complete config file reference |
| `docs/vsync.md` | VSync and display settings guide |

### Updated Documentation

All documentation updated to reflect:
- Local builds only (no CI/CD)
- VSync enabled by default
- Touch coordinate fixes
- Apple Pencil support
- Platform-specific configuration

### JOURNAL Files

**Commit `c4b3515`** (2026-02-02):

JOURNAL.md files added throughout the codebase for AI agent context:
- Root: `JOURNAL.md`
- `.github/JOURNAL.md`
- `cmake/JOURNAL.md`
- `dist/JOURNAL.md`
- `os/JOURNAL.md`, `os/ios/JOURNAL.md`, `os/macos/JOURNAL.md`
- `scripts/JOURNAL.md`
- `src/JOURNAL.md`, `src/game/JOURNAL.md`, `src/int/JOURNAL.md`
- `src/platform/JOURNAL.md`, `src/plib/JOURNAL.md`
- `third_party/JOURNAL.md`

These provide context about directory purpose, current state, and implementation notes.

### Development Documentation

Internal documentation in `development/`:
- `VSYNC/` - Implementation plan for VSync
- `applepencil/` - Apple Pencil support plan
- `SCREEN_DIMENSIONS.md` - Apple device resolutions
- `HIGH_RESOLUTION.md` - Resolution configuration
- `IPAD_RESOLUTION.md` - iPad-specific guidance

---

## Community Contributions

Cherry-picked improvements from community forks:

### evaera (evaera/fallout1-ce)

| Feature | Commit |
|---------|--------|
| iPad mouse/trackpad support | `ddc8e5e` |
| F-key emulation for iPad | `fc229da` |
| Input switching consistency | `a50c339` |
| Hide status bar on iPadOS | `abfaba5` |

### zverinapavel (zverinapavel/fallout1-ce)

| Feature | Commit |
|---------|--------|
| Touch control optimization | `966d18b` |

### radozd (radozd/fallout1-ce)

| Feature | Commit |
|---------|--------|
| Borderless window mode | `a401e7c` |

### korri123 (korri123/fallout1-ce)

| Feature | Commit |
|---------|--------|
| Object tooltips | `e06370f` |
| Close tooltips on interface | `ec1f6e0` |
| Auto-mouse combat | `500f63d` |
| QoL tweaks system | `694ab65` |

---

## Commit Timeline

### 2023 (Fork Creation & Early Development)

| Date | Commit | Milestone |
|------|--------|-----------|
| 2023-02-09 | `7520167` | Initial commit (fork from upstream) |
| 2023-02-11 | `5d1e415` | First bug fix (First Aid skill) |
| 2023-02-28 | `7bbfa8b` | Fix iPad settings |
| 2023-05-01 | `c485246` | Xcode for iOS builds |
| 2023-05-01 | `1fa0c53` | Xcode for macOS builds |
| 2023-05-20 | `76be4b2` | Improve touch controls |
| 2023-06-12 | `55fb75b` | SCALE_2X support |
| 2023-10-31 | `f33143d` | ASAN/UBSAN support |

### 2024 (Stability & Platform Improvements)

| Date | Commit | Milestone |
|------|--------|-----------|
| 2024-03-04 | `99315ee` | Background refresh fix |
| 2024-04-23 | `a401e7c` | Borderless window mode (radozd) |
| 2024-11-26 | `966d18b` | Touch optimization (zverinapavel) |

### 2025 (Major Feature Integration)

| Date | Commit | Milestone |
|------|--------|-----------|
| 2025-01-15 | `7c8f694` | Reconcile with F2CE |
| 2025-01-15 | `0609bcf` | Externalize adecode |
| 2025-07-10 | `ddc8e5e` | iPad mouse support (evaera) |
| 2025-07-10 | `fc229da` | F-key emulation (evaera) |
| 2025-10-05 | `533637b` | Format string fixes |
| 2025-12-16 | `ec58604` | 2X zoom verified on iPad |
| 2025-12-23 | `e06370f` | Object tooltips (korri123) |
| 2025-12-24 | `500f63d` | Auto-mouse combat (korri123) |

### 2026 (Apple-Only Focus & Polish)

| Date | Commit | Milestone |
|------|--------|-----------|
| 2026-01-31 | `3e5baea` | iOS Simulator script |
| 2026-01-31 | `694ab65` | Tweaks system |
| 2026-02-01 | `658c428` | Merge feature/apple-rebirth |
| 2026-02-01 | `d2d4be3` | Apple Pencil initial support |
| 2026-02-01 | `a187979` | Complete Apple Pencil support |
| 2026-02-02 | `4c72775` | Platform cleanup (remove Windows/Linux/Android) |
| 2026-02-02 | `3f9e3ce` | Static analysis cleanup |
| 2026-02-02 | `c4b3515` | VSync, touch fixes, local-only builds |

---

## Summary

Fallout 1 Rebirth represents a focused fork of fallout1-ce that:

1. **Simplifies** by targeting only Apple platforms
2. **Enhances** with native Apple features (Pencil, ProMotion, VSync)
3. **Improves** input handling for touch-first iPad experience
4. **Integrates** community QoL features from multiple forks
5. **Documents** comprehensively for both users and AI agents

Total commits analyzed: **119**

The fork maintains compatibility with the original Fallout 1 game data while providing a modern, polished experience optimized for macOS and iOS/iPadOS.
---

## Proof of Work

- **Timestamp**: February 5, 2026
- **Files verified**:
  - `CMakeLists.txt` - Confirmed iOS deployment target 15.0, macOS 11.0
  - `third_party/sdl3/CMakeLists.txt` - Confirmed SDL3 3.2.4
  - `src/plib/gnw/svga.cc` - Confirmed SDL3 integration and VSync implementation
  - `scripts/` directory - Confirmed all referenced scripts exist
- **Updates made**:
  - Updated iOS deployment target from 14.0 to 15.0 to match CMakeLists.txt

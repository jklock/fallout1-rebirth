# High Resolution Support Plan

## Status: Research Complete - Implementation Required

**Date**: February 4, 2026  
**Priority**: High  
**Complexity**: Significant (300+ code changes required)

---

## Executive Summary

High resolution support in Fallout 1 Rebirth (and upstream fallout1-ce) is **incomplete**. While the SDL rendering layer can output to any resolution, the game engine internally has **289+ hardcoded `640` values** that cause crashes and rendering issues at resolutions above 640×480.

The documentation claims "arbitrary resolution support" which is **technically misleading** - the window can be any size, but the game logic operates at 640×480.

---

## Current Behavior

### What Works
- **640×480 logical resolution** with any window/display size
- **SCALE_2X=1**: Renders at 640×480, then 2x integer scales to 1280×960 physical
- **Fullscreen desktop mode**: Game fills screen with letterboxing

### What Doesn't Work
- **SCR_WIDTH > 640 or SCR_HEIGHT > 480** causes crashes in `map_scroll()`, buffer overflows
- **"See more of the game world"** - cannot increase logical resolution
- **The documentation** incorrectly describes SCALE_2X behavior

### The Crash: map_scroll() Buffer Overflow

```cpp
// src/game/map.cc line ~755
int width = scr_size.lrx - scr_size.ulx + 1;  // 1024 at high-res
int pitch = width;                              // 1024

// But display_buf was allocated for screenGetWidth() which may be different!
// And many other buffers use hardcoded 640 for their pitch calculations

for (int y = 0; y < height; y++) {
    memmove(dest, src, width);  // Copies 1024 bytes but other buffers expect 640
    dest += step;
    src += step;
}
```

---

## Root Cause Analysis

### 1. Hardcoded Dimensions Throughout Codebase

| File | Issue |
|------|-------|
| `src/game/options.cc:821` | `int windowWidth = 640;` |
| `src/game/gmovie.cc` | Buffer pitches hardcoded to 640 |
| `src/game/intface.cc` | Interface bar fixed at 640 wide |
| `src/game/tile.cc` | Tile buffer calculations assume 640 |
| `src/game/display.cc` | Display buffer pitch = 640 |
| `src/plib/gnw/svga.cc` | Various internal buffers |
| **Total**: 289+ occurrences of hardcoded `640` |

### 2. SCALE_2X Actual Behavior vs Documentation

**Documentation claims:**
> `SCALE_2X=1` → Renders at (SCR_WIDTH/2) × (SCR_HEIGHT/2), then 2x scales

**Actual behavior in game.cc:**
```cpp
if (SCALE_2X == 1) {
    video_options.width = SCR_WIDTH / 2;
    video_options.height = SCR_HEIGHT / 2;
    
    // CLAMP to minimum 640x480!
    video_options.width = std::max(video_options.width, 640);
    video_options.height = std::max(video_options.height, 480);
}
```

So with `SCR_WIDTH=1024, SCR_HEIGHT=768, SCALE_2X=1`:
- After division: 512×384
- After clamping: **640×480** (the minimum)
- Result: Same as default!

### 3. Inconsistent Buffer Sizes

The crash occurs because:
1. `scr_size` is set from video_options (e.g., 1024×768)
2. `display_buf` is allocated at that size
3. But `tile_buf` and other buffers use hardcoded 640
4. `memmove()` in `map_scroll()` tries to copy 1024 bytes into a 640-byte-wide buffer

---

## Upstream Status

The upstream `alexbatalov/fallout1-ce` has **the same limitations**:

| Issue | Description |
|-------|-------------|
| #245 | "Character shows up on map when playing in high resolutions" |
| #223 | "Sanitizers found serious problems" (buffer overflows) |
| No fix | These issues remain open |

**The claim "high resolution support" in fallout1-ce is marketing, not reality.**

---

## Options for Resolution

### Option A: Document Limitation (Low Effort)
**Effort**: 1 hour  
**Impact**: No new functionality

- Update documentation to accurately describe 640×480 logical limit
- Remove misleading "arbitrary resolution" claims
- Document that SCALE_2X only affects display output, not game world visibility
- Users get 640×480 scaled to any size (crisp pixels)

### Option B: Partial Fix - Safe High Resolution (Medium Effort)
**Effort**: 2-3 days  
**Impact**: Moderate - may achieve 800×600 or 1024×768

1. **Audit all hardcoded 640 values**
2. **Create screen dimension functions**:
   ```cpp
   int gameGetLogicalWidth();   // replaces hardcoded 640
   int gameGetLogicalHeight();  // replaces hardcoded 480
   ```
3. **Replace top 50 most critical hardcoded values**
4. **Fix buffer allocation in map.cc, tile.cc, display.cc**
5. **Test at 1024×768 and 1280×960**

### Option C: Full High Resolution Support (High Effort)
**Effort**: 1-2 weeks  
**Impact**: High - true arbitrary resolution

1. **Replace all 289+ hardcoded dimension values**
2. **Refactor buffer management**:
   - Centralized buffer allocation based on logical resolution
   - Ensure all systems use consistent dimensions
3. **Update interface bar** to scale or expand
4. **Test all game systems** at multiple resolutions
5. **Update all documentation**

### Option D: Fork NMA Approach (Alternative)
**Effort**: Unknown  
**Impact**: Windows-only

The NMA High Resolution Patch uses a different approach (DLL injection) that might have different solutions. However, it's Windows-only and not applicable to iOS/macOS.

---

## Recommended Approach

**Phase 1: Document Accurately (Immediate)**
- Fix documentation to reflect actual 640×480 logical limit
- This is what users have now; be honest about it

**Phase 2: Investigate Partial Fix (This Week)**
- Identify the critical 20-30 hardcoded values that cause crashes
- Test if fixing just those enables 1024×768
- May be achievable with moderate effort

**Phase 3: Evaluate Full Fix (Future)**
- If Phase 2 succeeds, consider full refactoring
- This is a significant undertaking

---

## Implementation Tasks (Phase 2)

### Task 1: Create Dimension Helper Functions
```cpp
// src/game/game.h
int gameGetLogicalWidth();   // Currently-active logical width
int gameGetLogicalHeight();  // Currently-active logical height

// src/game/game.cc
static int s_logicalWidth = 640;
static int s_logicalHeight = 480;

int gameGetLogicalWidth() { return s_logicalWidth; }
int gameGetLogicalHeight() { return s_logicalHeight; }
```

### Task 2: Fix Critical Buffer Calculations

**map.cc** - Fix display buffer pitch:
```cpp
// Line ~755: Use consistent width
int width = gameGetLogicalWidth();  // NOT scr_size
int pitch = width;
```

**tile.cc** - Fix tile buffer:
```cpp
// Allocate based on actual resolution
int bufWidth = gameGetLogicalWidth();
int bufHeight = gameGetLogicalHeight() - INTERFACE_BAR_HEIGHT;
```

**options.cc** - Fix window width:
```cpp
// Line 821: Replace hardcoded 640
int windowWidth = gameGetLogicalWidth();
```

### Task 3: Test Matrix

| Resolution | SCALE_2X | Expected Result |
|------------|----------|-----------------|
| 640×480 | 0 | Works (baseline) |
| 640×480 | 1 | Works (1280×960 output) |
| 800×600 | 0 | Test after fixes |
| 1024×768 | 0 | Test after fixes |
| 1280×960 | 0 | Test after fixes |

---

## Files Requiring Changes

Based on grep analysis of hardcoded `640`:

| Priority | File | Occurrences | Notes |
|----------|------|-------------|-------|
| P0 | src/game/map.cc | 8 | Critical - causes crash |
| P0 | src/game/tile.cc | 12 | Critical - buffer sizes |
| P0 | src/game/display.cc | 6 | Critical - display buffer |
| P1 | src/game/intface.cc | 15 | Interface bar |
| P1 | src/game/options.cc | 4 | Options menu |
| P2 | src/game/gmovie.cc | 6 | Movie playback |
| P2 | src/game/worldmap.cc | 8 | World map |
| P2 | src/game/loadsave.cc | 4 | Save/load screens |
| P3 | Other files | ~226 | Various UI elements |

---

## Current Workaround

For iPad users wanting "more visible game world" - **this is not currently possible**.

The workaround is to use crisp 2x scaled pixels at 640×480 logical:

```ini
[MAIN]
SCR_WIDTH=1280
SCR_HEIGHT=960
SCALE_2X=1
; Results in 640×480 logical, 1280×960 output
; Sharp pixels, fills iPad screen nicely
; But same game world visibility as original
```

Or simply no f1_res.ini (defaults to 640×480 fullscreen).

---

## Documentation Updates Needed

1. **development/HIGH_RESOLUTION.md** - Fix SCALE_2X description
2. **development/IPAD_RESOLUTION.md** - Clarify logical vs physical
3. **development/SCREEN_DIMENSIONS.md** - Note 640×480 logical limit
4. **docs/configuration.md** - Accurate resolution documentation
5. **gameconfig/ios/f1_res.ini** - Fix comments

---

## References

- Upstream issue #245: https://github.com/alexbatalov/fallout1-ce/issues/245
- Upstream issue #223: https://github.com/alexbatalov/fallout1-ce/issues/223
- NMA High Resolution Patch: https://www.nma-fallout.com/resources/fallout-1-high-res-patch.52/

---

## Appendix: Hardcoded 640 Locations

Run this to find all occurrences:
```bash
grep -rn "640" src/ --include="*.cc" --include="*.h" | grep -v "//.*640" | wc -l
```

Current count: **289+ occurrences** across 50+ files.

# Community Edition Pull Requests (CEPR)

This document outlines fixes and improvements from Fallout 1 Rebirth that can be contributed back to the upstream [fallout1-ce](https://github.com/alexbatalov/fallout1-ce) repository.

All changes listed here are **platform-agnostic** and benefit all platforms (Windows, Linux, macOS, iOS, Android).

---

## Static Analysis Fixes

These fixes resolve issues identified by cppcheck static analysis and improve code quality across all platforms.

### PR 1: Initialize Uninitialized Variables

**Title:** Fix uninitialized variable warnings in game engine

**Files Affected:**
- `src/game/actions.cc` - Initialize `keyCode` to 0 in `pick_object()`
- `src/game/anim.cc` - Initialize `x` and `y` to 0 before conditional blocks
- `src/game/combat.cc` - Initialize `text` buffer with `text[0] = '\0'`
- `src/game/sfxlist.cc` - Use brace initialization for `dummy` struct
- `src/int/intrpret.cc` - Initialize `jmp_buf env` with `= {}`
- `src/int/mousemgr.cc` - Initialize `width` and `height` to 0 before loop

**Description:**
Static analysis identified several uninitialized variable warnings. These could lead to undefined behavior in edge cases. All variables are now properly initialized.

**Rationale:**
Prevents potential undefined behavior and removes static analysis warnings. Changes are minimal and low-risk.

---

### PR 2: Fix Array Bounds Access

**Title:** Fix array out-of-bounds access in editor and worldmap

**Files Affected:**
- `src/game/editor.cc` - Add `failedIndex` tracking to prevent OOB access in cleanup loop
- `src/game/worldmap.cc` - Add bounds check `if (entrance >= 7) return;` before array access

**Description:**
Static analysis identified array out-of-bounds access. In editor.cc, the loop variable `index` could be 5 after the for loop, causing access to `down[5]` which is out of bounds for a 5-element array. In worldmap.cc, `entrance` could be 7 after the loop, accessing `brnpos[7]`.

**Rationale:**
Prevents crashes and undefined behavior from array overflows.

---

### PR 3: Add Null Pointer Check After malloc

**Title:** Add null check after malloc in colorPushColorPalette

**Files Affected:**
- `src/plib/color/color.cc` - Add null check and error return after malloc

**Description:**
The `colorPushColorPalette()` function allocates memory but did not check if allocation succeeded before using the pointer. Now returns `false` with error string on allocation failure.

**Rationale:**
Prevents null pointer dereference if memory allocation fails.

---

### PR 4: SDL Version Macro Compatibility

**Title:** Add SDL_VERSION_ATLEAST fallback for static analysis

**Files Affected:**
- `src/plib/gnw/kb.cc` - Add `#ifndef SDL_VERSION_ATLEAST` fallback definition

**Description:**
Static analysis tools that don't process includes may fail on SDL_VERSION_ATLEAST macro. Add a fallback definition that defaults to 0 when the macro is not defined.

**Rationale:**
Allows static analysis tools to process the file without errors while maintaining correct behavior when compiled.

---

## Bug Fixes

### PR 5: Fix Undefined Behavior in movie_lib.cc

**Title:** Fix incorrect return type of getOffset function

**Files Affected:**
- `src/movie_lib.cc`

**Description:**
The `getOffset` function had an incorrect return type that could cause undefined behavior.

**Commits:**
- `63f63d0` movie_lib.cc: Fix incorrect return type of `getOffset`

**Rationale:**
Corrects a type mismatch that could cause issues on different platforms.

---

### PR 6: Fix Undefined Behavior in Line-of-Sight Check

**Title:** Fix undefined behavior in obj_can_see_obj

**Files Affected:**
- `src/game/object.cc`

**Description:**
The line-of-sight check in `obj_can_see_obj` had undefined behavior that could cause incorrect results.

**Commits:**
- `d94e777` Fix undefined behavior in obj_can_see_obj line-of-sight check

**Rationale:**
Ensures consistent behavior across platforms and compilers.

---

### PR 7: Fix Format String Vulnerabilities

**Title:** Fix format string vulnerabilities and creature examination bug

**Files Affected:**
- Multiple files with format string issues

**Description:**
Fixed format string vulnerabilities where user-controlled strings were passed directly to printf-style functions. Also fixed a `%s` bug in creature examination.

**Commits:**
- `533637b` Fix format string vulnerabilities and creature examination %s bug

**Rationale:**
Security improvement and bug fix for creature examination display.

---

## Quality of Life Improvements

### PR 8: Borderless Windowed Mode

**Title:** Support for non-exclusive fullscreen (borderless windowed)

**Files Affected:**
- `src/plib/gnw/svga.cc` (or equivalent graphics initialization)

**Description:**
Adds support for borderless windowed mode, which provides a better user experience on modern operating systems by allowing seamless window switching without the lag of exclusive fullscreen.

**Commits:**
- `a401e7c` support for non-exclusive fullscreen mode aka windowed borderless

**Rationale:**
Modern UX improvement that benefits all desktop platforms.

---

### PR 9: Object Tooltips

**Title:** Add object tooltips feature

**Files Affected:**
- `src/game/object.cc`
- `src/game/intface.cc`

**Description:**
Adds tooltips when hovering over objects, and closes tooltips when interface opens.

**Commits:**
- `e06370f` object tooltips
- `ec1f6e0` close object tooltips on interface open

**Rationale:**
Quality of life improvement for gameplay.

---

### PR 10: Auto-Mouse Combat Support

**Title:** Auto-mouse combat support

**Files Affected:**
- `src/game/combat.cc`

**Description:**
Implements auto-mouse support during combat for improved input handling.

**Commits:**
- `500f63d` automouse combat support

**Rationale:**
Improves combat input handling.

---

## Notes on Platform-Specific Changes

The following changes from this fork are **NOT suitable for upstream** as they are Apple-platform specific:

- Apple Pencil support (iOS only)
- Touch input optimization (iOS only)  
- F-key emulation for iPad
- iOS path handling
- macOS notarization workflow
- iOS Simulator testing scripts

These should remain in this fork or be contributed with proper platform guards.

---

## How to Contribute

For each PR above:

1. Create a new branch from `upstream/main`
2. Cherry-pick or manually apply the relevant changes
3. Ensure all platforms still build and tests pass
4. Submit PR with clear description referencing this document

When submitting to upstream, reference the original commit hashes from this fork for attribution.

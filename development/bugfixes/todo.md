# TODO: iPad Polish Pass (Bugs 1–6)

Last updated: 2026-02-07

**Line numbers are exact as of current repo state.** If any file shifts before
implementation, re-check with `nl -ba` and adjust the patch locations.

---

## Change Set A — iOS Size-Change Handling (Bugs 1 + 6)

1) **Change `handleWindowSizeChanged` signature to return `bool`.**
- File: `/Volumes/Storage/GitHub/fallout1-rebirth/src/plib/gnw/svga.h` line 30
- Change:
  - `void handleWindowSizeChanged();` → `bool handleWindowSizeChanged();`
- Why:
  - We need a deterministic “did size actually change?” signal so we can
    avoid unnecessary refreshes and iOS renderer rebuilds.
- Docs:
  - SDL high-DPI event guidance: https://wiki.libsdl.org/SDL3/README-highdpi

2) **Track iOS pixel size to debounce updates.**
- File: `/Volumes/Storage/GitHub/fallout1-rebirth/src/plib/gnw/svga.cc` lines 32–42
- Change:
  - Add cached pixel-size statics in the iOS section:
    - `static int g_iOS_last_window_pw = 0;`
    - `static int g_iOS_last_window_ph = 0;`
- Why:
  - Prevent repeated size-change events from triggering heavy redraws.
- Docs:
  - SDL high-DPI: https://wiki.libsdl.org/SDL3/README-highdpi

3) **Make iOS size-change handling lightweight.**
- File: `/Volumes/Storage/GitHub/fallout1-rebirth/src/plib/gnw/svga.cc` lines 469–475
- Change:
  - Replace `handleWindowSizeChanged()` implementation:
    - On iOS: only update dest rect if pixel size changed; **do not** rebuild renderer.
    - On non-iOS: keep existing renderer rebuild path.
    - Return `true` only when size actually changed.
- Why:
  - Renderer rebuilds + full refresh cause visible stutter/audio glitching.
- Docs:
  - SDL high-DPI: https://wiki.libsdl.org/SDL3/README-highdpi

4) **Gate refreshes on actual size change.**
- File: `/Volumes/Storage/GitHub/fallout1-rebirth/src/plib/gnw/input.cc` lines 1177–1179
- Change:
  - Replace:
    - `handleWindowSizeChanged(); win_refresh_all(&scr_size);`
  - With:
    - `if (handleWindowSizeChanged()) { /* refresh logic */ }`
- Why:
  - Avoid redundant refreshes on repeated iOS pixel-size events.
- Docs:
  - SDL event model: https://wiki.libsdl.org/SDL3/SDL_EventType

5) **Track on-screen keyboard visibility to avoid refresh spikes during animations.**
- File: `/Volumes/Storage/GitHub/fallout1-rebirth/src/plib/gnw/input.cc`
  - Add statics near line 133:
    - `static bool g_iOS_keyboard_visible = false;`
    - `static unsigned int g_iOS_keyboard_toggle_time = 0;` (ms via `get_time()`)
  - Add event cases near line 1166:
    - `SDL_EVENT_SCREEN_KEYBOARD_SHOWN` → set visible true + timestamp
    - `SDL_EVENT_SCREEN_KEYBOARD_HIDDEN` → set visible false + timestamp
  - In the size-change case (line 1177), skip `win_refresh_all` if keyboard
    is visible *and* toggle time is within a small debounce window (e.g. 500ms).
- Why:
  - Keyboard show/hide animations can fire repeated size-change events; avoiding
    full refresh prevents stutter.
- Docs:
  - SDL event list: https://wiki.libsdl.org/SDL3/SDL_EventType
  - SDL screen keyboard status: https://wiki.libsdl.org/SDL3/SDL_ScreenKeyboardShown

6) **Ensure screen keyboard behavior is deterministic when text input starts.**
- File: `/Volumes/Storage/GitHub/fallout1-rebirth/src/plib/gnw/input.cc` lines 1360–1362
- Change:
  - Add (iOS-only) `SDL_SetHint(SDL_HINT_ENABLE_SCREEN_KEYBOARD, "auto");`
    immediately before `SDL_StartTextInput(gSdlWindow);`
- Why:
  - SDL requires this hint to be set before `SDL_StartTextInput()` if behavior
    should be explicit and consistent.
- Docs:
  - SDL hint: https://wiki.libsdl.org/SDL3/SDL_HINT_ENABLE_SCREEN_KEYBOARD
  - SDL_StartTextInput: https://wiki.libsdl.org/SDL3/SDL_StartTextInput

---

## Change Set B — Arrow-Key Tearing (Bug 2)

7) **Add an iOS-only full redraw scroll helper.**
- File: `/Volumes/Storage/GitHub/fallout1-rebirth/src/game/map.h` line 110
- Change:
  - Add declaration: `int map_scroll_and_full_refresh(int dx, int dy);`
- Why:
  - Keep mouse-edge scroll fast while forcing a clean redraw for keyboard scroll.

8) **Implement `map_scroll_and_full_refresh`.**
- File: `/Volumes/Storage/GitHub/fallout1-rebirth/src/game/map.cc` after line 812
- Change:
  - Add helper that calls `map_scroll(dx, dy)` and, if it returns 0:
    - `tile_refresh_display();`
    - `win_draw(display_win);`
    - `renderPresent();` (iOS only)
- Why:
  - Partial refresh + memmove can leave shear artifacts on iOS.

9) **Use full-refresh path for arrow keys on iOS only.**
- File: `/Volumes/Storage/GitHub/fallout1-rebirth/src/game/game.cc` lines 883–894
- Change:
  - Wrap arrow key cases with `#if __APPLE__ && TARGET_OS_IOS` and call
    `map_scroll_and_full_refresh(...)` there; keep `map_scroll(...)` on other platforms.
- Why:
  - Eliminate tearing for keyboard-driven movement without slowing mouse scroll.

---

## Change Set C — Touch/Pencil Offsets (Bug 3)

10) **Track in-bounds start and last valid position per touch.**
- File: `/Volumes/Storage/GitHub/fallout1-rebirth/src/plib/gnw/touch.cc` lines 33–43
- Change:
  - Extend `Touch` struct with:
    - `bool started_in_bounds;`
    - `TouchLocation lastInBounds;`
- Why:
  - Out-of-bounds starts should be ignored; drags that leave bounds should clamp.

11) **Make `convert_touch_to_logical` return in-bounds state and avoid clamping starts.**
- File: `/Volumes/Storage/GitHub/fallout1-rebirth/src/plib/gnw/touch.cc` lines 98–137
- Change:
  - Convert to `static bool convert_touch_to_logical(..., int* out_x, int* out_y)`.
  - On iOS: return `iOS_windowToGameCoords(...)` directly; **do not clamp** in this helper.
  - On non-iOS: keep clamping (or return true if in bounds after conversion).
- Why:
  - Clamping out-of-bounds starts creates false edge hits and offsets.

12) **Ignore out-of-bounds touch starts; clamp move to last in-bounds.**
- File: `/Volumes/Storage/GitHub/fallout1-rebirth/src/plib/gnw/touch.cc` lines 159–200
- Change:
  - In `touch_handle_start`, if `convert_touch_to_logical` returns false:
    - do not mark the touch as used (ignore the start).
  - If in bounds:
    - set `started_in_bounds = true` and `lastInBounds = startLocation`.
  - In `touch_handle_move`, if `started_in_bounds` and new location is out of bounds:
    - clamp to `lastInBounds` instead of snapping to edges.
- Why:
  - Ensures taps in letterbox/pillarbox bars do not create off-by-one hits.

---

## Change Set D — whoHitMe Audit (Bug 4)

13) **Replace direct `whoHitMe` clears with setter for consistency.**
- File: `/Volumes/Storage/GitHub/fallout1-rebirth/src/game/map.cc` line 895
- Change:
  - `obj_dude->data.critter.combat.whoHitMe = NULL;` → `critter_set_who_hit_me(obj_dude, NULL);`
- Why:
  - Ensures all assignments flow through the validated path.

14) **Replace direct `whoHitMe` clears in proto initialization.**
- File: `/Volumes/Storage/GitHub/fallout1-rebirth/src/game/proto.cc` line 706
- Change:
  - `obj->data.critter.combat.whoHitMe = NULL;` → `critter_set_who_hit_me(obj, NULL);`
- Why:
  - Keeps assignment semantics consistent across combat initialization.

15) **Audit any remaining non-null direct assignments.**
- Files to review (line numbers from current audit):
  - `/Volumes/Storage/GitHub/fallout1-rebirth/src/game/combat.cc` lines 1666–1672
  - `/Volumes/Storage/GitHub/fallout1-rebirth/src/game/object.cc` lines 585–591
- Change:
  - If any non-null assignment bypasses the setter, route it through
    `critter_set_who_hit_me()` or apply equivalent validation.
- Why:
  - Prevents self/same-team targets from entering combat state during
    ladder/map transitions.

---

## Change Set E — iPad Dock Reveal Mitigation (Bug 5)

16) **Defer system edge gestures via SDL iOS hint.**
- File: `/Volumes/Storage/GitHub/fallout1-rebirth/src/plib/gnw/svga.cc` line 218
- Change:
  - Add (iOS-only) `SDL_SetHint(SDL_HINT_IOS_HIDE_HOME_INDICATOR, "2");`
    before `SDL_InitSubSystem(SDL_INIT_VIDEO)`.
- Why:
  - Defers system gestures at screen edges so the dock doesn’t appear on
    the first swipe/edge movement.
- Docs:
  - SDL hint: https://wiki.libsdl.org/SDL3/SDL_HINT_IOS_HIDE_HOME_INDICATOR

17) **Enable pointer lock (relative mouse mode) when a mouse/trackpad is in use.**
- File: `/Volumes/Storage/GitHub/fallout1-rebirth/src/plib/gnw/dxinput.cc`
  - Add `static bool g_iOS_relative_mouse_enabled = false;` near line 24.
  - In `dxinput_notify_mouse()` (lines 272–279):
    - If not enabled, call `SDL_SetWindowRelativeMouseMode(gSdlWindow, true)`
      and set flag based on return value.
  - In `dxinput_notify_touch()` (lines 283–289):
    - If enabled, disable relative mode with `SDL_SetWindowRelativeMouseMode(..., false)`
      and clear the flag.
- Why:
  - Relative mode enables pointer lock (`prefersPointerLocked`), preventing
    the system cursor from hitting the bottom edge (dock trigger).
- Docs:
  - SDL relative mouse: https://wiki.libsdl.org/SDL3/SDL_SetWindowRelativeMouseMode

18) **When relative mode is enabled, use relative deltas scaled to game space.**
- File: `/Volumes/Storage/GitHub/fallout1-rebirth/src/plib/gnw/dxinput.cc` lines 76–177
- Change:
  - If `g_iOS_relative_mouse_enabled`:
    - Use `SDL_GetRelativeMouseState(&rel_x, &rel_y)` instead of `SDL_GetMouseState`.
    - Convert relative deltas to game-space deltas by scaling using
      `iOS_getDestRect()` and the game resolution.
- Why:
  - Keeps pointer movement consistent while locked and avoids absolute-edge
    hits that trigger the dock.
- Docs:
  - SDL relative state: https://wiki.libsdl.org/SDL3/SDL_GetRelativeMouseState

19) **Do NOT rely on UIRequiresFullScreen as a fix.**
- File: `/Volumes/Storage/GitHub/fallout1-rebirth/os/ios/Info.plist` line 37
- Change:
  - No change unless all other mitigations fail; if tried, add
    `UIRequiresFullScreen = YES` with a rollback note.
- Why:
  - Apple documents this key as deprecated; it may not affect modern iPadOS.
- Docs:
  - Apple: https://developer.apple.com/documentation/BundleResources/Information-Property-List/UIRequiresFullScreen

---

## Post-Change Process — Create `validation.md`

After **all** changes above are implemented, create:
`/Volumes/Storage/GitHub/fallout1-rebirth/development/bugfixes/validation.md`
with the following structure:

1) **Build + Device Info**
- Commit/branch
- iPad model
- iPadOS version
- Input hardware (mouse/trackpad/Pencil)

2) **Validation Table (one row per bug)**
- Bug ID / Scenario
- Steps performed
- Expected result
- Actual result
- Pass/Fail

3) **Per-bug Notes**
- Bug 1: top-edge cursor stutter + audio glitch
- Bug 2: arrow key scroll tearing
- Bug 3: touch/Pencil edge clicks
- Bug 4: ladder self-attack
- Bug 5: dock reveal at bottom edge (mouse + touch)
- Bug 6: keyboard show/hide stutter

---

## Source Documentation Index
- SDL Event Types: https://wiki.libsdl.org/SDL3/SDL_EventType
- SDL High-DPI: https://wiki.libsdl.org/SDL3/README-highdpi
- SDL Start Text Input: https://wiki.libsdl.org/SDL3/SDL_StartTextInput
- SDL Screen Keyboard: https://wiki.libsdl.org/SDL3/SDL_ScreenKeyboardShown
- SDL Hint (Enable Screen Keyboard): https://wiki.libsdl.org/SDL3/SDL_HINT_ENABLE_SCREEN_KEYBOARD
- SDL Hint (Hide Home Indicator): https://wiki.libsdl.org/SDL3/SDL_HINT_IOS_HIDE_HOME_INDICATOR
- SDL Relative Mouse Mode: https://wiki.libsdl.org/SDL3/SDL_SetWindowRelativeMouseMode
- SDL Relative Mouse State: https://wiki.libsdl.org/SDL3/SDL_GetRelativeMouseState
- Apple UIRequiresFullScreen: https://developer.apple.com/documentation/BundleResources/Information-Property-List/UIRequiresFullScreen

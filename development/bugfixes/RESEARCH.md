# Bugfix Research Audit (All 6 Issues)

Last updated: 2026-02-07

## Scope
This audit documents all code interaction points for the six active bugs,
explains current behavior, shows how the proposed fixes change behavior, and
records SDL3/iOS references used to validate the approach.

## SDL3 + Apple Reference Notes (External)
- SDL_EventType includes window size, safe-area, and screen keyboard events.
  Source: https://wiki.libsdl.org/SDL3/SDL_EventType
- SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED is used to track backbuffer size changes
  on high-DPI displays; SDL guarantees this event and recommends using it to
  (re)size graphics context.
  Source: https://wiki.libsdl.org/SDL3/README-highdpi
- SDL_HINT_IOS_HIDE_HOME_INDICATOR controls home indicator and gesture
  deferral behavior on iPhone X+ (values 0/1/2).
  Source: https://wiki.libsdl.org/SDL3/SDL_HINT_IOS_HIDE_HOME_INDICATOR
- SDL_HINT_ENABLE_SCREEN_KEYBOARD controls when the on-screen keyboard shows
  while text input is active; must be set before SDL_StartTextInput().
  Source: https://wiki.libsdl.org/SDL3/SDL_HINT_ENABLE_SCREEN_KEYBOARD
- SDL_StartTextInput enables text input events and can show screen keyboard
  on some platforms; must be paired with SDL_StopTextInput().
  Source: https://wiki.libsdl.org/SDL_StartTextInput
- UIRequiresFullScreen is deprecated; iPadOS behavior varies by OS version and
  multitasking mode.
  Source: https://developer.apple.com/documentation/BundleResources/Information-Property-List/UIRequiresFullScreen
- Game Mode (iOS 18 / iPadOS 18) turns on automatically when you launch a game,
  minimizes background activity, and reduces controller/AirPods latency.
  Source: https://apps.apple.com/us/story/id1760172878
- preferredScreenEdgesDeferringSystemGestures indicates which edges give your
  app’s gestures precedence over system gestures.
  Source: https://learn.microsoft.com/en-us/dotnet/api/uikit.uiviewcontroller.preferredscreenedgesdeferringsystemgestures
- Pointer lock behavior is at the system’s discretion and may not always be
  granted; apps must observe lock changes.
  Source: https://developer.apple.com/videos/play/wwdc2020/10094/

---

## Bug 1: Cursor-at-top stutter + audio glitches

### Current Behavior (Code Path)
- Cursor hitting the top edge can cause the iOS status bar/safe-area change.
- SDL sends window size/pixel-size change events.
- The event handler rebuilds the renderer and forces a full refresh.

Interaction points (proof):
- Event handling and size-change reaction:
  - /Volumes/Storage/GitHub/fallout1-rebirth/src/plib/gnw/input.cc:1174-1180
- Renderer rebuild on size-change:
  - /Volumes/Storage/GitHub/fallout1-rebirth/src/plib/gnw/svga.cc:469-475
- iOS dest rect recompute:
  - /Volumes/Storage/GitHub/fallout1-rebirth/src/plib/gnw/svga.cc:44-94

### Proposed Fix (Outcome + Mechanism)
- Outcome: No stutter or audio glitching when pointer hits the top edge.
- Mechanism: On iOS, treat pixel-size change events as *layout-only*:
  update the iOS dest rect (and only if the pixel size actually changed),
  avoid destroying/recreating the renderer, and debounce `win_refresh_all()`.

### Comparison (Now vs Fix)
- Now: frequent SDL size events => renderer rebuild + full refresh => stalls.
- Fix: size events only update render destination => no heavy stalls.

### Remaining Validation
- Confirm that SDL is emitting repeated pixel size events during top-edge
  cursor movement and that the size actually toggles; one device run should
  confirm after fix.

---

## Bug 2: Tearing when using arrow keys to move cursor

### Current Behavior (Code Path)
- Arrow keys call `map_scroll()` (memmove + partial refresh).
- On iOS this partial update can leave a visible shear until a full redraw.

Interaction points (proof):
- Arrow key handling:
  - /Volumes/Storage/GitHub/fallout1-rebirth/src/game/game.cc:883-894
- Scroll implementation (memmove + partial refresh + win_draw):
  - /Volumes/Storage/GitHub/fallout1-rebirth/src/game/map.cc:713-812

### Proposed Fix (Outcome + Mechanism)
- Outcome: No tearing during arrow-key scroll.
- Mechanism: For keyboard-driven scroll only, force a full redraw (iOS-only),
  leaving the fast memmove path for mouse-edge scrolling.

### Comparison (Now vs Fix)
- Now: partial refresh can leave shear artifacts on iOS.
- Fix: forced full redraw for arrow keys ensures a clean frame each step.

### Remaining Validation
- Confirm tearing is gone only for keyboard scroll while mouse-edge scroll
  remains performant.

---

## Bug 3: Sporadic touch/Pencil click location errors

### Current Behavior (Code Path)
- Touch conversions on iOS use custom mapping; out-of-bounds touches are
  clamped to the nearest edge, which can shift hit-tests.

Interaction points (proof):
- Touch conversion + clamp on iOS:
  - /Volumes/Storage/GitHub/fallout1-rebirth/src/plib/gnw/touch.cc:98-137
- iOS window -> game coordinate conversion and in-bounds detection:
  - /Volumes/Storage/GitHub/fallout1-rebirth/src/plib/gnw/svga.cc:498-572
- Mouse conversion uses iOS_screenToGameCoords too:
  - /Volumes/Storage/GitHub/fallout1-rebirth/src/plib/gnw/dxinput.cc:96-161

### Proposed Fix (Outcome + Mechanism)
- Outcome: Touch/Pencil taps land accurately, especially near edges.
- Mechanism: If a touch *starts* out of bounds, ignore it (don’t clamp).
  If a touch starts in bounds but drifts out, clamp to last valid point.
  Unify mapping math for touch and mouse to avoid rounding mismatch.

### Comparison (Now vs Fix)
- Now: out-of-bounds touch starts clamp to edges, causing offsets.
- Fix: out-of-bounds starts are ignored; only in-bounds starts are tracked.

### Remaining Validation
- Edge taps on letterbox/pillarbox bars should never trigger false in-game
  clicks; one device run should confirm.

---

## Bug 4: Vault 15 self-attack regression (ladder transitions)

### Current Behavior (Code Path)
- There is an existing guard in `critter_set_who_hit_me()` preventing self
  targeting and same-team targeting, but not all paths necessarily use it.

Interaction points (proof):
- Guard in setter:
  - /Volumes/Storage/GitHub/fallout1-rebirth/src/game/critter.cc:1146-1177
- Combat load validation also guards self/same-team:
  - /Volumes/Storage/GitHub/fallout1-rebirth/src/game/combat.cc:1666-1672
- Direct assignment exists on map load (bypasses setter):
  - /Volumes/Storage/GitHub/fallout1-rebirth/src/game/map.cc:895
- Call sites that do use setter (non-exhaustive):
  - /Volumes/Storage/GitHub/fallout1-rebirth/src/game/combatai.cc:1024
  - /Volumes/Storage/GitHub/fallout1-rebirth/src/game/combat.cc:2034

### Proposed Fix (Outcome + Mechanism)
- Outcome: Ladder transitions never trigger self-attack combat.
- Mechanism: Audit every write to `whoHitMe` and route through
  `critter_set_who_hit_me()` (or apply the same validation) so self/same-team
  targets are rejected in all paths, including map transitions.

### Comparison (Now vs Fix)
- Now: some paths validate, some can still assign directly.
- Fix: all paths validated; self/same-team always rejected.

### Remaining Validation
- Identify the exact direct assignment path causing the regression; confirm
  via a single reproduction save in Vault 15/Junktown.

### Direct Assignment Audit (Partial List)
These locations assign `whoHitMe` directly (not via the setter) and should be
audited for validation consistency:
- /Volumes/Storage/GitHub/fallout1-rebirth/src/game/map.cc:895
- /Volumes/Storage/GitHub/fallout1-rebirth/src/game/proto.cc:706
- /Volumes/Storage/GitHub/fallout1-rebirth/src/game/combat.cc:1633
- /Volumes/Storage/GitHub/fallout1-rebirth/src/game/combat.cc:1659
- /Volumes/Storage/GitHub/fallout1-rebirth/src/game/combat.cc:1670
- /Volumes/Storage/GitHub/fallout1-rebirth/src/game/combat.cc:1672
- /Volumes/Storage/GitHub/fallout1-rebirth/src/game/combat.cc:1764
- /Volumes/Storage/GitHub/fallout1-rebirth/src/game/combat.cc:1826
- /Volumes/Storage/GitHub/fallout1-rebirth/src/game/combat.cc:4763
- /Volumes/Storage/GitHub/fallout1-rebirth/src/game/object.cc:585
- /Volumes/Storage/GitHub/fallout1-rebirth/src/game/object.cc:589
- /Volumes/Storage/GitHub/fallout1-rebirth/src/game/object.cc:591

---

## Bug 5: iPad dock reveal stutter (bottom edge) in fullscreen

### Current Behavior (Code Path)
- iOS window is fullscreen + borderless, but no explicit iOS gesture deferral
  hint is set via SDL.
- Dock can appear when pointer/finger reaches bottom edge, causing stutter.

Interaction points (proof):
- iOS window flags (fullscreen + borderless):
  - /Volumes/Storage/GitHub/fallout1-rebirth/src/plib/gnw/svga.cc:226-234
- Info.plist has UIStatusBarHidden but no UIRequiresFullScreen:
  - /Volumes/Storage/GitHub/fallout1-rebirth/os/ios/Info.plist:37-48

### Proposed Fix (Outcome + Mechanism)
- Outcome: Dock no longer interrupts bottom-edge pointer movement.
- Mechanism:
  1) Defer system gestures on all edges using
     `SDL_HINT_IOS_HIDE_HOME_INDICATOR = "2"`, which SDL exposes specifically
     for iOS home indicator/gesture deferral. This should require a second
     swipe to trigger system UI at edges, reducing accidental dock reveals.
     (SDL doc reference in External Notes.)
  2) For mouse/trackpad: request pointer lock by enabling SDL relative mouse
     mode during gameplay. SDL’s UIKit controller uses `prefersPointerLocked`
     when relative mode is active (internal), and pointer lock prevents the
     system cursor from reaching the screen edge. Pointer lock is at system
     discretion, so this is a strong mitigation but not 100% guaranteed.
     (Apple pointer-lock reference in External Notes.)
  3) Do not rely on Game Mode as a toggle. Apple describes Game Mode as an
     automatic system feature for games, with no public opt-in API; treat it
     as a best-effort bonus rather than a controllable fix.
     (Apple Game Mode reference in External Notes; inference about lack of API.)
  4) UIRequiresFullScreen remains a last-resort experiment only; it is
     deprecated and may not affect modern iPadOS multitasking behavior.

### Comparison (Now vs Fix)
- Now: no explicit gesture deferral; dock can appear on bottom edge.
- Fix: gesture deferral + pointer lock reduces both swipe and pointer-edge
  triggers, aligning behavior with “game-like” fullscreen controls.

### Remaining Validation
- Confirm behavior with trackpad/mouse vs finger; iPadOS may treat these
  differently. One device run should confirm.
- Confirm pointer lock is granted on the target iPadOS version.

---

## Bug 6: iOS on-screen keyboard stutter (text input)

### Current Behavior (Code Path)
- Text input is enabled in certain game flows (character name, save name).
- SDL_StartTextInput is called during those loops.
- Keyboard show/hide can trigger window pixel size changes, which currently
  rebuild the renderer and refresh the full screen (stutter).

Interaction points (proof):
- Text input enable/disable in character editor:
  - /Volumes/Storage/GitHub/fallout1-rebirth/src/game/editor.cc:1453-1543
- Text input enable/disable in save UI:
  - /Volumes/Storage/GitHub/fallout1-rebirth/src/game/loadsave.cc:2180-2276
- SDL_StartTextInput wrapper:
  - /Volumes/Storage/GitHub/fallout1-rebirth/src/plib/gnw/input.cc:1360-1366
- Window pixel-size change handling:
  - /Volumes/Storage/GitHub/fallout1-rebirth/src/plib/gnw/input.cc:1177-1180
  - /Volumes/Storage/GitHub/fallout1-rebirth/src/plib/gnw/svga.cc:469-475

### Proposed Fix (Outcome + Mechanism)
- Outcome: Keyboard show/hide no longer causes stutter.
- Mechanism:
  1) Track SDL_EVENT_SCREEN_KEYBOARD_SHOWN/HIDDEN and debounce window size
     handling during keyboard transitions.
  2) On iOS, do not rebuild the renderer on keyboard-driven size changes;
     only update dest rect.
  3) Ensure `SDL_HINT_ENABLE_SCREEN_KEYBOARD` is configured before
     `SDL_StartTextInput()` if we need deterministic keyboard behavior.

### Comparison (Now vs Fix)
- Now: keyboard appearance => size-change => renderer rebuild + full refresh.
- Fix: keyboard appearance => dest rect update only, smooth transition.

### Remaining Validation
- Confirm SDL sends SCREEN_KEYBOARD events during input on iOS and that size
  change events align with keyboard transitions. One device run should confirm.

---

## Confidence Summary (Current)
- High: Bugs 1, 2, 3 (clear code paths and localized fixes).
- Medium: Bug 4 (needs exact direct assignment path identified).
- Medium: Bugs 5, 6 (depends on iPadOS gesture behavior and SDL event sequence,
  but supported by SDL3 docs).

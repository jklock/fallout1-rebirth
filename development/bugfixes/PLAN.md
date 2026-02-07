# Bugfix Plan (Input/Rendering/Combat)

Last updated: 2026-02-07

## Goal
Stabilize input accuracy and rendering/audio smoothness, and resolve the
Vault 15 self-attack regression while keeping behavior faithful to Fallout 1.

## Workstreams

### 1) Cursor-at-top stutter + audio glitches
- Make iOS window-size changes lightweight:
  `handleWindowSizeChanged()` should update dest rect only (no renderer rebuild).
- Debounce refresh on iOS window size events (refresh only if size actually changed).
- If needed, lock status bar visibility in iOS so top-edge pointer movement
  doesn’t trigger safe-area changes.

### 2) Tearing when moving cursor with arrow keys
- Treat keyboard scroll as a full redraw on iOS:
  after `map_scroll(...)` for `KEY_ARROW_*`, force `tile_refresh_display()`.
- Keep mouse-edge scroll on the fast path with a helper
  `map_scroll_and_full_refresh(dx, dy)` called only for arrow keys.
- Ensure the forced redraw is presented immediately on iOS if needed.

### 3) Sporadic touch/Pencil click location
- Ignore out-of-bounds touch starts instead of clamping to edges.
- Clamp drag movement when leaving the dest rect to last in-bounds position.
- Unify mapping math for touch + mouse to keep rounding consistent.
- Keep dest rect updated via the iOS size-change fix from Bug 1.

### 4) Vault 15 self-attack regression
- Review commit d147705 (Vault 15 fix) and audit all paths that assign
  whoHitMe directly instead of using critter_set_who_hit_me().
- Validate combat_load() and any script-driven attack setup logic during
  ladder transitions (map changes or proto reloads).
- Reproduce in Vault 15 and Junktown ladders, capture save state and
  confirm which NPCs enter combat and whoHitMe values at transition.

### 5) iPad dock reveal stutter (bottom edge) in fullscreen
- Confirm if the app is in true fullscreen (no Stage Manager) and if
  `UIRequiresFullScreen` is needed in `os/ios/Info.plist`.
- Set `SDL_HINT_IOS_HIDE_HOME_INDICATOR` to "2" before SDL init and verify
  `preferredScreenEdgesDeferringSystemGestures` defers all edges on iPad.
- Verify pointer behavior vs finger (trackpad/mouse vs touch) to see if
  dock reveal ignores system gesture deferring.

### 6) iOS on-screen keyboard stutter (text input)
- Identify where text input is triggered in-game and ensure
  `beginTextInput()` / `endTextInput()` are paired correctly.
- Log SDL events around keyboard show/hide (screen keyboard + window size
  changes) to confirm if renderer rebuild is being triggered.
- On iOS, treat keyboard-driven size changes as lightweight: update dest
  rect and debounce refresh instead of rebuilding the renderer.

## Exit Criteria
- No stutter or audio glitches when cursor hits screen edges.
- No tearing during keyboard-driven cursor movement.
- Touch/Pencil clicks land reliably at the tap point.
- Ladder transitions no longer trigger self-attack combat.
- Dock reveal no longer interrupts fullscreen pointer movement on iPad.
- On-screen keyboard show/hide no longer causes stutter.

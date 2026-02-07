# Bugfix Plan (Input/Rendering/Combat)

Last updated: 2026-02-07

## Goal
Stabilize input accuracy and rendering/audio smoothness, and resolve the
Vault 15 self-attack regression while keeping behavior faithful to Fallout 1.

## Workstreams

### 1) Cursor-at-top stutter + audio glitches
- Reproduce with trackpad/mouse on iPad/macOS and confirm if the issue
  correlates with UI-safe-area or window-size changes.
- Add temporary logging for SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED and
  SDL_EVENT_WINDOW_EXPOSED to confirm if size changes are firing when
  cursor hits the top edge.
- Inspect iOS window flags and status bar behavior (borderless/fullscreen)
  and determine if the status bar reveal is causing repeated renderer rebuilds.
- Evaluate if handleWindowSizeChanged() should be throttled or ignored
  for transient top-edge changes on iOS.

### 2) Tearing when moving cursor with arrow keys
- Locate keyboard-mouse movement path (likely int/mousemgr.cc, gnw/kb.cc, or
  gmouse code) and confirm how it triggers screen refresh.
- Confirm renderer vsync state on those frames (SDL_SetRenderVSync is set in
  createRenderer, but verify it is not being undone or bypassed).
- Compare render path pre/post load-save to see what resets tearing.
- Consider forcing a renderer present or flush when keyboard-driven cursor
  movement occurs.

### 3) Sporadic touch/Pencil click location
- Instrument touch.cc conversion with logs for in/out-of-bounds and clamping.
- Track last_input_was_mouse transitions around touch events to ensure we do
  not briefly enter mouse path and skew click positions.
- Validate iOS_windowToGameCoords and dest rect values during orientation
  changes and after window-size change events.
- Confirm CLICK_OFFSET_X/Y and CLICK_OFFSET_MOUSE_X/Y are applied correctly
  and not double-applied in any path.

### 4) Vault 15 self-attack regression
- Review commit d147705 (Vault 15 fix) and audit all paths that assign
  whoHitMe directly instead of using critter_set_who_hit_me().
- Validate combat_load() and any script-driven attack setup logic during
  ladder transitions (map changes or proto reloads).
- Reproduce in Vault 15 and Junktown ladders, capture save state and
  confirm which NPCs enter combat and whoHitMe values at transition.

## Exit Criteria
- No stutter or audio glitches when cursor hits screen edges.
- No tearing during keyboard-driven cursor movement.
- Touch/Pencil clicks land reliably at the tap point.
- Ladder transitions no longer trigger self-attack combat.


# Bug 2: Screen tearing when using arrow keys to move cursor

Last updated: 2026-02-07

## Report
Using arrow keys to move the cursor causes visible tearing. The tearing goes
away after loading a save.

## Suspected Triggers
- Keyboard-driven cursor movement may bypass the normal render present path.
- VSync might not be applied on frames driven by keyboard input.
- Some state is reset on load (e.g., renderer state, refresh cadence).

## Relevant Code
- src/plib/gnw/mouse.cc: mouse_simulate_input() + mouse_show() + win_refresh_all().
- src/plib/gnw/svga.cc: createRenderer() sets SDL_SetRenderVSync(gSdlRenderer, 1).
- src/int/mousemgr.cc / gnw/kb.cc / game gmouse code: likely sources for
  keyboard-driven mouse movement (to locate).

## Repro Checklist
1) Start game, use arrow keys to move cursor
2) Observe tearing while moving
3) Load a save; observe tearing disappears

## Instrumentation Ideas
- Log every call that moves the cursor via keyboard and which render path
  runs immediately after.
- Confirm SDL_SetRenderVSync return value and if it ever gets toggled.
- Compare renderPresent calls before and after load.

## Candidate Fixes
- Force a renderer present after keyboard-driven cursor movement.
- Ensure keyboard-mouse movement triggers the same refresh path as
  normal mouse movement.
- Verify no code path resets render/texture state only after load.


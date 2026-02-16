# SDL3 Deterministic Input Audit - 2026-02-15

## Goal
Deliver a single deterministic SDL3 input translation layer for macOS + iOS/iPadOS that preserves desktop mouse behavior and stabilizes touch/pencil semantics.

## Git History Review (Input Path)
Reviewed files:
- `src/plib/gnw/input.cc`
- `src/plib/gnw/mouse.cc`
- `src/plib/gnw/touch.cc`
- `src/plib/gnw/dxinput.cc`
- `src/plib/gnw/svga.cc`
- `src/plib/gnw/winmain.cc`
- `src/platform/ios/pencil.mm`

### Timeline of Tried/Reverted Changes
| Commit | Date (local) | Attempt | Outcome | Reverted/Why |
|---|---|---|---|---|
| `74b8bbe` | 2026-02-03 | Deferred tap release in `mouse_info` (button-up next frame). | Improved click registration but introduced fragile stateful path in gesture branch. | Partially rolled back by `11de3ee` while broader mouse behavior was reset. |
| `11de3ee` | 2026-02-04 | Roll back prior mouse-state changes; remove deferred release path. | Restored older behavior but reintroduced immediate-release edge cases. | Superseded by later deterministic queue/state-machine approach. |
| `fb51a66` | 2026-02-04 | Convert touch coords via SDL logical transform (`SDL_RenderWindowToLogical`). | Did not solve touch offset on iPad; mapping still inconsistent. | Explicitly reverted by `f8397c3`. |
| `f8397c3` | 2026-02-04 | Revert SDL logical transform experiment; return to direct normalized scaling. | Reduced one class of offset but left system fragmented. | Superseded by shared mapping contract in final solution. |
| `0c8f6c3` | 2026-02-04 | Restore known-good touch path from `3f9e296`; recover pencil config behavior. | Stabilized a regressed baseline. | Temporary; later changes diverged again. |
| `12137b7` | 2026-02-05 | Capture click position at button-down in `dxinput`. | Addressed stale-click symptom for one pipeline. | Removed in `faa7bd8` to test whether capture logic itself caused misalignment. |
| `faa7bd8` | 2026-02-05 | Remove click-capture; use live mapping only. | Simplified path, but stale-position and desync risk remained under mixed sources. | Superseded by deterministic FIFO action ownership. |
| `52cb14a` | 2026-02-06 | Filter synthetic touch-mouse, reset iOS button state on touch, tighten hit-test. | Reduced duplicate events/stuck buttons. | Kept as part of final ownership model. |
| `c945840` | 2026-02-06 | Tune long-press/tap thresholds and drag semantics. | Improved some gestures but still heuristic-heavy and state-fragmented. | Superseded by explicit state machine semantics. |
| `7a47066` | 2026-02-06 | Add deferred tap release + threshold tuning + touch-active mouse skip. | Better tap reliability but still coupled to recognizer timing heuristics. | Superseded by queue-driven deterministic output. |
| `dddbf51` | 2026-02-06 | Re-enable mouse fallback when no gesture active. | Restored desktop path in idle touch state. | Preserved conceptually in final ownership gating (`touch_is_pointer_active`). |
| `74c5987` | 2026-02-07 | iOS edge/keyboard transition smoothing, relative-mode/resize handling, touch bounds retention. | Addressed stutter/edge behavior; introduced additional complexity. | Later refactors replaced pieces with shared mapping and simpler changed-rect logic. |
| `667203b` | 2026-02-14 | Rework macOS/iOS mouse mapping and window behavior. | Large mixed change set; unresolved iPad input regressions remained. | Superseded by focused deterministic input layer split. |
| `571d15d` | 2026-02-14 | iPad resolution/input follow-up adjustments. | Added pen synthetic filtering and out-of-bounds suppression. | Kept as baseline hardening; deterministic layer now unifies upstream behavior. |
| current (working tree) | 2026-02-15 | Introduce `InputStateMachine` + `input_mapping`; rebuild touch/mouse bridge around FIFO events. | Deterministic ownership, unified mapping, automated validation coverage. | Target implementation. |

### Post-Review Correction (2026-02-15)
- Regression source identified from history comparison (`0c8f6c3` baseline vs `cea989d` changes):
  - `cea989d` added `SDL_HINT_PEN_MOUSE_EVENTS=0` and `SDL_HINT_PEN_TOUCH_EVENTS=0` in `winmain.cc`; this can suppress Pencil event flow while no `SDL_EVENT_PEN_*` translation path exists.
  - iOS touch activation depended on `inBounds=true` from `iOS_windowToGameCoords`; when custom letterbox mapping is not active yet, false was returned and the touch stream was dropped.
- Applied correction:
  - Removed `SDL_HINT_PEN_*` disabling in `src/plib/gnw/winmain.cc`.
  - Hardened iOS mapping fallback in `src/plib/gnw/touch.cc` and `src/plib/gnw/svga.cc` so startup/fallback mapping does not discard touch-first input and does not rely on renderer logical conversion.

## Final Architecture (Implemented)
- Deterministic translation core:
  - `src/plib/gnw/input_state_machine.h`
  - `src/plib/gnw/input_state_machine.cc`
- Shared coordinate mapping:
  - `src/plib/gnw/input_mapping.h`
  - `src/plib/gnw/input_mapping.cc`
- Touch wrapper now forwards all gesture/mouse synthesis through state machine:
  - `src/plib/gnw/touch.cc`
- Legacy integration point drains translated queue only:
  - `src/plib/gnw/mouse.cc`
- Pencil body gestures routed through same queue:
  - `src/plib/gnw/input.cc`
- iOS mapping/safe-area/windowing path uses shared letterbox mapper:
  - `src/plib/gnw/svga.cc`
- SDL synthetic touch/pen mouse events are explicitly ignored in GNW event intake while preserving hardware mouse path:
  - `src/plib/gnw/input.cc`

## Event/State Diagram
```mermaid
flowchart TD
    SDLFinger[SDL finger/pen events] --> TouchWrapper[touch_handle_*]
    SDLMouse[SDL mouse/trackpad via dxinput] --> MouseSubmit[touch_submit_mouse_state]
    PencilBody[pencil_poll_gesture double-tap/squeeze] --> Secondary[touch_enqueue_secondary_click]

    TouchWrapper --> SM[InputStateMachine]
    MouseSubmit --> SM
    Secondary --> SM

    SM --> Queue[FIFO InputAction queue]
    Queue --> MouseInfo[mouse_info]
    MouseInfo --> LegacyMouse[mouse_simulate_input + wheel]
```

## Failure Modes Fixed
| Failure mode | Fix | Validation |
|---|---|---|
| Cursor jump / transient teleport | Ignore out-of-bounds move updates for active touch stream; canonical mapping + pointer ownership gating. | `test_out_of_bounds_move_does_not_jump`, `test_mouse_path_is_blocked_while_touch_active` in `src/plib/gnw/input_layer_test.cc`. |
| Stale-position click | Deferred final release and blocked mouse handoff until deterministic release emission. | `test_stale_position_click_prevention` in `src/plib/gnw/input_layer_test.cc`. |
| Drag instability | Deterministic heartbeat during active drag and FIFO ordering. | `test_single_finger_drag_stability_heartbeat` and `test_two_finger_right_drag`. |
| Pencil down/up mismatch | Pencil tip uses same left-button state machine down/move/up sequence. | `test_pencil_precise_down_move_up`. |
| OS pointer vs game cursor desync | Hardware absolute pointer translated through unified queue only when touch stream inactive. | `test_mouse_absolute_sync_no_touch`; headless mouse path checks. |
| iPad orientation/window/safe-area mapping drift | Shared `input_compute_letterbox_rect` + `input_map_screen_to_game` used by iOS coordinate conversion. | `test_mapping_portrait_fullscreen`, `test_mapping_landscape_fullscreen`, `test_mapping_safe_area_insets`, `test_mapping_windowed_and_dynamic_bounds`. |
| Gesture semantics mismatch | Explicit single-finger left and two-finger right mapping; Pencil is deterministic left-click-only (body gestures ignored). | `test_single_finger_click_and_drag`, `test_two_finger_right_click`, `test_pencil_precise_down_move_up`. |

## Automated Validation Assets
- Unit layer tests:
  - `scripts/test/test-input-layer.sh`
- Headless platform checks:
  - `scripts/test/test-macos-headless.sh`
  - `scripts/test/test-ios-headless.sh` (now captures simulator screenshot evidence)
- Unattended gate:
  - `dev/run-unattended-until-100.sh`

### Autotest Hardening (2026-02-15)
- `maybe_run_touch_autotest` now injects the full scripted touch sequence in one pass to avoid frame-scheduling stalls.
- In autotest-exit mode, translated touch mouse actions are drained and logged before exit under `INPUT_AUTOTEST_MOUSE` so evidence is deterministic.
- `scripts/test/test-ios-headless.sh` wait-loop parsing was fixed to avoid `0\n0` arithmetic errors when checking process liveness.

Evidence locations (latest run):
- `dev/state/latest-summary.tsv`
- `dev/state/history.tsv`
- Latest history row: `2	input	1	1	100	PASS	2026-02-15T20:48:57Z`
- `dev/state/logs/round-2-input-input_layer-rerun.log`
- `dev/state/logs/round-2-input-macos_headless-rerun.log`
- `dev/state/logs/round-2-input-ios_headless-rerun.log`
- `dev/state/logs/screens/ios-headless-com-fallout1rebirth-game-20260215T204510Z.png`
- `dev/state/logs/ios-touch-autotest-20260215T204516Z.patchlog.txt`

## Build Artifacts (This Validation Run)
- macOS app: `build-macos/RelWithDebInfo/Fallout 1 Rebirth.app`
- iOS simulator app: `build-ios-sim/RelWithDebInfo-iphonesimulator/fallout1-rebirth.app`
- Release macOS app: `releases/prod/macOS/Fallout 1 Rebirth.app`
- Release iOS IPA: `releases/prod/iOS/fallout1-rebirth.ipa`

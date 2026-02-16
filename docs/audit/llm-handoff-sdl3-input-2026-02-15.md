# SDL3 Input End-to-End Handoff (LLM)

Date: 2026-02-15
Owner handoff: Codex -> Next LLM
Scope: Fallout 1 Rebirth deterministic SDL3 input path on macOS + iOS/iPadOS.

## 1) Repository Snapshot
- Repo: `/Volumes/Storage/GitHub/fallout1-rebirth`
- Branch: `RME-DEV`
- Last pushed implementation commit: `c1accdf27927603e1d6b4c115dded9bac08c0a72`
- Remote branch state at handoff creation: clean on `origin/RME-DEV`.

## 2) What Was Implemented
A deterministic translation path was hardened around existing work (not a clean rewrite), focused on startup/input ownership regressions and durable test evidence capture.

### Core input behavior and mapping fixes
- `src/plib/gnw/winmain.cc`
- Removed iOS pen hint suppression (`SDL_HINT_PEN_MOUSE_EVENTS`, `SDL_HINT_PEN_TOUCH_EVENTS`) that could suppress Pencil flow in this app's event path.

- `src/plib/gnw/svga.cc`
- Hardened iOS coordinate conversion for startup + fallback + dynamic window bounds.
- Explicit points->pixels conversion using window logical and pixel sizes.
- Ensures fallback mapping returns valid mapped coords instead of dropping stream when custom letterbox rect is not active yet.

- `src/plib/gnw/touch.cc`
- Added fallback normalized-touch->screen mapping for startup/fallback states.
- Prevents touch-first activation from being discarded before full mapping state is initialized.

- `src/plib/gnw/input.cc`
- Added deterministic touch autotest injector (`maybe_run_touch_autotest`) for simulator runs.
- In autotest mode, injects full sequence in one pass and logs translated pointer evidence before optional exit.
- Maintains Pencil as left-click-only (body gestures ignored deliberately).

- `src/plib/gnw/mouse.cc`
- Added optional patchlog traces for translated touch mouse events in autotest mode (`INPUT_AUTOTEST_MOUSE`) to make action evidence explicit.

### iOS test harness hardening
- `scripts/test/test-ios-headless.sh`
- Added scripted touch autotest run to simulator test cycle.
- Fixed process-liveness parsing issue in wait loop.
- Added archival of simulator patchlog into repo-owned evidence dir:
  - `dev/state/logs/ios-touch-autotest-<timestamp>.patchlog.txt`

## 3) History Review Outcome (what was tried/reverted)
Primary consolidated review is documented here:
- `docs/audit/sdl3-input-deterministic-audit-2026-02-15.md`

Highlights from the reviewed sequence:
- Multiple prior attempts alternated between direct mapping, logical transform usage, deferred releases, synthetic event filtering, and threshold tuning.
- A key regression trigger identified from comparison work was iOS pen hint suppression combined with strict in-bounds dependency during early mapping states.
- Current implementation keeps the deterministic state-machine direction and fixes startup/fallback mapping drops.

## 4) Scripted Action Coverage (important)
The implemented automated suite does execute scripted touch action sequences and verifies translated mouse semantics, but this is not equivalent to full external UI gameplay automation on real hardware.

### What is scripted and verified now
- Script entry: `scripts/test/test-ios-headless.sh`
- App-side injector: `src/plib/gnw/input.cc` (`F1R_TOUCH_AUTOTEST=1` path)
- Injection mechanism: in-app synthetic SDL finger events during simulator run (deterministic code-path validation).
- Scripted sequence includes:
- single-finger down/move/up (left click/drag flow)
- two-finger down/move/up (right click/right-drag flow)
- Verification checks in patchlog:
- autotest start/done markers
- translated pointer evidence with `buttons=0x1` and `buttons=0x2`

### What this does NOT prove
- It does not prove full live gameplay behavior on a physical iPad across OS-level device event differences.
- It does not perform external, end-user-like character movement/right-click action automation through the real iPad touchscreen/pencil stack.

## 5) Current Automated Status
Latest 100% input-track proof is recorded in:
- `dev/state/latest-summary.tsv`
- `dev/state/history.tsv`

Latest history row at time of this handoff:
- `2	input	1	1	100	PASS	2026-02-15T20:48:57Z`

Latest logs used for that row:
- `dev/state/logs/round-2-input-input_layer-rerun.log`
- `dev/state/logs/round-2-input-macos_headless-rerun.log`
- `dev/state/logs/round-2-input-ios_headless-rerun.log`
- `dev/state/logs/ios-touch-autotest-20260215T204516Z.patchlog.txt`
- `dev/state/logs/screens/ios-headless-com-fallout1rebirth-game-20260215T204510Z.png`

## 6) Build/Release Artifacts
Fresh artifacts currently staged:
- macOS app: `releases/prod/macOS/Fallout 1 Rebirth.app`
- iOS IPA: `releases/prod/iOS/fallout1-rebirth.ipa`

Also installed for local desktop test:
- `/Applications/Fallout 1 Rebirth.app`

## 7) Documents Updated During This Work
- `docs/audit/sdl3-input-deterministic-audit-2026-02-15.md`
- `dev/input-validation-round2-2026-02-15.md`
- `dev/state/latest-summary.tsv`
- `dev/state/history.tsv`

## 8) Open Gap for Next LLM
Required to close final real-world confidence gap:
- Run physical iPad live validation against real game interactions:
- touch-first launch must not crash
- move character with touch
- left click/drag stability
- two-finger right click/right-drag behavior
- Pencil down/move/up in left-click-only mode
- verify no cursor teleport, stale-click, drag instability, or cursor/pointer desync

## 9) Recommended Next-LLM Start Commands
From repo root:

```bash
git checkout RME-DEV
git pull
scripts/test/test-input-layer.sh
GAME_DATA=/Volumes/Storage/GitHub/fallout1-rebirth-gamefiles/patchedfiles scripts/test/test-macos-headless.sh
GAME_DATA=/Volumes/Storage/GitHub/fallout1-rebirth-gamefiles/patchedfiles scripts/test/test-ios-headless.sh
```

Then proceed directly to physical iPad validation pass and log outcomes into:
- `dev/state/latest-summary.tsv`
- `dev/state/history.tsv`
- `docs/audit/sdl3-input-deterministic-audit-2026-02-15.md`

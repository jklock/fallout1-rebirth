# Dev Plans - Automated Program

## Scope
Two tracks must complete and pass automated validation with no manual steps:
- `Track A`: Input state machine migration (SDL3 single-translator model).
- `Track B`: Config compatibility restoration (all baseline unpatched keys functional).

## Track A - Input State Machine Plan

### Goal
Replace mixed input ownership with one deterministic translation layer that emits canonical mouse semantics.

### Architecture Target
- One input owner per source stream.
- One coordinate transform path.
- One button-state owner.
- One output sink: `mouse_simulate_input(...)`.

### States
- `idle`
- `pointer_move`
- `pending_secondary_touch` (two-finger right-click disambiguation window)
- `left_drag`
- `right_drag`
- `scroll_pan`
- `pencil_drag`

### Phases
1. Add feature-flagged state machine scaffold (`legacy_input` toggle).
2. Route finger/pen through state machine; keep hardware mouse path independent.
3. Remove mixed gesture/button ownership from legacy branches.
4. Turn on strict source filtering and remove duplicate synthesis.
5. Flip default after full pass matrix.

### Validation Matrix
- Finger: tap, long-press drag, two-finger right-click, two-finger scroll.
- Pencil: move, tap, drag, body-gesture right-click.
- Trackpad/mouse: move, click, drag, wheel.
- Resizing/orientation/content-bounds transitions on iPadOS.

## Track B - Config Compatibility Plan

### Goal
All keys from unpatched baseline files must be functional and validated.

### Baselines
- Unpatched baseline manifests:
  - `docs/audit/key-manifests/unpatched-f1_res.keys`
  - `docs/audit/key-manifests/unpatched-fallout.cfg.keys`
- Legacy compatibility superset:
  - `docs/audit/key-manifests/gog-f1_res.keys`

### Phases
1. Key inventory and per-key coverage table.
2. Wire missing high-impact keys (`VSYNC`, `FPS_LIMIT`, etc.).
3. Expand to legacy Hi-Res compatibility keys with mapped behavior.
4. Sync all templates and release payloads from compatibility map.
5. Add regression tests that fail on any key behavior drop.

### Validation Rules
- No baseline key silently ignored.
- Each key has:
  - parse proof
  - application proof
  - behavior proof

## Unattended Completion Model
- Both tracks run as suites in repeated rounds.
- A round is `100%` only when all checks in selected tracks pass.
- Program exits success only on first full-green round.

## Command Entrypoint
- `dev/run-unattended-until-100.sh`


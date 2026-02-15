# Dev Tasks - Execution Checklist

## Global
- [ ] Establish build artifacts for macOS and iOS simulator.
- [ ] Confirm data roots (`unpatchedfiles` and `patchedfiles`) are available.
- [ ] Enable unattended runner and state/log directories.

## Track A - Input State Machine

### A1. Scaffold
- [ ] Add state-machine module and event contracts.
- [ ] Add config/flag for legacy vs state-machine mode.
- [ ] Add deterministic event trace logs.

### A2. Source Ownership
- [ ] Hardware mouse/trackpad path isolated.
- [ ] Finger path translated only by state machine.
- [ ] Pencil path translated only by state machine + optional body gestures.
- [ ] Remove duplicate button down/up ownership.

### A3. Coordinate and Bounds
- [ ] One canonical transform for touch/pen -> game coords.
- [ ] Explicit in-bounds/out-of-bounds policy.
- [ ] No cursor snap at bars/edge transitions.

### A4. Behavior Completion
- [ ] Two-finger right-click deterministic.
- [ ] Click+drag deterministic.
- [ ] Pencil move/tap/drag deterministic.

### A5. Automated Tests
- [ ] Add/update iOS input regression scripts.
- [ ] Add simulator scenario replay tests.
- [ ] Add pass/fail signal to unattended runner.

## Track B - Config Compatibility

### B1. Coverage Matrix
- [ ] Produce per-key matrix from baseline manifests.
- [ ] Mark `wired / partial / missing` with evidence.

### B2. Implement Missing Keys
- [ ] `f1_res.ini`: wire missing baseline keys (`VSYNC`, `FPS_LIMIT` first).
- [ ] `fallout.cfg`: ensure all baseline keys are actually applied at startup/runtime.
- [ ] Legacy key aliases mapped and tested.

### B3. Template Sync
- [ ] Regenerate `gameconfig/*` templates from compatibility map.
- [ ] Regenerate `dist/*` templates from same source of truth.
- [ ] Verify app/ipa packaged configs match.

### B4. Automated Tests
- [ ] Add per-key effect tests.
- [ ] Add config compatibility gate to unattended runner.

## Completion Gate (100%)
- [ ] Track A suite pass = 100%.
- [ ] Track B suite pass = 100%.
- [ ] Combined unattended round pass = 100%.

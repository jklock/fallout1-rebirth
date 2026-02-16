# Dev Tasks - Execution Checklist

## Global
- [x] Establish build artifacts for macOS and iOS simulator.
- [x] Confirm data roots (`unpatchedfiles` and `patchedfiles`) are available.
- [x] Enable unattended runner and state/log directories.

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
- [x] Add pass/fail signal to unattended runner.

## Track B - Config Compatibility

### B1. Coverage Matrix
- [x] Produce per-key matrix from baseline manifests.
- [x] Mark `wired / partial / missing` with evidence.

### B2. Implement Missing Keys
- [x] `f1_res.ini`: wire missing baseline keys (`VSYNC`, `FPS_LIMIT` first).
- [x] `fallout.cfg`: ensure all baseline keys are exposed and loaded at startup/runtime.
- [x] Legacy key aliases mapped and tested.

### B3. Template Sync
- [x] Regenerate `gameconfig/*` templates from compatibility map.
- [x] Regenerate `dist/*` templates from same source of truth.
- [x] Verify app/ipa packaged configs match.

### B4. Automated Tests
- [x] Add per-key effect tests.
- [x] Add config compatibility gate to unattended runner.
- [x] Add template/package config alignment gate (`test-rme-config-packaging.sh`).

## Completion Gate (100%)
- [x] Track A suite pass = 100%.
- [x] Track B suite pass = 100%.
- [x] Combined unattended round pass = 100%.

# Config Compatibility Project Plan - 2026-02-15

## Completion Status

Status: **Completed** (2026-02-15).

Completion evidence:
- Per-key matrix: `docs/audit/config-key-coverage-matrix-2026-02-15.md` (`61/61 PASS`)
- Packaging alignment: `docs/audit/config-packaging-alignment-2026-02-15.md` (`PASS`)
- Unattended proof: `dev/state/history.tsv` latest `PASS` row (`2026-02-15T16:03:04Z`)

## Objective
Restore full config compatibility so the unpatched baseline files behave as expected:
- `f1_res.ini`
- `fallout.cfg`

This replaces the prior "trim templates to active keys" direction.

## Requirement Clarification
New requirement (authoritative): every key present in the unpatched baseline files must be functional in runtime behavior.

Primary baseline sources:
- `/Volumes/Storage/GitHub/fallout1-rebirth-gamefiles/unpatchedfiles/f1_res.ini`
- `/Volumes/Storage/GitHub/fallout1-rebirth-gamefiles/unpatchedfiles/fallout.cfg`

Compatibility superset source (legacy Hi-Res style keys still expected by some users):
- `/Volumes/Storage/GitHub/fallout1-rebirth-gamefiles/Fallout1_GOGBackup/f1_res.ini`
- `/Volumes/Storage/GitHub/fallout1-rebirth-gamefiles/Fallout1_GOGBackup/fallout.ini`

## Current Gap Summary

### `fallout.cfg`
Most keys exist in runtime config defaults and are read by game systems, but coverage is uneven:
- some keys are read and actively applied.
- some are loaded but only used indirectly or not applied until options/menu code runs.
- legacy alias behavior exists for a subset (`player_speed` -> `player_speedup`, `combat_looks` -> `running_burning_guy`).

### `f1_res.ini`
Current runtime directly reads only:
- `[MAIN] SCR_WIDTH, SCR_HEIGHT, WINDOWED, EXCLUSIVE, SCALE_2X`
- `[INPUT] CLICK_OFFSET_X, CLICK_OFFSET_Y, CLICK_OFFSET_MOUSE_X, CLICK_OFFSET_MOUSE_Y`

Unpatched and legacy keys such as `VSYNC`, `FPS_LIMIT`, and many section options are not yet wired end-to-end.

## Execution Plan

### Phase 0 - Freeze and Traceability
Deliverables:
- capture current config behavior baseline with logs.
- produce immutable key manifests from unpatched files.

Actions:
- add scripts that parse INI keys by section and emit sorted manifests.
- save baseline run evidence for both macOS and iOS.

Acceptance:
- deterministic manifests in repo.
- baseline behavior report checked in.

### Phase 1 - Key Manifest and Coverage Matrix
Deliverables:
- `docs/config-key-coverage.md` with one row per baseline key.

Columns:
- key
- source file/section
- parsed in code (Y/N)
- applied at startup (Y/N)
- applied during runtime/options (Y/N)
- verified by automated test (Y/N)
- notes

Acceptance:
- all baseline keys enumerated with explicit status.
- no undocumented keys left in templates.

### Phase 2 - `fallout.cfg` Full Behavioral Coverage
Deliverables:
- all baseline `fallout.cfg` keys either:
  - actively wired and verified, or
  - explicitly mapped to canonical aliases with tests.

Actions:
- audit each key in `gconfig` load path.
- ensure startup application for keys that currently only apply in options/menu flows.
- keep legacy aliases and extend where needed.

Acceptance:
- changing any baseline `fallout.cfg` key changes observable runtime behavior or mapped equivalent.

### Phase 3 - `f1_res.ini` Full Behavioral Coverage
Deliverables:
- compatibility layer for baseline `f1_res.ini` keys.

Priority order:
1. Rendering/runtime controls expected in current unpatched baseline (`VSYNC`, `FPS_LIMIT`).
2. Input controls (`CLICK_OFFSET_*`, etc.) with startup proof logs.
3. Legacy Hi-Res style keys from GOG backup:
   - keys that can be mapped to current engine behavior: implement mappings.
   - keys requiring missing engine subsystems: implement where feasible, otherwise create explicit compatibility behavior with documented fallback.

Acceptance:
- every baseline key has deterministic behavior and verification evidence.
- no silent ignore for baseline keys.

### Phase 4 - Template and Packaging Sync
Deliverables:
- regenerated `gameconfig/*` and `dist/*` templates from manifests + compatibility map.

Actions:
- remove hand-edited drift.
- ensure packaged `.app`/`.ipa` ship the same validated key set.

Acceptance:
- template keys match compatibility matrix 1:1.
- release artifacts include validated config files.

### Phase 5 - Automated Validation
Deliverables:
- config-behavior test harness.

Test types:
- parse/load tests (key present and parsed).
- behavior tests (toggle key and assert changed runtime state/log).
- integration smoke tests for macOS and iOS simulator.

Acceptance:
- CI/local scripts fail when a supported key loses behavior.
- report generated per build.

## Input-System Tie-In (SDL3)
Config compatibility and input stabilization are linked:
- `f1_res.ini` and `fallout.cfg` input-related keys must be validated under the new single-owner input architecture.
- key-effect tests must cover finger, pencil, and trackpad paths independently.

## Risks and Controls
Risks:
- legacy Hi-Res keys may reference behavior not fully present in current engine.
- mixed platform behavior (macOS vs iOS) can mask config regressions.

Controls:
- explicit compatibility map per key.
- no "ignored silently" baseline keys.
- automated tests for each supported key.

## Immediate Next Actions
1. Generate committed key manifests from unpatched baseline files.
2. Build and commit initial coverage matrix with current statuses.
3. Implement first missing keys with highest impact:
   - `f1_res.ini`: `VSYNC`, `FPS_LIMIT`.
4. Add behavior tests for these keys before moving to remaining keyset.

# Config Key Coverage Baseline - 2026-02-15

## Source Manifests
- `docs/audit/key-manifests/unpatched-f1_res.keys` (6 keys)
- `docs/audit/key-manifests/unpatched-fallout.cfg.keys` (55 keys)
- `docs/audit/key-manifests/gog-f1_res.keys` (56 keys, compatibility superset)

## Historical Initial Snapshot (Pre-Implementation)

This section is retained as historical context from the start of the project.
Current authoritative status is in **Final Coverage Snapshot** below.

### Unpatched `f1_res.ini` (6 keys)

| Key | Status | Evidence |
|---|---|---|
| `MAIN::SCR_WIDTH` | wired | `src/game/game.cc:214` |
| `MAIN::SCR_HEIGHT` | wired | `src/game/game.cc:219` |
| `MAIN::WINDOWED` | wired | `src/game/game.cc:224` |
| `MAIN::SCALE_2X` | wired | `src/game/game.cc:234` |
| `DISPLAY::VSYNC` | missing | no config read path yet |
| `DISPLAY::FPS_LIMIT` | missing | no config read path yet |

Historical summary: 4/6 wired, 2/6 missing at project start.

### Unpatched `fallout.cfg` (55 keys)

Historical status at project start:
- key inventory complete and committed.
- runtime coverage exists for most core game/sound/system keys through `gconfig` and options subsystems.
- per-key startup/runtime behavior verification is still pending and tracked by the compatibility plan.

Critical note:
- previous template strategy ("only active keys") is now replaced by full baseline compatibility target.
- no baseline key should be silently ignored once this project is complete.

## Final Coverage Snapshot (Post-Implementation)

- Per-key automated matrix: `docs/audit/config-key-coverage-matrix-2026-02-15.md`
- Machine-readable matrix: `tmp/rme/config-compat/coverage-matrix.tsv`
- Gate script: `scripts/test/test-rme-config-compat.sh`

Final status:
- `fallout.cfg`: 55/55 PASS (parse/apply/runtime effect)
- `f1_res.ini`: 6/6 PASS (parse/apply/runtime effect)
- Total baseline keys: 61/61 PASS
- Template/package alignment gate: `scripts/test/test-rme-config-packaging.sh` PASS

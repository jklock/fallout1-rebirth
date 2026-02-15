# Config Key Coverage Baseline - 2026-02-15

## Source Manifests
- `docs/audit/key-manifests/unpatched-f1_res.keys` (6 keys)
- `docs/audit/key-manifests/unpatched-fallout.cfg.keys` (55 keys)
- `docs/audit/key-manifests/gog-f1_res.keys` (56 keys, compatibility superset)

## Initial Coverage Snapshot

### Unpatched `f1_res.ini` (6 keys)

| Key | Status | Evidence |
|---|---|---|
| `MAIN::SCR_WIDTH` | wired | `src/game/game.cc:214` |
| `MAIN::SCR_HEIGHT` | wired | `src/game/game.cc:219` |
| `MAIN::WINDOWED` | wired | `src/game/game.cc:224` |
| `MAIN::SCALE_2X` | wired | `src/game/game.cc:234` |
| `DISPLAY::VSYNC` | missing | no config read path yet |
| `DISPLAY::FPS_LIMIT` | missing | no config read path yet |

Summary: 4/6 wired, 2/6 missing.

### Unpatched `fallout.cfg` (55 keys)

Status at this stage:
- key inventory complete and committed.
- runtime coverage exists for most core game/sound/system keys through `gconfig` and options subsystems.
- per-key startup/runtime behavior verification is still pending and tracked by the compatibility plan.

Critical note:
- previous template strategy ("only active keys") is now replaced by full baseline compatibility target.
- no baseline key should be silently ignored once this project is complete.

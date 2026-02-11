# RME Logging Validation Playbook (2026-02-11)

Use this checklist to exercise every logging surface touched by the 2026-02-11 patch. Run on macOS builds only. Respect project rules: **use scripts, never raw cmake/xcodebuild**.

## Preconditions
- Build: `./scripts/build/build-macos.sh`
- Headless sanity: `./scripts/test/test-macos-headless.sh`
- Working dir: `build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/MacOS`
- Clean logs: remove old `rme.log*` before each run.
- Enable logging: `RME_LOG=<topics>` where topics is `all` or comma-list.
- Timeout: cap game runs at ~15s if unattended (`timeout 15s RME_LOG=... ./fallout1-rebirth`).

## Core Startup Pass (once)
- Command: `timeout 15s RME_LOG=1 ./fallout1-rebirth`
- Verify in `rme.log`:
  - Patch tree summaries `missing=0 case_mismatch=0` (master/critter)
  - `fallout.cfg` resolved and dump of master/critter paths, music paths
  - Inventories for maps/proto/text/art present with counts
  - `f1_res.ini` present line with dimensions

## Topic Sweeps (rerun per section)
Each sweep: delete `rme.log*`, run with narrow topics to keep logs short.

### Fonts/Text
- `timeout 15s RME_LOG=text,art ./fallout1-rebirth`
- Open UI text (menus/character sheet) if interacting.
- Expect: no `font*.fon/.aaf` misses; `message_load` successes for game/dialog; no case warnings.

### Movies (iplogo/intro)
- `timeout 20s RME_LOG=movie ./fallout1-rebirth`
- Let startup play iplogo/intro.
- Expect: `movie_play request` lines; no `iplogo.cfg` missing log; `.mve` hits; subtitle missing only if actual files absent.

### Maps + Scripts + Proto
- `timeout 20s RME_LOG=map,script,proto ./fallout1-rebirth`
- If interactive, load an RME map (Hub/Junktown) via in-game load.
- Expect: map_load request/success, scripts.lst entries logged, proto lst/pro loads with no missing pro/lst messages.

### Text/Messages
- `timeout 20s RME_LOG=text ./fallout1-rebirth`
- Enter dialogs/Pip-Boy.
- Expect: localized msg paths found; no missing game/dialog msg files; casing warnings absent.

### Art/Tiles
- `timeout 20s RME_LOG=art ./fallout1-rebirth`
- Open UI; move maps to force tile loads if possible.
- Expect: `art present` lines; no FRM/PAL missing messages.

### Sound/Music
- `timeout 20s RME_LOG=sound ./fallout1-rebirth`
- Trigger SFX (inventory, clicks) and background music.
- Expect: music_path logs, sfx/music hits; no `miss` lines.

### Saves
- `timeout 20s RME_LOG=save ./fallout1-rebirth`
- Create and load a save slot.
- Expect: SaveSlot/LoadSlot open logs with paths; no failures.

### Bundle Sweep
- Re-run base startup with `RME_LOG=db,config`.
- Confirm working dir selection, bundle presence (Info.plist, Resources), and no case mismatches.

## Automation Shortcut
- Script: `./scripts/test/rme-log-sweep.sh`
  - Builds via project script, runs headless sanity, then executes all topic sweeps with `RME_LOG`.
  - Logs collected under `tmp/rme-log-sweep/*.log` with per-run missing/case counts.
- GUI exercise: `./scripts/test/rme-gui-drive.sh`
  - Builds, runs macOS verify, launches the GUI with `RME_LOG=1`, drives a few mouse clicks (skip intro, tap menu), and saves `tmp/rme-log-sweep/gui.log`.
  - Uses `osascript` for clicks; ensure Accessibility permission for Terminal if prompted.

## Evidence Capture
- Keep resulting `rme.log` per sweep; if clean, note “zero misses/case warnings”.
- If a miss appears, log the exact line and fix or document.

## Quick One-Liner to Summarize Current Log
```
cd build-macos/RelWithDebInfo/Fallout\ 1\ Rebirth.app/Contents/MacOS
ls -lh rme.log*
echo "missing_lines=$(grep -i -E 'dat miss|missing' rme.log | wc -l | tr -d ' ')" \
  "case_lines=$(grep -i 'case' rme.log | wc -l | tr -d ' ')"
```

Run all sweeps until every topic reports zero missing/case warnings.

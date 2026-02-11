# RME Patch Logging Checklist (2026-02-11)

Goal: build a comprehensive, toggleable logging net that proves every RME addition/patch is reachable on macOS/iOS from process start through gameplay. Prefer concise one-line events with resolved paths, db handles, and success/failure flags.

## Toggle and output
- Single gate: env `RME_LOG=1` or config key `debug/rme_log=1` to enable all RME logs; default off in release.
- Optional filters: allow `RME_LOG=db,map,script,proto,text,art,sound` comma list to reduce noise when needed.
- Output target: emit to stderr and to a rotating file `rme.log` in working dir (Contents/MacOS) with size cap; include prefix `[RME]` and timestamp.
- Avoid per-frame spam; only log resource resolutions, opens, failures, and one-shot inventories.

## Startup and path resolution
- winmain (macOS): log SDL base path, working-dir candidates (MacOS, Resources, parent), and chosen chdir target. Note presence/absence of `fallout.cfg`, `master.dat`, `critter.dat`, `data/` at each candidate.
- fallout.cfg: log resolved path, whether loaded, and overrides applied from argv/env. Dump effective values for `master_dat`, `critter_dat`, `master_patches`, `critter_patches`, language, splash, music paths.
- DB init: in `game_init_databases` log `db_init` inputs and whether master/critter handles opened; on failure log cwd and patch path.
- Patch path invariants: one-time scan that confirms `data/`, `data/data/` hard-coded files (badwords.txt, vault13.gam), and lower-case enforcement. Warn on mixed-case hits.

## Generic db access
- `db_fopen`: log requested path, selected database (master vs critter vs patches), resolved native path, and success/failure. Include when falling back from patch to .dat.
- Case warning: if a file exists with different case in patch path, emit a warning once per file.
- `db_get_file_list`: gate to log enumerations used for validation (maps, proto, art, text).

## Asset classes and states
- Maps: in `map_load` log map and gam names, chosen db handle, and failures. Startup inventory: list all `maps/*.map` from patch path and .dat, flag missing RME maps.
- Scripts (.int): in `scripts.cc::loadProgram` log script path, current `cd_path_base` and `script_path_base`, and failure reasons. Log `scripts.lst` parse with entry count and missing files.
- Proto: in `proto_list_str` and proto load, log requested PID/type, path, and missing `.lst`/`.pro` with which db was selected. Startup check: enumerate `proto/*/*.pro` and compare to `.lst` entries; summarize missing/extra per type.
- Text/messages: in `message_load` log language, attempted localized paths, and missing files. One-shot check: verify `text/english/game/*.msg` and `text/english/dialog/*.msg` presence and casing.
- Art (FRM/PAL): in art cache loader log missing FRM/PAL with fid and resolved path. Startup probe: ensure `art/intrface/*.frm` (UI set) and `art/tiles/grid000.frm` exist in patch path.
- Sound/Music: log failures for `sound/music/*.acm` and SFX lookups; include fallback attempts and effective music paths from config.
- Movies: log movie open failures (intro/splash) with resolved paths to catch missing/case issues.
- Saves: when opening save slots, log base path and whether proto/script/text assets needed during load are found.
- f1_res.ini and config mirrors: log load of `f1_res.ini` and any per-platform overrides; dump key display/touch values in effect. Warn if file is missing or mismatched casing. When fallback to default resolutions occurs, log the chosen values.
- Bundled app resources: log presence of Info.plist, icons, launch storyboard, and embedded resources in Contents/Resources vs Contents/MacOS. Emit warning if required data/assets are only in one candidate and not the chosen working dir.
- Patched data tree completeness: one-shot walk of patched data folder (and .dat indexes) to confirm presence of every expected subdir: `art/`, `data/`, `sound/`, `music/`, `proto/`, `text/`, `scripts/`, `maps/`, `movies/`, `data/data/` (hard-coded files). Summarize missing or extra top-level entries.

## Validation scenarios
- Boot path: capture logs from process start through main menu (includes chdir, cfg load, db init, splash/movie loads).
- RME map smoke test: load an RME map (e.g., Hub/Junktown) and confirm map/scripts/proto/text/art assets log as found.
- Asset sweeps: run one-shot inventories (maps, proto, text, art) with `RME_LOG` on and store the resulting `rme.log` as evidence.
- App-bundle sweep: with `RME_LOG` on, run a pass that inspects both Contents/MacOS and Contents/Resources to ensure data files, cfg, f1_res.ini, and assets are present in at least one candidate; record chosen working dir and any gaps.

## Exit criteria
- With `RME_LOG=1`, there are zero missing-asset warnings across startup, inventories, and map load. Any case-mismatch warnings must be resolved or documented.


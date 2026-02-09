# Script Reference Audit

- scripts.lst entries: 966
- missing expected .int files: 63
- missing .int files with any reference signal (proto/map): 17

## Notes
- Runtime script filename is always `<base>.int` regardless of `.int` vs `.ssl` in scripts.lst (see `scr_index_to_name`).
- `map_header_ref_*` is derived from MAP header `scriptIndex` (1-based in file, converted to 0-based).
- `map_script_ref_*` is derived from the MAP's serialized scripts section (parsed like `scr_load`).

## Missing Scripts With Reference Signals

- idx=219 token=JunkDemo.int expected=SCRIPTS\JunkDemo.INT map_header_refs=1
- idx=372 token=DemoComp.int expected=SCRIPTS\DemoComp.INT map_script_refs=1
- idx=379 token=DemoDoor.int expected=SCRIPTS\DemoDoor.INT map_script_refs=1
- idx=401 token=Phrax.int expected=SCRIPTS\Phrax.INT map_script_refs=1
- idx=402 token=DemoGen.int expected=SCRIPTS\DemoGen.INT map_script_refs=1
- idx=403 token=DemoCryp.int expected=SCRIPTS\DemoCryp.INT map_script_refs=4
- idx=404 token=DemoFool.int expected=SCRIPTS\DemoFool.INT map_script_refs=2
- idx=405 token=Lenny.int expected=SCRIPTS\Lenny.INT map_script_refs=1
- idx=407 token=Skizzer.int expected=SCRIPTS\Skizzer.INT map_script_refs=1
- idx=408 token=Pez.int expected=SCRIPTS\Pez.INT map_script_refs=5
- idx=409 token=Rock.int expected=SCRIPTS\Rock.INT map_script_refs=1
- idx=410 token=Lex.int expected=SCRIPTS\Lex.INT map_script_refs=1
- idx=411 token=Rayze.int expected=SCRIPTS\Rayze.INT map_script_refs=1
- idx=412 token=Skippy.int expected=SCRIPTS\Skippy.INT map_script_refs=1
- idx=413 token=Baka.int expected=SCRIPTS\Baka.INT map_script_refs=1
- idx=414 token=ScoutC.int expected=SCRIPTS\ScoutC.INT map_script_refs=2
- idx=415 token=ScoutF.int expected=SCRIPTS\ScoutF.INT map_script_refs=1

## Outputs
- CSV: 12_script_refs.csv
- MD: 12_script_refs.md

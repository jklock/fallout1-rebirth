# Script Reference Audit

- scripts.lst entries: 966
- missing expected .int files: 0
- missing .int files with any reference signal (proto/map): 0

## Notes
- Runtime script filename is always `<base>.int` regardless of `.int` vs `.ssl` in scripts.lst (see `scr_index_to_name`).
- `map_header_ref_*` is derived from MAP header `scriptIndex` (1-based in file, converted to 0-based).
- `map_script_ref_*` is derived from the MAP's serialized scripts section (parsed like `scr_load`).

## Missing Scripts With Reference Signals

(none)

## Outputs
- CSV: 12_script_refs.csv
- MD: 12_script_refs.md

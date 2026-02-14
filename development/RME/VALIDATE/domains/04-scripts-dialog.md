# Scripts And Dialog Validation Exercises

Last updated: 2026-02-14

## Exercises
1. Run all domain commands.
2. Record command results and blockers.
3. Re-run after fixes until pass.

## Commands
- `python3 scripts/test/rme-audit-script-refs.py --patched-dir GOG/patchedfiles --out-dir development/RME/validation/raw`

## Run Log
- Baseline run timestamp (UTC): `2026-02-14T05:55:12Z`
- Baseline result: pass
- Regression rerun timestamp (UTC): `2026-02-14T13:17:29Z`
- Regression rerun result: fail (`TypeError: write_text() got an unexpected keyword argument 'newline'`)
- Failure classification: harness/tooling issue
- Remediation: update `scripts/test/rme-audit-script-refs.py` output write call
- Impacted rerun timestamp (UTC): `2026-02-14T13:17:57Z`
- Impacted rerun result: pass

## Result
- Result: pass
- Blockers:
- None.
- Next action:
- None; domain is complete.

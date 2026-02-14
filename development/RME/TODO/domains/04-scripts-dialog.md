# Scripts And Dialog TODO

Last updated: 2026-02-14

## Tasks
- [x] Run domain validation commands.
- [x] Triage and classify failures.
- [x] Apply remediation and rerun smallest impacted command.
- [x] Update domain outcome document.

## Commands
- `python3 scripts/test/rme-audit-script-refs.py --patched-dir GOG/patchedfiles --out-dir development/RME/validation/raw`

## Failure Triage
- Baseline command passed (`2026-02-14T05:55:12Z`).
- Regression rerun failed (`2026-02-14T13:17:29Z`) with unsupported `Path.write_text(..., newline=...)` usage.
- Classification: harness/tooling issue.

## Fix
- Updated `scripts/test/rme-audit-script-refs.py` output writing to append `"\n"` directly.
- Reran the impacted command (`2026-02-14T13:17:57Z`) and verified regenerated outputs.

## Current State
- Domain complete.
- Automated script/dialog reference validation passes with canonical `GOG/patchedfiles`.

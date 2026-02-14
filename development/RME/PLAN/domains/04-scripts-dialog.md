# Scripts And Dialog Plan

Last updated: 2026-02-14

## Objective
Verify script and dialog asset references resolve cleanly against canonical patched data.

## Coverage Target
- Domain-specific blockers are reduced to zero.
- Domain validation commands complete cleanly.

## Primary Commands
- `python3 scripts/test/rme-audit-script-refs.py --patched-dir GOG/patchedfiles --out-dir development/RME/validation/raw`

## Execution Summary
- Baseline audit run (`2026-02-14T05:55:12Z`) passed.
- Regression rerun (`2026-02-14T13:17:29Z`) failed with `TypeError: write_text() got an unexpected keyword argument 'newline'`.
- Root-cause class: harness/tooling issue.
- Remediation: updated `scripts/test/rme-audit-script-refs.py` to write newline-terminated output without unsupported `Path.write_text(..., newline=...)`.
- Impacted rerun (`2026-02-14T13:17:57Z`) passed and regenerated script reference outputs.
- Under the active acceptance criteria, automated load/reference integrity is sufficient; manual branch walkthroughs are non-blocking.

## Status
- Domain status: complete
- Blocker-level defects: none

## Evidence
- `development/RME/validation/scripts-dialog/04-audit-script-refs-20260214T055512Z.log`
- `development/RME/validation/scripts-dialog/04-audit-script-refs-20260214T131729Z.log`
- `development/RME/validation/scripts-dialog/04-audit-script-refs-rerun-20260214T131757Z.log`
- `development/RME/validation/raw/12_script_refs.csv`
- `development/RME/validation/raw/12_script_refs.md`

# Patch Integrity Plan

Last updated: 2026-02-14

## Objective
Guarantee patched RME output is complete, validated, and sourced from canonical `GOG/patchedfiles`.

## Scope
- Canonical source enforcement
- Overlay payload integrity
- DAT patch integrity
- Validation script reliability

## Baseline Commands
- `./scripts/test/rme-ensure-patched-data.sh`
- `./scripts/patch/rebirth-validate-data.sh --patched GOG/patchedfiles --base GOG/unpatchedfiles --rme third_party/rme`
- `./scripts/patch/rebirth-refresh-validation.sh --unpatched GOG/unpatchedfiles --patched GOG/patchedfiles --rme third_party/rme --out development/RME/validation`

## Execution Summary
- Phase 1 complete: canonical source directories are present and usable.
- Phase 2 blocker found: refresh script referenced missing helper path `scripts/patch/rme-crossref.py`.
- Failure class: path resolution issue.
- Targeted fix applied in `scripts/patch/rebirth-refresh-validation.sh`: switched helper paths to `scripts/test/rme-crossref.py` and `scripts/test/rme-find-lst-candidates.py`.
- Phase 3 complete: reran impacted command first, then full baseline set; all pass.

## Status
- Domain status: complete
- Blocker-level integrity defects: none

## Evidence
- `development/RME/validation/raw/rebirth_validate.log`
- `development/RME/validation/raw/12_script_refs_run.log`
- `development/RME/validation/raw/_run_complete_notice.txt`

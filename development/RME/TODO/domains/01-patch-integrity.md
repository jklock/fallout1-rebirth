# Patch Integrity TODO

Last updated: 2026-02-14

## Tasks
- [x] Confirm canonical source data is present (`GOG/patchedfiles`, `GOG/unpatchedfiles`, `third_party/rme`).
- [x] Run domain validation commands.
- [x] Triage and classify failures.
- [x] Apply minimal targeted fix.
- [x] Re-run impacted command first.
- [x] Re-run full baseline command set until stable.
- [x] Update plan/outcome/validate/progress documents.

## Failure Triage
- `rebirth-refresh-validation.sh` failed at crossref step.
- Classification: path resolution issue.
- Root cause: script referenced non-existent `scripts/patch/*.py` helper paths.

## Fix
- Updated helper invocations to `scripts/test/rme-crossref.py` and `scripts/test/rme-find-lst-candidates.py`.

## Current State
- All domain baseline commands pass.

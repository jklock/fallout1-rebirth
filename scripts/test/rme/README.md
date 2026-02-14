# scripts/test/rme

Last updated (UTC): 2026-02-14

Python entrypoint for RME validation workflows.

## Primary Command
- `python3 scripts/test/rme/suite.py MODE`

## Modes
- `quick`: fast CI-style fixture validation.
- `patchflow`: single patchflow run.
- `autofix`: patchflow with autofix integration coverage.
- `full`: full end-to-end validation (`test-rme-end-to-end.sh`).
- `all`: `quick` then `full`.

## Notes
- This suite is the recommended end-user entrypoint for RME workflows.
- Existing `test-rme-*` scripts remain available for granular debugging.

# Maps Runtime Outcome

Last updated: 2026-02-14

## Status
- Current state: Complete

## Success Criteria
- Domain commands pass.
- No blocker defects remain for this domain.

## Summary Of Changes
- Completed full 72-map runtime sweep and patchlog analysis.
- Identified a single false-fail on `JUNKDEMO.MAP` (process exit `2`) with otherwise clean full-load verification.
- Remediated harness behavior in:
- `scripts/test/rme-runtime-sweep.py`
- `scripts/test/rme-repeat-map.py`
- Revalidated with targeted `JUNKDEMO` rerun and full-sweep rerun.
- Revalidated again after domain `06` harness updates with targeted `JUNKDEMO` regression retest (`2026-02-14T14:35:54Z`).

## Validation Result
- Full sweep coverage: 72/72 maps.
- Runtime sweep status: pass after remediation.
- Patchlog analyzer status: pass (no suspicious map-level analyzer findings).
- Hotspot status (`CARAVAN`, `ZDESERT1`, `TEMPLAT1`): pass in full sweep.
- Post-domain `06` regression retest (`JUNKDEMO`): pass.

## Blockers
- None.

## Evidence Paths (local-only)
- `development/RME/validation/runtime/02-runtime-sweep-20260214T041721Z.log`
- `development/RME/validation/runtime/02-junkdemo-retest-20260214T045853Z.log`
- `development/RME/validation/runtime/02-junkdemo-retest-postfix-20260214T050101Z.log`
- `development/RME/validation/runtime/02-runtime-sweep-rerun-20260214T050200Z.log`
- `development/RME/validation/runtime/runtime_map_sweep.csv`
- `development/RME/validation/runtime/runtime_map_sweep.md`
- `development/RME/validation/runtime/runtime_map_sweep_run.log`
- `development/RME/validation/runtime/patchlogs/patchlog_summary.md`
- `development/RME/validation/runtime/02-regression-junkdemo-20260214T143554Z.log`

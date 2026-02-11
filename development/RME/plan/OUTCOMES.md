# Expected Outcomes & Acceptance Criteria — RME Patchflow

## Canonical outcomes
- Reproducible, machine-readable test runs that use `GOG/patchedfiles` as the authoritative patched dataset.
- Self-test reports (`rme-selftest.json`) and aggregated run summaries (`rme-run-summary.json`) for every executed run.
- Clear pass/fail criteria documented and enforced by the parser.

## Acceptance criteria (default)
- `rebuild-validate-data.sh --patched GOG/patchedfiles` passes (or defects recorded if base validation needs special handling).
- `rme-run-summary.json` has `pass: true` with:
  - `db_open_failures == 0` (unless whitelisted)
  - `selftest_failures == 0` (maps/scripts/protos/text/art/sound)
  - `case_mismatch_warnings` allowed but recorded (0 fatal unless whitelisted)
- Artifacts produced and saved under `tmp/` and `development/RME/validation/` with timestamps.

## Allowed deviations / Whitelist
- Non-fatal case-only mismatches may be accepted and recorded in a whitelist file `development/RME/validation/whitelist.txt` with regex lines that the parser will ignore.

## When to stop iterating
- Stop when `rme-run-summary.json` passes or when a blocking decision is needed (documented in `development/RME/todo/` and referenced from the task in `TASKS.md`).

## Artifacts (per run)
- `tmp/rme-run-<timestamp>/app.stdout` — captured app stdout
- `tmp/rme-run-<timestamp>/app.stderr` — captured app stderr
- `tmp/rme-run-<timestamp>/rme.log` — runtime logging
- `tmp/rme-run-<timestamp>/rme-selftest.json` — selftest details
- `tmp/rme-run-<timestamp>/rme-run-summary.json` — parsed summary
- `development/RME/validation/run-<timestamp>/report.md` — human readable report of the above

## Success Handover
- Create PR with change commits and link to the validation artifacts. Include a short summary of remaining issues if any (prefer none).
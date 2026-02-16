# Dev Outcomes - Required End State

## Outcome A - Input Reliability
- No transient cursor jumps.
- No stale-position click behavior.
- No dead-input sessions after startup.
- Finger, pencil, and trackpad all map consistently to mouse semantics.

Measured by:
- automated input scenario suite
- repeated simulator/headless runs
- unattended loop full-green pass

## Outcome B - Config Compatibility
- Every key from unpatched baseline manifests has functional runtime behavior.
- No baseline key is silently ignored.
- Templates and shipped configs expose supported keys only from compatibility map.

Measured by:
- per-key parse/apply/behavior tests
- compatibility matrix marked fully wired
- unattended config suite full-green pass

## Outcome C - Unattended Operation
- One command runs both tracks repeatedly until 100% pass.
- Logs and state artifacts are persisted for each round.
- Non-zero exit if max rounds reached before full green.
- Fresh build artifacts are validated (not stale binaries).

Measured by:
- `dev/run-unattended-until-100.sh` round summary and exit status
- fresh build + release outputs:
  - `releases/prod/macOS/Fallout 1 Rebirth.app`
  - `releases/prod/iOS/fallout1-rebirth.ipa`

## "Done" Definition
Done means all three outcomes are true in the same execution window:
1. Input suite: 100%
2. Config suite: 100%
3. Combined unattended round: 100%

## Latest Proof Snapshot
- Timestamp: `2026-02-15T16:03:04Z`
- History row: `1	both	2	2	100	PASS	2026-02-15T16:03:04Z`
- Step summary:
  - `config/rme_quick`: `PASS`
  - `config/rme_full`: `PASS`
  - `config/config_compat_gate`: `PASS`
  - `input/macos_headless`: `PASS`
  - `input/ios_headless`: `PASS`

## Latest Input-Only Snapshot
- Timestamp: `2026-02-15T17:25:24Z`
- History row: `1	input	1	1	100	PASS	2026-02-15T17:25:24Z`
- Step summary:
  - `input/input_layer`: `PASS`
  - `input/macos_headless`: `PASS`
  - `input/ios_headless`: `PASS`

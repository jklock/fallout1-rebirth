# Blocking: Proposed RME_CASE_FALLBACK opt-in change

**timestamp:** 2026-02-12T05:00:00Z

**reason:** The proposed `RME_CASE_FALLBACK=1` runtime toggle alters file-open behavior by attempting case-insensitive fallbacks when `db_fopen` (and message loads) fail to find a file. This is a policy-level change that may hide data inconsistencies or mask upstream issues; human review and explicit approval are required.

**proposed implementation (summary):**
- Add an opt-in runtime check in `db_fopen` (and message loaders) that when `RME_CASE_FALLBACK=1` is set, attempts a case-insensitive lookup within the DAT archive (enumerating directory entries and matching case-insensitively) before returning failure.
- Log fallback attempts with `rme` logs (e.g., `db` topic with a `case-fallback` message) and ensure no canonical filename mutation occurs.
- Add unit tests and an integration test that use the test harness (see `scripts/test/test-rme-patchflow-autofix.sh` and `scripts/test/tools/fake_fallout_runner`) to verify both fallback-on and fallback-off behaviors.

**risks / considerations:**
- May change failure semantics for mods or data; could mask distribution packaging errors.
- Might hide real incompatibilities that should be surfaced to mod authors.
- Must be opt-in (off by default) and clearly documented.

**recommended next steps:**
1. Review the proposed design and confirm that an opt-in fallback is acceptable for this project.
2. If approved, execute the following steps locally (do not merge without approval):

```bash
# Create a branch (human operator) and apply the change via patch (example):
git checkout -b rme/t009-case-fallback
# (apply provided patch file located in development/RME/fixes-proposed/ or create new set of commits)
# Run formatting and checks
./scripts/dev/dev-format.sh
./scripts/dev/dev-check.sh
# Run unit tests and integration test (fast fixture)
python3 scripts/test/test_parse_rme_log.py
python3 scripts/test/test_rme_autofix.py
./scripts/test/test-rme-patchflow-autofix.sh
# If tests pass, push changes and open PR for human review
git add ... && git commit -m "task(RME/T009): opt-in case-insensitive db_fopen fallback (RME_CASE_FALLBACK)"
git push origin rme/t009-case-fallback
```

**blocking action required:** Please review and respond with either: `approve` to implement and proceed on a new branch, or `reject` to leave the opt-in proposal unimplemented. If `approve`, also confirm whether automated merging of this opt-in should be allowed or if manual approval is required when whitelisting or code modifications are proposed.

**artifacts:** None yet; this file was created to request human approval before implementing code changes.

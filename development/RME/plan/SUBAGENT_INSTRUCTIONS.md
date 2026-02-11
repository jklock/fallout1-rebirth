# Subagent Instructions — RME Validation (How to operate)

These are the exact instructions that any autonomous subagent (Plan / Implement / Test / Report) must follow while executing RME patchflow validation work.

A. Run the Plan agent (one-time)
- Confirm `GOG/patchedfiles` is present and valid.
- Create/verify tasks in `development/RME/plan/TASKS.md` and set acceptance criteria.
- Create these plan docs if missing: `PROCESS.md`, `TASKS.md`, `OUTCOMES.md`.

B. Implement agent (code changes)
- Make focused changes with tests and clear commit messages: `task(RME/T###): short message`.
- Steps per task:
  1. Run `./scripts/dev/dev-check.sh` (format & lint fixes).
  2. Run `./scripts/dev/dev-verify.sh` (build + static checks).
  3. Run unit tests and integration steps locally where available.
  4. Commit when green. Use small commits and logical granularity.

C. Test agent (orchestrator)
- Prepare run environment:
  - `TMPDIR=tmp/rme-run-<timestamp>`
  - `WORKDIR=$TMPDIR/work` (copy `GOG/patchedfiles` -> `WORKDIR` using `rsync -a` to preserve case)
- Run pipeline:
  1. `./scripts/patch/rebirth-validate-data.sh --patched $WORKDIR --base GOG/unpatchedfiles` (validate overlay)
  2. Build the app `./scripts/build/build-macos.sh`.
  3. Run the app with envs:
     - `RME_WORKING_DIR=$WORKDIR`
     - `RME_SELFTEST=1`
     - `RME_LOG=all` (or filtered list)
     - `F1R_AUTORUN_MAP=1` (when running full map load)
     - Optional timeout wrapper (`timeout`/`gtimeout`) with 120s default.
  4. Collect artifacts: app stdout/stderr, `rme.log`, `rme-selftest.json`.
  5. Run parser: `scripts/test/parse-rme-log.py --rme-log rme.log --selftest rme-selftest.json --whitelist development/RME/validation/whitelist.txt` and produce `rme-run-summary.json`.
  6. Save artifacts into `development/RME/validation/run-<timestamp>/` and put a short `report.md` summarizing pass/fail with core log excerpts.

D. Repair iteration rules
- If tests fail:
  1. Analyze `rme-selftest.json` and `rme.log` for reproducible errors.
  2. Try conservative fixes (add logging, fix path normalization, small bug fix) and re-run.
  3. After each code change, run dev-check/dev-verify and a short test run.
  4. Commit each fix with `task(RME/T###): fix ...` and update task notes.
- If failure requires policy (e.g., accept data normalization, change case policy), create `development/RME/todo/<timestamp>-blocking-*.md` and stop for human approval.

E. Report agent
- For each run, create a short report file `development/RME/validation/run-<timestamp>/report.md` containing:
  - Summary pass/fail
  - Key failure lists
  - Commits applied this iteration
  - Next recommended steps
- Update progress in `development/RME/todo/progress.md`.

F. Governance & safety
- Do not edit `GOG/patchedfiles` in place.
- If a data-only normalization is strictly required for a reproducible run, implement it as an **optional** test helper script and document intent in `development/RME/plan/`.
- If the parser reports false positives, update the whitelist at `development/RME/validation/whitelist.txt` with an explanatory comment.

---

These instructions are the authoritative checklist for any autonomous subagent working on the RME validation flow.
# Development Process — Autonomous Subagent Governance

Purpose
- Define a clear, repeatable process for autonomous subagents (Plan / Implement / Test / Report) that will execute the RME patch validation work with minimal human interaction.

Scope
- This process applies to any autonomous work that a subagent (or chain of subagents) performs in the repository, including planning, code changes, test automation, iterating on fixes, and producing artifacts.

Principles
- Plan → Implement → Test → Report: every change flows through these stages and is documented.
- Small, focused commits: each change is a single responsibility with a descriptive commit message referencing a task ID.
- Reproducible artifacts: test runs and logs are persisted under `tmp/` and `development/RME/validation/` with timestamps.
- Data safety: do not modify RME or game data under `GOG/patchedfiles` or `third_party/rme` unless an explicit, documented normalization step is required *only* for test harness reproducibility.

Lifecycle (subagent responsibilities)
1. Plan
   - Create/update task entries and a short plan that defines acceptance criteria and steps.
   - Record expected artifacts and test commands.
2. Implement
   - Make small, well-tested code changes.
   - Run `./scripts/dev/dev-check.sh` (format & lint) and `./scripts/dev/dev-verify.sh` (build + quick checks) locally.
   - Commit with message prefix `task(RME/T###): short summary`.
3. Test
   - Run the orchestrator `scripts/test/test-rme-patchflow.sh` (or agent-run equivalent) using `GOG/patchedfiles` as the authoritative patched dataset.
   - Collect artifacts: `rme.log`, `rme-selftest.json`, program stdout/stderr, and `rme-run-summary.json`.
4. Report
   - Save run artifacts under `tmp/rme-run-<timestamp>/` and `development/RME/validation/<timestamp>/` and update the task status.
   - If blocked by design decisions, create a blocking issue file `development/RME/todo/<timestamp>-blocking-*.md` with reproduction steps and log excerpts.

Reporting & Artifacts
- Run workspace: `tmp/rme-run-YYYYMMDD-HHMMSS/` — contains raw logs and JSON outputs.
- Canonical artifacts: `development/RME/validation/run-YYYYMMDD-HHMMSS/` — contains final summary and human-readable report.md.
- Commits: small, focused, tested. If a change touches multiple responsibilities, split commits.

Escalation (Blocking)
- If a change requires a risky algorithmic approach, human policy decision, or data modifications, stop and open a blocking file under `development/RME/todo/` and mark the current task as blocked.

Subagent coordination rules
- Use `runSubagent` for complex multi-step autonomous work. Each run must produce a concise final report in the format described below.
- Limit concurrency: only one major implementation subagent should be 'in-progress' for the same task ID.
- Use the `development/RME/plan/TASKS.md` file to coordinate ownership and status updates.

RunSubagent Final Report Format
- Summary: short one-line status.
- Changes: list of commits created (hash + message).
- Artifacts: paths to `tmp/` and `development/RME/validation/` folders produced.
- Test result: pass/fail with counts and core failures.
- Blockers: description + path to blocking issue file if any.

---

This process document is the canonical governance for subagents working on RME validation and related tasks.
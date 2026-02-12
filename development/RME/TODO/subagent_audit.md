# Subagent: Audit & cleanup — whitelist, placeholder audit, GNW anomaly triage

Purpose
- Apply/verify whitelist proposals, audit placeholder usage (`allnone.int`, `blank.frm`), and run targeted patchlog analysis to triage GNW render anomalies.

Non-interactive commands (exact)
- Whitelist validation (dry-run):
  - python3 scripts/test/parse-rme-log.py development/RME/ARTIFACTS/evidence/runtime/patchlogs/*.patchlog.txt | tee development/RME/ARTIFACTS/evidence/gate-2/patchlog-parse-summary.txt
  - (If whitelist approved) apply `development/RME/fixes-proposed/whitelist-proposed.diff` to `development/RME/validation/whitelist.txt` and re-run `./scripts/test/test-rme-patchflow.sh` to confirm warnings suppressed.
- Placeholder audit (automated discovery):
  - grep -Ri "allnone\|blank.frm" GOG/patchedfiles/data || true
  - Save results to `development/RME/ARTIFACTS/evidence/gate-2/placeholder-audit.txt`
- GNW anomaly triage (automated analysis):
  - python3 scripts/dev/patchlog_analyze.py development/RME/ARTIFACTS/evidence/runtime/patchlogs/*.patchlog.txt > development/RME/ARTIFACTS/evidence/gate-2/patchlog-anomaly-report.txt

Acceptance criteria
- Whitelist: proposed whitelist entries either suppress known benign warnings or are rejected; `test-rme-patchflow.sh` shows no unexpected failures after whitelist apply.
- Placeholder audit: every `allnone.int`/`blank.frm` occurrence has owner and next-step recommendation documented.
- GNW anomaly triage: all `surf_pre>0 && surf_post==0` events are categorized as Data / Engine / False-positive; engine issues are flagged for dev owner.

Subagent prompt (use this EXACT prompt when launching a subagent to run audit tasks)

"Run the audit & cleanup automation for RME. Steps:
1) Scan `GOG/patchedfiles` for placeholders (`allnone.int`, `blank.frm`) and write `development/RME/ARTIFACTS/evidence/gate-2/placeholder-audit.txt` listing path, LST/proto references, and suggested owner.
2) Run `python3 scripts/dev/patchlog_analyze.py` across all patchlogs under `development/RME/ARTIFACTS/evidence/runtime/patchlogs/` and save the combined output to `development/RME/ARTIFACTS/evidence/gate-2/patchlog-anomaly-report.txt`.
3) Dry-run whitelist: run `./scripts/test/test-rme-patchflow.sh --skip-build GOG/patchedfiles` and report whether `whitelist-proposed.diff` would suppress the same warnings. If whitelist file is to be applied, create a patch file that adds the entries (do not commit), and re-run `test-rme-patchflow.sh` to verify.

Return a JSON summary: `placeholders` (list of found entries + recommended owner), `gnw_anomalies` (count + paths to analyzer outputs), `whitelist_effect` (before/after counts), and `artifacts` (paths). Include suggested remediation for each GNW anomaly (data fix / packaging / engine guard)."
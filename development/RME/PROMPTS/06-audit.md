# Subagent orchestration prompt — Audit & cleanup (whitelist, placeholders, GNW anomaly triage)

Subagent prompt (EXACT — pass this to the audit subagent):

"Run the automated audit tasks for RME (non-interactive). Steps:

1) Placeholder audit: grep `allnone` and `blank.frm` across `GOG/patchedfiles` and `development/RME/summary/rme-crossref.csv`. Write `development/RME/ARTIFACTS/evidence/gate-2/placeholder-audit.txt` listing each occurrence, referencing LST/PRO lines where present, and recommend an owner for remediation.

2) GNW anomaly triage: run `python3 scripts/dev/patchlog_analyze.py` over `development/RME/ARTIFACTS/evidence/runtime/patchlogs/*.patchlog.txt` and consolidate results to `development/RME/ARTIFACTS/evidence/gate-2/patchlog-anomaly-report.txt`. For each suspicious event classify as `data|packaging|engine|false-positive` and provide one-line remediation recommendation.

3) Whitelist dry-run: run `./scripts/test/test-rme-patchflow.sh --skip-build GOG/patchedfiles` and report the number of warnings that would be suppressed by `development/RME/fixes-proposed/whitelist-proposed.diff`. Do NOT apply or commit the whitelist; produce a patchfile suggestion and save it to `development/RME/ARTIFACTS/evidence/gate-2/whitelist-suggestion.diff` (if applicable).

Return JSON (exact schema):
{
  "placeholders": [{"path":"...","reference":"LST/PRO line","owner":"name or recommendation"}, ...],
  "gnw_anomalies": [{"map":"MAPNAME","lineno":N,"classification":"data|engine|packaging|false-positive","recommendation":"text"}, ...],
  "whitelist_effect": {"before":INT,"after":INT,"suggestion_path":"path-or-null"},
  "artifacts": ["paths..."],
  "errors": ["text..."]
}

Fail rules:
- If placeholder usage is unowned or affects critical maps (CHILDRN1/CHILDRN2/HUBDWNTN), mark as `errors` and set `pass=false`.

Do not modify production data or source — only analyze and report."
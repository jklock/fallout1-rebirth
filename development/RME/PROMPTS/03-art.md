# Subagent orchestration prompt — Art (FRM / LST verification + anomaly triage)

Subagent prompt (EXACT — pass this to the art subagent):

"Run automated art verification for RME (non-interactive). Steps:

1) Count FRM groups and save results:
   - ls GOG/patchedfiles/data/art/critters/ | grep -Ei "nachld|hanpwr|malieu|mamtnt" -n || true
   - Save to `development/RME/ARTIFACTS/evidence/gate-2/art/A-1-critter-counts.txt`.

2) Locate `CRITTERS.LST` and write a snippet showing lines that reference `NACHLD`, `HANPWR`, `MALIEU` to `development/RME/ARTIFACTS/evidence/gate-2/art/A-2-critter-lst-snippet.txt`.

3) Run the runtime sweep (if not already present) with `F1R_PATCHLOG=1` and collect `present-anomalies` and screenshots; ensure present-anomaly BMPs are copied to `development/RME/ARTIFACTS/evidence/runtime/present-anomalies/`.

4) Produce a `missing_frm_report` listing any FRM referenced by LST that has no corresponding file in `GOG/patchedfiles/data/art/critters/`.

Return JSON (exact schema):
{
  "frm_counts": {"nachld": INT, "hanpwr": INT, "malieu": INT, "mamtnt": INT},
  "lst_lines": INT,
  "missing_frms": ["NAME.frm", ...],
  "present_anomalies": ["path/to/bmp", ...],
  "artifacts": ["paths..."],
  "pass": true|false,
  "errors": ["text..."]
}

Failure conditions:
- If any LST references an FRM that does not exist, set `pass=false` and include the exact LST line and expected FRM filename.

Do not change data files; only report and save evidence."
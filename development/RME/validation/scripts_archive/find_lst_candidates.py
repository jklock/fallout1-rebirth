#!/usr/bin/env python3
"""find_lst_candidates.py

Parse rme-lst-report.md (patched) and for each missing reference search
GOG/patchedfiles and GOG/unpatchedfiles for case-insensitive candidates.
Produce CSV: GOG/validation/raw/lst_candidates.csv
"""
import csv
import os
import subprocess

INPUT='GOG/rme_xref_patched/rme-lst-report.md'
OUT='GOG/validation/raw/lst_candidates.csv'

if not os.path.exists(INPUT):
    print('Input LST report not found:', INPUT)
    raise SystemExit(1)

candidates=[]
with open(INPUT,'r',encoding='utf-8') as f:
    for line in f:
        line=line.strip()
        if line.startswith('- '):
            parts=line[2:].split('->')
            if len(parts)==2:
                lst=parts[0].strip()
                missing=parts[1].strip()
                # search for candidate files by basename (case-insensitive)
                try:
                    proc=subprocess.run(['bash','-lc', f"find GOG/patchedfiles GOG/unpatchedfiles -iname '{missing}' | sed -n '1,200p'"], capture_output=True, text=True)
                    found=proc.stdout.splitlines()
                except Exception as e:
                    found=[]
                if found:
                    for fpath in found:
                        candidates.append((lst, missing, fpath))
                else:
                    candidates.append((lst, missing, ''))

# write CSV
os.makedirs(os.path.dirname(OUT), exist_ok=True)
with open(OUT,'w',newline='',encoding='utf-8') as csvf:
    w=csv.writer(csvf)
    w.writerow(['lst_file','missing_token','candidate_path'])
    for row in candidates:
        w.writerow(row)

print('Wrote candidate matches to', OUT)

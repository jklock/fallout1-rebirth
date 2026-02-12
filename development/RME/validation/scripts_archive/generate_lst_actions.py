#!/usr/bin/env python3
"""Generate ISSUE-LST-002 action CSV from lst_candidates.csv
Produces: third_party/rme/docs/validation/ISSUE-LST-002_actions.csv
"""
import csv
import os
import ntpath
from pathlib import Path

base = Path('GOG')
lst_csv = base / 'validation' / 'raw' / 'lst_candidates.csv'
if not lst_csv.exists():
    raise SystemExit('Missing lst_candidates.csv')
# Build map of loose files by basename lowercased
search_dirs = [base / 'patchedfiles', base / 'unpatchedfiles']
loose_map = {}
for sd in search_dirs:
    if sd.exists():
        for root, dirs, files in os.walk(sd):
            for f in files:
                loose_map.setdefault(f.lower(), []).append(os.path.join(root, f))

# Read crossref patched
crossref = (base / 'validation' / 'raw' / 'rme-crossref-patched.csv')
dat_map = {}
if crossref.exists():
    with open(crossref, newline='') as cf:
        reader = csv.DictReader(cf)
        for r in reader:
            path = r.get('path', '')
            # Crossref paths are Windows-style (backslashes). Use ntpath for basename.
            bn = ntpath.basename(path).lower()
            dat_map.setdefault(bn, []).append(r.get('base_source', ''))

# Function to check RME LST for comment
rme_base = Path('third_party') / 'rme' / 'source' / 'DATA'

def check_rme_lst(lstfile, token):
    p = rme_base / Path(lstfile.replace('\\', '/'))
    if not p.exists():
        return False, ''
    try:
        with open(p, 'r', encoding='utf-8', errors='ignore') as fh:
            for line in fh:
                if token.lower() in line.lower():
                    return True, line.strip()
    except Exception:
        return False, ''
    return False, ''

out_rows = []
with open(lst_csv, newline='') as f:
    reader = csv.DictReader(f)
    for row in reader:
        lst_file = row['lst_file']
        token = row['missing_token']
        candidate = row.get('candidate_path', '')
        rme_present, rme_line = check_rme_lst(lst_file, token)
        if rme_present and 'no longer used' in rme_line.lower():
            rme_comment = 'NO_LONGER_USED'
            recommended = 'REVIEW_REMOVE_OR_COMMENT'
        else:
            rme_comment = rme_line
            recommended = ''
        bn = token.lower()
        loose = loose_map.get(bn, [])
        in_dat = bn in dat_map
        dats = ';'.join(sorted(set(dat_map.get(bn, [])))) if in_dat else ''
        if not recommended:
            if in_dat:
                recommended = 'EXTRACT_FROM_DAT'
            elif loose:
                recommended = 'COPY_FROM_LOOSE'
            else:
                recommended = 'MISSING_NEED_UPSTREAM'
        out_rows.append({
            'lst_file': lst_file,
            'missing_token': token,
            'rme_present': 'yes' if rme_present else 'no',
            'rme_line': rme_line,
            'present_in_dat': 'yes' if in_dat else 'no',
            'dat_name': dats,
            'loose_candidates': '|'.join(loose),
            'csv_candidate_path': candidate,
            'recommended_action': recommended,
        })

outp = Path('third_party') / 'rme' / 'docs' / 'validation' / 'ISSUE-LST-002_actions.csv'
outp.parent.mkdir(parents=True, exist_ok=True)
with open(outp, 'w', newline='') as outfh:
    fieldnames = ['lst_file', 'missing_token', 'rme_present', 'rme_line', 'present_in_dat', 'dat_name', 'loose_candidates', 'csv_candidate_path', 'recommended_action']
    writer = csv.DictWriter(outfh, fieldnames=fieldnames)
    writer.writeheader()
    for r in out_rows:
        writer.writerow(r)
print('Wrote', outp)

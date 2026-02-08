#!/usr/bin/env python3
"""generate_patch_mapping.py

Create GOG/validation/patch_mapping.csv from the patched rme-crossref CSV.
Fields: path,ext,size,sha256,base_source,patched_found,patched_path,recommended_action,priority
"""
import csv, os, subprocess
INCSV='GOG/validation/raw/rme-crossref-patched.csv'
OUT='GOG/validation/patch_mapping.csv'

priority_map={'PRO':'High','INT':'High','GAM':'High','MAP':'High','MSG':'High','LST':'High','FRM':'Medium','FR0':'Medium','FR1':'Medium','FR2':'Medium','FR3':'Medium','FR4':'Medium','FR5':'Medium'}

if not os.path.exists(INCSV):
    print('Missing crossref CSV:', INCSV)
    raise SystemExit(1)

rows=[]
with open(INCSV,'r',encoding='utf-8') as f:
    r=csv.reader(f)
    header=next(r)
    for parts in r:
        # path,ext,size,sha256,base_source,base_length,notes
        path=parts[0]
        ext=parts[1]
        size=parts[2]
        sha256=parts[3]
        base_source=parts[4]
        # locate candidate in patchedfiles (case-insensitive)
        basename=os.path.basename(path)
        try:
            proc=subprocess.run(['bash','-lc', f"find GOG/patchedfiles -type f -iname '{basename}' -print -quit"], capture_output=True, text=True)
            found=proc.stdout.strip()
        except Exception:
            found=''
        patched_found='yes' if found else 'no'
        patched_path=found
        if base_source.lower() in ['master.dat','critter.dat']:
            recommended_action='extract-to-overlay'
        elif base_source.strip()=='' :
            recommended_action='newfile-keep'
        else:
            recommended_action='inspect'
        priority=priority_map.get(ext.upper(),'Low')
        rows.append((path,ext,size,sha256,base_source,patched_found,patched_path,recommended_action,priority))

os.makedirs(os.path.dirname(OUT), exist_ok=True)
with open(OUT,'w',newline='',encoding='utf-8') as f:
    w=csv.writer(f)
    w.writerow(['path','ext','size','sha256','base_source','patched_found','patched_path','recommended_action','priority'])
    w.writerows(rows)

print('Wrote mapping to', OUT)

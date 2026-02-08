#!/usr/bin/env python3
import os, subprocess, shutil

pairs = []
with open('GOG/case_renames.txt') as f:
    for line in f:
        line=line.strip()
        if line.startswith('-'):
            parts=line[1:].split('<->')
            if len(parts)==2:
                a=parts[0].strip(); b=parts[1].strip()
                pairs.append((a,b))

logpath='GOG/validation/case_test_results.txt'
with open(logpath,'w') as out:
    out.write('Case-sensitivity test results\n')
    out.write('Mounted case-sensitive volume: /Volumes/cs_test\n\n')
    os.makedirs('/Volumes/cs_test/case_test', exist_ok=True)
    ci_dir='/tmp/case_test_ci'
    if os.path.exists(ci_dir):
        shutil.rmtree(ci_dir)
    os.makedirs(ci_dir, exist_ok=True)
    for i,(a,b) in enumerate(pairs,1):
        out.write(f'Pair {i}: {a} <-> {b}\n')
        # find both cases in patched and unpatched
        res = subprocess.run(['bash','-lc', f"find GOG/patchedfiles GOG/unpatchedfiles -iname '{a}' -o -iname '{b}' | sed -n '1,200p'"], capture_output=True, text=True)
        paths=[p for p in res.stdout.splitlines() if p]
        out.write('  Found paths:\n')
        for p in paths: out.write('    '+p+'\n')
        dest_cs=f'/Volumes/cs_test/case_test/pair_{i}'
        if os.path.exists(dest_cs):
            shutil.rmtree(dest_cs)
        os.makedirs(dest_cs)
        for p in paths:
            if os.path.isdir(p):
                subprocess.run(['cp','-a', p, dest_cs])
            else:
                subprocess.run(['cp', p, dest_cs])
        out.write('  /Volumes/cs_test listing:\n')
        out.write('\n'.join(subprocess.run(['ls','-la', dest_cs], capture_output=True, text=True).stdout.splitlines()) + '\n')
        # compute shasum
        entries=[os.path.join(dest_cs,fn) for fn in os.listdir(dest_cs)]
        if entries:
            out.write('  shasums:\n')
            out.write(subprocess.run(['shasum','-a','256']+entries, capture_output=True, text=True).stdout+'\n')
        else:
            out.write('  (no files)\n\n')
        # case-insensitive test
        dest_ci=os.path.join(ci_dir, f'pair_{i}')
        if os.path.exists(dest_ci):
            shutil.rmtree(dest_ci)
        os.makedirs(dest_ci)
        for p in paths:
            if os.path.isdir(p):
                subprocess.run(['cp','-a', p, dest_ci])
            else:
                subprocess.run(['cp', p, dest_ci])
        out.write('  /tmp listing (case-insensitive):\n')
        out.write('\n'.join(subprocess.run(['ls','-la', dest_ci], capture_output=True, text=True).stdout.splitlines()) + '\n')
        entries_ci=[os.path.join(dest_ci,fn) for fn in os.listdir(dest_ci)]
        if entries_ci:
            out.write('  shasums (ci):\n')
            out.write(subprocess.run(['shasum','-a','256']+entries_ci, capture_output=True, text=True).stdout+'\n')
        else:
            out.write('  (no files)\n\n')
        out.write('\n')

print('Done case-test; results written to',logpath)

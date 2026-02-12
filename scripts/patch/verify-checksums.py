#!/usr/bin/env python3
"""Verify checksums in third_party/rme/checksums.txt against files in GOG/patchedfiles.
Writes a report listing missing files, mismatched hashes, ambiguous matches, and unexpected extras.

Usage:
  scripts/patch/verify-checksums.py --checks third_party/rme/checksums.txt --overlay GOG/patchedfiles --out development/RME/ARTIFACTS/evidence/gate-2/patch-validation/checksums-verify.txt
"""
import argparse
import hashlib
import os
import re

parser = argparse.ArgumentParser(description="Verify RME checksums against patchedfiles overlay")
parser.add_argument("--checks", required=True)
parser.add_argument("--overlay", required=True)
parser.add_argument("--out", required=True)
args = parser.parse_args()

checks = args.checks
base = args.overlay
out = args.out

# Read checks
entries = []
with open(checks, "r", encoding="utf-8", errors="replace") as f:
    for ln in f:
        ln = ln.strip()
        if not ln or ln.startswith("#"):
            continue
        m = re.match(r"^([0-9a-fA-F]{64})\s+(.+)$", ln)
        if m:
            entries.append((m.group(1).lower(), m.group(2).strip()))

# Build file map
rel_map = {}  # lower rel -> actual path
basename_map = {}
for root, dirs, files in os.walk(base):
    for fn in files:
        ap = os.path.join(root, fn)
        rel = os.path.relpath(ap, base).replace("\\", "/").lower()
        rel_map[rel] = ap
        basename_map.setdefault(os.path.basename(rel), []).append(rel)

matched = set()
missing = []
mismatches = []
ambiguous = []

for expected_hash, expected_path in entries:
    exp_rel = expected_path.strip('/').lower()
    found = None
    # direct
    if exp_rel in rel_map:
        found = rel_map[exp_rel]
    else:
        # suffix match
        ends = [rel for rel in rel_map.keys() if rel.endswith('/' + exp_rel) or rel == exp_rel]
        if len(ends) == 1:
            found = rel_map[ends[0]]
        elif len(ends) > 1:
            # prefer shortest matching path
            ends_sorted = sorted(ends, key=lambda x: (len(x), x))
            found = rel_map[ends_sorted[0]]
        else:
            bn = os.path.basename(exp_rel)
            cand = basename_map.get(bn, [])
            if len(cand) == 1:
                found = rel_map[cand[0]]
            elif len(cand) > 1:
                ambiguous.append((expected_path, cand))
                continue
    if not found:
        missing.append(expected_path)
        continue
    # compute sha256
    h = hashlib.sha256()
    try:
        with open(found, 'rb') as fh:
            for chunk in iter(lambda: fh.read(8192), b''):
                h.update(chunk)
        actual = h.hexdigest()
        if actual != expected_hash:
            mismatches.append((expected_path, os.path.relpath(found, base).replace('\\','/'), expected_hash, actual))
        matched.add(os.path.relpath(found, base).replace('\\','/').lower())
    except Exception as e:
        mismatches.append((expected_path, str(found), expected_hash, f'ERROR:{e}'))

extras = [rel for rel in rel_map.keys() if rel not in matched]

with open(out, 'w', encoding='utf-8') as f:
    f.write('Checksums verification report\n')
    f.write('=============================\n\n')
    f.write(f'Total checksum entries: {len(entries)}\n')
    f.write(f'Files matched: {len(matched)}\n')
    f.write(f'Missing files: {len(missing)}\n')
    f.write(f'Mismatches: {len(mismatches)}\n')
    f.write(f'Ambiguous matches: {len(ambiguous)}\n')
    f.write(f'Unexpected extras in overlay: {len(extras)}\n\n')
    if missing:
        f.write('--- Missing files (present in checksums, not found in overlay) ---\n')
        for m in missing:
            f.write(m + '\n')
        f.write('\n')
    if mismatches:
        f.write('--- Mismatches (expected_hash vs actual_hash; found_at relative path) ---\n')
        for e in mismatches:
            f.write(f'ExpectedPath: {e[0]}\n FoundAt: {e[1]}\n Expected: {e[2]}\n Actual: {e[3]}\n---\n')
        f.write('\n')
    if ambiguous:
        f.write('--- Ambiguous matches (expected_path -> candidate_relpaths) ---\n')
        for e in ambiguous:
            f.write(e[0] + ' -> ' + ', '.join(e[1]) + '\n')
        f.write('\n')
    if extras:
        f.write('--- Unexpected extras found in GOG/patchedfiles (not referenced in checksums) ---\n')
        for x in sorted(extras):
            f.write(x + '\n')

print('Wrote verification report to', out)

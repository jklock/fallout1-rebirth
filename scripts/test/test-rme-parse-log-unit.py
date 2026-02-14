#!/usr/bin/env python3
import json
import os
import subprocess
import sys
import tempfile

# Simple functional test for test-rme-parse-log.py
SCRIPT = os.path.join(os.path.dirname(__file__), 'test-rme-parse-log.py')

# Create a small selftest JSON with one failure
selftest = {
    "totals": {"scripts_checked": 0, "maps_checked": 0, "proto_checked": 0, "messages_checked": 0, "art_checked": 0, "sound_checked": 0},
    "failures": [
        {"kind": "message", "path": "data/text/english/game/map.msg", "error": "message_load failed"}
    ]
}

with tempfile.TemporaryDirectory() as tmpdir:
    st_path = os.path.join(tmpdir, 'rme-selftest.json')
    with open(st_path, 'w', encoding='utf-8') as f:
        json.dump(selftest, f)

    # No rme.log (missing db errors) -> should fail because selftest failure exists and default thresholds 0
    proc = subprocess.run([sys.executable, SCRIPT, '--selftest', st_path], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    out = json.loads(proc.stdout)
    assert out['pass'] is False
    assert out['selftest_failures_total'] == 1

    # With whitelist matching the failure -> pass
    wl_path = os.path.join(tmpdir, 'whitelist.txt')
    with open(wl_path, 'w', encoding='utf-8') as f:
        f.write('message:data/text/english/game/map.msg\n')

    proc = subprocess.run([sys.executable, SCRIPT, '--selftest', st_path, '--whitelist', wl_path], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    out = json.loads(proc.stdout)
    assert out['pass'] is True

print('parse-rme-log.py basic tests: OK')

#!/usr/bin/env python3
"""
Unit tests for rme-autofix rules and basic dry-run behavior.
"""
import json
import os
import subprocess
import tempfile

SCRIPT = os.path.join(os.path.dirname(__file__), 'rme-autofix.py')
RULES = os.path.join(os.path.dirname(__file__), 'rme_autofix_rules.py')

# Import rules directly
import importlib.util
spec = importlib.util.spec_from_file_location('rules', RULES)
rules_mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(rules_mod)


def test_ensure_fallout_cfg_language():
    with tempfile.TemporaryDirectory() as wd:
        # create a selftest with a message failure
        st = {"failures": [{"kind": "message", "path": "data/text/english/game/map.msg", "error": "message_load failed"}]}
        with open(os.path.join(wd, 'rme-selftest.json'), 'w', encoding='utf-8') as f:
            json.dump(st, f)

        # create minimal fallout.cfg without language
        with open(os.path.join(wd, 'fallout.cfg'), 'w', encoding='utf-8') as f:
            f.write('[system]\nsome_setting=1\n')

        fixes = rules_mod.ensure_fallout_cfg_language(wd, {}, st)
        assert len(fixes) == 1
        f = fixes[0]
        assert f['type'] == 'edit'
        assert 'language=english' in f['updated']


def test_relocate_text_for_message_load():
    with tempfile.TemporaryDirectory() as wd:
        # create file under data/text/english/map.msg but failure expects game/map.msg
        os.makedirs(os.path.join(wd, 'data', 'text', 'english'), exist_ok=True)
        with open(os.path.join(wd, 'data', 'text', 'english', 'map.msg'), 'w', encoding='utf-8') as f:
            f.write('dummy')

        st = {"failures": [{"kind": "message", "path": "data/text/english/game/map.msg", "error": "message_load failed"}]}
        fixes = rules_mod.relocate_text_for_message_load(wd, {}, st)
        assert len(fixes) == 1
        f = fixes[0]
        assert f['type'] == 'copy_file'
        assert f['src'] == os.path.join('data', 'text', 'english', 'map.msg')
        assert f['dst'] == os.path.join('data', 'text', 'english', 'game', 'map.msg')


def test_autofix_dry_run_creates_proposed_diff():
    with tempfile.TemporaryDirectory() as tmp:
        # simulate a run dir
        workdir = os.path.join(tmp, 'work')
        os.makedirs(workdir, exist_ok=True)
        st = {"failures": [{"kind": "message", "path": "data/text/english/game/map.msg", "error": "message_load failed"}]}
        with open(os.path.join(workdir, 'rme-selftest.json'), 'w', encoding='utf-8') as f:
            json.dump(st, f)
        # create fallback source file
        os.makedirs(os.path.join(workdir, 'data', 'text', 'english'), exist_ok=True)
        with open(os.path.join(workdir, 'data', 'text', 'english', 'map.msg'), 'w', encoding='utf-8') as f:
            f.write('dummy')

        proc = subprocess.run([SCRIPT, '--workdir', workdir, '--iterations', '1', '--dry-run'], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        assert proc.returncode == 0
        prop = os.path.join(workdir, 'fixes', 'iter-1', 'proposed.diff')
        assert os.path.isfile(prop)


def test_whitelist_propose_and_blocking():
    with tempfile.TemporaryDirectory() as tmp:
        workdir = os.path.join(tmp, 'work')
        os.makedirs(workdir, exist_ok=True)
        st = {"failures": [{"kind": "message", "path": "data/text/english/game/map.msg", "error": "message_load failed"}]}
        with open(os.path.join(workdir, 'rme-selftest.json'), 'w', encoding='utf-8') as f:
            json.dump(st, f)
        # Run autofix requesting whitelist apply
        proc = subprocess.run([SCRIPT, '--workdir', workdir, '--iterations', '1', '--apply-whitelist', '--dry-run'], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        assert proc.returncode == 0
        # Check that a proposed diff was written into development/RME/fixes-proposed
        outdiff = os.path.join(os.path.dirname(os.path.dirname(__file__)), '..', 'development', 'RME', 'fixes-proposed', 'whitelist-proposed.diff')
        assert os.path.isfile(os.path.normpath(outdiff))
        # Check a blocking file was created under development/RME/todo
        todo_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), '..', 'development', 'RME', 'todo')
        found = False
        for f in os.listdir(os.path.normpath(todo_dir)):
            if f.endswith('-blocking-whitelist-apply.md'):
                found = True
                break
        assert found
    test_relocate_text_for_message_load()
    test_autofix_dry_run_creates_proposed_diff()
    print('rme-autofix.py unit tests: OK')

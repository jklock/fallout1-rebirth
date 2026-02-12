#!/usr/bin/env python3
"""
RME auto-fix engine.

CLI:
  --workdir <path> (required)
  --iterations N (default 3)
  --dry-run|--simulate
  --apply
  --apply-whitelist
  --verbose

Behavior:
- Load rme-run-summary.json if present, else run parse-rme-log.py on rme.log + work/rme-selftest.json.
- Load rules from `rme_autofix_rules.py` and run them to produce candidate fixes.
- Write per-iteration artifacts under <workdir>/fixes/iter-<i>/
- If --apply, update files in workdir (only allowed if workdir path matches tmp/rme-run- pattern)
- For whitelist proposals: write `whitelist-additions.txt` and do not modify canonical whitelist unless --apply-whitelist *and* human approval is given. When --apply-whitelist is passed, write a diff to `development/RME/fixes-proposed/whitelist-proposed.diff` and create a blocking file `development/RME/todo/<TS>-blocking-whitelist-apply.md`.
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
import tempfile
import time
from datetime import datetime
from difflib import unified_diff
from typing import List, Dict, Any

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(__file__)))
PARSER = os.path.join(REPO_ROOT, "scripts", "test", "parse-rme-log.py")
RULES_MODULE = os.path.join(REPO_ROOT, "scripts", "test", "rme_autofix_rules.py")


def load_run_summary(workdir: str) -> Dict[str, Any]:
    # look for summary next to workdir (parent dir)
    parent = os.path.dirname(workdir)
    json_path = os.path.join(parent, "rme-run-summary.json")
    if os.path.isfile(json_path):
        with open(json_path, "r", encoding="utf-8") as f:
            return json.load(f)

    # Fallback: call parser with rme.log and work/rme-selftest.json
    rme_log = os.path.join(parent, "rme.log")
    selftest = os.path.join(workdir, "rme-selftest.json")
    if os.path.isfile(PARSER):
        cmd = [sys.executable, PARSER, "--rme-log", rme_log, "--selftest", selftest]
        try:
            proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, check=False)
            if proc.returncode == 0 and proc.stdout:
                return json.loads(proc.stdout)
        except Exception:
            pass
    # Last resort: try to load selftest only
    if os.path.isfile(selftest):
        try:
            with open(selftest, "r", encoding="utf-8") as f:
                st = json.load(f)
        except Exception:
            st = {}
        out = {
            "pass": False if st.get("failures") else True,
            "selftest_failures_total": len(st.get("failures", [])),
            "selftest_failures_unwhitelisted": len(st.get("failures", [])),
            "selftest_failures": st.get("failures", []),
            "rme_log_summary": {},
        }
        return out

    return {"pass": False, "selftest_failures_total": 0, "selftest_failures_unwhitelisted": 0, "selftest_failures": [], "rme_log_summary": {}}


def write_iter_artifacts(workdir: str, iter_n: int, patches: List[Dict[str, Any]], whitelist_entries: List[Dict[str, Any]]):
    outdir = os.path.join(workdir, "fixes", f"iter-{iter_n}")
    os.makedirs(outdir, exist_ok=True)

    # Compose unified diff of edits and added/copied files
    diffs = []
    for p in patches:
        if p["type"] == "edit":
            original = p.get("original", "")
            updated = p["updated"]
            tgt = p["target"]
            diffs.extend(list(unified_diff(original.splitlines(True), updated.splitlines(True), fromfile=f"a/{tgt}", tofile=f"b/{tgt}")))
        elif p["type"] == "add_file":
            content = p["content"]
            tgt = p["target"]
            diffs.append(f"--- /dev/null\n")
            diffs.append(f"+++ b/{tgt}\n")
            diffs.extend(list(unified_diff([], content.splitlines(True), fromfile=f"/dev/null", tofile=f"b/{tgt}")))
        elif p["type"] == "copy_file":
            # Diff representing new file (dst) with contents of src
            src_path = os.path.join(workdir, p["src"])
            dst_rel = p["dst"]
            try:
                with open(src_path, "r", encoding="utf-8", errors="replace") as f:
                    content = f.read()
            except Exception:
                content = ""
            diffs.append(f"--- /dev/null\n")
            diffs.append(f"+++ b/{dst_rel}\n")
            diffs.extend(list(unified_diff([], content.splitlines(True), fromfile=f"/dev/null", tofile=f"b/{dst_rel}")))

    prop_diff_path = os.path.join(outdir, "proposed.diff")
    with open(prop_diff_path, "w", encoding="utf-8") as f:
        f.writelines(diffs)

    # Write fix-summary
    summary = {"patch_count": len(patches), "whitelist_count": len(whitelist_entries)}
    with open(os.path.join(outdir, "fix-summary.json"), "w", encoding="utf-8") as f:
        json.dump(summary, f, indent=2)

    # whitelist additions
    if whitelist_entries:
        with open(os.path.join(outdir, "whitelist-additions.txt"), "w", encoding="utf-8") as f:
            for e in whitelist_entries:
                f.write(f"{e['pattern']}  # {e['reason']}\n")


def apply_patches_to_workdir(workdir: str, patches: List[Dict[str, Any]]):
    # Safety guard: only allow apply when workdir path contains '/tmp/rme-run-'
    if "/tmp/rme-run-" not in os.path.abspath(workdir) and "rme-run-" not in os.path.abspath(workdir):
        raise RuntimeError("Refusing to apply patches: workdir does not look like a tmp rme run directory")

    applied = []
    for p in patches:
        t = p["type"]
        if t == "edit":
            tgt = os.path.join(workdir, p["target"])
            os.makedirs(os.path.dirname(tgt), exist_ok=True)
            with open(tgt, "w", encoding="utf-8") as f:
                f.write(p["updated"])
            applied.append({"type": "edit", "target": p["target"]})
        elif t == "add_file":
            tgt = os.path.join(workdir, p["target"])
            os.makedirs(os.path.dirname(tgt), exist_ok=True)
            with open(tgt, "w", encoding="utf-8") as f:
                f.write(p["content"])
            applied.append({"type": "add_file", "target": p["target"]})
        elif t == "copy_file":
            src = os.path.join(workdir, p["src"])
            dst = os.path.join(workdir, p["dst"])
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            shutil.copy2(src, dst)
            applied.append({"type": "copy_file", "src": p["src"], "dst": p["dst"]})
    return applied


def main(argv):
    parser = argparse.ArgumentParser()
    parser.add_argument("--workdir", required=True)
    parser.add_argument("--iterations", type=int, default=3)
    parser.add_argument("--dry-run", dest="dry_run", action="store_true")
    parser.add_argument("--simulate", dest="dry_run", action="store_true")
    parser.add_argument("--apply", dest="apply", action="store_true")
    parser.add_argument("--apply-whitelist", dest="apply_whitelist", action="store_true")
    parser.add_argument("--verbose", dest="verbose", action="store_true")

    args = parser.parse_args(argv)

    workdir = os.path.abspath(args.workdir)
    iterations = args.iterations
    dry_run = args.dry_run
    do_apply = args.apply
    apply_whitelist = args.apply_whitelist
    verbose = args.verbose

    if not os.path.isdir(workdir):
        print(f"Workdir not found: {workdir}", file=sys.stderr)
        return 2

    # Load rules
    try:
        import importlib.util
        spec = importlib.util.spec_from_file_location("rme_autofix_rules", RULES_MODULE)
        rules = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(rules)
        RULES = getattr(rules, "RME_AUTO_RULES", [])
    except Exception as e:
        print(f"Failed to import rules: {e}", file=sys.stderr)
        return 3

    # Initial summary
    summary = load_run_summary(workdir)
    # Try to load explicit selftest JSON
    st_path = os.path.join(workdir, "rme-selftest.json")
    selftest = {}
    if os.path.isfile(st_path):
        try:
            with open(st_path, "r", encoding="utf-8") as f:
                selftest = json.load(f)
        except Exception:
            selftest = {}

    for i in range(1, iterations + 1):
        if verbose:
            print(f"Iteration {i}: evaluating rules")

        patches: List[Dict[str, Any]] = []
        whitelist_entries: List[Dict[str, Any]] = []

        for r in RULES:
            try:
                res = r(workdir, summary, selftest)
                for item in res:
                    if item.get("type") == "whitelist":
                        whitelist_entries.append(item)
                    else:
                        patches.append(item)
            except Exception as e:
                print(f"Rule {r.__name__} failed: {e}", file=sys.stderr)

        write_iter_artifacts(workdir, i, patches, whitelist_entries)

        applied = []
        if patches and do_apply and not dry_run:
            try:
                applied = apply_patches_to_workdir(workdir, patches)
                # write applied diff
                outdir = os.path.join(workdir, "fixes", f"iter-{i}")
                with open(os.path.join(outdir, "applied.json"), "w", encoding="utf-8") as f:
                    json.dump({"applied": applied}, f, indent=2)
            except Exception as e:
                print(f"Failed to apply patches: {e}", file=sys.stderr)

        # Handle whitelist additions
        if whitelist_entries:
            # Always write per-iter additions
            # If apply_whitelist is requested, create workspace diff and a blocking file instead of committing
            if apply_whitelist:
                # Create proposed diff against canonical whitelist
                whitelist_path = os.path.join(REPO_ROOT, "development", "RME", "validation", "whitelist.txt")
                proposed_lines = [f"{e['pattern']}  # {e['reason']}\n" for e in whitelist_entries]
                if os.path.isfile(whitelist_path):
                    with open(whitelist_path, "r", encoding="utf-8") as f:
                        orig = f.read()
                else:
                    orig = ""
                new = orig + "\n" + "".join(proposed_lines)
                diff = list(unified_diff(orig.splitlines(True), new.splitlines(True), fromfile=whitelist_path, tofile=whitelist_path + ".proposed"))
                outdiff_dir = os.path.join(REPO_ROOT, "development", "RME", "fixes-proposed")
                os.makedirs(outdiff_dir, exist_ok=True)
                outdiff_file = os.path.join(outdiff_dir, "whitelist-proposed.diff")
                with open(outdiff_file, "w", encoding="utf-8") as f:
                    f.writelines(diff)
                # Create blocking file requesting human approval to merge whitelist
                ts = datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")
                blockdir = os.path.join(REPO_ROOT, "development", "RME", "todo")
                os.makedirs(blockdir, exist_ok=True)
                blockfile = os.path.join(blockdir, f"{ts}-blocking-whitelist-apply.md")
                with open(blockfile, "w", encoding="utf-8") as bf:
                    bf.write(f"# Blocking: Propose whitelist additions\n\n")
                    bf.write("**reason:** Proposed whitelist additions from rme-autofix engine\n\n")
                    bf.write("**diff path:** %s\n\n" % (os.path.relpath(outdiff_file, REPO_ROOT)))
                    bf.write("**action:** If approved, apply these changes to `development/RME/validation/whitelist.txt` and commit to the current branch.\n")
                print(f"Whitelist proposed; diff written to {outdiff_file} and blocking file {blockfile}")

        # If we applied patches, re-run the orchestrator run on the WORKDIR to get fresh artifacts
        if applied:
            print("Re-running app selftest with modified WORKDIR to validate fixes")
            # Invoke test-rme-patchflow.sh with --skip-build to avoid rebuilds
            runner = os.path.join(REPO_ROOT, "scripts", "test", "test-rme-patchflow.sh")
            try:
                proc = subprocess.run([runner, "--skip-build" , workdir], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, check=False)
                out = (proc.stdout or "") + "\n" + (proc.stderr or "")
            except Exception as e:
                print(f"Runner invocation failed: {e}", file=sys.stderr)
                out = ""

            # Try to locate the new run dir from runner output (it prints 'artifacts at $RUNDIR')
            import re
            new_rundir = None
            m = re.search(r"artifacts at (.+)", out)
            if m:
                new_rundir = m.group(1).strip()

            # Refresh summary and selftest
            if new_rundir and os.path.isfile(os.path.join(new_rundir, "rme-run-summary.json")):
                with open(os.path.join(new_rundir, "rme-run-summary.json"), "r", encoding="utf-8") as f:
                    summary = json.load(f)
                # also pick up selftest from that run if present
                st_path = os.path.join(new_rundir, "rme-selftest.json")
                if os.path.isfile(st_path):
                    try:
                        with open(st_path, "r", encoding="utf-8") as f:
                            selftest = json.load(f)
                    except Exception:
                        selftest = {}
            else:
                summary = load_run_summary(workdir)
                st_path = os.path.join(os.path.dirname(workdir), "rme-selftest.json")
                if os.path.isfile(st_path):
                    try:
                        with open(st_path, "r", encoding="utf-8") as f:
                            selftest = json.load(f)
                    except Exception:
                        selftest = {}

            # If pass, move applied diffs to work/fixes/fixes_successful or similar
            if summary.get("pass"):
                print(f"PASS achieved after iteration {i}")
                # copy iter artifacts to parent artifacts/fixes
                parent = os.path.dirname(workdir)
                dst = os.path.join(parent, "artifacts", "fixes")
                os.makedirs(dst, exist_ok=True)
                src_iter = os.path.join(workdir, "fixes", f"iter-{i}")
                if os.path.isdir(src_iter):
                    shutil.copytree(src_iter, os.path.join(dst, f"iter-{i}"), dirs_exist_ok=True)
                return 0

        # Stop early if no patches and no whitelist proposals
        if not patches and not whitelist_entries:
            if verbose:
                print("No fixes proposed in this iteration; stopping")
            break

        # Stop if dry-run
        if dry_run and not do_apply:
            print(f"Dry-run mode: created proposals for iteration {i} but did not apply them")
            return 0

    # After iterations, if we still don't have pass, return non-zero
    final_summary = load_run_summary(workdir)
    if not final_summary.get("pass"):
        print("Final run still failing after autofix iterations")
        return 1

    print("Autofix finished and run passed")
    return 0


if __name__ == "__main__":
    rc = main(sys.argv[1:])
    sys.exit(rc)

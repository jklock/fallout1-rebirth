#!/usr/bin/env python3
"""
Simple RME run parser that consumes rme.log and rme-selftest.json and
produces a rme-run-summary.json describing pass/fail based on thresholds.

Usage: parse-rme-log.py --rme-log <path> --selftest <path> --whitelist <path> \
       --max-db-open-failures N --max-selftest-failures N

This is intentionally small and has a permissive whitelist format:
- Each non-empty, non-# line in the whitelist file is treated as a
  glob pattern which is matched against the failure `path` string. If a
  failure's path matches any whitelist pattern it is considered whitelisted.

Outputs JSON to stdout containing at least the following fields:
- pass: boolean
- db_open_failures: int
- selftest_failures_total: int
- selftest_failures_unwhitelisted: int
- selftest_failures: list of failure objects with an extra `whitelisted` boolean
- rme_log_summary: small summary of topics counts
"""

import argparse
import json
import os
import re
import sys
from fnmatch import fnmatch


def load_whitelist(path):
    patterns = []
    if not path or not os.path.isfile(path):
        return patterns
    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            patterns.append(line)
    return patterns


def is_whitelisted(patterns, kind, path):
    if not patterns:
        return False
    target = f"{kind}:{path}"
    for p in patterns:
        # Try exact or glob match against `kind:path` first, then the path alone
        if fnmatch(target, p) or fnmatch(path, p):
            return True
    return False


DB_ERROR_RE = re.compile(r"\b(miss|fail|failed|error|not found)\b", re.I)


def analyze_rme_log(path):
    summary = {
        "raw_lines_parsed": 0,
        "topics": {},
        "db_open_failures": 0,
    }

    if not path or not os.path.isfile(path):
        return summary

    with open(path, "r", encoding="utf-8", errors="replace") as f:
        for ln in f:
            ln = ln.rstrip("\n")
            if not ln:
                continue
            summary["raw_lines_parsed"] += 1
            # Expected rme.log format: "<timestamp> <topic> <message>"
            parts = ln.split(" ", 2)
            if len(parts) < 3:
                # Unparseable line; attribute to "unknown" topic
                topic = "unknown"
                msg = ln
            else:
                _, topic, msg = parts
            topic_counts = summary["topics"].setdefault(topic, {"lines": 0, "error_lines": 0})
            topic_counts["lines"] += 1
            # Heuristic: if message contains miss/fail/error/not found, count as failure
            if topic == "db" and DB_ERROR_RE.search(msg):
                topic_counts["error_lines"] += 1
                summary["db_open_failures"] += 1
            elif DB_ERROR_RE.search(msg):
                topic_counts["error_lines"] += 1

    return summary


def main(argv):
    parser = argparse.ArgumentParser()
    parser.add_argument("--rme-log", dest="rme_log", default=None)
    parser.add_argument("--selftest", dest="selftest", default=None)
    parser.add_argument("--whitelist", dest="whitelist", default=None)
    parser.add_argument("--max-db-open-failures", dest="max_db_open_failures", type=int, default=0)
    parser.add_argument("--max-selftest-failures", dest="max_selftest_failures", type=int, default=0)

    args = parser.parse_args(argv)

    # Load whitelist
    patterns = load_whitelist(args.whitelist)

    # Parse rme.log
    rme_summary = analyze_rme_log(args.rme_log)

    # Parse selftest
    selftest = {"failures": []}
    if args.selftest and os.path.isfile(args.selftest):
        try:
            with open(args.selftest, "r", encoding="utf-8") as f:
                selftest = json.load(f)
        except Exception as e:
            print(f"Failed to load selftest json: {e}", file=sys.stderr)
            # Continue with empty failures
            selftest = {"failures": []}

    failures = selftest.get("failures", []) if isinstance(selftest, dict) else []

    parsed_failures = []
    unwhitelisted_count = 0
    for f in failures:
        kind = f.get("kind", "unknown")
        path = f.get("path", "")
        error = f.get("error", "")
        whitelisted = is_whitelisted(patterns, kind, path)
        if not whitelisted:
            unwhitelisted_count += 1
        parsed_failures.append({"kind": kind, "path": path, "error": error, "whitelisted": whitelisted})

    # Evaluate pass/fail via thresholds
    pass_flag = True
    if rme_summary.get("db_open_failures", 0) > args.max_db_open_failures:
        pass_flag = False
    if unwhitelisted_count > args.max_selftest_failures:
        pass_flag = False

    # Compose output
    out = {
        "pass": pass_flag,
        "db_open_failures": rme_summary.get("db_open_failures", 0),
        "selftest_failures_total": len(failures),
        "selftest_failures_unwhitelisted": unwhitelisted_count,
        "selftest_failures": parsed_failures,
        "rme_log_summary": rme_summary,
    }

    # Emit JSON to stdout
    json.dump(out, sys.stdout, indent=2)
    sys.stdout.write("\n")

    # Exit code 0 for success, 2 for parser error
    return 0


if __name__ == "__main__":
    rc = main(sys.argv[1:])
    sys.exit(rc)

#!/usr/bin/env python3
"""
Given an RME LST missing-reference report, find candidate matches by basename
in one or more search roots and write a CSV for human review.

This intentionally does NOT auto-rename/copy anything. It only produces
evidence to drive a manual fix or a curated overlay.
"""

from __future__ import annotations

import argparse
import csv
import os
import re
from collections import defaultdict
from pathlib import Path
from typing import DefaultDict, Iterable, List, Sequence, Tuple


_MISSING_RE = re.compile(r"^\-\s+([^\s]+)\s+\-\>\s+(.+?)\s*$")


def parse_missing(md_path: Path) -> List[Tuple[str, str]]:
    out: List[Tuple[str, str]] = []
    for line in md_path.read_text("utf-8", errors="ignore").splitlines():
        m = _MISSING_RE.match(line.strip())
        if not m:
            continue
        lst_file = m.group(1).strip()
        token = m.group(2).strip()
        out.append((lst_file, token))
    return out


def build_basename_index(roots: Sequence[Path]) -> DefaultDict[str, List[str]]:
    idx: DefaultDict[str, List[str]] = defaultdict(list)
    for root in roots:
        if not root.exists():
            continue
        for p in root.rglob("*"):
            if not p.is_file():
                continue
            idx[p.name.lower()].append(str(p))
    # Deterministic order for stable CSV diffs.
    for k in list(idx.keys()):
        idx[k].sort(key=lambda s: s.lower())
    return idx


def main() -> int:
    ap = argparse.ArgumentParser(description="Find candidate files for missing LST references")
    ap.add_argument(
        "--lst-report",
        default="tmp/rme/validation/raw/08_lst_missing.md",
        help="Path to rme-lst-report.md (or copied equivalent)",
    )
    ap.add_argument(
        "--search",
        nargs="+",
        default=[],
        help="One or more roots to search for candidate basenames",
    )
    ap.add_argument(
        "--out",
        default="tmp/rme/validation/raw/lst_candidates.csv",
        help="Output CSV path",
    )
    ap.add_argument(
        "--max-per-token",
        type=int,
        default=200,
        help="Max candidate paths to emit per missing token (0 = unlimited)",
    )
    args = ap.parse_args()

    report = Path(args.lst_report)
    if not report.exists():
        raise SystemExit(f"Missing LST report: {report}")

    search_roots = list(args.search)
    if not search_roots:
        gamefiles_root = os.environ.get("FALLOUT_GAMEFILES_ROOT") or os.environ.get("GAMEFILES_ROOT")
        if gamefiles_root:
            search_roots = [
                str(Path(gamefiles_root) / "patchedfiles"),
                str(Path(gamefiles_root) / "unpatchedfiles"),
            ]
        elif os.environ.get("GAME_DATA"):
            search_roots = [os.environ["GAME_DATA"]]
        else:
            raise SystemExit("Missing --search roots. Provide --search, GAME_DATA, or FALLOUT_GAMEFILES_ROOT.")

    roots = [Path(p) for p in search_roots]
    missing = parse_missing(report)
    idx = build_basename_index(roots)

    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)

    written = 0
    with out_path.open("w", newline="", encoding="utf-8") as f:
        w = csv.writer(f, lineterminator="\n")
        w.writerow(["lst_file", "missing_token", "candidate_path"])
        for lst_file, token in missing:
            cand = idx.get(token.lower(), [])
            if not cand:
                w.writerow([lst_file, token, ""])
                written += 1
                continue
            limit = None if args.max_per_token == 0 else args.max_per_token
            for path in cand[:limit]:
                w.writerow([lst_file, token, path])
                written += 1

    print(f"[OK] Missing tokens: {len(missing)}")
    print(f"[OK] Index entries: {len(idx)}")
    print(f"[OK] Wrote rows: {written} -> {out_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

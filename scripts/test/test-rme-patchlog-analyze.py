#!/usr/bin/env python3
"""Fast patchlog analyzer for GNW_SHOW_RECT clear events.

Finds GNW_SHOW_RECT entries where surf_pre>0 and surf_post==0, then filters
out entries that have a matching GNW_SHOW_RECT_RECOVERED seq.
"""

from __future__ import annotations

import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import List, Optional, Set

LINE_RE = re.compile(r"^\[(?P<ts>[^\]]+)\] \[(?P<tag>[^\]]+)\] (?P<data>.*)$")
KV_RE = re.compile(r"(\w+)=([\w\d:xA-Fa-f\-\._,()]+)")


@dataclass
class Event:
    lineno: int
    ts: str
    data: str
    seq: Optional[str]


def parse_kv_pairs(s: str) -> dict[str, str]:
    return {m.group(1): m.group(2) for m in KV_RE.finditer(s)}


def to_int(value: Optional[str]) -> Optional[int]:
    if value is None:
        return None
    try:
        return int(value)
    except Exception:
        return None


def analyze(path: Path, max_results: int = 20) -> List[Event]:
    candidates: List[Event] = []
    recovered_seqs: Set[str] = set()

    with path.open("r", encoding="utf-8", errors="replace") as handle:
        for lineno, line in enumerate(handle, start=1):
            line = line.rstrip("\n")
            if "GNW_SHOW_RECT" not in line and "GNW_SHOW_RECT_RECOVERED" not in line:
                continue

            match = LINE_RE.match(line)
            if not match:
                continue

            tag = match.group("tag")
            data = match.group("data")
            kv = parse_kv_pairs(data)
            seq = kv.get("seq")

            if tag == "GNW_SHOW_RECT_RECOVERED" and seq:
                recovered_seqs.add(seq)
                continue

            if tag != "GNW_SHOW_RECT":
                continue

            surf_pre = to_int(kv.get("surf_pre"))
            surf_post = to_int(kv.get("surf_post"))
            if surf_pre is None or surf_post is None:
                continue
            if surf_pre > 0 and surf_post == 0:
                candidates.append(
                    Event(
                        lineno=lineno,
                        ts=match.group("ts"),
                        data=data,
                        seq=seq,
                    )
                )

    suspicious = [event for event in candidates if not event.seq or event.seq not in recovered_seqs]
    return suspicious[:max_results]


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print("Usage: test-rme-patchlog-analyze.py <patchlog.txt>")
        return 2

    path = Path(argv[1])
    if not path.is_file():
        print(f"Missing patchlog: {path}")
        return 2

    print("Analyzing", path)
    results = analyze(path)
    if not results:
        print("No suspicious GNW_SHOW_RECT surf_pre>0 && surf_post==0 found")
        return 0

    print(f"\nFound {len(results)} suspicious events (showing up to {len(results)}).\n")
    for idx, event in enumerate(results, start=1):
        print(f"--- Event #{idx}/{len(results)}: {event.lineno}:{event.ts} ---")
        print(event.data)
        print("")
    print("Done")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))

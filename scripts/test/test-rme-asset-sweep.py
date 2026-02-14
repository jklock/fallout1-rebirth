#!/usr/bin/env python3
"""
Full asset sweep for patched Fallout data.

This verifies that all major content domains are readable from the patched data
root in one pass: maps, audio, critters, proto, scripts, text, and art.
"""

from __future__ import annotations

import argparse
import json
import os
import struct
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Sequence, Tuple


@dataclass(frozen=True)
class DatEntry:
    flags: int
    offset: int
    length: int
    field_c: int


def _read_u32_be(f) -> int:
    b = f.read(4)
    if len(b) != 4:
        raise EOFError("Unexpected EOF while reading u32")
    return struct.unpack(">I", b)[0]


def _read_assoc_header(f) -> Tuple[int, int, int, int]:
    size = _read_u32_be(f)
    max_ = _read_u32_be(f)
    datasize = _read_u32_be(f)
    ptr = _read_u32_be(f)
    return size, max_, datasize, ptr


def _read_assoc_key(f) -> str:
    b = f.read(1)
    if not b:
        raise EOFError("Unexpected EOF while reading key length")
    n = b[0]
    raw = f.read(n)
    if len(raw) != n:
        raise EOFError("Unexpected EOF while reading key bytes")

    raw = raw.split(b"\x00", 1)[0].rstrip(b"\r\n")
    return raw.decode("ascii", errors="ignore")


def _iter_dat_entries(dat_path: Path) -> Dict[str, DatEntry]:
    entries: Dict[str, DatEntry] = {}

    with dat_path.open("rb") as f:
        root_size, _, root_datasize, _ = _read_assoc_header(f)
        dirs: List[str] = []

        for _ in range(root_size):
            key = _read_assoc_key(f)
            dirs.append(key)
            if root_datasize:
                skipped = f.read(root_datasize)
                if len(skipped) != root_datasize:
                    raise EOFError("Unexpected EOF while skipping root data")

        for dir_name in dirs:
            dir_size, _, dir_datasize, _ = _read_assoc_header(f)
            if dir_datasize != 16:
                raise ValueError(f"Unexpected dir datasize={dir_datasize} in {dat_path}")

            for _ in range(dir_size):
                file_name = _read_assoc_key(f)
                flags = _read_u32_be(f)
                offset = _read_u32_be(f)
                length = _read_u32_be(f)
                field_c = _read_u32_be(f)

                if dir_name in (".", ""):
                    full_path = file_name
                else:
                    full_path = f"{dir_name}\\{file_name}"
                entries[full_path.upper()] = DatEntry(flags, offset, length, field_c)

    return entries


def _category_from_rel(rel: str) -> List[str]:
    rel = rel.replace("\\", "/").lower()
    out: List[str] = []

    if rel.startswith("maps/") and rel.endswith(".map"):
        out.append("maps")
    if rel.startswith("sound/"):
        out.append("audio")
    if rel.startswith("art/critters/") or rel.startswith("proto/critters/"):
        out.append("critters")
    if rel.startswith("proto/"):
        out.append("proto")
    if rel.startswith("scripts/"):
        out.append("scripts")
    if rel.startswith("text/"):
        out.append("text")
    if rel.startswith("art/"):
        out.append("art")

    if not out:
        out.append("other")
    return out


def _category_from_dat(path_upper: str) -> List[str]:
    p = path_upper.replace("/", "\\")
    out: List[str] = []

    if p.startswith("MAPS\\") and p.endswith(".MAP"):
        out.append("maps")
    if p.startswith("SOUND\\"):
        out.append("audio")
    if p.startswith("ART\\CRITTERS\\") or p.startswith("PROTO\\CRITTERS\\"):
        out.append("critters")
    if p.startswith("PROTO\\"):
        out.append("proto")
    if p.startswith("SCRIPTS\\"):
        out.append("scripts")
    if p.startswith("TEXT\\"):
        out.append("text")
    if p.startswith("ART\\"):
        out.append("art")
    if not out:
        out.append("other")
    return out


def _new_counter() -> Dict[str, int]:
    return {
        "maps": 0,
        "audio": 0,
        "critters": 0,
        "proto": 0,
        "scripts": 0,
        "text": 0,
        "art": 0,
        "other": 0,
        "total": 0,
    }


def _count_categories(paths: Iterable[str], fn) -> Dict[str, int]:
    c = _new_counter()
    for p in paths:
        cats = fn(p)
        c["total"] += 1
        for k in cats:
            c[k] += 1
    return c


def _scan_overlay(data_root: Path, read_bytes: int) -> Tuple[Dict[str, int], List[Dict[str, str]]]:
    data_dir = data_root / "data"
    if not data_dir.is_dir():
        raise FileNotFoundError(f"Missing data directory: {data_dir}")

    rel_files: List[str] = []
    failures: List[Dict[str, str]] = []

    for p in sorted(data_dir.rglob("*")):
        if not p.is_file():
            continue

        rel = p.relative_to(data_dir).as_posix()
        rel_files.append(rel)

        try:
            with p.open("rb") as fh:
                fh.read(read_bytes)
        except Exception as e:
            failures.append({"path": str(p), "error": str(e)})

    return _count_categories(rel_files, _category_from_rel), failures


def _scan_dat_index(dat_path: Path) -> Dict[str, int]:
    entries = _iter_dat_entries(dat_path)
    return _count_categories(entries.keys(), _category_from_dat)


def _resolve_data_root(cli_value: str) -> Path:
    if cli_value:
        return Path(cli_value).resolve()

    env_root = os.environ.get("FALLOUT_GAMEFILES_ROOT") or os.environ.get("GAMEFILES_ROOT")
    env_data = os.environ.get("GAME_DATA")

    if env_data:
        return Path(env_data).resolve()
    if env_root:
        return (Path(env_root) / "patchedfiles").resolve()

    raise SystemExit("Missing data root. Provide --data-root or set GAME_DATA/FALLOUT_GAMEFILES_ROOT.")


def _write_markdown(path: Path, summary: Dict) -> None:
    lines = [
        "# RME Asset Sweep",
        "",
        f"- Data root: `{summary['data_root']}`",
        f"- Overlay read failures: **{len(summary['overlay_failures'])}**",
        "",
        "## Overlay Counters",
        "",
        "| Category | Count |",
        "|---|---:|",
    ]

    for k in ("maps", "audio", "critters", "proto", "scripts", "text", "art", "other", "total"):
        lines.append(f"| {k} | {summary['overlay_counts'][k]} |")

    lines.extend(
        [
            "",
            "## DAT Index Counters",
            "",
            "| Source | maps | audio | critters | proto | scripts | text | art | other | total |",
            "|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|",
        ]
    )

    for source in ("master.dat", "critter.dat"):
        c = summary["dat_counts"][source]
        lines.append(
            f"| {source} | {c['maps']} | {c['audio']} | {c['critters']} | {c['proto']} | {c['scripts']} | {c['text']} | {c['art']} | {c['other']} | {c['total']} |"
        )

    if summary["overlay_failures"]:
        lines.extend(["", "## Overlay Read Failures", ""])
        for f in summary["overlay_failures"]:
            lines.append(f"- `{f['path']}`: {f['error']}")

    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main(argv: Optional[Sequence[str]] = None) -> int:
    p = argparse.ArgumentParser(description="Sweep all major patched asset domains and verify readability")
    p.add_argument(
        "--data-root",
        default="",
        help="Path to patched data root (master.dat/critter.dat/data). Defaults to GAME_DATA or FALLOUT_GAMEFILES_ROOT/patchedfiles",
    )
    p.add_argument("--out-dir", default="tmp/rme/validation/asset-sweep", help="Output directory for reports")
    p.add_argument("--read-bytes", type=int, default=512, help="Bytes to read per overlay file")
    args = p.parse_args(argv)

    data_root = _resolve_data_root(args.data_root)
    out_dir = Path(args.out_dir).resolve()
    out_dir.mkdir(parents=True, exist_ok=True)

    master = data_root / "master.dat"
    critter = data_root / "critter.dat"
    if not master.is_file() or not critter.is_file():
        print(f"[ERROR] Missing master.dat/critter.dat under {data_root}")
        return 2

    try:
        overlay_counts, overlay_failures = _scan_overlay(data_root, max(1, args.read_bytes))
    except Exception as e:
        print(f"[ERROR] Overlay scan failed: {e}")
        return 2

    try:
        master_counts = _scan_dat_index(master)
        critter_counts = _scan_dat_index(critter)
    except Exception as e:
        print(f"[ERROR] DAT index scan failed: {e}")
        return 2

    summary = {
        "data_root": str(data_root),
        "overlay_counts": overlay_counts,
        "overlay_failures": overlay_failures,
        "dat_counts": {
            "master.dat": master_counts,
            "critter.dat": critter_counts,
        },
    }

    json_path = out_dir / "asset_sweep.json"
    md_path = out_dir / "asset_sweep.md"

    json_path.write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
    _write_markdown(md_path, summary)

    print(f"[INFO] Wrote {json_path}")
    print(f"[INFO] Wrote {md_path}")
    print(f"[INFO] Overlay failures: {len(overlay_failures)}")
    return 0 if not overlay_failures else 1


if __name__ == "__main__":
    raise SystemExit(main())

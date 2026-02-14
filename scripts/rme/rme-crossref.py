#!/usr/bin/env python3
"""
RME cross-reference tool.

Generates a CSV mapping of every file in the RME payload's DATA/ tree to
whether it exists in the provided base directory's master.dat/critter.dat.

Also produces a heuristic report for missing LST references and a short
markdown summary.

USAGE:
  python3 scripts/patch/rme-crossref.py --rme third_party/rme --base-dir GOG/patchedfiles --out-dir GOG/rme_xref_patched
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import os
import struct
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Sequence, Set, Tuple


MAP_VERSION_EXPECTED = 19


@dataclass(frozen=True)
class DirEntry:
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

    # Keys are ASCII in Fallout DATs. Be defensive around stray NUL/newlines.
    raw = raw.split(b"\x00", 1)[0].rstrip(b"\r\n")
    return raw.decode("ascii", errors="ignore")


def _iter_dat_entries(dat_path: Path) -> Dict[str, DirEntry]:
    """
    Parse Fallout 1 DAT index (assoc arrays) and return a mapping:
      UPPERCASE_WINDOWS_PATH -> DirEntry
    """
    entries: Dict[str, DirEntry] = {}

    with dat_path.open("rb") as f:
        root_size, _, root_datasize, _ = _read_assoc_header(f)

        dirs: List[str] = []
        for _ in range(root_size):
            key = _read_assoc_key(f)
            dirs.append(key)
            if root_datasize:
                # Root datasize is 0 in stock Fallout DATs, but don't assume.
                skipped = f.read(root_datasize)
                if len(skipped) != root_datasize:
                    raise EOFError("Unexpected EOF while skipping root data")

        for dir_name in dirs:
            dir_size, _, dir_datasize, _ = _read_assoc_header(f)

            if dir_datasize != 16:
                raise ValueError(
                    f"Unexpected dir entry datasize={dir_datasize} in {dat_path} (expected 16)"
                )

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

                entries[full_path.upper()] = DirEntry(
                    flags=flags, offset=offset, length=length, field_c=field_c
                )

    return entries


def _sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def _rel_to_win(rel: Path) -> str:
    # Keep original casing as stored in the filesystem. Convert separators.
    return rel.as_posix().replace("/", "\\")


def _looks_like_comment(line: str) -> bool:
    s = line.lstrip()
    return not s or s.startswith(";") or s.startswith("#") or s.startswith("//")


def _strip_inline_comment(line: str) -> str:
    # LSTs commonly use ';' for comments. Also treat '#' as comment starter.
    for delim in (";", "#"):
        if delim in line:
            line = line.split(delim, 1)[0]
    return line.strip()


def _iter_lst_tokens(lst_path: Path) -> Iterable[str]:
    with lst_path.open("r", encoding="utf-8", errors="ignore") as f:
        for raw in f:
            if _looks_like_comment(raw):
                continue
            line = _strip_inline_comment(raw)
            if not line:
                continue

            token = line.split()[0].strip().strip("\"'").strip()
            if "." not in token:
                continue
            yield token


def _make_ref_path(lst_rel: Path, token: str) -> str:
    token = token.strip().strip("\"'").strip()
    token = token.replace("/", "\\")
    while token.startswith(".\\"):
        token = token[2:]
    token = token.lstrip("\\")

    if "\\" in token:
        return token

    parent_parts = lst_rel.parent.parts
    if not parent_parts:
        return token
    return "\\".join(parent_parts) + "\\" + token


def _map_endian_note(path: Path) -> str:
    try:
        with path.open("rb") as f:
            hdr = f.read(4)
    except OSError:
        return ""

    if len(hdr) != 4:
        return ""

    be = struct.unpack(">I", hdr)[0]
    le = struct.unpack("<I", hdr)[0]

    if be == MAP_VERSION_EXPECTED and le != MAP_VERSION_EXPECTED:
        return "map_endian=big"
    if le == MAP_VERSION_EXPECTED and be != MAP_VERSION_EXPECTED:
        return "map_endian=little"

    return ""


def _write_text(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="\n") as f:
        f.write(content)


def main(argv: Optional[Sequence[str]] = None) -> int:
    parser = argparse.ArgumentParser(description="RME cross-reference generator")
    parser.add_argument("--rme", default="third_party/rme", help="RME payload directory")
    parser.add_argument("--base-dir", required=True, help="Base directory containing master.dat/critter.dat")
    parser.add_argument("--out-dir", required=True, help="Output directory for reports")
    args = parser.parse_args(argv)

    rme_dir = Path(args.rme).resolve()
    base_dir = Path(args.base_dir).resolve()
    out_dir = Path(args.out_dir).resolve()

    rme_data = rme_dir / "DATA"
    if not rme_data.is_dir():
        print(f"[ERROR] RME DATA directory not found: {rme_data}", file=sys.stderr)
        return 2

    master_dat = base_dir / "master.dat"
    critter_dat = base_dir / "critter.dat"
    if not master_dat.is_file() or not critter_dat.is_file():
        print(f"[ERROR] Base dir must contain master.dat and critter.dat: {base_dir}", file=sys.stderr)
        return 2

    out_dir.mkdir(parents=True, exist_ok=True)

    print(f">>> Indexing DATs from: {base_dir}")
    master_idx = _iter_dat_entries(master_dat)
    critter_idx = _iter_dat_entries(critter_dat)
    dat_paths: Set[str] = set(master_idx.keys()) | set(critter_idx.keys())

    print(f">>> Scanning RME payload: {rme_data}")
    rme_files: List[Path] = [p for p in rme_data.rglob("*") if p.is_file()]
    rme_files.sort(key=lambda p: _rel_to_win(p.relative_to(rme_data)).upper())

    rows: List[Tuple[str, str, int, str, str, str, str]] = []
    map_endian_paths: List[str] = []
    rme_paths: Set[str] = set()

    for p in rme_files:
        rel = p.relative_to(rme_data)
        path_win = _rel_to_win(rel)
        key = path_win.upper()
        rme_paths.add(key)

        ext = p.suffix[1:].upper() if p.suffix.startswith(".") else ""
        size = p.stat().st_size
        digest = _sha256(p)

        base_source = "none"
        base_length = ""
        if key in master_idx:
            base_source = "master.dat"
            base_length = str(master_idx[key].length)
        elif key in critter_idx:
            base_source = "critter.dat"
            base_length = str(critter_idx[key].length)

        notes = ""
        if ext == "MAP":
            notes = _map_endian_note(p)
            if notes == "map_endian=big":
                map_endian_paths.append(path_win)

        rows.append((path_win, ext, size, digest, base_source, base_length, notes))

    # LST missing reference report (heuristic)
    lst_files = [p for p in rme_files if p.suffix.lower() == ".lst"]
    lst_files.sort(key=lambda p: _rel_to_win(p.relative_to(rme_data)).upper())

    missing: List[Tuple[str, str]] = []
    seen_missing: Set[Tuple[str, str]] = set()

    for lst_path in lst_files:
        lst_rel = lst_path.relative_to(rme_data)
        lst_win = _rel_to_win(lst_rel)
        for token in _iter_lst_tokens(lst_path):
            # SCRIPTS.LST can contain `.ssl` source names, but runtime always
            # resolves to `<base>.int` (see scr_index_to_name).
            ref_token = token
            if lst_win.upper() == r"SCRIPTS\SCRIPTS.LST" and token.lower().endswith(".ssl"):
                ref_token = token[:-4] + ".int"

            ref_win = _make_ref_path(lst_rel, ref_token)
            ref_key = ref_win.upper()
            if ref_key in rme_paths or ref_key in dat_paths:
                continue
            item = (lst_win, token)
            if item in seen_missing:
                continue
            seen_missing.add(item)
            missing.append(item)

    # Write CSV
    csv_path = out_dir / "rme-crossref.csv"
    with csv_path.open("w", encoding="utf-8", newline="") as f:
        writer = csv.writer(f, lineterminator="\n")
        writer.writerow(["path", "ext", "size", "sha256", "base_source", "base_length", "notes"])
        for path_win, ext, size, digest, base_source, base_length, notes in rows:
            writer.writerow([path_win, ext, str(size), digest, base_source, base_length, notes])

    # Write LST report
    lst_report_path = out_dir / "rme-lst-report.md"
    report_lines = [
        "# RME LST Reference Report",
        "",
        "Each entry lists an LST file and a referenced asset that was not found",
        "in the RME overlay or the base DATs.",
        "",
        "Note: This is a heuristic check that only validates LST entries with",
        "explicit filenames (i.e., tokens containing a '.' extension). Some LST",
        "formats encode non-file data and will not be validated here.",
        "",
    ]
    for lst_win, token in missing:
        report_lines.append(f"- {lst_win} -> {token}")
    report_lines.append("")
    _write_text(lst_report_path, "\n".join(report_lines))

    # Write summary markdown
    override_master = sum(1 for r in rows if r[4] == "master.dat")
    override_critter = sum(1 for r in rows if r[4] == "critter.dat")
    new_files = sum(1 for r in rows if r[4] == "none")

    summary_lines = [
        "# RME Cross-Reference Mapping",
        "",
        "Generated from current RME payload + base DATs.",
        "",
        "## Summary",
        f"- Total RME files: {len(rows)}",
        f"- Override master.dat: {override_master}",
        f"- Override critter.dat: {override_critter}",
        f"- New files (not in DATs): {new_files}",
        f"- LST files checked: {len(lst_files)}",
        f"- LST missing references (heuristic): {len(missing)}",
        f"- MAP files with big-endian header: {len(map_endian_paths)}",
        "",
        "## MAP Endian Issues",
    ]
    for p in map_endian_paths:
        summary_lines.append(f"- {p}")
    summary_lines += [
        "",
        "## Outputs",
        "- CSV: rme-crossref.csv",
        "- LST report: rme-lst-report.md",
        "",
    ]
    _write_text(out_dir / "rme-crossref.md", "\n".join(summary_lines))

    print(f"[OK] Wrote: {csv_path}")
    print(f"[OK] Wrote: {out_dir / 'rme-crossref.md'}")
    print(f"[OK] Wrote: {lst_report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

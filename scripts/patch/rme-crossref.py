#!/usr/bin/env python3
"""
Fallout 1 Rebirth — RME Cross-Reference Mapping

Generates a cross-reference mapping between the RME payload (DATA/ folder)
and the base Fallout DAT files (master.dat and critter.dat).

Outputs:
- rme-crossref.csv (per-file mapping)
- rme-crossref.md  (summary + key findings)
- rme-lst-report.md (LST reference validation)

Usage:
  python3 scripts/patch/rme-crossref.py \
    --base-dir /path/to/base \
    --rme-dir /path/to/rme/source \
    --out-dir /path/to/output

Notes:
- --base-dir must contain master.dat and critter.dat
- --rme-dir must contain DATA/
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import os
import struct
from typing import Dict, List, Tuple


def read_be_u32(fp) -> int:
    data = fp.read(4)
    if len(data) != 4:
        raise EOFError("Unexpected EOF")
    return struct.unpack(">I", data)[0]


def read_assoc_array(fp, parse_entry=False) -> Tuple[List[Tuple[str, Tuple[int, int, int, int] | None]], int]:
    size = read_be_u32(fp)
    _max = read_be_u32(fp)
    datasize = read_be_u32(fp)
    _ptr = read_be_u32(fp)

    entries = []
    for _ in range(size):
        key_len_raw = fp.read(1)
        if not key_len_raw:
            raise EOFError("Unexpected EOF reading key length")
        key_len = key_len_raw[0]
        key = fp.read(key_len).decode("ascii", errors="replace")
        data = None
        if datasize:
            raw = fp.read(datasize)
            if parse_entry:
                if len(raw) != 16:
                    raise EOFError("Unexpected EOF reading dir_entry")
                data = struct.unpack(">IIII", raw)
        entries.append((key, data))
    return entries, datasize


def load_dat_index(dat_path: str) -> Dict[str, Dict[str, int]]:
    index: Dict[str, Dict[str, int]] = {}

    with open(dat_path, "rb") as fp:
        root_entries, root_datasize = read_assoc_array(fp, parse_entry=False)
        if root_datasize != 0:
            # Unexpected, but continue.
            pass

        for dir_name, _ in root_entries:
            dir_entries, datasize = read_assoc_array(fp, parse_entry=True)
            if datasize != 16:
                # Unexpected, but continue.
                pass

            for file_name, de in dir_entries:
                if dir_name == ".":
                    rel_path = file_name
                else:
                    rel_path = f"{dir_name}\\{file_name}"

                key = rel_path.upper()
                if de is None:
                    continue

                index[key] = {
                    "flags": de[0],
                    "offset": de[1],
                    "length": de[2],
                    "field_c": de[3],
                }

    return index


def sha256_file(path: str) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as fp:
        for chunk in iter(lambda: fp.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def normalize_rel_path(path: str) -> str:
    # Convert to Windows-style separators, keep original case in output
    return path.replace(os.sep, "\\")


def list_rme_files(rme_data_dir: str) -> List[str]:
    files = []
    for dirpath, _, filenames in os.walk(rme_data_dir):
        for name in filenames:
            full = os.path.join(dirpath, name)
            rel = os.path.relpath(full, rme_data_dir)
            files.append(rel)
    return sorted(files)


def map_endian_status(path: str) -> str:
    try:
        with open(path, "rb") as fp:
            data = fp.read(4)
        if len(data) != 4:
            return "map_endian=short"
        le = struct.unpack("<I", data)[0]
        be = struct.unpack(">I", data)[0]
        if be == 19 and le != 19:
            return "map_endian=big"
        if le == 19:
            return "map_endian=little"
        return f"map_endian=unknown(le={le},be={be})"
    except Exception as exc:
        return f"map_endian=error({exc})"


def parse_lst_file(path: str) -> List[str]:
    entries: List[str] = []
    with open(path, "r", errors="ignore") as fp:
        for line in fp:
            line = line.strip()
            if not line:
                continue
            if line.startswith(";") or line.startswith("#"):
                continue
            # Strip trailing comments
            if ";" in line:
                line = line.split(";", 1)[0].strip()
            if not line:
                continue
            token = line.split()[0]
            if not token:
                continue
            # Only validate explicit filenames (heuristic: require an extension)
            if "." not in token:
                continue
            entries.append(token)
    return entries


def ensure_dir(path: str) -> None:
    os.makedirs(path, exist_ok=True)


def main() -> int:
    parser = argparse.ArgumentParser(description="RME cross-reference mapping")
    parser.add_argument("--base-dir", required=True, help="Folder containing master.dat and critter.dat")
    parser.add_argument("--rme-dir", required=True, help="RME source folder (contains DATA)")
    parser.add_argument("--out-dir", required=True, help="Output directory for mapping docs")
    args = parser.parse_args()

    base_dir = os.path.abspath(args.base_dir)
    rme_dir = os.path.abspath(args.rme_dir)
    out_dir = os.path.abspath(args.out_dir)

    master_dat = os.path.join(base_dir, "master.dat")
    critter_dat = os.path.join(base_dir, "critter.dat")
    rme_data = os.path.join(rme_dir, "DATA")

    if not os.path.isfile(master_dat) or not os.path.isfile(critter_dat):
        raise SystemExit("Base dir must contain master.dat and critter.dat")
    if not os.path.isdir(rme_data):
        raise SystemExit("RME dir must contain DATA/")

    ensure_dir(out_dir)

    print("Loading base DAT indices...")
    master_index = load_dat_index(master_dat)
    critter_index = load_dat_index(critter_dat)

    print("Scanning RME payload...")
    rme_files = list_rme_files(rme_data)

    csv_path = os.path.join(out_dir, "rme-crossref.csv")
    md_path = os.path.join(out_dir, "rme-crossref.md")
    lst_report_path = os.path.join(out_dir, "rme-lst-report.md")

    total = 0
    in_master = 0
    in_critter = 0
    missing = 0
    map_big_endian = []

    lst_missing: List[Tuple[str, str]] = []
    lst_checked = 0

    overlay_index_upper = set()
    for rel in rme_files:
        overlay_index_upper.add(normalize_rel_path(rel).upper())

    with open(csv_path, "w", newline="") as csv_fp:
        writer = csv.writer(csv_fp)
        writer.writerow([
            "path",
            "ext",
            "size",
            "sha256",
            "base_source",
            "base_length",
            "notes",
        ])

        for rel in rme_files:
            total += 1
            rel_os = rel
            rel_win = normalize_rel_path(rel_os)
            rel_upper = rel_win.upper()
            full_path = os.path.join(rme_data, rel)
            ext = os.path.splitext(rel)[1].upper().lstrip(".")
            size = os.path.getsize(full_path)
            sha = sha256_file(full_path)

            base_source = "none"
            base_length = ""

            if rel_upper in master_index:
                base_source = "master.dat"
                base_length = str(master_index[rel_upper]["length"])
                in_master += 1
            elif rel_upper in critter_index:
                base_source = "critter.dat"
                base_length = str(critter_index[rel_upper]["length"])
                in_critter += 1
            else:
                missing += 1

            notes = []
            if ext == "MAP":
                status = map_endian_status(full_path)
                notes.append(status)
                if status == "map_endian=big":
                    map_big_endian.append(rel_win)

            writer.writerow([
                rel_win,
                ext,
                size,
                sha,
                base_source,
                base_length,
                ";".join(notes),
            ])

            # LST validation
            if ext == "LST":
                lst_checked += 1
                lst_entries = parse_lst_file(full_path)
                base_dir_os = os.path.dirname(rel_os)
                if base_dir_os == ".":
                    base_dir_os = ""
                base_dir = normalize_rel_path(base_dir_os)
                for entry in lst_entries:
                    # Normalize separators and build rel path
                    entry_path = entry.replace("/", "\\")
                    if base_dir:
                        candidate = f"{base_dir}\\{entry_path}"
                    else:
                        candidate = entry_path

                    cand_upper = candidate.upper()
                    if cand_upper in overlay_index_upper:
                        continue
                    if cand_upper in master_index or cand_upper in critter_index:
                        continue
                    lst_missing.append((rel_win, entry_path))

    # Summary markdown
    with open(md_path, "w") as md:
        md.write("# RME Cross-Reference Mapping\n\n")
        md.write("Generated from current RME payload + base DATs.\n\n")
        md.write("## Summary\n")
        md.write(f"- Total RME files: {total}\n")
        md.write(f"- Override master.dat: {in_master}\n")
        md.write(f"- Override critter.dat: {in_critter}\n")
        md.write(f"- New files (not in DATs): {missing}\n")
        md.write(f"- LST files checked: {lst_checked}\n")
        md.write(f"- LST missing references (heuristic): {len(lst_missing)}\n")
        md.write(f"- MAP files with big-endian header: {len(map_big_endian)}\n\n")

        md.write("## MAP Endian Issues\n")
        if map_big_endian:
            for item in map_big_endian:
                md.write(f"- {item}\n")
        else:
            md.write("- None\n")

        md.write("\n## Outputs\n")
        md.write(f"- CSV: {os.path.basename(csv_path)}\n")
        md.write(f"- LST report: {os.path.basename(lst_report_path)}\n")

    # LST report
    with open(lst_report_path, "w") as md:
        md.write("# RME LST Reference Report\n\n")
        md.write("Each entry lists an LST file and a referenced asset that was not found\n")
        md.write("in the RME overlay or the base DATs.\n")
        md.write("\n")
        md.write("Note: This is a heuristic check that only validates LST entries with\n")
        md.write("explicit filenames (i.e., tokens containing a '.' extension). Some LST\n")
        md.write("formats encode non-file data and will not be validated here.\n\n")
        if lst_missing:
            for lst_file, missing_entry in lst_missing:
                md.write(f"- {lst_file} -> {missing_entry}\n")
        else:
            md.write("- No missing references found.\n")

    print("Done.")
    print(f"CSV: {csv_path}")
    print(f"Summary: {md_path}")
    print(f"LST report: {lst_report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""Find and extract a MAP from master.dat (patched first, then unpatched).

Writes:
 - tmp/rme/artifacts/evidence/gate-2/<map>-dat-entries.txt
 - tmp/rme/artifacts/evidence/gate-2/<map>-extract-info.txt (if extracted)
 - <target data root>/data/maps/<MAP>.MAP (if extracted)

Usage: python3 scripts/test/test-rme-extract-map.py MAPNAME [--patched-master ...] [--unpatched-master ...] [--target-map ...]
"""
from __future__ import annotations

import argparse
import hashlib
import os
import struct
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Sequence, Tuple

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

    raw = raw.split(b"\x00", 1)[0].rstrip(b"\r\n")
    return raw.decode("ascii", errors="ignore")


def iter_dat_entries(dat_path: Path) -> Dict[str, DirEntry]:
    entries: Dict[str, DirEntry] = {}

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


# LZSS decode and extract functions copied from rme-audit-script-refs

def lzss_decode(data: bytes) -> bytes:
    ring = bytearray(b" " * 4096)
    ring_index = 4078

    out = bytearray()
    pos = 0
    n = len(data)

    while pos < n:
        control = data[pos]
        pos += 1

        for mask in (0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80):
            if pos >= n:
                break

            if (control & mask) != 0:
                b = data[pos]
                pos += 1
                out.append(b)
                ring[ring_index] = b
                ring_index = (ring_index + 1) & 0xFFF
            else:
                if pos + 1 >= n:
                    pos = n
                    break
                low = data[pos]
                high = data[pos + 1]
                pos += 2

                dict_offset = low | ((high & 0xF0) << 4)
                chunk_len = (high & 0x0F) + 3
                for i in range(chunk_len):
                    b = ring[(dict_offset + i) & 0xFFF]
                    out.append(b)
                    ring[ring_index] = b
                    ring_index = (ring_index + 1) & 0xFFF

    return bytes(out)


def extract_dat_file(f, entry: DirEntry) -> bytes:
    f.seek(entry.offset)

    flags = entry.flags or 16
    mode = flags & 0xF0

    if mode == 32:
        data = f.read(entry.length)
        if len(data) != entry.length:
            raise EOFError("Unexpected EOF while reading uncompressed DAT entry")
        return data

    if mode == 16:
        comp = f.read(entry.field_c)
        if len(comp) != entry.field_c:
            raise EOFError("Unexpected EOF while reading compressed DAT entry")
        dec = lzss_decode(comp)
        if len(dec) < entry.length:
            return dec
        return dec[: entry.length]

    if mode == 64:
        remaining = entry.length
        out = bytearray()
        while remaining > 0:
            v = _read_u16_be(f)
            if (v & 0x8000) != 0:
                n = v & ~0x8000
                chunk = f.read(n)
                if len(chunk) != n:
                    raise EOFError("Unexpected EOF while reading raw chunk")
            else:
                comp = f.read(v)
                if len(comp) != v:
                    raise EOFError("Unexpected EOF while reading chunk-compressed payload")
                chunk = lzss_decode(comp)

            take = min(remaining, len(chunk))
            out.extend(chunk[:take])
            remaining -= take

            if len(chunk) == 0:
                break
        return bytes(out)

    raise ValueError(f"Unsupported DAT entry compression flags: {entry.flags} (mode={mode})")


def _read_u16_be(f):
    b = f.read(2)
    if len(b) != 2:
        raise EOFError("Unexpected EOF while reading u16")
    return struct.unpack(">H", b)[0]


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


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def main(argv: Optional[Sequence[str]] = None) -> int:
    repo = Path('.').resolve()
    gamefiles_root = os.environ.get("FALLOUT_GAMEFILES_ROOT") or os.environ.get("GAMEFILES_ROOT")
    game_data = os.environ.get("GAME_DATA")

    parser = argparse.ArgumentParser(description='Extract a MAP from master.dat')
    parser.add_argument('map', help='MAP name, e.g., ZDESERT1 or TEMPLAT1')
    parser.add_argument(
        '--patched-master',
        default='',
        help='Path to patched master.dat (defaults to GAME_DATA/master.dat or FALLOUT_GAMEFILES_ROOT/patchedfiles/master.dat)',
    )
    parser.add_argument(
        '--unpatched-master',
        default='',
        help='Path to unpatched master.dat (defaults to FALLOUT_GAMEFILES_ROOT/unpatchedfiles/master.dat when set)',
    )
    parser.add_argument(
        '--target-map',
        default='',
        help='Exact output path for extracted MAP file',
    )
    parser.add_argument(
        '--evidence-dir',
        default='tmp/rme/artifacts/evidence/gate-2',
        help='Directory for extraction evidence outputs',
    )
    args = parser.parse_args(argv)

    patched = Path(args.patched_master) if args.patched_master else None
    if patched is None and game_data:
        patched = Path(game_data) / 'master.dat'
    if patched is None and gamefiles_root:
        patched = Path(gamefiles_root) / 'patchedfiles' / 'master.dat'
    if patched is None:
        patched = Path('master.dat')

    unpatched = Path(args.unpatched_master) if args.unpatched_master else None
    if unpatched is None and gamefiles_root:
        unpatched = Path(gamefiles_root) / 'unpatchedfiles' / 'master.dat'
    if unpatched is None:
        unpatched = Path('unpatched-master.dat')

    mapname = args.map.upper()
    evidence_dir = Path(args.evidence_dir)
    out_entries = evidence_dir / f"{mapname.lower()}-dat-entries.txt"
    out_info = evidence_dir / f"{mapname.lower()}-extract-info.txt"

    if args.target_map:
        target_map = Path(args.target_map)
    elif game_data:
        target_map = Path(game_data) / 'data' / 'maps' / f"{mapname}.MAP"
    elif gamefiles_root:
        target_map = Path(gamefiles_root) / 'patchedfiles' / 'data' / 'maps' / f"{mapname}.MAP"
    else:
        target_map = repo / 'tmp' / 'rme' / 'extract-map' / 'data' / 'maps' / f"{mapname}.MAP"

    out_entries.parent.mkdir(parents=True, exist_ok=True)

    pattern = mapname

    chosen_dat = None
    chosen_key = None
    chosen_entry = None

    # Try patched
    if patched.is_file():
        try:
            idx = iter_dat_entries(patched)
        except Exception as e:
            with out_entries.open('w') as f:
                f.write(f"ERROR parsing patched master.dat: {e}\n")
            print('ERROR parsing patched master.dat:', e)
            return 2
        matches = [(k, v) for k, v in idx.items() if pattern in k]
        if matches:
            with out_entries.open('w') as f:
                f.write(f"Searched: {patched}\nFound {len(matches)} entries containing '{pattern}'\n\n")
                for k, entry in matches:
                    f.write(f"{k} OFFSET={entry.offset} LENGTH={entry.length} FLAGS=0x{entry.flags:02x} FIELD_C={entry.field_c}\n")
            print(f'FOUND {len(matches)} entries in patched master.dat')
            chosen_dat = patched
            # prefer exact MAPS\<MAP>.MAP
            exact = f'MAPS\\{mapname}.MAP'
            for k, e in matches:
                if k == exact:
                    chosen_key, chosen_entry = k, e
                    break
            if not chosen_entry:
                for k, e in matches:
                    if k.endswith(f'{mapname}.MAP'):
                        chosen_key, chosen_entry = k, e
                        break
            if not chosen_entry:
                chosen_key, chosen_entry = matches[0][0], matches[0][1]
        else:
            matches = []

    # If none found in patched, try unpatched
    if not matches and unpatched.is_file():
        try:
            idx = iter_dat_entries(unpatched)
        except Exception as e:
            with out_entries.open('w') as f:
                f.write(f"ERROR parsing unpatched master.dat: {e}\n")
            print('ERROR parsing unpatched master.dat:', e)
            return 2
        matches = [(k, v) for k, v in idx.items() if pattern in k]
        if matches:
            with out_entries.open('w') as f:
                f.write(f"Searched: {unpatched}\nFound {len(matches)} entries containing '{pattern}'\n\n")
                for k, entry in matches:
                    f.write(f"{k} OFFSET={entry.offset} LENGTH={entry.length} FLAGS=0x{entry.flags:02x} FIELD_C={entry.field_c}\n")
            print(f'FOUND {len(matches)} entries in unpatched master.dat')
            chosen_dat = unpatched
            exact = f'MAPS\\{mapname}.MAP'
            for k, e in matches:
                if k == exact:
                    chosen_key, chosen_entry = k, e
                    break
            if not chosen_entry:
                for k, e in matches:
                    if k.endswith(f'{mapname}.MAP'):
                        chosen_key, chosen_entry = k, e
                        break
            if not chosen_entry:
                chosen_key, chosen_entry = matches[0][0], matches[0][1]
        else:
            matches = []

    if not matches:
        with out_entries.open('w') as f:
            f.write(f"No entries containing '{pattern}' found in patched or unpatched master.dat\n")
        print('No entries found in either DAT')
        return 0

    # Extract chosen entry
    assert chosen_key and chosen_entry

    target_map.parent.mkdir(parents=True, exist_ok=True)

    with chosen_dat.open('rb') as f:
        try:
            data = extract_dat_file(f, chosen_entry)
        except Exception as e:
            with out_info.open('w') as finfo:
                finfo.write(f"ERROR extracting {chosen_key} from {chosen_dat}: {e}\n")
            print('ERROR extracting entry:', e)
            return 3

    with target_map.open('wb') as out:
        out.write(data)

    # Verify extraction
    info_lines = []
    info_lines.append(f"Source DAT: {chosen_dat}")
    info_lines.append(f"Key: {chosen_key}")
    info_lines.append(f"OFFSET={chosen_entry.offset} LENGTH={chosen_entry.length} FLAGS=0x{chosen_entry.flags:02x} FIELD_C={chosen_entry.field_c}")
    info_lines.append(f"Extracted: {target_map} SIZE={target_map.stat().st_size} SHA256={sha256(target_map)}")

    # file(1) output
    try:
        import subprocess

        p = subprocess.run(["file", "-b", str(target_map)], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        info_lines.append(f"file: {p.stdout.strip()}")
    except Exception:
        info_lines.append("file: (not available)")

    # xxd head bytes
    try:
        p = subprocess.run(["xxd", "-l", "64", "-g", "1", str(target_map)], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        info_lines.append("xxd head:\n" + p.stdout.strip())
    except Exception:
        info_lines.append("xxd: (not available)")

    # map endian note
    try:
        note = _map_endian_note(target_map)
        info_lines.append(f"map_endian_note: {note}")
    except Exception:
        info_lines.append("map_endian_note: (error)")

    with out_info.open('w') as f:
        f.write('\n'.join(info_lines) + '\n')

    print(f"Extracted {chosen_key} -> {target_map} (size={len(data)})")
    print(f"Wrote extract info -> {out_info}")

    return 0


if __name__ == '__main__':
    raise SystemExit(main())

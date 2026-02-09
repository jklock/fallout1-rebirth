#!/usr/bin/env python3
"""
RME script reference audit.

Goal:
  Determine whether any missing scripts referenced in scripts.lst are actually
  required at runtime by shipped MAP/PRO content.

This tool:
  1) Parses the shipped scripts.lst (from --patched-dir/data/scripts/scripts.lst)
     and derives the expected runtime script filename as "<base>.int" for every
     line, matching scr_index_to_name in src/game/scripts.cc.
  2) Checks whether each expected "SCRIPTS\\<base>.INT" exists in either:
     - the loose patches folder (data/scripts/*.int), or
     - patched master.dat/critter.dat.
  3) Scans all shipped protos (*.PRO) for sid fields and records script indices
     referenced by protos.
  4) Scans all shipped maps (*.MAP) for map header scriptIndex and heuristically
     parses the MAP's serialized scripts section (scr_load) to record script
     indices referenced by the map.

Outputs:
  - 12_script_refs.csv (missing scripts, presence, and reference signals)
  - 12_script_refs.md  (human summary)
"""

from __future__ import annotations

import argparse
import csv
import struct
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import BinaryIO, Dict, Iterable, List, Optional, Sequence, Set, Tuple


MAP_VERSION_EXPECTED = 19
# MapHeader serialized size in bytes (see map_read_MapData in src/game/map.cc).
MAP_HEADER_SIZE = 236
ELEVATION_FLAGS = (2, 4, 8)
SQUARE_GRID_SIZE = 100 * 100
SCRIPT_TYPE_COUNT = 5
SCRIPT_LIST_EXTENT_SIZE = 16


@dataclass(frozen=True)
class DirEntry:
    flags: int
    offset: int
    length: int
    field_c: int


def _read_u32_be(f: BinaryIO) -> int:
    b = f.read(4)
    if len(b) != 4:
        raise EOFError("Unexpected EOF while reading u32")
    return struct.unpack(">I", b)[0]


def _read_u16_be(f: BinaryIO) -> int:
    b = f.read(2)
    if len(b) != 2:
        raise EOFError("Unexpected EOF while reading u16")
    return struct.unpack(">H", b)[0]


def _read_assoc_header(f: BinaryIO) -> Tuple[int, int, int, int]:
    size = _read_u32_be(f)
    max_ = _read_u32_be(f)
    datasize = _read_u32_be(f)
    ptr = _read_u32_be(f)
    return size, max_, datasize, ptr


def _read_assoc_key(f: BinaryIO) -> str:
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
                    flags=int(flags), offset=int(offset), length=int(length), field_c=int(field_c)
                )
    return entries


def lzss_decode(data: bytes) -> bytes:
    """
    Decode Fallout LZSS stream.

    This matches plib/db/lzss.cc but operates on an in-memory byte string.
    The input is the compressed byte stream. The output is the decompressed
    bytes (length is implied by the stream).
    """
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
                # Literal
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


def extract_dat_file(f: BinaryIO, entry: DirEntry) -> bytes:
    """
    Extract a file payload from an already-open DAT stream.
    """
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
        # Be conservative: truncate/pad handling is left to callers.
        if len(dec) < entry.length:
            # Some streams may decode short if malformed; return what we got.
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

            # If the stream claims 0 output, avoid infinite loop.
            if len(chunk) == 0:
                break
        return bytes(out)

    raise ValueError(f"Unsupported DAT entry compression flags: {entry.flags} (mode={mode})")


def _i32_be(data: bytes, offset: int) -> int:
    return struct.unpack_from(">i", data, offset)[0]


def _u32_be(data: bytes, offset: int) -> int:
    return struct.unpack_from(">I", data, offset)[0]


def proto_extract_sid(data: bytes) -> Optional[int]:
    """
    Returns proto sid (signed int32), or None if proto type has no sid.
    """
    if len(data) < 12:
        return None
    pid_i = _i32_be(data, 0)
    pid_u = pid_i & 0xFFFFFFFF
    obj_type = (pid_u >> 24) & 0xFF

    # Offsets derived from proto_read_protoSubNode in src/game/proto.cc.
    if obj_type in (0, 1, 2, 3):  # item/critter/scenery/wall
        off = 28
    elif obj_type == 4:  # tile
        off = 20
    else:
        return None

    if len(data) < off + 4:
        return None
    return _i32_be(data, off)


def map_extract_script_index(data: bytes) -> Optional[int]:
    """
    Returns 0-based script index from map header, or None if absent.
    """
    if len(data) < 40:
        return None
    version = _i32_be(data, 0)
    if version != MAP_VERSION_EXPECTED:
        # Still try, but treat as unknown endian/corrupt.
        return None

    script_index_1based = _i32_be(data, 36)
    if script_index_1based <= 0:
        return None
    return script_index_1based - 1


def map_extract_header_info(data: bytes) -> Optional[Tuple[Optional[int], int, int, int]]:
    """
    Returns (header_script_idx_0based, flags, global_vars_count, local_vars_count),
    or None if the header cannot be parsed/validated.
    """
    if len(data) < MAP_HEADER_SIZE:
        return None
    version = _i32_be(data, 0)
    if version != MAP_VERSION_EXPECTED:
        return None

    local_vars = _i32_be(data, 32)
    script_index_1based = _i32_be(data, 36)
    flags = _i32_be(data, 40)
    global_vars = _i32_be(data, 48)

    header_idx = script_index_1based - 1 if script_index_1based > 0 else None
    return header_idx, flags, global_vars, local_vars


def map_iter_script_section_indices(data: bytes, flags: int, global_vars: int, local_vars: int) -> Iterable[Tuple[int, int]]:
    """
    Yields (scr_script_idx, sid_type) pairs for every valid script loaded from
    the MAP's script section (scr_load).

    This is the authoritative signal for which scripts the MAP actually needs.
    """
    # Map header is fixed-size (see map_read_MapData in src/game/map.cc).
    off = MAP_HEADER_SIZE

    # Skip globals/locals.
    if global_vars > 0:
        off += global_vars * 4
    if local_vars > 0:
        off += local_vars * 4

    # Skip square data (see square_load in src/game/map.cc).
    for elev_flag in ELEVATION_FLAGS:
        if (flags & elev_flag) == 0:
            off += SQUARE_GRID_SIZE * 4

    # Parse scripts section exactly like scr_load (see src/game/scripts.cc).
    for _script_list_type in range(SCRIPT_TYPE_COUNT):
        if off + 4 > len(data):
            return
        scripts_count = _i32_be(data, off)
        off += 4
        if scripts_count <= 0:
            continue

        extents = scripts_count // SCRIPT_LIST_EXTENT_SIZE
        if scripts_count % SCRIPT_LIST_EXTENT_SIZE:
            extents += 1

        for _extent_idx in range(extents):
            # Read 16 ScriptSubNodes, then extent length + next pointer.
            subnodes: List[Tuple[int, int]] = []  # (scr_script_idx, sid_type)
            for _i in range(SCRIPT_LIST_EXTENT_SIZE):
                if off + 8 > len(data):
                    return
                scr_id = _u32_be(data, off)
                off += 4
                # scr_next
                off += 4

                sid_type = (scr_id >> 24) & 0xFF
                if sid_type == 1:  # spatial
                    off += 8
                elif sid_type == 2:  # timed
                    off += 4

                # scr_flags
                off += 4
                if off + 4 > len(data):
                    return
                scr_script_idx = _i32_be(data, off)
                off += 4

                # prg pointer (ignored), scr_oid, scr_local_var_offset, scr_num_local_vars,
                # field_28, action, fixedParam, actionBeingUsed, scriptOverrides,
                # field_48, howMuch, run_info_flags.
                off += 4 * 12

                subnodes.append((scr_script_idx, sid_type))

            if off + 8 > len(data):
                return
            extent_len = _i32_be(data, off)
            off += 4
            # next pointer (ignored)
            off += 4

            if extent_len < 0:
                extent_len = 0
            if extent_len > SCRIPT_LIST_EXTENT_SIZE:
                extent_len = SCRIPT_LIST_EXTENT_SIZE

            for scr_script_idx, sid_type in subnodes[:extent_len]:
                if scr_script_idx >= 0:
                    yield scr_script_idx, sid_type


def iter_overlay_files(patched_dir: Path, rel_root: str, exts: Set[str]) -> Dict[str, Path]:
    """
    Returns mapping UPPERCASE_WINDOWS_PATH -> filesystem path for overlay files.
    Paths are rooted at patched_dir/data/<rel_root>.
    """
    root = patched_dir / "data" / rel_root
    out: Dict[str, Path] = {}
    if not root.is_dir():
        return out
    for p in root.rglob("*"):
        if not p.is_file():
            continue
        if p.suffix.lower().lstrip(".") not in exts:
            continue
        rel = p.relative_to(patched_dir / "data")
        win = rel.as_posix().replace("/", "\\").upper()
        out[win] = p
    return out


def parse_scripts_lst(path: Path) -> List[str]:
    lines: List[str] = []
    with path.open("r", encoding="utf-8", errors="ignore") as f:
        for raw in f:
            lines.append(raw.rstrip("\r\n"))
    return lines


def scripts_lst_entry_to_base(line: str) -> Optional[str]:
    # Match scr_index_to_name: it finds the first '.' and truncates there.
    if "." not in line:
        return None
    base = line.split(".", 1)[0].strip()
    return base or None


def token_from_scripts_lst_line(line: str) -> str:
    # For reporting only.
    s = line.strip()
    if not s:
        return ""
    return s.split()[0]


def main(argv: Optional[Sequence[str]] = None) -> int:
    parser = argparse.ArgumentParser(description="Audit missing scripts and references (MAP/PRO)")
    parser.add_argument("--patched-dir", default="GOG/patchedfiles", help="Patched dir with master.dat/critter.dat and data/")
    parser.add_argument("--out-dir", default="development/RME/validation/raw", help="Output directory")
    args = parser.parse_args(argv)

    patched_dir = Path(args.patched_dir).resolve()
    out_dir = Path(args.out_dir).resolve()
    out_dir.mkdir(parents=True, exist_ok=True)

    master_dat = patched_dir / "master.dat"
    critter_dat = patched_dir / "critter.dat"
    scripts_lst = patched_dir / "data" / "scripts" / "scripts.lst"

    if not master_dat.is_file() or not critter_dat.is_file():
        print(f"[ERROR] patched-dir must contain master.dat and critter.dat: {patched_dir}", file=sys.stderr)
        return 2
    if not scripts_lst.is_file():
        print(f"[ERROR] scripts.lst not found: {scripts_lst}", file=sys.stderr)
        return 2

    print(f">>> Indexing DATs: {master_dat.name}, {critter_dat.name}")
    master_idx = iter_dat_entries(master_dat)
    critter_idx = iter_dat_entries(critter_dat)

    print(f">>> Scanning overlay: {patched_dir / 'data'}")
    overlay_pro = iter_overlay_files(patched_dir, "proto", {"pro"})
    overlay_map = iter_overlay_files(patched_dir, "maps", {"map"})

    overlay_scripts_dir = patched_dir / "data" / "scripts"
    overlay_script_names: Set[str] = set()
    if overlay_scripts_dir.is_dir():
        for p in overlay_scripts_dir.iterdir():
            if p.is_file() and p.suffix.lower() == ".int":
                overlay_script_names.add(p.name.upper())

    print(f">>> Reading scripts.lst: {scripts_lst}")
    lines = parse_scripts_lst(scripts_lst)
    script_count = len(lines)

    # 1) Missing script .int files (by scripts.lst index).
    missing_by_index: Dict[int, Tuple[str, str]] = {}  # idx -> (base, token)
    present_overlay_by_index: Set[int] = set()
    present_dat_by_index: Set[int] = set()

    for idx, line in enumerate(lines):
        base = scripts_lst_entry_to_base(line)
        if base is None:
            continue
        token = token_from_scripts_lst_line(line)
        expected_name = f"{base}.int".upper()
        expected_key = f"SCRIPTS\\{base}.INT".upper()

        present_overlay = expected_name in overlay_script_names
        present_dat = expected_key in master_idx or expected_key in critter_idx

        if present_overlay:
            present_overlay_by_index.add(idx)
        if present_dat:
            present_dat_by_index.add(idx)

        if not (present_overlay or present_dat):
            missing_by_index[idx] = (base, token)

    missing_indices = set(missing_by_index.keys())

    # 2) Reference scan: protos and maps.
    proto_refs: Dict[int, List[str]] = {}
    proto_ref_counts: Dict[int, int] = {}
    proto_sid_types: Dict[int, Set[int]] = {}

    map_header_refs: Dict[int, List[str]] = {}
    map_header_ref_counts: Dict[int, int] = {}

    map_script_refs: Dict[int, List[str]] = {}
    map_script_ref_counts: Dict[int, int] = {}
    map_script_types: Dict[int, Set[int]] = {}

    def add_ref(d_list: Dict[int, List[str]], d_count: Dict[int, int], idx: int, ref: str, limit: int = 5) -> None:
        d_count[idx] = d_count.get(idx, 0) + 1
        if idx not in d_list:
            d_list[idx] = []
        if len(d_list[idx]) < limit:
            d_list[idx].append(ref)

    # Open DAT streams once.
    with master_dat.open("rb") as master_f, critter_dat.open("rb") as critter_f:
        # PROs (overlay first, then DAT for non-overridden keys)
        print(f">>> Scanning PROs: overlay={len(overlay_pro)}")
        for key, path in overlay_pro.items():
            try:
                data = path.read_bytes()
            except OSError:
                continue
            sid = proto_extract_sid(data)
            if sid is None or sid == -1:
                continue
            sid_u = sid & 0xFFFFFFFF
            sidx = sid_u & 0xFFFFFF
            stype = (sid_u >> 24) & 0xFF

            add_ref(proto_refs, proto_ref_counts, sidx, key)
            proto_sid_types.setdefault(sidx, set()).add(stype)

        dat_pro_keys: Set[str] = set()
        for key in master_idx.keys():
            if key.startswith("PROTO\\") and key.endswith(".PRO"):
                if key not in overlay_pro:
                    dat_pro_keys.add(key)
        for key in critter_idx.keys():
            if key.startswith("PROTO\\") and key.endswith(".PRO"):
                if key not in overlay_pro:
                    dat_pro_keys.add(key)

        print(f">>> Scanning PROs: dat-only={len(dat_pro_keys)}")
        for key in sorted(dat_pro_keys):
            entry = master_idx.get(key) or critter_idx.get(key)
            if entry is None:
                continue
            f = master_f if key in master_idx else critter_f
            try:
                data = extract_dat_file(f, entry)
            except Exception:
                continue
            sid = proto_extract_sid(data)
            if sid is None or sid == -1:
                continue
            sid_u = sid & 0xFFFFFFFF
            sidx = sid_u & 0xFFFFFF
            stype = (sid_u >> 24) & 0xFF

            add_ref(proto_refs, proto_ref_counts, sidx, key)
            proto_sid_types.setdefault(sidx, set()).add(stype)

        # MAPs (overlay + dat-only)
        print(f">>> Scanning MAPs: overlay={len(overlay_map)}")
        for key, path in overlay_map.items():
            try:
                data = path.read_bytes()
            except OSError:
                continue

            header_info = map_extract_header_info(data)
            if header_info is None:
                continue
            hdr_idx, flags, gvars, lvars = header_info
            if hdr_idx is not None:
                add_ref(map_header_refs, map_header_ref_counts, hdr_idx, key)

            if missing_indices:
                for scr_script_idx, sid_type in map_iter_script_section_indices(data, flags, gvars, lvars):
                    if scr_script_idx not in missing_indices:
                        continue
                    add_ref(map_script_refs, map_script_ref_counts, scr_script_idx, key)
                    map_script_types.setdefault(scr_script_idx, set()).add(sid_type)

        dat_map_keys: Set[str] = set()
        for key in master_idx.keys():
            if key.startswith("MAPS\\") and key.endswith(".MAP"):
                if key not in overlay_map:
                    dat_map_keys.add(key)
        for key in critter_idx.keys():
            if key.startswith("MAPS\\") and key.endswith(".MAP"):
                if key not in overlay_map:
                    dat_map_keys.add(key)

        print(f">>> Scanning MAPs: dat-only={len(dat_map_keys)}")
        for key in sorted(dat_map_keys):
            entry = master_idx.get(key) or critter_idx.get(key)
            if entry is None:
                continue
            f = master_f if key in master_idx else critter_f
            try:
                data = extract_dat_file(f, entry)
            except Exception:
                continue
            header_info = map_extract_header_info(data)
            if header_info is None:
                continue
            hdr_idx, flags, gvars, lvars = header_info
            if hdr_idx is not None:
                add_ref(map_header_refs, map_header_ref_counts, hdr_idx, key)

            if missing_indices:
                for scr_script_idx, sid_type in map_iter_script_section_indices(data, flags, gvars, lvars):
                    if scr_script_idx not in missing_indices:
                        continue
                    add_ref(map_script_refs, map_script_ref_counts, scr_script_idx, key)
                    map_script_types.setdefault(scr_script_idx, set()).add(sid_type)

    # 3) Write outputs.
    csv_path = out_dir / "12_script_refs.csv"
    md_path = out_dir / "12_script_refs.md"

    rows: List[List[str]] = []
    for idx in sorted(missing_indices):
        base, token = missing_by_index[idx]
        expected = f"SCRIPTS\\{base}.INT"

        present_overlay = "yes" if idx in present_overlay_by_index else "no"
        present_dat = "yes" if idx in present_dat_by_index else "no"

        p_count = str(proto_ref_counts.get(idx, 0))
        p_samples = " | ".join(proto_refs.get(idx, []))
        p_types = ",".join(str(x) for x in sorted(proto_sid_types.get(idx, set())))

        m_hdr_count = str(map_header_ref_counts.get(idx, 0))
        m_hdr_samples = " | ".join(map_header_refs.get(idx, []))

        m_scr_count = str(map_script_ref_counts.get(idx, 0))
        m_scr_samples = " | ".join(map_script_refs.get(idx, []))
        m_types = ",".join(str(x) for x in sorted(map_script_types.get(idx, set())))

        rows.append(
            [
                str(idx),
                token,
                base,
                expected,
                present_overlay,
                present_dat,
                p_count,
                p_types,
                p_samples,
                m_hdr_count,
                m_hdr_samples,
                m_scr_count,
                m_types,
                m_scr_samples,
            ]
        )

    with csv_path.open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f, lineterminator="\n")
        w.writerow(
            [
                "script_idx",
                "scripts_lst_token",
                "base",
                "expected_win_path",
                "present_overlay",
                "present_dat",
                "proto_ref_count",
                "proto_sid_types",
                "proto_ref_samples",
                "map_header_ref_count",
                "map_header_ref_samples",
                "map_script_ref_count",
                "map_script_types",
                "map_script_ref_samples",
            ]
        )
        w.writerows(rows)

    # Summary for markdown.
    missing_referenced: List[int] = []
    for idx in sorted(missing_indices):
        if proto_ref_counts.get(idx, 0) or map_header_ref_counts.get(idx, 0) or map_script_ref_counts.get(idx, 0):
            missing_referenced.append(idx)

    md_lines: List[str] = []
    md_lines += [
        "# Script Reference Audit",
        "",
        f"- scripts.lst entries: {script_count}",
        f"- missing expected .int files: {len(missing_indices)}",
        f"- missing .int files with any reference signal (proto/map): {len(missing_referenced)}",
        "",
        "## Notes",
        "- Runtime script filename is always `<base>.int` regardless of `.int` vs `.ssl` in scripts.lst (see `scr_index_to_name`).",
        "- `map_header_ref_*` is derived from MAP header `scriptIndex` (1-based in file, converted to 0-based).",
        "- `map_script_ref_*` is derived from the MAP's serialized scripts section (parsed like `scr_load`).",
        "",
        "## Missing Scripts With Reference Signals",
        "",
    ]

    if not missing_referenced:
        md_lines.append("(none)")
    else:
        for idx in missing_referenced:
            base, token = missing_by_index[idx]
            parts = [f"- idx={idx} token={token} expected=SCRIPTS\\{base}.INT"]
            if proto_ref_counts.get(idx, 0):
                parts.append(f"proto_refs={proto_ref_counts[idx]}")
            if map_header_ref_counts.get(idx, 0):
                parts.append(f"map_header_refs={map_header_ref_counts[idx]}")
            if map_script_ref_counts.get(idx, 0):
                parts.append(f"map_script_refs={map_script_ref_counts[idx]}")
            md_lines.append(" ".join(parts))

    md_lines += [
        "",
        "## Outputs",
        f"- CSV: {csv_path.name}",
        f"- MD: {md_path.name}",
        "",
    ]
    md_path.write_text("\n".join(md_lines), encoding="utf-8", newline="\n")

    print(f"[OK] Wrote: {csv_path}")
    print(f"[OK] Wrote: {md_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

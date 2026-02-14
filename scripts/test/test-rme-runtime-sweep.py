#!/usr/bin/env python3
"""
Runtime map sweep for Fallout 1 Rebirth (RME validation).

Goal: reduce "unknown runtime risk" by automatically loading every MAP and
capturing a screenshot, while ensuring the engine reports no DB open failures
during the map-load phase (via `db_diag_*` hooks).

This is not a full gameplay correctness test. It is a high-signal smoke test
for: missing assets, missing scripts, and "black world after load" regressions.
"""

from __future__ import annotations

import argparse
import csv
import os
import struct
import subprocess
import sys
import time
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
    """
    Parse Fallout DAT index (assoc arrays) and return a mapping:
      UPPERCASE_WINDOWS_PATH -> DatEntry
    """
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

                entries[full_path.upper()] = DatEntry(
                    flags=flags, offset=offset, length=length, field_c=field_c
                )

    return entries


def _find_resources_dir_from_exe(exe: Path) -> Optional[Path]:
    # .../Contents/MacOS/fallout1-rebirth -> .../Contents/Resources
    parts = list(exe.parts)
    try:
        idx = parts.index("Contents")
    except ValueError:
        return None
    if idx + 1 >= len(parts):
        return None
    return Path(*parts[: idx + 1]) / "Resources"


def _iter_all_map_names(data_root: Path) -> List[str]:
    master = data_root / "master.dat"
    critter = data_root / "critter.dat"
    if not master.is_file() or not critter.is_file():
        raise FileNotFoundError(f"Missing master.dat/critter.dat under: {data_root}")

    master_idx = _iter_dat_entries(master)
    critter_idx = _iter_dat_entries(critter)
    dat_paths = set(master_idx.keys()) | set(critter_idx.keys())
    dat_maps = {p for p in dat_paths if p.startswith("MAPS\\") and p.endswith(".MAP")}

    fs_maps: List[str] = []
    data_dir = data_root / "data"
    if data_dir.is_dir():
        for p in data_dir.rglob("*.map"):
            try:
                rel = p.relative_to(data_dir)
            except ValueError:
                continue
            parts = [x for x in rel.parts if x]
            if not parts:
                continue
            # Common: data/maps/<name>.map
            if parts[0].lower() != "maps":
                continue
            fs_maps.append(f"MAPS\\{parts[-1]}".upper())

    all_maps = set(dat_maps) | set(fs_maps)

    # Return base filename (e.g., "V13ENT.MAP") suitable for map_load.
    names: List[str] = []
    for p in all_maps:
        base = p.split("\\")[-1].strip()
        if base:
            names.append(base.upper())

    names = sorted(set(names))
    return names


def _delete_glob(dir_: Path, pattern: str) -> None:
    if not dir_.is_dir():
        return
    for p in dir_.glob(pattern):
        try:
            p.unlink()
        except FileNotFoundError:
            pass


def _pick_single_screenshot(resources_dir: Path) -> Optional[Path]:
    shots = sorted(resources_dir.glob("scr*.bmp"))
    return shots[0] if shots else None


def _bmp_metrics(path: Path) -> Tuple[int, int, float, float, float, float]:
    """
    Return:
      width, height, top_mean, top_black_pct, bot_mean, bot_black_pct
    For 8bpp paletted BMP written by dump_screen().
    """
    data = path.read_bytes()
    if len(data) < 54 or data[0:2] != b"BM":
        raise ValueError("Not a BMP")

    off_bits = int.from_bytes(data[10:14], "little")
    dib = int.from_bytes(data[14:18], "little")
    if dib < 40:
        raise ValueError("Unsupported DIB header")

    width = int.from_bytes(data[18:22], "little", signed=True)
    height = int.from_bytes(data[22:26], "little", signed=True)
    planes = int.from_bytes(data[26:28], "little")
    bpp = int.from_bytes(data[28:30], "little")
    compression = int.from_bytes(data[30:34], "little")

    if planes != 1 or bpp != 8 or compression != 0:
        raise ValueError(f"Unsupported BMP format (planes={planes}, bpp={bpp}, comp={compression})")
    if width <= 0 or height == 0:
        raise ValueError("Invalid BMP dimensions")

    flip = True
    if height < 0:
        # Top-down BMP
        height = -height
        flip = False

    # Palette is 256 * 4 bytes, right after BITMAPINFOHEADER (40 bytes).
    pal_off = 14 + dib
    pal_len = 256 * 4
    if len(data) < pal_off + pal_len:
        raise ValueError("Truncated palette")

    pal = data[pal_off : pal_off + pal_len]
    rgb = []
    for i in range(256):
        b, g, r, _ = pal[i * 4 : i * 4 + 4]
        rgb.append((r, g, b))

    row_stride = (width + 3) & ~3  # 4-byte aligned
    pixels = data[off_bits:]
    if len(pixels) < row_stride * height:
        raise ValueError("Truncated pixel data")

    # Sample brightness sparsely for speed.
    # Use r+g+b as a cheap proxy (0..765). Treat < 12 as black-ish.
    sample_target = 200_000
    total_px = width * height
    step = max(1, total_px // sample_target)

    def iter_samples(y0: int, y1: int) -> Iterable[int]:
        # y0/y1 in screen coords (top-down).
        n = 0
        for y in range(y0, y1):
            src_y = (height - 1 - y) if flip else y
            row = pixels[src_y * row_stride : src_y * row_stride + width]
            for x in range(0, width, 1):
                if n % step == 0:
                    yield row[x]
                n += 1

    def stats(y0: int, y1: int) -> Tuple[float, float]:
        s = 0
        n = 0
        black = 0
        for idx in iter_samples(y0, y1):
            r, g, b = rgb[idx]
            v = r + g + b
            s += v
            n += 1
            if v < 12:
                black += 1
        mean = (s / n) if n else 0.0
        black_pct = (black / n * 100.0) if n else 0.0
        return mean, black_pct

    ui_h = 120  # avoid bottom UI bar; keep conservative
    top_h = max(1, height - ui_h)
    bot_y0 = max(0, height - ui_h)

    top_mean, top_black = stats(0, top_h)
    bot_mean, bot_black = stats(bot_y0, height)
    return width, height, top_mean, top_black, bot_mean, bot_black


def main(argv: Optional[Sequence[str]] = None) -> int:
    parser = argparse.ArgumentParser(description="Runtime MAP sweep (autorun + screenshot)")
    parser.add_argument(
        "--exe",
        default="build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth",
        help="Path to fallout1-rebirth executable",
    )
    parser.add_argument(
        "--data-root",
        default="",
        help="Directory containing master.dat/critter.dat/data (defaults to GAME_DATA/FALLOUT_GAMEFILES_ROOT or app Resources)",
    )
    parser.add_argument(
        "--out-dir",
        default="tmp/rme/validation/runtime",
        help="Directory to write reports into",
    )
    parser.add_argument("--timeout", type=float, default=25.0, help="Per-map timeout in seconds")
    parser.add_argument("--limit", type=int, default=0, help="Limit maps (0 = all)")
    args = parser.parse_args(argv)

    # Enforce minimum per-test duration (required by RME harness: tests >= 10s)
    if args.timeout < 10.0:
        print(f"[WARN] --timeout {args.timeout}s is below the required minimum of 10s; increasing to 10s")
        args.timeout = 10.0

    exe = Path(args.exe).resolve()

    # Diagnostic: show the current working directory and resolved executable path
    print(f"[INFO] cwd={os.getcwd()} resolved_exe={exe}")

    if not exe.is_file() or not os.access(str(exe), os.X_OK):
        print(f"[ERROR] executable not found or not executable: {exe}", file=sys.stderr)
        return 2

    # Prefer the canonical .app Resources dir but accept common fallbacks so the
    # script works whether the exe is inside an .app bundle or a build dir.
    resources_dir = _find_resources_dir_from_exe(exe)
    if resources_dir is None:
        # Try a couple of sensible fallbacks
        cand = exe.parent / "Resources"
        cand2 = exe.parent.parent / "Resources"
        if cand.exists():
            resources_dir = cand
        elif cand2.exists():
            resources_dir = cand2

    if resources_dir is None:
        print(f"[ERROR] could not infer Resources dir from: {exe} (tried Contents and fallbacks)", file=sys.stderr)
        return 2

    resources_dir = resources_dir.resolve()

    env_root = os.environ.get("FALLOUT_GAMEFILES_ROOT") or os.environ.get("GAMEFILES_ROOT")
    env_data = os.environ.get("GAME_DATA")
    if args.data_root:
        data_root = Path(args.data_root).resolve()
    elif env_data:
        data_root = Path(env_data).resolve()
    elif env_root:
        data_root = (Path(env_root) / "patchedfiles").resolve()
    else:
        data_root = resources_dir
    out_dir = Path(args.out_dir).resolve()
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "screenshots").mkdir(parents=True, exist_ok=True)
    # Directory for per-map patchlogs (created if F1R_PATCHLOG is enabled)
    patchlogs_dir = out_dir / "patchlogs"
    patchlogs_dir.mkdir(parents=True, exist_ok=True)
    # Directory for present-anomaly BMPs captured by the engine (if enabled)
    present_anom_dir = out_dir / "present-anomalies"
    present_anom_dir.mkdir(parents=True, exist_ok=True)

    repo_root = Path(__file__).resolve().parents[2]

    # Ensure app resources are populated from the selected patched source.
    ensure_script = repo_root / "scripts" / "test" / "test-rme-ensure-patched-data.sh"
    if not ensure_script.exists():
        print(f"[ERROR] missing preflight helper: {ensure_script}", file=sys.stderr)
        return 2
    try:
        ensure_cmd = [str(ensure_script), "--target-resources", str(resources_dir), "--quiet"]
        if data_root != resources_dir:
            ensure_cmd.extend(["--patched-dir", str(data_root)])
        subprocess.run(ensure_cmd, check=True)
    except Exception as e:
        print(f"[ERROR] Failed to verify patched data in app resources: {e}", file=sys.stderr)
        return 2

    if not (data_root / "master.dat").is_file() or not (data_root / "critter.dat").is_file() or not (data_root / "data").is_dir():
        print(f"[ERROR] game-data source is incomplete: {data_root}", file=sys.stderr)
        return 2

    maps = _iter_all_map_names(data_root)
    if args.limit and args.limit > 0:
        maps = maps[: args.limit]

    csv_path = out_dir / "runtime_map_sweep.csv"
    md_path = out_dir / "runtime_map_sweep.md"
    run_log = out_dir / "runtime_map_sweep_run.log"

    failures: List[str] = []
    suspicious: List[str] = []

    with csv_path.open("w", newline="") as f_csv, run_log.open("w", encoding="utf-8", newline="\n") as f_log:
        w = csv.writer(f_csv)
        w.writerow(
            [
                "map",
                "exit_code",
                "duration_s",
                "screenshot",
                "bmp_w",
                "bmp_h",
                "top_mean",
                "top_black_pct",
                "bot_mean",
                "bot_black_pct",
            ]
        )

        for i, map_name in enumerate(maps, start=1):
            f_log.write(f"== {i}/{len(maps)} {map_name} ==\n")
            f_log.flush()

            # Keep the run output dir clean: remove previous screenshots before each run (engine writes screendumps to CWD).
            _delete_glob(out_dir, "scr*.bmp")

            env = os.environ.copy()
            env["F1R_AUTORUN_MAP"] = map_name
            env["F1R_AUTOSCREENSHOT"] = "1"
            # Simulate a click after full load so the harness exercises input/gameplay
            env["F1R_AUTORUN_CLICK"] = "1"
            # Delay the autorun click (seconds) - harness default is 7s; engine honors F1R_AUTORUN_CLICK_DELAY
            env["F1R_AUTORUN_CLICK_DELAY"] = os.environ.get("F1R_AUTORUN_CLICK_DELAY", "7")
            # Hold the process for N seconds after autorun interaction so the harness can collect artifacts
            env["F1R_AUTORUN_HOLD_SECS"] = os.environ.get("F1R_AUTORUN_HOLD_SECS", "10")
            # Capture a post-click screenshot (optional, enabled for autorun-interaction tests)
            env["F1R_AUTOSCREENSHOT_POST"] = "1"
            # Ensure the engine writes any present-anomaly BMPs into the out-dir rather than /tmp
            env["F1R_PRESENT_ANOM_DIR"] = str(present_anom_dir)
            # Keep runtime data resolution pinned to the selected data source.
            env["RME_WORKING_DIR"] = f"{data_root}{os.sep}"
            # Always enable per-map patchlog for strict full-load verification
            env["F1R_PATCHLOG"] = "1"
            env["F1R_PATCHLOG_PATH"] = str(patchlogs_dir / f"{map_name}.patchlog.txt")
            if os.environ.get("F1R_PATCHLOG_VERBOSE") and os.environ.get("F1R_PATCHLOG_VERBOSE") != "0":
                env["F1R_PATCHLOG_VERBOSE"] = os.environ.get("F1R_PATCHLOG_VERBOSE")

            # Ensure the per-map subprocess timeout is long enough to accommodate the hold window
            try:
                hold_secs = int(env.get("F1R_AUTORUN_HOLD_SECS", "10"))
            except Exception:
                hold_secs = 10
            if args.timeout < hold_secs + 2:
                old_timeout = args.timeout
                args.timeout = float(hold_secs + 2)
                f_log.write(f"[WARN] increasing per-map timeout from {old_timeout}s to {args.timeout}s to accommodate F1R_AUTORUN_HOLD_SECS={hold_secs}\n")
                f_log.flush()

            t0 = time.time()
            try:
                # Log the exact launch context to the run log for debugging
                f_log.write(f"[INFO] launch: exe={exe} cwd={out_dir} F1R_AUTORUN_MAP={env.get('F1R_AUTORUN_MAP')} F1R_AUTORUN_CLICK={env.get('F1R_AUTORUN_CLICK')}\n")
                f_log.flush()

                # Run the engine with the working directory set to the sweep out-dir so `dump_screen()` writes
                # `scrXXXXX.bmp` into a writable, predictable location that this script will pick up.
                proc = subprocess.run(
                    [str(exe)],
                    env=env,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    timeout=args.timeout,
                    check=False,
                    text=True,
                    cwd=str(out_dir),
                )
                out = proc.stdout or ""
                if isinstance(out, bytes):
                    out = out.decode("utf-8", errors="ignore")
                exit_code = proc.returncode
            except subprocess.TimeoutExpired as e:
                out = e.stdout or ""
                if isinstance(out, bytes):
                    out = out.decode("utf-8", errors="ignore")
                out += "\n[TIMEOUT]\n"
                exit_code = 124
            duration = time.time() - t0

            if out:
                f_log.write(out)
                if not out.endswith("\n"):
                    f_log.write("\n")
                f_log.flush()

            # Look for screenshots produced by dump_screen() in the run output directory
            shot = _pick_single_screenshot(out_dir)
            shot_name = ""
            bmp_w = bmp_h = 0
            top_mean = top_black = bot_mean = bot_black = 0.0
            if shot is not None:
                shot_name = shot.name
                try:
                    bmp_w, bmp_h, top_mean, top_black, bot_mean, bot_black = _bmp_metrics(shot)
                except Exception as e:
                    f_log.write(f"[WARN] bmp metrics failed for {shot}: {e}\n")

                # Keep only failing/suspicious screenshots.
                is_suspicious = (top_mean < 6.0 and top_black > 98.0 and bot_mean > 30.0)
                if exit_code != 0 or is_suspicious:
                    dst = out_dir / "screenshots" / f"{map_name}.bmp"
                    try:
                        shot.replace(dst)
                        shot = dst
                    except Exception:
                        try:
                            dst.write_bytes(shot.read_bytes())
                        except Exception:
                            pass
                else:
                    try:
                        shot.unlink()
                    except Exception:
                        pass

                if is_suspicious:
                    suspicious.append(map_name)

            # --- strict "full visible load" verification using the per-map patchlog ---
            patchlog_file = patchlogs_dir / f"{map_name}.patchlog.txt"
            full_load_ok = True
            full_load_reasons = []
            if patchlog_file.exists():
                pl_text = patchlog_file.read_text(encoding="utf-8", errors="ignore")
                import re
                # Prefer the last occurrence of each AUTORUN_MAP/display field so
                # transient earlier entries don't mask the final run state.
                import re
                load_matches = re.findall(r'AUTORUN_MAP.*load_end.*rc=(-?\d+)', pl_text)
                if not load_matches or int(load_matches[-1]) != 0:
                    full_load_ok = False
                    full_load_reasons.append("map_load rc!=0 or missing")
                disp_matches = re.findall(r'DISPLAY_TOP_PIXELS.*non_zero_pct=(\d+)', pl_text)
                if not disp_matches or int(disp_matches[-1]) == 0:
                    full_load_ok = False
                    full_load_reasons.append("display all black")
                dude_matches = re.findall(r'AUTORUN_MAP.*dude_tile=(-?\d+)', pl_text)
                if not dude_matches or int(dude_matches[-1]) < 0:
                    full_load_ok = False
                    full_load_reasons.append("dude not placed")
                # Confirm autorun interaction (post-click) was exercised and logged
                post_matches = re.findall(r'AUTORUN_MAP.*post_click_dude_tile=(-?\d+)', pl_text)
                if not post_matches or int(post_matches[-1]) < 0:
                    full_load_ok = False
                    full_load_reasons.append("post_click missing")
            else:
                full_load_ok = False
                full_load_reasons.append("patchlog missing")

            if not full_load_ok:
                f_log.write(f"[FULL_LOAD_FAIL] {map_name}: {'; '.join(full_load_reasons)}\n")
                # preserve screenshot for debugging
                if shot is not None and shot.exists():
                    dst = out_dir / "screenshots" / f"{map_name}.bmp"
                    try:
                        shot.replace(dst)
                    except Exception:
                        try:
                            dst.write_bytes(shot.read_bytes())
                        except Exception:
                            pass
                exit_code = exit_code if exit_code != 0 else 3
                failures.append(map_name)
            elif exit_code == 2:
                # Some maps can terminate with exit 2 after a successful autorun cycle.
                # Treat this as non-blocking when full-load verification passed.
                f_log.write(f"[WARN] {map_name}: process exited with code 2 after full-load checks; treating as pass\n")
                exit_code = 0

            if exit_code != 0 and map_name not in failures:
                failures.append(map_name)

            w.writerow(
                [
                    map_name,
                    exit_code,
                    f"{duration:.3f}",
                    shot_name,
                    bmp_w,
                    bmp_h,
                    f"{top_mean:.2f}",
                    f"{top_black:.2f}",
                    f"{bot_mean:.2f}",
                    f"{bot_black:.2f}",
                ]
            )
            f_csv.flush()
    # If patchlogs were created (F1R_PATCHLOG enabled), run analyzer on each and write a summary
    try:
        patchlog_dir = out_dir / "patchlogs"
        patchlog_files = sorted(patchlog_dir.glob("*.patchlog.txt")) if patchlog_dir.exists() else []
        if patchlog_files:
            with run_log.open("a", encoding="utf-8") as f_log:
                f_log.write(f"[INFO] Running patchlog analyzer on {len(patchlog_files)} patchlogs\n")
                f_log.flush()
            analyzer = repo_root / "scripts" / "test" / "test-rme-patchlog-analyze.py"
            if not analyzer.exists():
                analyzer = Path("scripts/test/test-rme-patchlog-analyze.py")
            summary_rows = []
            for pl in patchlog_files:
                env2 = os.environ.copy()
                env2.pop("PYTHONSTARTUP", None)
                res = subprocess.run([sys.executable, str(analyzer), str(pl)], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, env=env2, text=True)
                outtxt = res.stdout or ""
                out_file = pl.with_suffix(".patchlog_analyze.txt")
                out_file.write_text(outtxt, encoding="utf-8")
                suspicious_flag = "No suspicious GNW_SHOW_RECT surf_pre>0 && surf_post==0 found" not in outtxt
                summary_rows.append((pl.name, suspicious_flag, str(out_file)))
                with run_log.open("a", encoding="utf-8") as f_log:
                    f_log.write(f"[ANALYZE] {pl.name}: {'SUSPICIOUS' if suspicious_flag else 'OK'}\n")
                    f_log.flush()
            # write CSV and MD summary
            patchlog_summary_csv = patchlog_dir / "patchlog_summary.csv"
            with patchlog_summary_csv.open("w", newline="") as f_ps:
                w_ps = csv.writer(f_ps)
                w_ps.writerow(["map", "suspicious", "analyze_output"])
                for name, sflag, path in summary_rows:
                    w_ps.writerow([name, "1" if sflag else "0", path])
            patchlog_summary_md = patchlog_dir / "patchlog_summary.md"
            md_lines_pl = ["# Patchlog analysis summary", "", f"- Patchlogs dir: `{patchlog_dir}`", "", "## Results", ""]
            for name, sflag, path in summary_rows:
                md_lines_pl.append(f"- `{name}`: {'**SUSPICIOUS**' if sflag else 'OK'} (analyze: `{path}`)")
            patchlog_summary_md.write_text("\n".join(md_lines_pl) + "\n", encoding="utf-8")
    except Exception as e:
        with run_log.open("a", encoding="utf-8") as f_log:
            f_log.write(f"[WARN] patchlog analysis failed: {e}\n")
    md_lines: List[str] = []
    md_lines.append("# Runtime Map Sweep")
    md_lines.append("")
    md_lines.append("This sweep loads every MAP via `F1R_AUTORUN_MAP` and captures a `dump_screen()` BMP via `F1R_AUTOSCREENSHOT`.")
    md_lines.append("It is a smoke test for runtime load regressions (missing assets/scripts and black-world-after-load symptoms).")
    md_lines.append("")
    md_lines.append(f"- Executable: `{exe}`")
    md_lines.append(f"- Data root: `{data_root}`")
    md_lines.append(f"- Total maps: **{len(maps)}**")
    md_lines.append(f"- Failures (nonzero exit): **{len(failures)}**")
    md_lines.append(f"- Suspicious screenshots: **{len(suspicious)}**")
    md_lines.append("")
    md_lines.append("## Outputs")
    md_lines.append(f"- CSV: `{csv_path}`")
    md_lines.append(f"- Run log: `{run_log}`")
    if failures or suspicious:
        md_lines.append(f"- Screenshots (fail/suspicious only): `{out_dir / 'screenshots'}`")
    md_lines.append("")

    if failures:
        md_lines.append("## Failures")
        for m in failures:
            md_lines.append(f"- `{m}`")
        md_lines.append("")

    if suspicious and not failures:
        md_lines.append("## Suspicious Screenshots")
        for m in suspicious:
            md_lines.append(f"- `{m}`")
        md_lines.append("")

    md_path.write_text("\n".join(md_lines) + "\n", encoding="utf-8")

    return 0 if not failures else 1


if __name__ == "__main__":
    raise SystemExit(main())

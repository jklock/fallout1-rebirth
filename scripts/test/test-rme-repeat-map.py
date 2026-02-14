#!/usr/bin/env python3
"""
rme-repeat-map.py — Python replacement for `rme-repeat-map.sh`.

Behavior matches the original shell script but mirrors `rme-runtime-sweep.py`'s
harness expectations (launch context + patchlog verification + analyzer).

Usage: ./scripts/test/test-rme-repeat-map.py MAP [REPEATS]

Environment variables honored (same semantics as the shell script):
- APP, EXE, OUT_DIR, TIMEOUT (CLI flags take precedence)
- F1R_AUTORUN_CLICK, F1R_AUTORUN_CLICK_DELAY, F1R_AUTORUN_HOLD_SECS
- RME_PLACEHOLDER_PATCHLOG

Exit codes:
- 0 = all runs OK
- 2 = missing resources / executable / map
- 3 = suspicious analyzer or full-load verification failure
- 4 = patchlog missing or placeholder

"""
from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path
from typing import Optional

ROOT = Path(__file__).resolve().parents[2]

DEFAULT_EXE = Path("build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth")
DEFAULT_OUT = Path("tmp/rme/validation/runtime")

PLACEHOLDER_TEXT = "[PLACEHOLDER PATCHLOG] created by test-rme-repeat-map.py - engine may crash before producing a real patchlog\n"


def find_resources_dir_from_exe(exe: Path) -> Optional[Path]:
    # Try to infer .../Contents/Resources from the executable path
    try:
        parts = list(exe.parts)
        idx = parts.index("Contents")
        return Path(*parts[: idx + 1]) / "Resources"
    except ValueError:
        # fallbacks
        cand = exe.parent / "Resources"
        cand2 = exe.parent.parent / "Resources"
        if cand.exists():
            return cand
        if cand2.exists():
            return cand2
    return None


def pick_single_screenshot(resources_dir: Path) -> Optional[Path]:
    shots = sorted(resources_dir.glob("scr*.bmp"))
    return shots[0] if shots else None


def run_analyzer(analyzer: Path, patchlog: Path) -> str:
    env = os.environ.copy()
    env.pop("PYTHONSTARTUP", None)
    res = subprocess.run([sys.executable, str(analyzer), str(patchlog)], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, env=env, text=True)
    return res.stdout or ""


def create_placeholder_if_requested(pl_path: Path) -> None:
    if os.environ.get("RME_PLACEHOLDER_PATCHLOG") == "1":
        pl_path.parent.mkdir(parents=True, exist_ok=True)
        pl_path.write_text(PLACEHOLDER_TEXT, encoding="utf-8")


def main(argv: Optional[list[str]] = None) -> int:
    p = argparse.ArgumentParser(description="Repeat autorun map harness (converted from shell) ")
    p.add_argument("map", help="Map name (without extension)")
    p.add_argument("repeats", nargs="?", type=int, default=3, help="Number of repeats (max 3)")
    p.add_argument("--exe", default=str(DEFAULT_EXE), help="Path to fallout1-rebirth executable")
    p.add_argument(
        "--data-root",
        default="",
        help="Directory containing master.dat/critter.dat/data (defaults to GAME_DATA or app Resources)",
    )
    p.add_argument("--out-dir", default=str(DEFAULT_OUT), help="Output directory for artifacts")
    p.add_argument("--timeout", type=int, default=int(os.environ.get("TIMEOUT", "5")), help="Per-run timeout (seconds)")
    args = p.parse_args(argv)

    # Normalize map argument: accept both `CARAVAN` and `CARAVAN.MAP`.
    map_input = args.map
    # canonical base (no extension, uppercase) used for artifact filenames
    map_base = map_input.upper()
    if map_base.endswith(".MAP"):
        map_base = map_base[:-4]
    # engine-facing map name (with extension)
    env_map = f"{map_base}.MAP"

    map_name = map_base
    repeats = max(1, args.repeats)
    if repeats > 3:
        print(f"[WARN] requested repeats={repeats}; capping to 3")
        repeats = 3
    exe = Path(args.exe).resolve()

    out_dir = Path(args.out_dir).resolve()
    patchlog_dir = out_dir / "patchlogs"
    screen_dir = out_dir / "screenshots-individual"
    present_dir = out_dir / "present-anomalies"
    patchlog_dir.mkdir(parents=True, exist_ok=True)
    screen_dir.mkdir(parents=True, exist_ok=True)
    present_dir.mkdir(parents=True, exist_ok=True)

    timeout = max(1, args.timeout)

    # Resolve resources dir
    resources_dir = find_resources_dir_from_exe(exe)
    if resources_dir is None or not resources_dir.exists():
        print(f"[ERROR] Resources dir not found for exe: {exe}", file=sys.stderr)
        return 2

    env_root = os.environ.get("FALLOUT_GAMEFILES_ROOT") or os.environ.get("GAMEFILES_ROOT")
    env_data = os.environ.get("GAME_DATA")
    if args.data_root:
        working_data_root = Path(args.data_root).resolve()
    elif env_data:
        working_data_root = Path(env_data).resolve()
    elif env_root:
        working_data_root = (Path(env_root) / "patchedfiles").resolve()
    else:
        working_data_root = resources_dir

    # Ensure app resources are populated from the requested patched source when provided.
    ensure_script = ROOT / "scripts" / "test" / "test-rme-ensure-patched-data.sh"
    if not ensure_script.exists():
        print(f"[ERROR] Missing preflight helper: {ensure_script}", file=sys.stderr)
        return 2
    try:
        ensure_cmd = [str(ensure_script), "--target-resources", str(resources_dir), "--quiet"]
        if working_data_root != resources_dir:
            ensure_cmd.extend(["--patched-dir", str(working_data_root)])
        subprocess.run(ensure_cmd, check=True)
    except Exception as e:
        print(f"[ERROR] Failed to verify patched data in app resources: {e}", file=sys.stderr)
        return 2

    if not (working_data_root / "master.dat").is_file() or not (working_data_root / "critter.dat").is_file() or not (working_data_root / "data").is_dir():
        print(f"[ERROR] Game-data source is incomplete: {working_data_root}", file=sys.stderr)
        return 2

    # Ensure required game data present (master.dat / critter.dat)
    master = resources_dir / "master.dat"
    critter = resources_dir / "critter.dat"
    if not master.is_file() or not critter.is_file():
        print("[ERROR] Required game data missing in app bundle Resources: master.dat and/or critter.dat", file=sys.stderr)
        print(f"Expected source: {working_data_root}", file=sys.stderr)
        return 2

    # Do not require a loose `data/maps/*.MAP` file; many targets are DAT-backed.
    map_file = resources_dir / "data" / "maps" / f"{map_name}.MAP"
    if not map_file.exists():
        print(f"[INFO] {map_name}.MAP not found as loose file; proceeding with DAT-backed load if available")

    # Per-run loop
    analyzer = ROOT / "scripts" / "test" / "test-rme-patchlog-analyze.py"
    for i in range(1, repeats + 1):
        print(f"Run {i}/{repeats} for {map_name}")

        # Remove stale screenshots in the out dir (matches runtime sweep cwd behavior)
        for p in out_dir.glob("scr*.bmp"):
            try:
                p.unlink()
            except Exception:
                pass

        pl_path = patchlog_dir / f"{map_name}.iter{ i:02}.patchlog.txt"
        run_log = patchlog_dir / f"{map_name}.iter{ i:02}.run.log"

        # Placeholder behaviour (same as shell script)
        create_placeholder_if_requested(pl_path)

        # Match runtime-sweep behavior: inherit ambient environment and override harness vars.
        env = os.environ.copy()
        env.update({
            "F1R_AUTORUN_MAP": env_map,
            "F1R_AUTORUN_CLICK": os.environ.get("F1R_AUTORUN_CLICK", "1"),
            "F1R_AUTORUN_CLICK_DELAY": os.environ.get("F1R_AUTORUN_CLICK_DELAY", "1"),
            "F1R_AUTORUN_HOLD_SECS": os.environ.get("F1R_AUTORUN_HOLD_SECS", "2"),
            "F1R_AUTOSCREENSHOT": "1",
            "F1R_AUTOSCREENSHOT_POST": "1",
            "F1R_PATCHLOG": "1",
            "F1R_PATCHLOG_PATH": str(pl_path),
            "F1R_PRESENT_ANOM_DIR": str(present_dir),
            # Keep runtime data resolution pinned to the selected data source.
            "RME_WORKING_DIR": f"{working_data_root}{os.sep}",
        })
        if os.environ.get("F1R_PATCHLOG_VERBOSE") and os.environ.get("F1R_PATCHLOG_VERBOSE") != "0":
            env["F1R_PATCHLOG_VERBOSE"] = os.environ.get("F1R_PATCHLOG_VERBOSE")

        # Avoid stale previous-run lines when reusing iterXX filenames.
        try:
            pl_path.unlink()
        except FileNotFoundError:
            pass

        # Diagnostics + run the executable
        with run_log.open("w", encoding="utf-8") as fh:
            fh.write(f"[INFO] PWD={os.getcwd()}\n")
            fh.write(f"[INFO] APP={exe.parents[1].resolve()}\n")
            fh.write(f"[INFO] EXE={exe}\n")
            fh.write(f"[INFO] RESOURCES_DIR={resources_dir}\n")
            fh.write(f"[INFO] PATCHLOG={pl_path}\n")
            fh.flush()

            if not exe.is_file() or not os.access(str(exe), os.X_OK):
                fh.write(f"[ERROR] executable not found or not executable: {exe}\n")
                print(f"[ERROR] executable not found or not executable: {exe}", file=sys.stderr)
                return 2

            try:
                proc = subprocess.run([str(exe)], cwd=str(out_dir), env=env, stdout=fh, stderr=subprocess.STDOUT, timeout=timeout, check=False)
                exit_code = proc.returncode
            except subprocess.TimeoutExpired as e:
                fh.write("[TIMEOUT]\n")
                fh.flush()
                exit_code = 124

        # Move produced screenshot (if any)
        shot = pick_single_screenshot(out_dir)
        if shot is not None:
            dst = screen_dir / f"{map_name}.iter{ i:02}.bmp"
            try:
                shutil.copyfile(shot, dst)
            except Exception:
                try:
                    dst.write_bytes(shot.read_bytes())
                except Exception:
                    pass

        # Fail early if no real patchlog was produced (placeholder still present or missing)
        if not pl_path.is_file() or pl_path.stat().st_size == 0 or pl_path.read_text(encoding="utf-8", errors="ignore").startswith("[PLACEHOLDER PATCHLOG"):
            print(f"[ERROR] patchlog missing or placeholder for {map_name} run {i}; see run log: {run_log}", file=sys.stderr)
            print("-- run log (head 200 lines) --", file=sys.stderr)
            try:
                with run_log.open("r", encoding="utf-8", errors="ignore") as fh:
                    for _ in range(200):
                        line = fh.readline()
                        if not line:
                            break
                        sys.stderr.write(line)
            except Exception:
                pass
            return 4

        # If the process timed out before autorun map markers appear, report that clearly.
        pl_text = pl_path.read_text(encoding="utf-8", errors="ignore")
        if exit_code == 124:
            if "AUTORUN_MAP" not in pl_text:
                print(f"[TIMEOUT_BEFORE_AUTORUN] {map_name}: process timed out before map autorun started; see {run_log}")
            else:
                print(f"[TIMEOUT_DURING_AUTORUN] {map_name}: process timed out after autorun started; see {run_log}")
            return 124

        # Run analyzer and check for suspicious GNW_SHOW_RECT events
        analyzer_out = ""
        if analyzer.exists():
            analyzer_out = run_analyzer(analyzer, pl_path)
            out_file = pl_path.with_name(f"{pl_path.stem}_analyze.txt")
            try:
                out_file.write_text(analyzer_out, encoding="utf-8")
            except Exception:
                pass

            if "No suspicious GNW_SHOW_RECT surf_pre>0 && surf_post==0 found" not in analyzer_out:
                print(f"SUSPICIOUS event found in {map_name} run {i}; analyze output: {out_file}")
                print("Artifacts are available in:")
                print(f"  patchlog: {pl_path}")
                print(f"  run log: {run_log}")
                print(f"  screenshot (if any): {screen_dir / f'{map_name}.iter{ i:02}.bmp'}")
                return 3

        # Additional strict full-load verification (same checks as runtime sweep)
        load_ok = True
        reasons = []
        # Use the *last* occurrence in the patchlog so transient/earlier entries do not mask final state.
        import re
        load_matches = re.findall(r'AUTORUN_MAP.*load_end.*rc=(-?\d+)', pl_text)
        if not load_matches or int(load_matches[-1]) != 0:
            load_ok = False
            reasons.append("map_load rc!=0 or missing")
        disp_matches = re.findall(r'DISPLAY_TOP_PIXELS.*non_zero_pct=(\d+)', pl_text)
        if not disp_matches or int(disp_matches[-1]) == 0:
            load_ok = False
            reasons.append("display all black")
        dude_matches = re.findall(r'AUTORUN_MAP.*dude_tile=(-?\d+)', pl_text)
        if not dude_matches or int(dude_matches[-1]) < 0:
            load_ok = False
            reasons.append("dude not placed")
        post_matches = re.findall(r'AUTORUN_MAP.*post_click_dude_tile=(-?\d+)', pl_text)
        if not post_matches or int(post_matches[-1]) < 0:
            load_ok = False
            reasons.append("post_click missing")

        if not load_ok:
            print(f"[FULL_LOAD_FAIL] {map_name}: {'; '.join(reasons)}")
            return 3

        # If process exit code non-zero, mark as failure unless this is the
        # known non-blocking exit-2 path after successful full-load checks.
        if exit_code != 0:
            if exit_code == 2:
                print(f"[WARN] run returned exit code 2 after successful full-load checks; treating as pass ({run_log})")
                continue
            print(f"[ERROR] run returned exit code {exit_code}; see run log: {run_log}")
            return exit_code if exit_code != 0 else 3

    print(f"All {repeats} runs for {map_name} OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

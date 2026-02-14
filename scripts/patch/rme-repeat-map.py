#!/usr/bin/env python3
"""
rme-repeat-map.py — Python replacement for `rme-repeat-map.sh`.

Behavior matches the original shell script but mirrors `rme-runtime-sweep.py`'s
harness expectations (F1R_AUTORUN_CLICK_DELAY, F1R_AUTORUN_HOLD_SECS,
10s minimum per-test, patchlog verification + analyzer).

Usage: ./scripts/patch/rme-repeat-map.py MAP [REPEATS]

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

ROOT = Path(__file__).resolve().parents[1]

DEFAULT_EXE = Path("build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth")
DEFAULT_OUT = Path("development/RME/validation/runtime")

PLACEHOLDER_TEXT = "[PLACEHOLDER PATCHLOG] created by rme-repeat-map.py - engine may crash before producing a real patchlog\n"


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


def create_placeholder_if_requested(pl_path: Path, out_dir: Path) -> None:
    if str(out_dir).find("/development/RME/ARTIFACTS/evidence") != -1 or os.environ.get("RME_PLACEHOLDER_PATCHLOG") == "1":
        pl_path.parent.mkdir(parents=True, exist_ok=True)
        pl_path.write_text(PLACEHOLDER_TEXT, encoding="utf-8")


def main(argv: Optional[list[str]] = None) -> int:
    p = argparse.ArgumentParser(description="Repeat autorun map harness (converted from shell) ")
    p.add_argument("map", help="Map name (without extension)")
    p.add_argument("repeats", nargs="?", type=int, default=5, help="Number of repeats")
    p.add_argument("--exe", default=str(DEFAULT_EXE), help="Path to fallout1-rebirth executable")
    p.add_argument("--out-dir", default=str(DEFAULT_OUT), help="Output directory for artifacts")
    p.add_argument("--timeout", type=int, default=int(os.environ.get("TIMEOUT", "60")), help="Per-run timeout (seconds)")
    args = p.parse_args(argv)

    map_name = args.map
    repeats = max(1, args.repeats)
    exe = Path(args.exe).resolve()

    out_dir = Path(args.out_dir).resolve()
    patchlog_dir = out_dir / "patchlogs"
    screen_dir = out_dir / "screenshots-individual"
    present_dir = out_dir / "present-anomalies"
    patchlog_dir.mkdir(parents=True, exist_ok=True)
    screen_dir.mkdir(parents=True, exist_ok=True)
    present_dir.mkdir(parents=True, exist_ok=True)

    # Enforce minimum per-test duration
    timeout = max(10, args.timeout)

    # Resolve resources dir
    resources_dir = find_resources_dir_from_exe(exe)
    if resources_dir is None or not resources_dir.exists():
        print(f"[ERROR] Resources dir not found for exe: {exe}", file=sys.stderr)
        return 2

    # Ensure required game data present (master.dat / critter.dat)
    master = resources_dir / "master.dat"
    critter = resources_dir / "critter.dat"
    if not master.is_file() or not critter.is_file():
        patched_dir = ROOT / "GOG" / "patchedfiles"
        installer = ROOT / "scripts" / "test" / "test-install-game-data.sh"
        if patched_dir.exists() and (patched_dir / "master.dat").exists() and installer.exists():
            print(f"[INFO] master.dat/critter.dat missing under {resources_dir}; attempting auto-install from {patched_dir}")
            try:
                subprocess.run([str(installer), "--source", str(patched_dir), "--target", str(resources_dir.parent.parent)], check=True)
            except Exception as e:
                print(f"[WARN] auto-install attempt failed: {e}")

    if not master.is_file() or not critter.is_file():
        print("[ERROR] Required game data missing in app bundle Resources: master.dat and/or critter.dat", file=sys.stderr)
        print(f"Install game data and retry, e.g. ./scripts/test/test-install-game-data.sh --source GOG/patchedfiles --target \"{resources_dir.parent}\"")
        return 2

    # Ensure the requested map file exists (try auto-install from GOG/patchedfiles if missing)
    map_file = resources_dir / "data" / "maps" / f"{map_name}.MAP"
    if not map_file.exists():
        patched_dir = ROOT / "GOG" / "patchedfiles"
        if patched_dir.exists() and (patched_dir / "data" / "maps" / f"{map_name}.MAP").exists():
            installer = ROOT / "scripts" / "test" / "test-install-game-data.sh"
            if installer.exists():
                print(f"[INFO] Map file {map_name} missing — auto-installing patched data from {patched_dir}")
                try:
                    subprocess.run([str(installer), "--source", str(patched_dir), "--target", str(resources_dir.parent.parent)], check=True)
                except Exception as e:
                    print(f"[WARN] auto-install attempt failed: {e}")

    if not map_file.exists():
        print(f"[ERROR] Map file not found for {map_name}: {map_file}", file=sys.stderr)
        print("Install the patched data (GOG/patchedfiles) into the app bundle and retry.")
        return 2

    # Per-run loop
    analyzer = ROOT / "scripts" / "dev" / "patchlog_analyze.py"
    for i in range(1, repeats + 1):
        print(f"Run {i}/{repeats} for {map_name}")

        # Remove stale screenshots in Resources
        for p in resources_dir.glob("scr*.bmp"):
            try:
                p.unlink()
            except Exception:
                pass

        pl_path = patchlog_dir / f"{map_name}.iter{ i:02}.patchlog.txt"
        run_log = patchlog_dir / f"{map_name}.iter{ i:02}.run.log"

        # Placeholder behaviour (same as shell script)
        create_placeholder_if_requested(pl_path, out_dir)

        # Prepare environment (sanitized)
        env = {"PATH": os.environ.get("PATH", "")}
        env.update({
            "F1R_AUTORUN_MAP": map_name,
            "F1R_AUTORUN_CLICK": os.environ.get("F1R_AUTORUN_CLICK", "0"),
            "F1R_AUTORUN_CLICK_DELAY": os.environ.get("F1R_AUTORUN_CLICK_DELAY", "7"),
            "F1R_AUTORUN_HOLD_SECS": os.environ.get("F1R_AUTORUN_HOLD_SECS", "10"),
            "F1R_AUTOSCREENSHOT": "1",
            "F1R_PATCHLOG": "1",
            "F1R_PATCHLOG_PATH": str(pl_path),
            "F1R_PATCHLOG_VERBOSE": os.environ.get("F1R_PATCHLOG_VERBOSE", "1"),
            "F1R_PRESENT_ANOM_DIR": str(present_dir),
        })

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

            # Adjust timeout to accommodate hold window
            try:
                hold_secs = int(env.get("F1R_AUTORUN_HOLD_SECS", "10"))
            except Exception:
                hold_secs = 10
            if timeout < hold_secs + 2:
                old_to = timeout
                timeout = hold_secs + 2
                fh.write(f"[WARN] increasing per-run timeout from {old_to}s to {timeout}s to accommodate F1R_AUTORUN_HOLD_SECS={hold_secs}\n")
                fh.flush()

            try:
                proc = subprocess.run([str(exe)], cwd=str(resources_dir), env=env, stdout=fh, stderr=subprocess.STDOUT, timeout=timeout, check=False)
                exit_code = proc.returncode
            except subprocess.TimeoutExpired as e:
                fh.write("[TIMEOUT]\n")
                fh.flush()
                exit_code = 124

        # Move produced screenshot (if any)
        shot = pick_single_screenshot(resources_dir)
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

        # Run analyzer and check for suspicious GNW_SHOW_RECT events
        analyzer_out = ""
        if analyzer.exists():
            analyzer_out = run_analyzer(analyzer, pl_path)
            (pl_path.with_suffix("")).with_suffix("_analyze.txt");
            try:
                out_file = pl_path.with_suffix("").with_suffix("_analyze.txt")
                out_file.write_text(analyzer_out, encoding="utf-8")
            except Exception:
                pass

            if "No suspicious GNW_SHOW_RECT surf_pre>0 && surf_post==0 found" not in analyzer_out:
                print(f"SUSPICIOUS event found in {map_name} run {i}; analyze output: {pl_path.with_suffix("").with_suffix("_analyze.txt")}")
                print("Artifacts are available in:")
                print(f"  patchlog: {pl_path}")
                print(f"  run log: {run_log}")
                print(f"  screenshot (if any): {screen_dir / f'{map_name}.iter{ i:02}.bmp'}")
                return 3

        # Additional strict full-load verification (same checks as runtime sweep)
        pl_text = pl_path.read_text(encoding="utf-8", errors="ignore")
        load_ok = True
        reasons = []
        m = re.search(r'AUTORUN_MAP.*load_end.*rc=(\-?\d+)', pl_text)
        if not m or int(m.group(1)) != 0:
            load_ok = False
            reasons.append("map_load rc!=0 or missing")
        m2 = re.search(r'DISPLAY_TOP_PIXELS.*non_zero_pct=(\d+)', pl_text)
        if not m2 or int(m2.group(1)) == 0:
            load_ok = False
            reasons.append("display all black")
        m3 = re.search(r'AUTORUN_MAP.*dude_tile=(-?\d+)', pl_text)
        if not m3 or int(m3.group(1)) < 0:
            load_ok = False
            reasons.append("dude not placed")
        m4 = re.search(r'AUTORUN_MAP.*post_click_dude_tile=(-?\d+)', pl_text)
        if not m4 or int(m4.group(1)) < 0:
            load_ok = False
            reasons.append("post_click missing")

        if not load_ok:
            print(f"[FULL_LOAD_FAIL] {map_name}: {'; '.join(reasons)}")
            return 3

        # If process exit code non-zero, mark as failure
        if exit_code != 0:
            print(f"[ERROR] run returned exit code {exit_code}; see run log: {run_log}")
            return exit_code if exit_code != 0 else 3

    print(f"All {repeats} runs for {map_name} OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

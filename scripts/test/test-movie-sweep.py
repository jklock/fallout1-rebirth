#!/usr/bin/env python3
"""Run all Fallout movies in autorun mode and capture one screenshot per movie."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
from typing import List, Optional


MOVIES = [
    "iplogo",
    "mplogo",
    "intro",
    "vexpld",
    "cathexp",
    "ovrintro",
    "boil3",
    "ovrrun",
    "walkm",
    "walkw",
    "dipedv",
    "boil1",
    "boil2",
    "raekills",
]


def repo_root() -> Path:
    return Path(__file__).resolve().parents[2]


def infer_default_exe(root: Path) -> Path:
    return root / "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth"


def infer_data_root(exe: Path, explicit: Optional[str]) -> Optional[Path]:
    if explicit:
        return Path(explicit).expanduser().resolve()

    game_data = os.environ.get("GAME_DATA")
    if game_data:
        return Path(game_data).expanduser().resolve()

    gamefiles_root = os.environ.get("FALLOUT_GAMEFILES_ROOT") or os.environ.get("GAMEFILES_ROOT")
    if gamefiles_root:
        return (Path(gamefiles_root).expanduser().resolve() / "patchedfiles")

    parts = exe.resolve().parts
    if ".app" in exe.as_posix():
        # .../<Name>.app/Contents/MacOS/fallout1-rebirth -> .../<Name>.app/Contents/Resources
        s = exe.as_posix()
        marker = ".app/Contents/MacOS/"
        idx = s.find(marker)
        if idx != -1:
            app_root = Path(s[: idx + 4])
            return app_root / "Contents/Resources"

    return None


def validate_data_root(path: Path) -> None:
    missing = []
    if not (path / "master.dat").is_file():
        missing.append("master.dat")
    if not (path / "critter.dat").is_file():
        missing.append("critter.dat")
    if not (path / "data").is_dir():
        missing.append("data/")
    if missing:
        raise SystemExit(f"[ERROR] Data root missing required files: {', '.join(missing)} at {path}")


def parse_args() -> argparse.Namespace:
    root = repo_root()
    ts = dt.datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")
    parser = argparse.ArgumentParser(description="Autorun all movies and capture screenshots.")
    parser.add_argument(
        "--exe",
        default=str(infer_default_exe(root)),
        help="Path to fallout1-rebirth executable inside .app",
    )
    parser.add_argument(
        "--data-root",
        default=None,
        help="Directory containing master.dat, critter.dat, and data/ "
        "(defaults to GAME_DATA, FALLOUT_GAMEFILES_ROOT/patchedfiles, or app Resources)",
    )
    parser.add_argument(
        "--out-dir",
        default=str(root / f"tmp/movie-sweep-{ts}"),
        help="Directory for screenshots and per-run logs",
    )
    parser.add_argument(
        "--timeout",
        type=int,
        default=45,
        help="Per-movie process timeout in seconds",
    )
    parser.add_argument(
        "--delay-ms",
        type=int,
        default=750,
        help="Delay before autoscreenshot while movie is playing",
    )
    return parser.parse_args()


def run_movie(exe: Path, data_root: Path, out_dir: Path, movie_index: int, timeout_s: int, delay_ms: int) -> dict:
    movie_name = MOVIES[movie_index]
    run_dir = out_dir / f"{movie_index:02d}_{movie_name}"
    run_dir.mkdir(parents=True, exist_ok=True)

    env = os.environ.copy()
    env["RME_WORKING_DIR"] = str(data_root)
    env["F1R_AUTORUN_MOVIE"] = str(movie_index)
    env["F1R_AUTOSCREENSHOT"] = "1"
    env["F1R_AUTOSCREENSHOT_DELAY_MS"] = str(delay_ms)
    env["F1R_AUTOSTOP_AFTER_SHOT"] = "1"

    proc = subprocess.run(
        [str(exe)],
        cwd=run_dir,
        env=env,
        capture_output=True,
        text=True,
        timeout=timeout_s,
        check=False,
    )

    (run_dir / "stdout.log").write_text(proc.stdout, encoding="utf-8")
    (run_dir / "stderr.log").write_text(proc.stderr, encoding="utf-8")

    screenshots = sorted(run_dir.glob("scr*.bmp"))
    screenshot_path = None
    if screenshots:
        screenshot_path = run_dir / f"{movie_index:02d}_{movie_name}.bmp"
        shutil.move(str(screenshots[0]), str(screenshot_path))

    ok = proc.returncode == 0 and screenshot_path is not None
    return {
        "movie_index": movie_index,
        "movie_name": movie_name,
        "return_code": proc.returncode,
        "screenshot": str(screenshot_path) if screenshot_path else None,
        "ok": ok,
    }


def main() -> int:
    args = parse_args()

    exe = Path(args.exe).expanduser().resolve()
    if not exe.is_file():
        print(f"[ERROR] Executable not found: {exe}", file=sys.stderr)
        return 2

    data_root = infer_data_root(exe, args.data_root)
    if data_root is None:
        print(
            "[ERROR] Could not infer data root. Pass --data-root or set GAME_DATA/FALLOUT_GAMEFILES_ROOT.",
            file=sys.stderr,
        )
        return 2
    validate_data_root(data_root)

    out_dir = Path(args.out_dir).expanduser().resolve()
    out_dir.mkdir(parents=True, exist_ok=True)

    results: List[dict] = []
    for idx, name in enumerate(MOVIES):
        print(f">>> [{idx:02d}] {name}")
        try:
            result = run_movie(exe, data_root, out_dir, idx, args.timeout, args.delay_ms)
        except subprocess.TimeoutExpired:
            result = {
                "movie_index": idx,
                "movie_name": name,
                "return_code": None,
                "screenshot": None,
                "ok": False,
                "error": f"timeout after {args.timeout}s",
            }

        results.append(result)
        status = "PASS" if result["ok"] else "FAIL"
        print(f"{status}: {name} rc={result.get('return_code')} shot={result.get('screenshot')}")

    summary = {
        "exe": str(exe),
        "data_root": str(data_root),
        "out_dir": str(out_dir),
        "results": results,
    }
    (out_dir / "summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")

    failures = [r for r in results if not r["ok"]]
    print(f"\nCompleted: {len(results) - len(failures)}/{len(results)} movies captured")
    print(f"Summary: {out_dir / 'summary.json'}")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())


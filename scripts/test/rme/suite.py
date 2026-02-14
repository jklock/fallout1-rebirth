#!/usr/bin/env python3
"""RME validation suite entrypoint.

Provides a single Python command for common RME validation workflows.
"""

from __future__ import annotations

import argparse
import os
import subprocess
import sys
from pathlib import Path
from typing import List


ROOT = Path(__file__).resolve().parents[3]
TEST_DIR = ROOT / "scripts" / "test"


def run_cmd(cmd: List[str], env: dict[str, str] | None = None) -> int:
    printable = " ".join(cmd)
    print(f">>> {printable}")
    proc = subprocess.run(cmd, cwd=str(ROOT), env=env, check=False)
    return proc.returncode


def with_common_env(args: argparse.Namespace) -> dict[str, str]:
    env = os.environ.copy()
    if args.base:
        env["BASE_DIR"] = str(Path(args.base).expanduser())
        env["UNPATCHED_DIR"] = env["BASE_DIR"]
    if args.patched:
        env["PATCHED_DIR"] = str(Path(args.patched).expanduser())
        env["GAME_DATA"] = env["PATCHED_DIR"]
    if args.out:
        env["OUT_DIR"] = str(Path(args.out).expanduser())
    if args.app:
        env["APP"] = str(Path(args.app).expanduser())
    if args.exe:
        env["EXE"] = str(Path(args.exe).expanduser())
    if args.timeout is not None:
        env["TIMEOUT"] = str(args.timeout)
    if args.run_ios:
        env["RUN_IOS"] = "1"
    return env


def mode_quick(args: argparse.Namespace) -> int:
    env = with_common_env(args)
    return run_cmd([str(TEST_DIR / "test-rme-validate-ci.sh")], env=env)


def mode_patchflow(args: argparse.Namespace) -> int:
    env = with_common_env(args)
    cmd = [str(TEST_DIR / "test-rme-patchflow.sh")]
    if args.patched:
        cmd.append(str(Path(args.patched).expanduser()))
    return run_cmd(cmd, env=env)


def mode_autofix(args: argparse.Namespace) -> int:
    env = with_common_env(args)
    cmd = [str(TEST_DIR / "test-rme-patchflow-autofix.sh")]
    if args.patched:
        cmd.append(str(Path(args.patched).expanduser()))
    return run_cmd(cmd, env=env)


def mode_full(args: argparse.Namespace) -> int:
    env = with_common_env(args)
    cmd = [str(TEST_DIR / "test-rme-end-to-end.sh")]
    if args.base:
        cmd.extend(["--base", str(Path(args.base).expanduser())])
    if args.patched:
        cmd.extend(["--patched", str(Path(args.patched).expanduser())])
    if args.timeout is not None:
        cmd.extend(["--timeout", str(args.timeout)])
    if args.run_ios:
        cmd.append("--run-ios")
    return run_cmd(cmd, env=env)


def mode_all(args: argparse.Namespace) -> int:
    rc = mode_quick(args)
    if rc != 0:
        return rc
    return mode_full(args)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Fallout 1 Rebirth RME suite (single Python entrypoint).",
    )
    parser.add_argument(
        "mode",
        choices=["quick", "patchflow", "autofix", "full", "all"],
        help="Suite mode to run",
    )
    parser.add_argument("--base", help="Unpatched base data directory")
    parser.add_argument("--patched", help="Patched data directory")
    parser.add_argument("--out", help="Output directory override")
    parser.add_argument("--app", help="App bundle path override")
    parser.add_argument("--exe", help="Executable path override")
    parser.add_argument("--timeout", type=int, help="Per-map timeout (seconds)")
    parser.add_argument("--run-ios", action="store_true", help="Run iOS validation in full mode")
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    handlers = {
        "quick": mode_quick,
        "patchflow": mode_patchflow,
        "autofix": mode_autofix,
        "full": mode_full,
        "all": mode_all,
    }
    return handlers[args.mode](args)


if __name__ == "__main__":
    raise SystemExit(main())

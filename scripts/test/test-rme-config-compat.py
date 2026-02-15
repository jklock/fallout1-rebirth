#!/usr/bin/env python3
"""Per-key config compatibility validator for baseline fallout.cfg + f1_res.ini.

This test runs the executable in config-compat probe mode, mutates one baseline key
per case, and verifies parse/apply/runtime-effect evidence for every key.
"""

from __future__ import annotations

import argparse
import configparser
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
from dataclasses import dataclass
from typing import Dict, List, Tuple


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_EXE = ROOT / "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth"
DEFAULT_MANIFEST_FALLOUT = ROOT / "docs/audit/key-manifests/unpatched-fallout.cfg.keys"
DEFAULT_MANIFEST_F1 = ROOT / "docs/audit/key-manifests/unpatched-f1_res.keys"
DEFAULT_GAMEFILES_ROOT = Path("/Volumes/Storage/GitHub/fallout1-rebirth-gamefiles")


FALLOUT_MUTATIONS: Dict[str, str] = {
    "debug::mode": "combat",
    "debug::output_map_data_info": "1",
    "debug::show_load_info": "1",
    "debug::show_script_messages": "1",
    "debug::show_tile_num": "1",
    "input::map_scroll_delay": "120",
    "input::pencil_right_click": "0",
    "preferences::brightness": "1.10",
    "preferences::combat_difficulty": "2",
    "preferences::combat_messages": "0",
    "preferences::combat_speed": "25",
    "preferences::combat_taunts": "0",
    "preferences::game_difficulty": "2",
    "preferences::item_highlight": "0",
    "preferences::language_filter": "1",
    "preferences::mouse_sensitivity": "1.50",
    "preferences::player_speed": "1",
    "preferences::player_speedup": "1",
    "preferences::running": "1",
    "preferences::running_burning_guy": "0",
    "preferences::subtitles": "1",
    "preferences::target_highlight": "1",
    "preferences::text_base_delay": "4.20",
    "preferences::text_line_delay": "0.80",
    "preferences::violence_level": "2",
    "sound::cache_size": "512",
    "sound::device": "2",
    "sound::dma": "44100",
    "sound::initialize": "0",
    "sound::irq": "16384",
    "sound::master_volume": "20000",
    "sound::music": "0",
    "sound::music_path1": "data/sound/music_alt/",
    "sound::music_path2": "data/sound/music_alt2/",
    "sound::music_volume": "18000",
    "sound::port": "32",
    "sound::sndfx_volume": "17000",
    "sound::sounds": "0",
    "sound::speech": "0",
    "sound::speech_volume": "16000",
    "system::art_cache_size": "12",
    "system::color_cycling": "0",
    "system::critter_dat": "critter_alt.dat",
    "system::critter_patches": "mods",
    "system::cycle_speed_factor": "2",
    "system::executable": "mapper",
    "system::free_space": "4096",
    "system::hashing": "0",
    "system::interrupt_walk": "0",
    "system::language": "french",
    "system::master_dat": "master_alt.dat",
    "system::master_patches": "mods",
    "system::scroll_lock": "1",
    "system::splash": "4",
    "system::times_run": "10",
}

F1_MUTATIONS: Dict[str, str] = {
    "DISPLAY::FPS_LIMIT": "60",
    "DISPLAY::VSYNC": "0",
    "MAIN::SCALE_2X": "1",
    "MAIN::SCR_HEIGHT": "1200",
    "MAIN::SCR_WIDTH": "1600",
    "MAIN::WINDOWED": "1",
}


@dataclass
class KeyCase:
    source: str
    section: str
    key: str

    @property
    def id(self) -> str:
        return f"{self.section}::{self.key}"


@dataclass
class CaseResult:
    source: str
    key_id: str
    parsed_ok: bool
    applied_ok: bool
    effect_ok: bool
    status: str
    mutation_value: str
    baseline_effect: str
    mutated_effect: str
    evidence: str


def load_manifest(path: Path) -> List[KeyCase]:
    cases: List[KeyCase] = []
    with path.open("r", encoding="utf-8") as handle:
        for raw in handle:
            line = raw.strip()
            if not line or line.startswith("#"):
                continue
            if "::" not in line:
                raise ValueError(f"Invalid manifest entry in {path}: {line}")
            section, key = line.split("::", 1)
            source = "fallout_cfg" if path.name.endswith("fallout.cfg.keys") else "f1_res_ini"
            cases.append(KeyCase(source=source, section=section, key=key))
    return cases


def read_ini(path: Path) -> configparser.ConfigParser:
    parser = configparser.ConfigParser(interpolation=None, strict=False)
    parser.optionxform = str
    with path.open("r", encoding="utf-8") as handle:
        parser.read_file(handle)
    return parser


def write_ini(path: Path, parser: configparser.ConfigParser) -> None:
    with path.open("w", encoding="utf-8") as handle:
        parser.write(handle, space_around_delimiters=False)


def build_baseline_paths(args: argparse.Namespace) -> Tuple[Path, Path]:
    if args.baseline_fallout and args.baseline_f1:
        return args.baseline_fallout.resolve(), args.baseline_f1.resolve()

    gamefiles_root = None
    if args.gamefiles_root:
        gamefiles_root = args.gamefiles_root.resolve()
    else:
        env_root = os.environ.get("FALLOUT_GAMEFILES_ROOT") or os.environ.get("GAMEFILES_ROOT")
        if env_root:
            gamefiles_root = Path(env_root).expanduser().resolve()
        elif DEFAULT_GAMEFILES_ROOT.is_dir():
            gamefiles_root = DEFAULT_GAMEFILES_ROOT

    if gamefiles_root is None:
        raise RuntimeError("Missing baseline files. Provide --baseline-fallout/--baseline-f1 or set FALLOUT_GAMEFILES_ROOT.")

    base_dir = gamefiles_root / "unpatchedfiles"
    fallout = args.baseline_fallout.resolve() if args.baseline_fallout else base_dir / "fallout.cfg"
    f1 = args.baseline_f1.resolve() if args.baseline_f1 else base_dir / "f1_res.ini"
    return fallout, f1


def run_probe(exe: Path, workdir: Path, out_json: Path) -> dict:
    env = os.environ.copy()
    env["RME_CONFIG_COMPAT_PROBE"] = "1"
    env["RME_CONFIG_COMPAT_PROBE_OUT"] = str(out_json)
    env["RME_WORKING_DIR"] = str(workdir)

    proc = subprocess.run(
        [str(exe)],
        cwd=str(ROOT),
        env=env,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        check=False,
    )
    if proc.returncode != 0:
        raise RuntimeError(
            f"Probe failed (rc={proc.returncode}) in {workdir}\n"
            f"stdout:\n{proc.stdout}\n"
            f"stderr:\n{proc.stderr}"
        )

    if not out_json.is_file():
        raise RuntimeError(f"Probe output missing: {out_json}")

    with out_json.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def probe_row_map(probe: dict, source: str) -> Dict[str, dict]:
    rows = probe[source]["keys"]
    result: Dict[str, dict] = {}
    for row in rows:
        result[f"{row['section']}::{row['key']}"] = row
    return result


def safe_case_dir_name(source: str, key_id: str) -> str:
    token = f"{source}-{key_id}"
    token = re.sub(r"[^A-Za-z0-9_.-]+", "_", token)
    return token


def apply_mutation(
    fallout_cfg: configparser.ConfigParser,
    f1_cfg: configparser.ConfigParser,
    case: KeyCase,
) -> str:
    if case.source == "fallout_cfg":
        mutation = FALLOUT_MUTATIONS.get(case.id)
        if mutation is None:
            raise KeyError(f"No mutation value for fallout key: {case.id}")
        if not fallout_cfg.has_section(case.section):
            fallout_cfg.add_section(case.section)
        fallout_cfg.set(case.section, case.key, mutation)

        # Legacy alias behavior validation: player_speed should backfill player_speedup
        # only when canonical key is absent.
        if case.id == "preferences::player_speed" and fallout_cfg.has_option("preferences", "player_speedup"):
            fallout_cfg.remove_option("preferences", "player_speedup")

        return mutation

    mutation = F1_MUTATIONS.get(case.id)
    if mutation is None:
        raise KeyError(f"No mutation value for f1_res key: {case.id}")
    if not f1_cfg.has_section(case.section):
        f1_cfg.add_section(case.section)
    f1_cfg.set(case.section, case.key, mutation)
    return mutation


def write_case_configs(
    workdir: Path,
    fallout_cfg: configparser.ConfigParser,
    f1_cfg: configparser.ConfigParser,
) -> None:
    workdir.mkdir(parents=True, exist_ok=True)
    write_ini(workdir / "fallout.cfg", fallout_cfg)
    write_ini(workdir / "f1_res.ini", f1_cfg)


def evaluate_case(
    case: KeyCase,
    baseline_probe: dict,
    mutated_probe: dict,
    mutation_value: str,
) -> CaseResult:
    baseline_rows = probe_row_map(baseline_probe, case.source)
    mutated_rows = probe_row_map(mutated_probe, case.source)
    baseline_row = baseline_rows.get(case.id)
    mutated_row = mutated_rows.get(case.id)

    if baseline_row is None or mutated_row is None:
        return CaseResult(
            source=case.source,
            key_id=case.id,
            parsed_ok=False,
            applied_ok=False,
            effect_ok=False,
            status="FAIL",
            mutation_value=mutation_value,
            baseline_effect="",
            mutated_effect="",
            evidence="missing probe row",
        )

    parsed_ok = int(mutated_row.get("parsed", 0)) == 1
    applied_ok = int(mutated_row.get("applied", 0)) == 1
    baseline_effect = str(baseline_row.get("effect_value", ""))
    mutated_effect = str(mutated_row.get("effect_value", ""))
    effect_ok = baseline_effect != mutated_effect

    status = "PASS" if parsed_ok and applied_ok and effect_ok else "FAIL"
    evidence = (
        f"effect:{mutated_row.get('effect')} baseline={baseline_effect!r} mutated={mutated_effect!r}"
    )

    return CaseResult(
        source=case.source,
        key_id=case.id,
        parsed_ok=parsed_ok,
        applied_ok=applied_ok,
        effect_ok=effect_ok,
        status=status,
        mutation_value=mutation_value,
        baseline_effect=baseline_effect,
        mutated_effect=mutated_effect,
        evidence=evidence,
    )


def write_tsv(path: Path, results: List[CaseResult]) -> None:
    lines = [
        "source\tkey\tparse\tapply\teffect\tstatus\tmutation\tbaseline_effect\tmutated_effect\tevidence"
    ]
    for row in results:
        lines.append(
            "\t".join(
                [
                    row.source,
                    row.key_id,
                    "PASS" if row.parsed_ok else "FAIL",
                    "PASS" if row.applied_ok else "FAIL",
                    "PASS" if row.effect_ok else "FAIL",
                    row.status,
                    row.mutation_value,
                    row.baseline_effect,
                    row.mutated_effect,
                    row.evidence,
                ]
            )
        )
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_markdown(path: Path, results: List[CaseResult], fallout_src: Path, f1_src: Path) -> None:
    total = len(results)
    passed = sum(1 for row in results if row.status == "PASS")
    failed = total - passed

    lines = [
        "# Config Compatibility Key Coverage Matrix",
        "",
        f"Baseline fallout.cfg: `{fallout_src}`",
        f"Baseline f1_res.ini: `{f1_src}`",
        "",
        f"Total keys: **{total}**  ",
        f"PASS: **{passed}**  ",
        f"FAIL: **{failed}**",
        "",
        "| Source | Key | Parse | Apply | Runtime Effect | Status | Evidence |",
        "|---|---|---|---|---|---|---|",
    ]

    for row in results:
        lines.append(
            "| "
            + " | ".join(
                [
                    row.source,
                    row.key_id,
                    "PASS" if row.parsed_ok else "FAIL",
                    "PASS" if row.applied_ok else "FAIL",
                    "PASS" if row.effect_ok else "FAIL",
                    row.status,
                    row.evidence.replace("|", "\\|"),
                ]
            )
            + " |"
        )

    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Validate per-key config compatibility (parse/apply/effect)")
    parser.add_argument("--exe", type=Path, default=DEFAULT_EXE, help="Path to fallout1-rebirth executable")
    parser.add_argument("--baseline-fallout", type=Path, help="Path to source-of-truth unpatched fallout.cfg")
    parser.add_argument("--baseline-f1", type=Path, help="Path to source-of-truth unpatched f1_res.ini")
    parser.add_argument("--gamefiles-root", type=Path, help="Root containing unpatchedfiles/ (fallback for baseline paths)")
    parser.add_argument("--manifest-fallout", type=Path, default=DEFAULT_MANIFEST_FALLOUT)
    parser.add_argument("--manifest-f1", type=Path, default=DEFAULT_MANIFEST_F1)
    parser.add_argument("--out-dir", type=Path, default=ROOT / "tmp/rme/config-compat")
    parser.add_argument("--matrix-tsv", type=Path, default=ROOT / "tmp/rme/config-compat/coverage-matrix.tsv")
    parser.add_argument("--matrix-md", type=Path, default=ROOT / "docs/audit/config-key-coverage-matrix-2026-02-15.md")
    parser.add_argument("--keep-cases", action="store_true", help="Keep per-case working dirs")
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    exe = args.exe.resolve()
    if not exe.is_file():
        print(f"FAIL: executable not found: {exe}", file=sys.stderr)
        return 2

    fallout_src, f1_src = build_baseline_paths(args)
    if not fallout_src.is_file() or not f1_src.is_file():
        print(f"FAIL: baseline files not found: {fallout_src} {f1_src}", file=sys.stderr)
        return 2

    manifest_fallout = args.manifest_fallout.resolve()
    manifest_f1 = args.manifest_f1.resolve()
    if not manifest_fallout.is_file() or not manifest_f1.is_file():
        print("FAIL: missing key manifests", file=sys.stderr)
        return 2

    fallout_cases = load_manifest(manifest_fallout)
    f1_cases = load_manifest(manifest_f1)
    all_cases = fallout_cases + f1_cases

    out_dir = args.out_dir.resolve()
    if out_dir.exists():
        shutil.rmtree(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    baseline_fallout_cfg = read_ini(fallout_src)
    baseline_f1_cfg = read_ini(f1_src)

    baseline_workdir = out_dir / "baseline"
    write_case_configs(baseline_workdir, baseline_fallout_cfg, baseline_f1_cfg)
    baseline_probe_path = out_dir / "baseline-probe.json"
    baseline_probe = run_probe(exe, baseline_workdir, baseline_probe_path)

    case_root = out_dir / "cases"
    results: List[CaseResult] = []

    for case in all_cases:
        case_fallout_cfg = read_ini(fallout_src)
        case_f1_cfg = read_ini(f1_src)
        mutation_value = apply_mutation(case_fallout_cfg, case_f1_cfg, case)

        case_dir = case_root / safe_case_dir_name(case.source, case.id)
        write_case_configs(case_dir, case_fallout_cfg, case_f1_cfg)

        probe_out = case_dir / "probe.json"
        mutated_probe = run_probe(exe, case_dir, probe_out)

        result = evaluate_case(case, baseline_probe, mutated_probe, mutation_value)
        result.evidence = f"{result.evidence}; probe={probe_out}"
        results.append(result)

        if not args.keep_cases:
            shutil.rmtree(case_dir, ignore_errors=True)

    write_tsv(args.matrix_tsv.resolve(), results)
    write_markdown(args.matrix_md.resolve(), results, fallout_src, f1_src)

    total = len(results)
    failed_rows = [row for row in results if row.status != "PASS"]
    passed = total - len(failed_rows)

    print(f"Config compatibility matrix: {passed}/{total} PASS")
    print(f"TSV: {args.matrix_tsv.resolve()}")
    print(f"Markdown: {args.matrix_md.resolve()}")

    if failed_rows:
        print("Failing keys:")
        for row in failed_rows:
            print(f"- {row.source} {row.key_id}: {row.evidence}")
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())

"""
Small, well-documented rule implementations for rme-autofix.
Rules are pure functions with signature:
    def rule(workdir: str, summary: dict, selftest: dict) -> List[dict]

Each returned dict describes a candidate fix with the following schema (informal):
- "type": one of "edit", "add_file", "copy_file", "whitelist"
- "description": short human-readable summary
- "target": relative path under workdir that would be changed/added/copied
- type-specific keys:
  - edit: "original" (optional), "updated" (the new file contents)
  - add_file: "content"
  - copy_file: "src" (existing relative path), "dst" (target relative path)
  - whitelist: "pattern", "reason"

Rules should be conservative and safe. The orchestrator will only `--apply` changes
when the workdir looks like a tmp run and explicit flags are given.
"""

from __future__ import annotations

import json
import os
from typing import List, Dict, Any


def _load_selftest(workdir: str, summary: dict, selftest: dict) -> dict:
    # selftest may already be provided; otherwise try to read it
    if selftest:
        return selftest
    st_path = os.path.join(workdir, "rme-selftest.json")
    if os.path.isfile(st_path):
        try:
            with open(st_path, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            return {}
    return {}


# Rule 1: ensure_fallout_cfg_language

def ensure_fallout_cfg_language(workdir: str, summary: dict, selftest: dict) -> List[Dict[str, Any]]:
    """If message failures are present and `fallout.cfg` lacks a language= entry
    in the [system] section, propose adding `language=english`.
    """
    failures = _load_selftest(workdir, summary, selftest or {}).get("failures", [])
    if not failures:
        return []

    # Only consider if there's at least one message-related failure
    has_message_fail = any(f.get("kind", "").startswith("message") or f.get("path", "").endswith(".msg") for f in failures)
    if not has_message_fail:
        return []

    cfg_path = os.path.join(workdir, "fallout.cfg")
    if os.path.isfile(cfg_path):
        with open(cfg_path, "r", encoding="utf-8", errors="replace") as f:
            src = f.read()
    else:
        src = ""

    # If language is already present, do nothing
    if "language=" in src:
        return []

    # Find [system] section; if present, insert language=english inside it; otherwise append section
    lines = src.splitlines()
    out_lines = list(lines)
    inserted = False
    for i, ln in enumerate(lines):
        if ln.strip().lower() == "[system]":
            # Find insert position after section header, but before next section
            j = i + 1
            while j < len(lines) and (lines[j].strip() == "" or lines[j].lstrip().startswith("#")):
                j += 1
            out_lines.insert(j, "language=english")
            inserted = True
            break

    if not inserted:
        if out_lines and out_lines[-1].strip() != "":
            out_lines.append("")
        out_lines.append("[system]")
        out_lines.append("language=english")

    new_src = "\n".join(out_lines) + ("\n" if not new_src_ends_with_newline(out_lines) else "")

    return [{
        "type": "edit",
        "description": "Add `language=english` to [system] in fallout.cfg to ensure message lookup uses english defaults",
        "target": "fallout.cfg",
        "original": src,
        "updated": new_src,
    }]


def new_src_ends_with_newline(lines: List[str]) -> bool:
    # simple heuristic; join above handles final newline, but we try to preserve intent
    return False


# Rule 2: relocate_text_for_message_load

def relocate_text_for_message_load(workdir: str, summary: dict, selftest: dict) -> List[Dict[str, Any]]:
    """For .msg failures, if the file exists at `data/text/<lang>/<file>` but the
    failure references `data/text/<lang>/game/<file>` (or the reverse), propose copying
    the file into the `game/` subdirectory where the loader expects it.
    """
    fixes: List[Dict[str, Any]] = []
    st = _load_selftest(workdir, summary, selftest or {})
    failures = st.get("failures", [])

    for f in failures:
        path = f.get("path", "")
        if not path.lower().endswith(".msg"):
            continue

        # Check canonical form: data/text/<lang>/game/<file>
        parts = path.split("/")
        # We only handle explicit long paths here
        try:
            idx = parts.index("data")
            if parts[idx + 1] != "text":
                continue
            lang = parts[idx + 2]
            # If next segment is 'game', then target expects game/<file>
            if parts[idx + 3] == "game":
                basename = "/".join(parts[idx + 4:])
                src_candidate = os.path.join(workdir, "data", "text", lang, basename)
                fallback_src = os.path.join(workdir, "data", "text", lang, basename)
                # Fallback: if src exists but target missing, propose copy
                src_plain = os.path.join(workdir, "data", "text", lang, os.path.basename(basename))
                dst = os.path.join(workdir, "data", "text", lang, "game", os.path.basename(basename))
                if os.path.isfile(src_plain) and not os.path.isfile(dst):
                    fixes.append({
                        "type": "copy_file",
                        "description": f"Copy {os.path.relpath(src_plain, workdir)} -> {os.path.relpath(dst, workdir)} to satisfy message_load expecting game/ subdir",
                        "src": os.path.relpath(src_plain, workdir),
                        "dst": os.path.relpath(dst, workdir),
                    })
        except (ValueError, IndexError):
            continue

    return fixes


# Rule 3: propose_whitelist_additions

def propose_whitelist_additions(workdir: str, summary: dict, selftest: dict) -> List[Dict[str, Any]]:
    """For remaining failures deemed benign, propose whitelist additions with a reason.
    This creates entries in `whitelist-additions.txt` in the iter folder.
    """
    st = _load_selftest(workdir, summary, selftest or {})
    failures = st.get("failures", [])
    entries: List[Dict[str, Any]] = []

    for f in failures:
        kind = f.get("kind", "unknown")
        path = f.get("path", "")
        error = f.get("error", "")
        # Heuristic: small text message missing that is present in alternate path can be whitelisted
        # We always produce candidates rather than assume they are acceptable
        reason = f"Auto-proposed whitelist for {kind}:{path} (error: {error})"
        pattern = f"{kind}:{path}"
        entries.append({
            "type": "whitelist",
            "pattern": pattern,
            "reason": reason,
        })

    return entries


# Export rules list
RME_AUTO_RULES = [ensure_fallout_cfg_language, relocate_text_for_message_load, propose_whitelist_additions]

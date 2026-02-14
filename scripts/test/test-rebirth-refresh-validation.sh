#!/usr/bin/env bash
# =============================================================================
# Fallout 1 Rebirth — RME Validation Refresh
# =============================================================================
# Regenerates validation evidence under tmp/rme/validation by default
# using user-provided unpatched/patched game-data directories.
#
# USAGE:
#   ./scripts/test/test-rebirth-refresh-validation.sh
#     [--unpatched <dir>] [--patched <dir>] [--rme <dir>] [--out <dir>]
#
# DEFAULTS:
#   --unpatched <dir>
#   --patched   <dir>
#   --rme       third_party/rme
#   --out       tmp/rme/validation
#
# REQUIREMENTS:
#   - python3
#   - shasum (or compatible)
# =============================================================================
set -euo pipefail

cd "$(dirname "$0")/../.."

UNPATCHED_DIR="${UNPATCHED_DIR:-}"
PATCHED_DIR="${PATCHED_DIR:-}"
GAMEFILES_ROOT="${FALLOUT_GAMEFILES_ROOT:-${GAMEFILES_ROOT:-}}"
if [[ -d "third_party/rme" ]]; then
  RME_DIR="third_party/rme"
else
  RME_DIR="third_party/rme/source"
fi
OUT_DIR="tmp/rme/validation"

log_info()  { echo -e "\033[0;34m>>>\033[0m $1"; }
log_ok()    { echo -e "\033[0;32m[OK]\033[0m $1"; }
log_error() { echo -e "\033[0;31m[ERROR]\033[0m $1"; }

show_help() {
  cat <<'EOF'
RME Validation Refresh

USAGE:
  ./scripts/test/test-rebirth-refresh-validation.sh
    [--unpatched <dir>] [--patched <dir>] [--rme <dir>] [--out <dir>]

DEFAULTS:
  --unpatched <required, or inferred from FALLOUT_GAMEFILES_ROOT>
  --patched   <required, or inferred from FALLOUT_GAMEFILES_ROOT>
  --rme       third_party/rme
  --out       tmp/rme/validation
EOF
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --unpatched) UNPATCHED_DIR="$2"; shift 2 ;;
    --patched) PATCHED_DIR="$2"; shift 2 ;;
    --rme) RME_DIR="$2"; shift 2 ;;
    --out) OUT_DIR="$2"; shift 2 ;;
    --help|-h) show_help ;;
    *) log_error "Unknown option: $1"; show_help ;;
  esac
done

if [[ -z "$UNPATCHED_DIR" && -n "$GAMEFILES_ROOT" ]]; then
  UNPATCHED_DIR="$GAMEFILES_ROOT/unpatchedfiles"
fi
if [[ -z "$PATCHED_DIR" && -n "$GAMEFILES_ROOT" ]]; then
  PATCHED_DIR="$GAMEFILES_ROOT/patchedfiles"
fi

if [[ ! -d "$UNPATCHED_DIR" || ! -d "$PATCHED_DIR" ]]; then
  log_error "Missing unpatched/patched directories."
  log_error "unpatched=$UNPATCHED_DIR patched=$PATCHED_DIR"
  log_error "Set --unpatched/--patched explicitly or export FALLOUT_GAMEFILES_ROOT."
  exit 1
fi

mkdir -p "$OUT_DIR/raw"

RAW_DIR="$OUT_DIR/raw"
TMP_CROSSREF_DIR="$OUT_DIR/tmp_crossref"
UNPATCHED_XREF_DIR="$TMP_CROSSREF_DIR/unpatched"
PATCHED_XREF_DIR="$TMP_CROSSREF_DIR/patched"
mkdir -p "$UNPATCHED_XREF_DIR" "$PATCHED_XREF_DIR"

log_info "1) Quick tree diff (diff -qr)"
{
  echo "1) Quick tree diff (diff -qr)"
  diff -qr "$UNPATCHED_DIR" "$PATCHED_DIR" || true
} > "$RAW_DIR/01_diff_qr.txt"

log_info "2) Unified diff (diff -ruN) (large)"
diff -ruN "$UNPATCHED_DIR" "$PATCHED_DIR" > "$OUT_DIR/unpatched_vs_patched.diff" || true
cp "$OUT_DIR/unpatched_vs_patched.diff" "$RAW_DIR/unpatched_vs_patched.diff" || true
{
  echo "2) Unified diff"
  ls -lh "$OUT_DIR/unpatched_vs_patched.diff" || true
} > "$RAW_DIR/02_unpatched_vs_patched_diff_info.txt"

log_info "3) Config diffs"
{
  echo "3) Config diffs"
  diff -u "$UNPATCHED_DIR/f1_res.ini" "$PATCHED_DIR/f1_res.ini" || true
  echo ""
  diff -u "$UNPATCHED_DIR/fallout.cfg" "$PATCHED_DIR/fallout.cfg" || true
} > "$RAW_DIR/03_configs_diff.txt"

log_info "4) DAT shasums"
{
  echo "4) DAT checksums"
  shasum -a 256 \
    "$UNPATCHED_DIR/master.dat" "$UNPATCHED_DIR/critter.dat" \
    "$PATCHED_DIR/master.dat" "$PATCHED_DIR/critter.dat"
} > "$RAW_DIR/04_dat_shasums.txt"

# Also keep the per-file sha256 evidence files (hash + path), matching existing convention.
shasum -a 256 "$UNPATCHED_DIR/master.dat" > "$OUT_DIR/master_unpatched.sha256"
shasum -a 256 "$PATCHED_DIR/master.dat"   > "$OUT_DIR/master_patched.sha256"
shasum -a 256 "$UNPATCHED_DIR/critter.dat" > "$OUT_DIR/critter_unpatched.sha256"
shasum -a 256 "$PATCHED_DIR/critter.dat"   > "$OUT_DIR/critter_patched.sha256"
echo "Checksums written" > "$OUT_DIR/checksum_notice.txt"

log_info "5) RME crossref (patched/unpatched) + LST report"
python3 scripts/test/test-rme-crossref.py --rme "$RME_DIR" --base-dir "$UNPATCHED_DIR" --out-dir "$UNPATCHED_XREF_DIR" >/dev/null
python3 scripts/test/test-rme-crossref.py --rme "$RME_DIR" --base-dir "$PATCHED_DIR"   --out-dir "$PATCHED_XREF_DIR"   >/dev/null

cp "$UNPATCHED_XREF_DIR/rme-crossref.csv" "$RAW_DIR/rme-crossref-unpatched.csv"
cp "$PATCHED_XREF_DIR/rme-crossref.csv"   "$RAW_DIR/rme-crossref-patched.csv"
cp "$PATCHED_XREF_DIR/rme-lst-report.md"  "$RAW_DIR/08_lst_missing.md"
echo "Copied LST reports" > "$OUT_DIR/lst_copy_notice.txt"

{
  echo "5) Copied rme-crossref CSVs (patched/unpatched)"
  echo "  - rme-crossref-unpatched.csv"
  echo "  - rme-crossref-patched.csv"
} > "$RAW_DIR/05_rme_crossref_copy.txt"

log_info "5b) LST candidate scan (by basename)"
python3 scripts/test/test-rme-find-lst-candidates.py \
  --lst-report "$RAW_DIR/08_lst_missing.md" \
  --search "$PATCHED_DIR" "$UNPATCHED_DIR" \
  --out "$RAW_DIR/lst_candidates.csv" \
  --max-per-token 200 \
  > "$RAW_DIR/find_lst_candidates.log" 2>&1 || true

log_info "6) Crossref counts + promotions lists"
python3 - "$RAW_DIR/rme-crossref-unpatched.csv" "$RAW_DIR/rme-crossref-patched.csv" "$OUT_DIR" "$RAW_DIR" <<'PYCODE'
import csv
import os
import sys
from collections import Counter
from pathlib import Path

unpatched_csv = Path(sys.argv[1])
patched_csv = Path(sys.argv[2])
out_dir = Path(sys.argv[3])
raw_dir = Path(sys.argv[4])

def read_rows(p: Path):
    with p.open(newline="") as f:
        r = csv.DictReader(f)
        return list(r)

u = read_rows(unpatched_csv)
p = read_rows(patched_csv)

def by_source(rows, source):
    return [r for r in rows if r.get("base_source") == source]

def paths_for(rows, source):
    return [r["path"] for r in rows if r.get("base_source") == source]

u_master = set(paths_for(u, "master.dat"))
u_critter = set(paths_for(u, "critter.dat"))
p_master = set(paths_for(p, "master.dat"))
p_critter = set(paths_for(p, "critter.dat"))

master_added = sorted(p_master - u_master, key=lambda s: s.upper())
critter_added = sorted(p_critter - u_critter, key=lambda s: s.upper())

def write_list(path: Path, items):
    path.write_text("\n".join(items) + ("\n" if items else ""), encoding="utf-8", newline="\n")

write_list(out_dir / "unpatched_master_files.txt", sorted(u_master, key=lambda s: s.upper()))
write_list(out_dir / "unpatched_critter_files.txt", sorted(u_critter, key=lambda s: s.upper()))
write_list(out_dir / "patched_master_files.txt", sorted(p_master, key=lambda s: s.upper()))
write_list(out_dir / "patched_critter_files.txt", sorted(p_critter, key=lambda s: s.upper()))

write_list(out_dir / "master_added_files.txt", master_added)
write_list(out_dir / "critter_added_files.txt", critter_added)

def ext_counts(paths):
    c = Counter()
    for s in paths:
        ext = s.rsplit(".", 1)[-1].lower() if "." in s else ""
        c[ext] += 1
    return c

def write_counts(path: Path, counts: Counter):
    lines = []
    for ext, n in counts.most_common():
        lines.append(f"{n:4d} {ext}")
    path.write_text("\n".join(lines) + ("\n" if lines else ""), encoding="utf-8", newline="\n")

write_counts(out_dir / "master_added_ext_counts.txt", ext_counts(master_added))
write_counts(out_dir / "critter_added_ext_counts.txt", ext_counts(critter_added))

# Crossref counts evidence (correct semantics: base_source == 'none').
def count_source(rows, src):
    return sum(1 for r in rows if r.get("base_source") == src)

counts_txt = []
counts_txt.append("6) RME crossref counts")
counts_txt.append(f"unpatched: new files (base_source=none)= {count_source(u, 'none')}")
counts_txt.append(f"unpatched: master.dat override count= {count_source(u, 'master.dat')}")
counts_txt.append(f"unpatched: critter.dat override count= {count_source(u, 'critter.dat')}")
counts_txt.append(f"patched: new files (base_source=none)= {count_source(p, 'none')}")
counts_txt.append(f"patched: master.dat override count= {count_source(p, 'master.dat')}")
counts_txt.append(f"patched: critter.dat override count= {count_source(p, 'critter.dat')}")
(raw_dir / "06_rme_crossref_counts.txt").write_text("\n".join(counts_txt) + "\n", encoding="utf-8", newline="\n")

PYCODE

{
  echo "9) Promotions crossref rows"
  grep -iF -f "$OUT_DIR/master_added_files.txt" "$RAW_DIR/rme-crossref-patched.csv" > "$RAW_DIR/master_added_rows.csv" || true
  echo "master_added_rows.csv: " $(wc -l < "$RAW_DIR/master_added_rows.csv" 2>/dev/null || echo 0)
  grep -iF -f "$OUT_DIR/critter_added_files.txt" "$RAW_DIR/rme-crossref-patched.csv" > "$RAW_DIR/critter_added_rows.csv" || true
  echo "critter_added_rows.csv: " $(wc -l < "$RAW_DIR/critter_added_rows.csv" 2>/dev/null || echo 0)
} > "$RAW_DIR/09_promotions_crossref.txt"

log_info "7) Map endian signal (from patched crossref)"
grep 'map_endian=big' "$RAW_DIR/rme-crossref-patched.csv" > "$RAW_DIR/07_map_endian.txt" || true

log_info "8) LST missing (copied from crossref output)"
{
  echo "8) LST missing references"
  echo "See: 08_lst_missing.md"
} > "$RAW_DIR/08_lst_missing.txt"

log_info "11) Run validation script (overlay + DAT xdelta)"
set +e
./scripts/test/test-rebirth-validate-data.sh --patched "$PATCHED_DIR" --base "$UNPATCHED_DIR" --rme "$RME_DIR" > "$RAW_DIR/rebirth_validate.log" 2>&1
rc=$?
set -e
if [[ $rc -ne 0 ]]; then
  log_error "test-rebirth-validate-data.sh failed (see $RAW_DIR/rebirth_validate.log)"
  exit $rc
fi
{
  echo "11) Validation script log"
  echo "See: rebirth_validate.log"
} > "$RAW_DIR/11_validation_script.txt"

log_info "12) Script reference audit (scripts.lst vs MAP/PRO)"
python3 scripts/test/test-rme-audit-script-refs.py \
  --patched-dir "$PATCHED_DIR" \
  --out-dir "$RAW_DIR" \
  > "$RAW_DIR/12_script_refs_run.log" 2>&1

echo "Full audit run complete. Raw logs are in $RAW_DIR." > "$RAW_DIR/_run_complete_notice.txt"
log_ok "Validation refreshed at: $OUT_DIR"

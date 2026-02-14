#!/usr/bin/env bash
# =============================================================================
# Fallout 1 Rebirth — RME Data Validation
# =============================================================================
# Validates that a patched output folder includes the full RME payload.
# Checks that all RME DATA files exist in the patched data and match checksums.
# Optionally validates master.dat/critter.dat against xdelta output if --base is provided.
#
# USAGE:
#   ./scripts/patch/rebirth-validate-data.sh --patched <path> [--base <path>] [--rme <path>]
#
# REQUIRED:
#   --patched PATH    Patched data folder (master.dat, critter.dat, data/)
#
# OPTIONAL:
#   --base PATH       Base data folder for DAT validation (master.dat, critter.dat)
#   --rme PATH        RME payload directory (default: third_party/rme)
#   --help            Show this help message
#
# REQUIREMENTS:
#   - xdelta3 (only when --base is provided)
#   - python3 (for hashing fallback)
# =============================================================================
set -euo pipefail

START_DIR="$(pwd)"
cd "$(dirname "$0")/../.."
ROOT_DIR="$(pwd)"

PATCHED_DIR=""
BASE_DIR=""
RME_DIR=""
RME_FROM_ARG=0

log_info()  { echo -e "\033[0;34m>>>\033[0m $1"; }
log_ok()    { echo -e "\033[0;32m[OK]\033[0m $1"; }
log_warn()  { echo -e "\033[1;33m[WARN]\033[0m $1"; }
log_error() { echo -e "\033[0;31m[ERROR]\033[0m $1"; }

show_help() {
    cat << 'EOF'
RME Data Validation

USAGE:
  ./scripts/patch/rebirth-validate-data.sh --patched <path> [--base <path>] [--rme <path>]

REQUIRED:
  --patched PATH    Patched data folder (master.dat, critter.dat, data/)

OPTIONAL:
  --base PATH       Base data folder for DAT validation (master.dat, critter.dat)
  --rme PATH        RME payload directory (default: third_party/rme)
  --help            Show this help message
EOF
    exit 0
}

require_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        log_error "Missing required tool: $1"
        exit 1
    fi
}

sha256_file() {
    if command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$1" | awk '{print $1}'
    else
        python3 - "$1" <<'PYCODE'
import hashlib
import sys
p = sys.argv[1]
h = hashlib.sha256()
with open(p, 'rb') as f:
    for chunk in iter(lambda: f.read(1024 * 1024), b''):
        h.update(chunk)
print(h.hexdigest())
PYCODE
    fi
}

sha256_text_normalized() {
    python3 - "$1" <<'PYCODE'
import hashlib
import sys

path = sys.argv[1]
with open(path, 'rb') as f:
    data = f.read()
data = data.replace(b'\r\n', b'\n')
h = hashlib.sha256()
h.update(data)
print(h.hexdigest())
PYCODE
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --patched)
            PATCHED_DIR="$2"
            shift 2
            ;;
        --base)
            BASE_DIR="$2"
            shift 2
            ;;
        --rme)
            RME_DIR="$2"
            RME_FROM_ARG=1
            shift 2
            ;;
        --help|-h)
            show_help
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            ;;
    esac
done

if [[ -z "$PATCHED_DIR" ]]; then
    log_error "Missing required arguments."
    show_help
fi

if [[ "$PATCHED_DIR" != /* ]]; then
    PATCHED_DIR="$START_DIR/$PATCHED_DIR"
fi
if [[ -n "$BASE_DIR" && "$BASE_DIR" != /* ]]; then
    BASE_DIR="$START_DIR/$BASE_DIR"
fi
if [[ -z "$RME_DIR" ]]; then
    if [[ -d "$ROOT_DIR/third_party/rme" ]]; then
        RME_DIR="$ROOT_DIR/third_party/rme"
    else
        RME_DIR="$ROOT_DIR/third_party/rme/source"
    fi
else
    if [[ "$RME_DIR" != /* ]]; then
        if [[ "$RME_FROM_ARG" -eq 1 ]]; then
            RME_DIR="$START_DIR/$RME_DIR"
        else
            RME_DIR="$ROOT_DIR/$RME_DIR"
        fi
    fi
fi

PATCHED_DIR="$(cd "$PATCHED_DIR" 2>/dev/null && pwd)" || { log_error "Invalid patched path"; exit 1; }
RME_DIR="$(cd "$RME_DIR" 2>/dev/null && pwd)" || { log_error "Invalid RME path"; exit 1; }
if [[ -n "$BASE_DIR" ]]; then
    BASE_DIR="$(cd "$BASE_DIR" 2>/dev/null && pwd)" || { log_error "Invalid base path"; exit 1; }
fi

if [[ ! -f "$PATCHED_DIR/master.dat" || ! -f "$PATCHED_DIR/critter.dat" || ! -d "$PATCHED_DIR/data" ]]; then
    log_error "Patched folder must contain master.dat, critter.dat, and data/"
    exit 1
fi

if [[ ! -f "$RME_DIR/master.xdelta" || ! -f "$RME_DIR/critter.xdelta" || ! -d "$RME_DIR/DATA" ]]; then
    log_error "RME payload missing master.xdelta, critter.xdelta, or DATA/"
    exit 1
fi

if [[ -n "$BASE_DIR" ]]; then
    if [[ ! -f "$BASE_DIR/master.dat" || ! -f "$BASE_DIR/critter.dat" ]]; then
        log_error "Base folder must contain master.dat and critter.dat"
        exit 1
    fi
fi

log_info "Validating RME DATA overlay..."
TOTAL=0
MISSING=0
MISMATCH=0
MISSING_LIST=()
MISMATCH_LIST=()

while IFS= read -r -d '' SRC; do
    REL="${SRC#$RME_DIR/DATA/}"
    REL_LOWER=$(echo "$REL" | tr '[:upper:]' '[:lower:]')
    DST_LOWER="$PATCHED_DIR/data/$REL_LOWER"
    DST_ORIG="$PATCHED_DIR/data/$REL"

    TOTAL=$((TOTAL + 1))

    if [[ -f "$DST_LOWER" ]]; then
        DST="$DST_LOWER"
    elif [[ -f "$DST_ORIG" ]]; then
        DST="$DST_ORIG"
    else
        MISSING=$((MISSING + 1))
        MISSING_LIST+=("$REL")
        continue
    fi

    EXT="${SRC##*.}"
    EXT_LC=$(printf '%s' "$EXT" | tr '[:upper:]' '[:lower:]')
    if [[ "$EXT_LC" == "lst" || "$EXT_LC" == "msg" || "$EXT_LC" == "txt" ]]; then
        SRC_HASH=$(sha256_text_normalized "$SRC")
        DST_HASH=$(sha256_text_normalized "$DST")
    else
        SRC_HASH=$(sha256_file "$SRC")
        DST_HASH=$(sha256_file "$DST")
    fi
    if [[ "$SRC_HASH" != "$DST_HASH" ]]; then
        MISMATCH=$((MISMATCH + 1))
        MISMATCH_LIST+=("$REL")
    fi

done < <(find "$RME_DIR/DATA" -type f -print0)

if [[ "$MISSING" -eq 0 && "$MISMATCH" -eq 0 ]]; then
    log_ok "RME DATA overlay verified ($TOTAL files)"
else
    log_error "RME DATA overlay issues: missing=$MISSING, mismatched=$MISMATCH"
    if [[ "$MISSING" -gt 0 ]]; then
        log_warn "Missing files (first 20):"
        printf '%s\n' "${MISSING_LIST[@]:0:20}" | sed 's/^/  - /'
    fi
    if [[ "$MISMATCH" -gt 0 ]]; then
        log_warn "Mismatched files (first 20):"
        printf '%s\n' "${MISMATCH_LIST[@]:0:20}" | sed 's/^/  - /'
    fi
fi

# -----------------------------------------------------------------------------
# Validate CRLF normalization for LST/MSG/TXT in patched data
# -----------------------------------------------------------------------------
log_info "Validating text line endings (CRLF -> LF)..."
CRLF_COUNT=0
CRLF_FILES=()

while IFS= read -r -d '' FILE; do
    if python3 - "$FILE" <<'PYCODE'
import sys
path = sys.argv[1]
with open(path, 'rb') as f:
    data = f.read()
sys.exit(0 if b'\r\n' not in data else 1)
PYCODE
    then
        continue
    else
        CRLF_COUNT=$((CRLF_COUNT + 1))
        CRLF_FILES+=("$FILE")
    fi
done < <(find "$PATCHED_DIR/data" -type f -iregex '.*\\.(lst|msg|txt)$' -print0)

if [[ "$CRLF_COUNT" -eq 0 ]]; then
    log_ok "Text line endings normalized"
else
    log_error "Found CRLF line endings in patched data"
    log_warn "Files with CRLF (first 20):"
    printf '%s\\n' \"${CRLF_FILES[@]:0:20}\" | sed 's/^/  - /'
fi

DAT_OK=true
if [[ -n "$BASE_DIR" ]]; then
    require_cmd xdelta3
    log_info "Validating master.dat/critter.dat against xdelta output..."
    TMP_DIR="$(mktemp -d)"

    xdelta3 -d -s "$BASE_DIR/master.dat" "$RME_DIR/master.xdelta" "$TMP_DIR/master.dat"
    xdelta3 -d -s "$BASE_DIR/critter.dat" "$RME_DIR/critter.xdelta" "$TMP_DIR/critter.dat"

    EXPECT_MASTER=$(sha256_file "$TMP_DIR/master.dat")
    EXPECT_CRITTER=$(sha256_file "$TMP_DIR/critter.dat")
    ACTUAL_MASTER=$(sha256_file "$PATCHED_DIR/master.dat")
    ACTUAL_CRITTER=$(sha256_file "$PATCHED_DIR/critter.dat")

    if [[ "$EXPECT_MASTER" != "$ACTUAL_MASTER" ]]; then
        log_error "master.dat does not match expected patched output"
        DAT_OK=false
    fi
    if [[ "$EXPECT_CRITTER" != "$ACTUAL_CRITTER" ]]; then
        log_error "critter.dat does not match expected patched output"
        DAT_OK=false
    fi

    rm -rf "$TMP_DIR"

    if [[ "$DAT_OK" == "true" ]]; then
        log_ok "DAT patches verified"
    fi
else
    log_warn "Skipping DAT validation (no --base provided)"
fi

# Mod list (from upstream RME readme)
if [[ -f "$RME_DIR/readme.txt" ]]; then
    echo ""
    echo "Included Mods (from RME readme):"
    awk '/^ - /{sub(/^ - /, ""); print "  - " $0}' "$RME_DIR/readme.txt"
fi

if [[ "$MISSING" -eq 0 && "$MISMATCH" -eq 0 && "$DAT_OK" == "true" ]]; then
    echo ""
    log_ok "Validation passed"
    exit 0
fi

echo ""
log_error "Validation failed"
exit 1

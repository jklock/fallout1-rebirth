#!/usr/bin/env bash
# =============================================================================
# Fallout 1 Rebirth — RME Patch (Core)
# =============================================================================
# Patches Fallout 1 data in place using the RME payload.
# Produces a patched output folder ready to copy into the .app / .ipa.
#
# USAGE:
#   ./scripts/patch/rebirth_patch_data.sh --base <path> --out <path> --config-dir <path> [--rme <path>] [--skip-checksums] [--force]
#
# REQUIRED:
#   --base PATH       Base Fallout 1 data folder (master.dat, critter.dat, data/)
#   --out PATH        Output folder for patched data
#   --config-dir PATH Config template directory (gameconfig/macos or gameconfig/ios)
#
# OPTIONAL:
#   --rme PATH          RME payload directory (default: third_party/rme/source)
#   --skip-checksums    Skip base DAT checksum validation
#   --force             Overwrite existing output folder
#
# REQUIREMENTS:
#   - xdelta3
#   - python3
#   - rsync (optional; falls back to cp)
# =============================================================================
set -euo pipefail

cd "$(dirname "$0")/../.."

# -----------------------------------------------------------------------------
# Defaults
# -----------------------------------------------------------------------------
RME_DIR="third_party/rme/source"
OUT_DIR=""
BASE_DIR=""
CONFIG_DIR=""
SKIP_CHECKSUMS=0
FORCE=0

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------
log_info()  { echo -e "\033[0;34m>>>\033[0m $1"; }
log_ok()    { echo -e "\033[0;32m[OK]\033[0m $1"; }
log_warn()  { echo -e "\033[1;33m[WARN]\033[0m $1"; }
log_error() { echo -e "\033[0;31m[ERROR]\033[0m $1"; }

show_help() {
    cat << 'EOF'
RME Patch Core

USAGE:
  ./scripts/patch/rebirth_patch_data.sh --base <path> --out <path> --config-dir <path> [--rme <path>] [--skip-checksums] [--force]

REQUIRED:
  --base PATH        Base Fallout 1 data folder (master.dat, critter.dat, data/)
  --out PATH         Output folder for patched data
  --config-dir PATH  Config template directory (gameconfig/macos or gameconfig/ios)

OPTIONAL:
  --rme PATH          RME payload directory (default: third_party/rme/source)
  --skip-checksums    Skip base DAT checksum validation
  --force             Overwrite existing output folder
  --help              Show this help
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

# -----------------------------------------------------------------------------
# Argument parsing
# -----------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        --base)
            BASE_DIR="$2"
            shift 2
            ;;
        --out)
            OUT_DIR="$2"
            shift 2
            ;;
        --config-dir)
            CONFIG_DIR="$2"
            shift 2
            ;;
        --rme)
            RME_DIR="$2"
            shift 2
            ;;
        --skip-checksums)
            SKIP_CHECKSUMS=1
            shift
            ;;
        --force)
            FORCE=1
            shift
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

if [[ -z "$BASE_DIR" || -z "$OUT_DIR" || -z "$CONFIG_DIR" ]]; then
    log_error "Missing required arguments."
    show_help
fi

BASE_DIR="$(cd "$BASE_DIR" 2>/dev/null && pwd)" || { log_error "Invalid base path"; exit 1; }
OUT_DIR="$(mkdir -p "$OUT_DIR" && cd "$OUT_DIR" 2>/dev/null && pwd)" || { log_error "Invalid out path"; exit 1; }
RME_DIR="$(cd "$RME_DIR" 2>/dev/null && pwd)" || { log_error "Invalid RME path"; exit 1; }
CONFIG_DIR="$(cd "$CONFIG_DIR" 2>/dev/null && pwd)" || { log_error "Invalid config dir"; exit 1; }

# -----------------------------------------------------------------------------
# Preconditions
# -----------------------------------------------------------------------------
require_cmd xdelta3
require_cmd python3
if ! command -v rsync >/dev/null 2>&1; then
    log_warn "rsync not found, falling back to cp -R"
fi

if [[ ! -f "$BASE_DIR/master.dat" || ! -f "$BASE_DIR/critter.dat" || ! -d "$BASE_DIR/data" ]]; then
    log_error "Base folder must contain master.dat, critter.dat, and data/"
    exit 1
fi

if [[ ! -f "$RME_DIR/master.xdelta" || ! -f "$RME_DIR/critter.xdelta" || ! -d "$RME_DIR/DATA" ]]; then
    log_error "RME payload missing master.xdelta, critter.xdelta, or DATA/"
    exit 1
fi

if [[ ! -f "$CONFIG_DIR/fallout.cfg" || ! -f "$CONFIG_DIR/f1_res.ini" ]]; then
    log_error "Config dir must contain fallout.cfg and f1_res.ini"
    exit 1
fi

if [[ -e "$OUT_DIR/master.dat" || -e "$OUT_DIR/critter.dat" || -d "$OUT_DIR/data" ]]; then
    if [[ "$FORCE" -eq 0 ]]; then
        log_error "Output folder is not empty. Use --force to overwrite."
        exit 1
    else
        log_warn "Cleaning output folder (force enabled)"
        rm -rf "$OUT_DIR"/*
    fi
fi

# -----------------------------------------------------------------------------
# Checksum validation
# -----------------------------------------------------------------------------
CHECKSUMS_FILE="third_party/rme/checksums.txt"
if [[ "$SKIP_CHECKSUMS" -eq 0 && -f "$CHECKSUMS_FILE" ]]; then
    log_info "Validating base DAT checksums..."
    EXPECT_MASTER=$(grep "BASE/master.dat" "$CHECKSUMS_FILE" | awk '{print $1}')
    EXPECT_CRITTER=$(grep "BASE/critter.dat" "$CHECKSUMS_FILE" | awk '{print $1}')

    if [[ -n "$EXPECT_MASTER" ]]; then
        ACTUAL_MASTER=$(sha256_file "$BASE_DIR/master.dat")
        if [[ "$ACTUAL_MASTER" != "$EXPECT_MASTER" ]]; then
            log_warn "master.dat checksum mismatch"
            log_warn "Expected: $EXPECT_MASTER"
            log_warn "Actual:   $ACTUAL_MASTER"
            log_warn "Use --skip-checksums to proceed anyway."
            exit 1
        fi
    fi

    if [[ -n "$EXPECT_CRITTER" ]]; then
        ACTUAL_CRITTER=$(sha256_file "$BASE_DIR/critter.dat")
        if [[ "$ACTUAL_CRITTER" != "$EXPECT_CRITTER" ]]; then
            log_warn "critter.dat checksum mismatch"
            log_warn "Expected: $EXPECT_CRITTER"
            log_warn "Actual:   $ACTUAL_CRITTER"
            log_warn "Use --skip-checksums to proceed anyway."
            exit 1
        fi
    fi

    log_ok "Base DAT checksums match"
else
    log_warn "Skipping base DAT checksum validation"
fi

# -----------------------------------------------------------------------------
# Copy base data
# -----------------------------------------------------------------------------
log_info "Copying base data to output..."
if command -v rsync >/dev/null 2>&1; then
    rsync -a "$BASE_DIR/" "$OUT_DIR/"
else
    cp -R "$BASE_DIR/." "$OUT_DIR/"
fi

# -----------------------------------------------------------------------------
# Apply xdelta patches
# -----------------------------------------------------------------------------
log_info "Applying xdelta patches..."

xdelta3 -d -s "$OUT_DIR/master.dat" "$RME_DIR/master.xdelta" "$OUT_DIR/master.dat.patched"
mv "$OUT_DIR/master.dat.patched" "$OUT_DIR/master.dat"

xdelta3 -d -s "$OUT_DIR/critter.dat" "$RME_DIR/critter.xdelta" "$OUT_DIR/critter.dat.patched"
mv "$OUT_DIR/critter.dat.patched" "$OUT_DIR/critter.dat"

log_ok "DAT patches applied"

# -----------------------------------------------------------------------------
# Overlay RME DATA
# -----------------------------------------------------------------------------
log_info "Overlaying RME DATA into out/data/..."
mkdir -p "$OUT_DIR/data"
if command -v rsync >/dev/null 2>&1; then
    rsync -a "$RME_DIR/DATA/" "$OUT_DIR/data/"
else
    cp -R "$RME_DIR/DATA/." "$OUT_DIR/data/"
fi

# -----------------------------------------------------------------------------
# Normalize case (lowercase)
# -----------------------------------------------------------------------------
log_info "Normalizing case to lowercase in out/data/..."
python3 - "$OUT_DIR/data" <<'PYCODE'
import os
import sys
root = os.path.abspath(sys.argv[1])

for dirpath, dirnames, filenames in os.walk(root, topdown=False):
    for name in filenames:
        src = os.path.join(dirpath, name)
        dst = os.path.join(dirpath, name.lower())
        if src != dst:
            try:
                os.rename(src, dst)
            except OSError:
                pass
    for name in dirnames:
        src = os.path.join(dirpath, name)
        dst = os.path.join(dirpath, name.lower())
        if src != dst:
            try:
                os.rename(src, dst)
            except OSError:
                pass
PYCODE

# -----------------------------------------------------------------------------
# Copy configs
# -----------------------------------------------------------------------------
log_info "Copying config templates..."
cp "$CONFIG_DIR/fallout.cfg" "$OUT_DIR/fallout.cfg"
cp "$CONFIG_DIR/f1_res.ini" "$OUT_DIR/f1_res.ini"

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
log_info "Patch complete"
FILE_COUNT=$(find "$OUT_DIR" -type f | wc -l | tr -d ' ')
SIZE=$(du -sh "$OUT_DIR" | awk '{print $1}')
log_ok "Output: $OUT_DIR"
log_ok "Files: $FILE_COUNT"
log_ok "Size:  $SIZE"

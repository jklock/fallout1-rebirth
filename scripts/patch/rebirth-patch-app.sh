#!/usr/bin/env bash
# =============================================================================
# Fallout 1 Rebirth — RME Patch (macOS)
# =============================================================================
# Wrapper for the core patch script with macOS config templates.
#
# USAGE:
#   ./scripts/patch/rebirth-patch-app.sh --base <path> --out <path> [--rme <path>] [--skip-checksums] [--force]
#
# OPTIONS:
#   --base PATH        Base Fallout 1 data folder
#   --out PATH         Output folder for patched data
#   --rme PATH          RME payload directory (default: third_party/rme)
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

show_help() {
    cat << 'EOF'
RME Patch (macOS)

USAGE:
  ./scripts/patch/rebirth-patch-app.sh --base <path> --out <path> [--rme <path>] [--skip-checksums] [--force]

OPTIONS:
  --base PATH        Base Fallout 1 data folder
  --out PATH         Output folder for patched data
  --rme PATH          RME payload directory (default: third_party/rme)
  --skip-checksums    Skip base DAT checksum validation
  --force             Overwrite existing output folder
  --help              Show this help
EOF
    exit 0
}

ARGS=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --base|--out|--rme|--skip-checksums|--force)
            ARGS+=("$1")
            if [[ "$1" == "--base" || "$1" == "--out" || "$1" == "--rme" ]]; then
                ARGS+=("$2")
                shift 2
            else
                shift
            fi
            ;;
        --help|-h)
            show_help
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            ;;
    esac
done

./scripts/patch/rebirth-patch-data.sh \
    --config-dir gameconfig/macos \
    "${ARGS[@]}"

echo ""
echo "Copy the patched output into:"
echo "  /Applications/Fallout 1 Rebirth.app/Contents/Resources/"

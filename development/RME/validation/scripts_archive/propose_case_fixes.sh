#!/usr/bin/env bash
set -euo pipefail
DESTDIR=${1:-GOG/validation/overlay_casefix}
mkdir -p "$DESTDIR"

echo "Generating case-fix overlay into: $DESTDIR"

INPUT=GOG/case_renames.txt

# Parse lines like: - HR_ALLTLK.FRM  <->  hr_alltlk.frm
while IFS= read -r line; do
  line=${line#- }
  [[ -z "$line" ]] && continue
  left=$(echo "$line" | awk -F '<->' '{print $1}' | xargs)
  right=$(echo "$line" | awk -F '<->' '{print $2}' | xargs)
  # find available source in patched or unpatched
  src=$(find GOG/patchedfiles GOG/unpatchedfiles -type f -iname "$left" -o -iname "$right" -print -quit || true)
  if [ -z "$src" ]; then
    echo "No source found for pair: $left <-> $right" >&2
    continue
  fi
  base=$(basename "$left")
  # create dest dir preserving nesting under 'data'
  rel_dir=$(echo "$src" | sed -n 's#.*\(/data/.*\)/.*#\1#p')
  if [ -z "$rel_dir" ]; then
    # fallback: put at root of overlay
    destdir="$DESTDIR"
  else
    destdir="$DESTDIR${rel_dir}"
    mkdir -p "$destdir"
  fi
  # Copy both variants if missing
  for v in "$left" "$right"; do
    destpath="$destdir/$(echo "$v" | tr '\\' '/')"
    destdirp=$(dirname "$destpath")
    mkdir -p "$destdirp"
    if [ ! -e "$destpath" ]; then
      cp -p "$src" "$destpath" && echo "COPIED: $src -> $destpath"
    else
      echo "Exists: $destpath"
    fi
  done
done < <(grep '^-' "$INPUT" || true)

echo "Case fix overlay created at: $DESTDIR"

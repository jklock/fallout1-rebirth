#!/usr/bin/env bash
set -euo pipefail
DESTDIR=${1:-GOG/validation/overlay_data}
mkdir -p "$DESTDIR"

echo "Generating overlay into: $DESTDIR"

CSV_MASTER=GOG/validation/raw/master_added_rows.csv
CSV_CRITTER=GOG/validation/raw/critter_added_rows.csv

action_copy() {
  local original_path="$1" # e.g., ART\INTRFACE\BOSHARRY.FRM
  local src_basename=$(basename "$original_path" )
  # Find case-insensitive candidate in patchedfiles
  local found=$(find GOG/patchedfiles -type f -iname "$src_basename" -print -quit || true)
  if [ -n "$found" ]; then
    # normalize destination path to lower-case directory structure
    local dest_path="$DESTDIR/$(echo "$original_path" | tr '\\' '/')"
    local dest_dir=$(dirname "$dest_path")
    mkdir -p "$dest_dir"
    cp -p "$found" "$dest_path" && echo "COPIED: $found -> $dest_path"
  else
    echo "MISSING: $original_path (no candidate found under GOG/patchedfiles)" >&2
  fi
}

if [ -f "$CSV_MASTER" ]; then
  echo "Processing master rows: $CSV_MASTER"
  while IFS= read -r line; do
    test -z "$line" && continue
    path=$(echo "$line" | awk -F"," '{print $1}')
    action_copy "$path"
  done < "$CSV_MASTER"
fi

if [ -f "$CSV_CRITTER" ]; then
  echo "Processing critter rows: $CSV_CRITTER"
  while IFS= read -r line; do
    test -z "$line" && continue
    path=$(echo "$line" | awk -F"," '{print $1}')
    action_copy "$path"
  done < "$CSV_CRITTER"
fi

echo "Overlay generation complete. Inspect $DESTDIR for copied files."

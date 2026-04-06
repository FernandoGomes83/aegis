#!/bin/bash
# aegis-sdd — Get modification timestamps for all Aegis artifact files
# Usage: aegis-timestamps.sh <output_dir>

set -euo pipefail

OUTPUT_DIR="${1:?Usage: aegis-timestamps.sh <output_dir>}"

ARTIFACTS=("requirements.md" "design.md" "ui-design.md" "tasks.md" "tests.md")

get_date() {
  local file="$1"
  case "$OSTYPE" in
    darwin*) stat -f "%Sm" -t "%Y-%m-%d" "$file" ;;
    *)       stat -c "%y" "$file" | cut -d' ' -f1 ;;
  esac
}

for artifact in "${ARTIFACTS[@]}"; do
  filepath="$OUTPUT_DIR/$artifact"
  if [ -f "$filepath" ]; then
    echo "$artifact=$(get_date "$filepath")"
  else
    echo "$artifact=NOT_FOUND"
  fi
done

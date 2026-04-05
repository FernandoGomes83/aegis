#!/bin/bash
# aegis-sdd v1.3.0 — Get modification timestamps for all Aegis artifact files
# Usage: aegis-timestamps.sh <output_dir>

set -euo pipefail

OUTPUT_DIR="${1:?Usage: aegis-timestamps.sh <output_dir>}"

ARTIFACTS=("requirements.md" "design.md" "ui-design.md" "tasks.md" "tests.md")

get_date() {
  local file="$1"
  if [[ "$(uname)" == "Darwin" ]]; then
    stat -f "%Sm" -t "%Y-%m-%d" "$file"
  else
    stat -c "%y" "$file" | cut -d' ' -f1
  fi
}

for artifact in "${ARTIFACTS[@]}"; do
  filepath="$OUTPUT_DIR/$artifact"
  if [ -f "$filepath" ]; then
    echo "$artifact=$(get_date "$filepath")"
  else
    echo "$artifact=NOT_FOUND"
  fi
done

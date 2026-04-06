#!/bin/bash
# aegis-sdd — Parse tasks.md and extract structured task data
# Usage: aegis-build-parse.sh <tasks_md_path>

set -uo pipefail

TASKS_FILE="${1:?Usage: aegis-build-parse.sh <tasks_md_path>}"

if [ ! -f "$TASKS_FILE" ]; then
  echo "ERROR=file_not_found"
  echo "File not found: $TASKS_FILE"
  exit 1
fi

# --- Detect tasks across all formalism levels ---
# Light:    - [ ] TASK-NNN: Title  /  - [x] TASK-NNN: Title
# Standard: ### TASK-NNN: Title
# Formal:   **TASK-NNN: Title**

TOTAL=0
DONE=0
TASK_IDS=""

# Temp dir for per-task data (bash 3.2 compat — no associative arrays)
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# Helper: safe grep that returns "" instead of failing under set -e
has_match() { grep -q "$@" 2>/dev/null && echo "yes" || echo "no"; }

# Pass 1: Extract task entries
LINE_NUM=0
CURRENT_TASK=""

while IFS= read -r line; do
  LINE_NUM=$((LINE_NUM + 1))

  # Light: - [ ] TASK-NNN: or - [x] TASK-NNN:
  if echo "$line" | grep -qE '^\s*- \[([ x])\] TASK-([0-9]{3}):' 2>/dev/null; then
    task_id=$(echo "$line" | sed -E 's/.*TASK-([0-9]{3}).*/\1/')
    task_done=$(echo "$line" | has_match '\[x\]')
    task_title=$(echo "$line" | sed -E 's/.*TASK-[0-9]{3}:\s*//')
    task_parallel=$(echo "$line" | has_match '\[P\]')

    CURRENT_TASK="$task_id"
    TOTAL=$((TOTAL + 1))
    if [ "$task_done" = "yes" ]; then
      DONE=$((DONE + 1))
    fi
    TASK_IDS="${TASK_IDS:+$TASK_IDS,}TASK-$task_id"

    echo "$task_title" > "$TMPDIR/title_$task_id"
    echo "$task_done" > "$TMPDIR/status_$task_id"
    echo "$task_parallel" > "$TMPDIR/parallel_$task_id"
    echo "" > "$TMPDIR/depends_$task_id"
    echo "" > "$TMPDIR/implements_$task_id"
    echo "$LINE_NUM" > "$TMPDIR/line_$task_id"
    CURRENT_BLOCK="$line"
    continue
  fi

  # Standard: ### TASK-NNN:
  if echo "$line" | grep -qE '^###\s+TASK-([0-9]{3}):' 2>/dev/null; then
    task_id=$(echo "$line" | sed -E 's/.*TASK-([0-9]{3}).*/\1/')
    task_title=$(echo "$line" | sed -E 's/^###\s+TASK-[0-9]{3}:\s*//')
    task_parallel=$(echo "$line" | has_match '\[P\]')

    CURRENT_TASK="$task_id"
    TOTAL=$((TOTAL + 1))
    TASK_IDS="${TASK_IDS:+$TASK_IDS,}TASK-$task_id"

    echo "$task_title" > "$TMPDIR/title_$task_id"
    echo "no" > "$TMPDIR/status_$task_id"
    echo "$task_parallel" > "$TMPDIR/parallel_$task_id"
    echo "" > "$TMPDIR/depends_$task_id"
    echo "" > "$TMPDIR/implements_$task_id"
    echo "$LINE_NUM" > "$TMPDIR/line_$task_id"
    continue
  fi

  # Formal: **TASK-NNN:
  if echo "$line" | grep -qE '^\*\*TASK-([0-9]{3}):' 2>/dev/null; then
    task_id=$(echo "$line" | sed -E 's/.*TASK-([0-9]{3}).*/\1/')
    task_title=$(echo "$line" | sed -E 's/^\*\*TASK-[0-9]{3}:\s*//' | sed 's/\*\*$//')
    task_parallel=$(echo "$line" | has_match '\[P\]')

    CURRENT_TASK="$task_id"
    TOTAL=$((TOTAL + 1))
    TASK_IDS="${TASK_IDS:+$TASK_IDS,}TASK-$task_id"

    echo "$task_title" > "$TMPDIR/title_$task_id"
    echo "no" > "$TMPDIR/status_$task_id"
    echo "$task_parallel" > "$TMPDIR/parallel_$task_id"
    echo "" > "$TMPDIR/depends_$task_id"
    echo "" > "$TMPDIR/implements_$task_id"
    echo "$LINE_NUM" > "$TMPDIR/line_$task_id"
    continue
  fi

  # Inside a task block — look for metadata fields
  if [ -n "$CURRENT_TASK" ]; then
    # Status: done (Standard/Formal)
    if echo "$line" | grep -qiE '^\s*Status:\s*done' 2>/dev/null; then
      echo "yes" > "$TMPDIR/status_$CURRENT_TASK"
    fi

    # Depends on: TASK-NNN, TASK-NNN
    if echo "$line" | grep -qiE '^\s*Depends\s+on:' 2>/dev/null; then
      deps=$(echo "$line" | sed -E 's/.*Depends\s+on:\s*//' | grep -oE 'TASK-[0-9]{3}' | tr '\n' ',' | sed 's/,$//' || true)
      echo "$deps" > "$TMPDIR/depends_$CURRENT_TASK"
    fi

    # Implements: PROP-NNN, SEC-PROP-*, REQ-NNN, etc.
    if echo "$line" | grep -qiE '^\s*Implements:' 2>/dev/null; then
      impls=$(echo "$line" | sed -E 's/.*Implements:\s*//')
      echo "$impls" > "$TMPDIR/implements_$CURRENT_TASK"
    fi

    # End of block detection: next header or section separator
    if echo "$line" | grep -qE '^(##|---|\*\*TASK-)' 2>/dev/null && [ "$LINE_NUM" -gt 1 ]; then
      CURRENT_TASK=""
    fi
  fi
done < "$TASKS_FILE"

# Re-count done tasks accurately (Status: done may update after initial count)
DONE=0
for id_file in "$TMPDIR"/status_*; do
  [ -f "$id_file" ] || continue
  status=$(cat "$id_file")
  if [ "$status" = "yes" ]; then
    DONE=$((DONE + 1))
  fi
done

# --- Output structured data ---

echo "TOTAL_TASKS=$TOTAL"
echo "DONE_TASKS=$DONE"

# Per-task details
IFS=',' read -ra TASK_ARR <<< "$TASK_IDS"
for full_id in "${TASK_ARR[@]}"; do
  id=$(echo "$full_id" | sed 's/TASK-//')
  [ -f "$TMPDIR/title_$id" ] || continue

  title=$(cat "$TMPDIR/title_$id")
  status_val=$(cat "$TMPDIR/status_$id")
  parallel_val=$(cat "$TMPDIR/parallel_$id")
  depends_val=$(cat "$TMPDIR/depends_$id")
  implements_val=$(cat "$TMPDIR/implements_$id")

  status_label="pending"
  if [ "$status_val" = "yes" ]; then
    status_label="done"
  fi

  echo "TASK_${id}_TITLE=$title"
  echo "TASK_${id}_STATUS=$status_label"
  echo "TASK_${id}_DEPENDS=$depends_val"
  echo "TASK_${id}_PARALLEL=$parallel_val"
  echo "TASK_${id}_IMPLEMENTS=$implements_val"
done

# --- Compute actionable tasks (not done AND all deps satisfied) ---

ACTIONABLE=""
for full_id in "${TASK_ARR[@]}"; do
  id=$(echo "$full_id" | sed 's/TASK-//')
  [ -f "$TMPDIR/status_$id" ] || continue

  status_val=$(cat "$TMPDIR/status_$id")
  if [ "$status_val" = "yes" ]; then
    continue
  fi

  deps=$(cat "$TMPDIR/depends_$id" 2>/dev/null || echo "")
  all_deps_done="yes"

  if [ -n "$deps" ]; then
    IFS=',' read -ra DEP_ARR <<< "$deps"
    for dep in "${DEP_ARR[@]}"; do
      dep_id=$(echo "$dep" | sed 's/TASK-//' | tr -d ' ')
      dep_status=$(cat "$TMPDIR/status_$dep_id" 2>/dev/null || echo "no")
      if [ "$dep_status" != "yes" ]; then
        all_deps_done="no"
        break
      fi
    done
  fi

  if [ "$all_deps_done" = "yes" ]; then
    ACTIONABLE="${ACTIONABLE:+$ACTIONABLE,}TASK-$id"
  fi
done

echo "ACTIONABLE=$ACTIONABLE"

# --- Group consecutive [P] tasks into parallel groups ---

GROUP_NUM=0
CURRENT_GROUP=""
PREV_WAS_PARALLEL="no"

for full_id in "${TASK_ARR[@]}"; do
  id=$(echo "$full_id" | sed 's/TASK-//')
  [ -f "$TMPDIR/parallel_$id" ] || continue

  parallel_val=$(cat "$TMPDIR/parallel_$id")
  status_val=$(cat "$TMPDIR/status_$id")

  if [ "$parallel_val" = "yes" ] && [ "$status_val" != "yes" ]; then
    if [ "$PREV_WAS_PARALLEL" = "no" ]; then
      # Start new group
      GROUP_NUM=$((GROUP_NUM + 1))
      CURRENT_GROUP="TASK-$id"
    else
      CURRENT_GROUP="${CURRENT_GROUP},TASK-$id"
    fi
    PREV_WAS_PARALLEL="yes"
  else
    if [ "$PREV_WAS_PARALLEL" = "yes" ] && [ -n "$CURRENT_GROUP" ]; then
      # Only emit groups with more than one task
      if echo "$CURRENT_GROUP" | grep -q ',' 2>/dev/null; then
        echo "PARALLEL_GROUP_${GROUP_NUM}=$CURRENT_GROUP"
      fi
      CURRENT_GROUP=""
    fi
    PREV_WAS_PARALLEL="no"
  fi
done

# Emit last group if pending
if [ "$PREV_WAS_PARALLEL" = "yes" ] && [ -n "$CURRENT_GROUP" ]; then
  if echo "$CURRENT_GROUP" | grep -q ',' 2>/dev/null; then
    echo "PARALLEL_GROUP_${GROUP_NUM}=$CURRENT_GROUP"
  fi
fi

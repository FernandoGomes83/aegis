#!/bin/bash
# aegis-sdd — Mark a task as done in tasks.md
# Usage: aegis-build-mark.sh <tasks_md_path> <task_id> <level>

set -euo pipefail

TASKS_FILE="${1:?Usage: aegis-build-mark.sh <tasks_md_path> <task_id> <level>}"
TASK_ID="${2:?Missing task ID (e.g., TASK-001)}"
LEVEL="${3:?Missing level (light|standard|formal)}"

if [ ! -f "$TASKS_FILE" ]; then
  echo "ERROR=file_not_found"
  echo "File not found: $TASKS_FILE"
  exit 1
fi

# Normalize TASK_ID
TASK_NUM=$(echo "$TASK_ID" | grep -oE '[0-9]{3}' | head -1)
if [ -z "$TASK_NUM" ]; then
  echo "ERROR=invalid_task_id"
  echo "Invalid task ID format: $TASK_ID (expected TASK-NNN)"
  exit 1
fi
TASK_ID="TASK-$TASK_NUM"

TIMESTAMP=$(date +%Y-%m-%d)
TMP_FILE="${TASKS_FILE}.tmp"

# Helper: convert checkbox to checked (sed to temp file, then replace)
convert_checkbox() {
  local file="$1"
  local tid="$2"
  local tmp="${file}.sed"
  sed "s/- \[ \] $tid:/- [x] $tid:/" "$file" > "$tmp"
  mv "$tmp" "$file"
}

case "$LEVEL" in
  light)
    # Change - [ ] TASK-NNN: to - [x] TASK-NNN:
    if grep -q "\- \[ \] $TASK_ID:" "$TASKS_FILE"; then
      sed "s/- \[ \] $TASK_ID:/- [x] $TASK_ID:/" "$TASKS_FILE" > "$TMP_FILE"
      mv "$TMP_FILE" "$TASKS_FILE"
      echo "MARKED=done"
      echo "TASK=$TASK_ID"
      echo "LEVEL=$LEVEL"
    else
      echo "ERROR=task_not_found"
      echo "Pattern '- [ ] $TASK_ID:' not found in $TASKS_FILE"
      exit 1
    fi
    ;;

  standard)
    # Insert "Status: done" after the task header line
    if grep -q "$TASK_ID:" "$TASKS_FILE"; then
      FOUND="no"
      : > "$TMP_FILE"
      while IFS= read -r line; do
        echo "$line" >> "$TMP_FILE"
        if echo "$line" | grep -qE "(### $TASK_ID:|- \[ \] $TASK_ID:|\*\*$TASK_ID:)" 2>/dev/null; then
          FOUND="yes"
          echo "Status: done" >> "$TMP_FILE"
        fi
      done < "$TASKS_FILE"

      if [ "$FOUND" = "yes" ]; then
        convert_checkbox "$TMP_FILE" "$TASK_ID"
        mv "$TMP_FILE" "$TASKS_FILE"
        echo "MARKED=done"
        echo "TASK=$TASK_ID"
        echo "LEVEL=$LEVEL"
      else
        rm -f "$TMP_FILE"
        echo "ERROR=task_not_found"
        echo "Task $TASK_ID not found in $TASKS_FILE"
        exit 1
      fi
    else
      echo "ERROR=task_not_found"
      echo "Task $TASK_ID not found in $TASKS_FILE"
      exit 1
    fi
    ;;

  formal)
    # Insert "Status: done" and "Completed at: YYYY-MM-DD" after the header
    if grep -q "$TASK_ID:" "$TASKS_FILE"; then
      FOUND="no"
      : > "$TMP_FILE"
      while IFS= read -r line; do
        echo "$line" >> "$TMP_FILE"
        if echo "$line" | grep -qE "(### $TASK_ID:|- \[ \] $TASK_ID:|\*\*$TASK_ID:)" 2>/dev/null; then
          FOUND="yes"
          echo "Status: done" >> "$TMP_FILE"
          echo "Completed at: $TIMESTAMP" >> "$TMP_FILE"
        fi
      done < "$TASKS_FILE"

      if [ "$FOUND" = "yes" ]; then
        convert_checkbox "$TMP_FILE" "$TASK_ID"
        mv "$TMP_FILE" "$TASKS_FILE"
        echo "MARKED=done"
        echo "TASK=$TASK_ID"
        echo "LEVEL=$LEVEL"
        echo "COMPLETED_AT=$TIMESTAMP"
      else
        rm -f "$TMP_FILE"
        echo "ERROR=task_not_found"
        echo "Task $TASK_ID not found in $TASKS_FILE"
        exit 1
      fi
    else
      echo "ERROR=task_not_found"
      echo "Task $TASK_ID not found in $TASKS_FILE"
      exit 1
    fi
    ;;

  *)
    echo "ERROR=invalid_level"
    echo "Invalid level: $LEVEL (expected light|standard|formal)"
    exit 1
    ;;
esac

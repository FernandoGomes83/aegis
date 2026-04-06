#!/bin/bash
# aegis-sdd — Extract implementation context for a task from project artifacts
# Usage: aegis-build-context.sh <output_dir> <task_id>

set -euo pipefail

OUTPUT_DIR="${1:?Usage: aegis-build-context.sh <output_dir> <task_id>}"
TASK_ID="${2:?Missing task ID (e.g., TASK-001)}"

TASKS_FILE="$OUTPUT_DIR/tasks.md"
DESIGN_FILE="$OUTPUT_DIR/design.md"
TESTS_FILE="$OUTPUT_DIR/tests.md"

if [ ! -f "$TASKS_FILE" ]; then
  echo "ERROR=tasks_not_found"
  echo "File not found: $TASKS_FILE"
  exit 1
fi

# Normalize TASK_ID to ensure format TASK-NNN
TASK_NUM=$(echo "$TASK_ID" | grep -oE '[0-9]{3}' | head -1)
if [ -z "$TASK_NUM" ]; then
  echo "ERROR=invalid_task_id"
  echo "Invalid task ID format: $TASK_ID (expected TASK-NNN)"
  exit 1
fi
TASK_ID="TASK-$TASK_NUM"

# --- Extract task block from tasks.md ---

echo "===TASK_ENTRY==="

FOUND="no"
IN_BLOCK="no"

while IFS= read -r line; do
  # Detect start of our task (any format: Light, Standard, Formal)
  if echo "$line" | grep -qE "(- \[[ x]\] $TASK_ID:|### $TASK_ID:|\*\*$TASK_ID:)"; then
    FOUND="yes"
    IN_BLOCK="yes"
    echo "$line"
    continue
  fi

  # Detect start of next task (end of our block)
  if [ "$IN_BLOCK" = "yes" ]; then
    if echo "$line" | grep -qE '(- \[[ x]\] TASK-[0-9]{3}:|### TASK-[0-9]{3}:|\*\*TASK-[0-9]{3}:)'; then
      IN_BLOCK="no"
      continue
    fi
    # Also stop at major section headers
    if echo "$line" | grep -qE '^## ' && [ "$FOUND" = "yes" ]; then
      IN_BLOCK="no"
      continue
    fi
    echo "$line"
  fi
done < "$TASKS_FILE"

if [ "$FOUND" = "no" ]; then
  echo "(Task $TASK_ID not found in $TASKS_FILE)"
fi

# --- Extract referenced IDs from the task block ---

# Re-read the task block to find Implements and Tests/Validates references
IMPL_IDS=""
TEST_IDS=""
IN_BLOCK="no"

while IFS= read -r line; do
  if echo "$line" | grep -qE "(- \[[ x]\] $TASK_ID:|### $TASK_ID:|\*\*$TASK_ID:)"; then
    IN_BLOCK="yes"
    continue
  fi
  if [ "$IN_BLOCK" = "yes" ]; then
    if echo "$line" | grep -qE '(- \[[ x]\] TASK-[0-9]{3}:|### TASK-[0-9]{3}:|\*\*TASK-[0-9]{3}:|^## )'; then
      break
    fi
    # Implements: field
    if echo "$line" | grep -qiE '^\s*Implements:'; then
      ids=$(echo "$line" | grep -oE '(PROP-[0-9]{3}|SEC-PROP-[A-Z_-]+|REQ-[0-9]{3}|SEC-REQ-[A-Z_-]+|UI-[0-9]{3})' || true)
      IMPL_IDS="${IMPL_IDS:+$IMPL_IDS }$ids"
    fi
    # Tests: or Validates: field
    if echo "$line" | grep -qiE '^\s*(Tests|Validates):'; then
      ids=$(echo "$line" | grep -oE '(TEST-PROP-[0-9]{3}[A-Z-]*|TEST-SEC-[A-Z_-]+|TEST-E2E-[0-9]{3}[A-Z_-]*|TEST-INT-[0-9]{3})' || true)
      TEST_IDS="${TEST_IDS:+$TEST_IDS }$ids"
    fi
  fi
done < "$TASKS_FILE"

# --- Extract design context ---

echo "===DESIGN_CONTEXT==="

if [ -f "$DESIGN_FILE" ] && [ -n "$IMPL_IDS" ]; then
  for ref_id in $IMPL_IDS; do
    # Build a pattern to match the section header for this ID
    PATTERN=""
    case "$ref_id" in
      PROP-*)    PATTERN="$ref_id" ;;
      SEC-PROP-*) PATTERN="$ref_id" ;;
      REQ-*)     PATTERN="$ref_id" ;;
      SEC-REQ-*) PATTERN="$ref_id" ;;
      UI-*)      PATTERN="$ref_id" ;;
    esac

    if [ -z "$PATTERN" ]; then
      continue
    fi

    echo "--- $ref_id ---"

    # Extract from the ID reference to the next same-level heading or next ID
    EXTRACTING="no"
    while IFS= read -r line; do
      if echo "$line" | grep -qF "$PATTERN"; then
        EXTRACTING="yes"
        echo "$line"
        continue
      fi
      if [ "$EXTRACTING" = "yes" ]; then
        # Stop at next PROP/SEC-PROP/major section
        if echo "$line" | grep -qE '(^###\s+(PROP-[0-9]{3}|SEC-PROP-)|^## |^\*\*(PROP-[0-9]{3}|SEC-PROP-))'; then
          break
        fi
        echo "$line"
      fi
    done < "$DESIGN_FILE"

    if [ "$EXTRACTING" = "no" ]; then
      echo "(ID $ref_id not found in design.md)"
    fi
    echo ""
  done
else
  if [ ! -f "$DESIGN_FILE" ]; then
    echo "(design.md not found at $DESIGN_FILE)"
  else
    echo "(No Implements references found in task block)"
  fi
fi

# --- Extract test context ---

echo "===TEST_CONTEXT==="

if [ -f "$TESTS_FILE" ] && [ -n "$TEST_IDS" ]; then
  for test_id in $TEST_IDS; do
    echo "--- $test_id ---"

    EXTRACTING="no"
    while IFS= read -r line; do
      if echo "$line" | grep -qF "$test_id"; then
        EXTRACTING="yes"
        echo "$line"
        continue
      fi
      if [ "$EXTRACTING" = "yes" ]; then
        # Stop at next TEST-* heading or major section
        if echo "$line" | grep -qE '(^###\s+TEST-|^## |^\*\*TEST-)'; then
          break
        fi
        echo "$line"
      fi
    done < "$TESTS_FILE"

    if [ "$EXTRACTING" = "no" ]; then
      echo "(ID $test_id not found in tests.md)"
    fi
    echo ""
  done
elif [ -f "$TESTS_FILE" ]; then
  # No explicit test IDs — try to find tests matching our IMPL_IDS
  for ref_id in $IMPL_IDS; do
    # Derive likely test ID from implementation ID
    derived_test=""
    case "$ref_id" in
      PROP-*)     derived_test="TEST-$ref_id" ;;
      SEC-PROP-*) derived_test=$(echo "$ref_id" | sed 's/SEC-PROP-/TEST-SEC-/') ;;
    esac

    if [ -n "$derived_test" ]; then
      EXTRACTING="no"
      while IFS= read -r line; do
        if echo "$line" | grep -qF "$derived_test"; then
          if [ "$EXTRACTING" = "no" ]; then
            echo "--- $derived_test ---"
          fi
          EXTRACTING="yes"
          echo "$line"
          continue
        fi
        if [ "$EXTRACTING" = "yes" ]; then
          if echo "$line" | grep -qE '(^###\s+TEST-|^## |^\*\*TEST-)'; then
            break
          fi
          echo "$line"
        fi
      done < "$TESTS_FILE"
      if [ "$EXTRACTING" = "yes" ]; then
        echo ""
      fi
    fi
  done
else
  echo "(tests.md not found at $TESTS_FILE)"
fi

echo "===END==="

#!/bin/bash
# aegis-sdd — Extract implementation context for a task from project artifacts
# Usage: aegis-build-context.sh <output_dir> <task_id>

set -euo pipefail

OUTPUT_DIR="${1:?Usage: aegis-build-context.sh <output_dir> <task_id>}"
TASK_ID="${2:?Missing task ID (e.g., TASK-001)}"

FORCE_FRONTEND="${FORCE_FRONTEND:-0}"
FORCE_SECURITY="${FORCE_SECURITY:-0}"

TASKS_FILE="$OUTPUT_DIR/tasks.md"
DESIGN_FILE="$OUTPUT_DIR/design.md"
UI_DESIGN_FILE="$OUTPUT_DIR/ui-design.md"
TESTS_FILE="$OUTPUT_DIR/tests.md"
AEGIS_HOME_DIR=$(cd "$(dirname "$0")/.." && pwd)
SECURITY_DIR="$AEGIS_HOME_DIR/framework/security"

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

# --- Detect security references in task ---

HAS_SEC_REFS="no"
SEC_CATEGORIES=""
for id in $IMPL_IDS; do
  case "$id" in
    SEC-PROP-*|SEC-REQ-*)
      HAS_SEC_REFS="yes"
      cat_key=$(echo "$id" | sed 's/SEC-PROP-//;s/SEC-REQ-//' | sed 's/-[0-9]*$//')
      # Deduplicate
      case " $SEC_CATEGORIES " in
        *" $cat_key "*) ;;
        *) SEC_CATEGORIES="$SEC_CATEGORIES $cat_key" ;;
      esac
      ;;
  esac
done

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

# --- Extract UI design context (from ui-design.md) ---

echo "===UI_DESIGN_CONTEXT==="

HAS_UI_REFS="no"

if [ -f "$UI_DESIGN_FILE" ] && [ -n "$IMPL_IDS" ]; then
  for ref_id in $IMPL_IDS; do
    case "$ref_id" in
      UI-*) ;;
      *) continue ;;
    esac

    HAS_UI_REFS="yes"
    echo "--- $ref_id ---"

    EXTRACTING="no"
    while IFS= read -r line; do
      if echo "$line" | grep -qF "$ref_id"; then
        EXTRACTING="yes"
        echo "$line"
        continue
      fi
      if [ "$EXTRACTING" = "yes" ]; then
        if echo "$line" | grep -qE '(^###\s+UI-[0-9]{3}|^## |^\*\*UI-[0-9]{3})'; then
          break
        fi
        echo "$line"
      fi
    done < "$UI_DESIGN_FILE"

    if [ "$EXTRACTING" = "no" ]; then
      echo "(ID $ref_id not found in ui-design.md)"
    fi
    echo ""
  done
elif [ ! -f "$UI_DESIGN_FILE" ]; then
  echo "(ui-design.md not found)"
else
  echo "(No UI-NNN references in task)"
fi

# --- Frontend aesthetics context ---

echo "===FRONTEND_DESIGN_CONTEXT==="

AESTHETICS_FILE="$AEGIS_HOME_DIR/shared/frontend-aesthetics.md"

if [ "$FORCE_FRONTEND" = "1" ] || [ "$HAS_UI_REFS" = "yes" ]; then
  if [ -f "$AESTHETICS_FILE" ]; then
    cat "$AESTHETICS_FILE"
  else
    echo "(frontend-aesthetics.md not found at $AESTHETICS_FILE)"
  fi
else
  echo "(Skipped — no UI-NNN references and FORCE_FRONTEND not set)"
fi

# --- Security context ---

echo "===SECURITY_CONTEXT==="

# Helper: extract section N from SECURITY_UNIVERSAL.md
extract_sec_section() {
  local file="$1" section_num="$2"
  local in_section="no"
  while IFS= read -r line; do
    if echo "$line" | grep -qE "^## ${section_num}\\."; then
      in_section="yes"
    elif [ "$in_section" = "yes" ] && echo "$line" | grep -qE '^## [0-9]+\.'; then
      break
    fi
    [ "$in_section" = "yes" ] && echo "$line"
  done < "$file"
}

# Helper: extract YAML entry by ID
extract_yaml_entry() {
  local file="$1" entry_id="$2"
  local in_entry="no"
  while IFS= read -r line; do
    if echo "$line" | grep -qF "id: $entry_id"; then
      in_entry="yes"
    elif [ "$in_entry" = "yes" ] && echo "$line" | grep -qE '^[[:space:]]*- id:'; then
      break
    fi
    [ "$in_entry" = "yes" ] && echo "$line"
  done < "$file"
}

# Helper: map category key to SECURITY_UNIVERSAL section number
sec_category_to_section() {
  case "$1" in
    RACE)     echo 1 ;;
    IDOR)     echo 2 ;;
    INPUT)    echo 3 ;;
    UPLOAD)   echo 4 ;;
    TIMING)   echo 6 ;;
    AUTH|CSRF) echo 7 ;;
    HONEYPOT) echo 8 ;;
    HEADERS)  echo 9 ;;
    RATE)     echo 10 ;;
    PRIVACY)  echo 11 ;;
    DEPS)     echo 13 ;;
    *)        echo "" ;;
  esac
}

SEC_UNIVERSAL="$SECURITY_DIR/SECURITY_UNIVERSAL.md"
SEC_PROPS_YAML="$SECURITY_DIR/security-properties.yaml"
SEC_REQS_YAML="$SECURITY_DIR/security-requirements.yaml"

if [ ! -f "$SEC_UNIVERSAL" ]; then
  echo "(WARNING: SECURITY_UNIVERSAL.md not found at $SEC_UNIVERSAL — security context unavailable)"
elif [ "$HAS_SEC_REFS" = "yes" ] || [ "$FORCE_SECURITY" = "1" ]; then
  # Tier 2: relevant sections + YAML entries + always-on checklist
  EMITTED_SECTIONS=""
  for cat_key in $SEC_CATEGORIES; do
    sec_num=$(sec_category_to_section "$cat_key")
    if [ -n "$sec_num" ]; then
      # Deduplicate sections (AUTH and CSRF both map to §7)
      case " $EMITTED_SECTIONS " in
        *" $sec_num "*) continue ;;
      esac
      EMITTED_SECTIONS="$EMITTED_SECTIONS $sec_num"
      extract_sec_section "$SEC_UNIVERSAL" "$sec_num"
      echo ""
    fi
  done

  # YAML entries for referenced IDs
  if [ -f "$SEC_PROPS_YAML" ]; then
    echo "--- Security Properties (formal statements) ---"
    for id in $IMPL_IDS; do
      case "$id" in
        SEC-PROP-*) extract_yaml_entry "$SEC_PROPS_YAML" "$id" ; echo "" ;;
      esac
    done
  fi

  if [ -f "$SEC_REQS_YAML" ]; then
    echo "--- Security Requirements (criteria) ---"
    for id in $IMPL_IDS; do
      case "$id" in
        SEC-REQ-*) extract_yaml_entry "$SEC_REQS_YAML" "$id" ; echo "" ;;
      esac
    done
  fi

  # Related IDs: for each SEC-PROP, find the SEC-REQ it validates
  if [ -f "$SEC_PROPS_YAML" ] && [ -f "$SEC_REQS_YAML" ]; then
    for id in $IMPL_IDS; do
      case "$id" in
        SEC-PROP-*)
          validates_id=$(grep -A1 "id: $id" "$SEC_PROPS_YAML" 2>/dev/null \
            | grep 'validates:' | sed 's/.*validates:[[:space:]]*//' | head -1)
          if [ -n "$validates_id" ]; then
            # Only emit if not already in IMPL_IDS
            case " $IMPL_IDS " in
              *" $validates_id "*) ;;
              *) echo "--- Related: $validates_id ---"
                 extract_yaml_entry "$SEC_REQS_YAML" "$validates_id"
                 echo "" ;;
            esac
          fi
          ;;
      esac
    done
  fi

  # Always append checklist sections
  extract_sec_section "$SEC_UNIVERSAL" 14
  echo ""
  extract_sec_section "$SEC_UNIVERSAL" 15
  echo ""
  extract_sec_section "$SEC_UNIVERSAL" 16
else
  # Tier 1: compact checklist only
  echo "No SEC-PROP/SEC-REQ references in this task."
  echo "Apply this security checklist to any code you write:"
  echo ""
  extract_sec_section "$SEC_UNIVERSAL" 14
  echo ""
  extract_sec_section "$SEC_UNIVERSAL" 15
  echo ""
  extract_sec_section "$SEC_UNIVERSAL" 16
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

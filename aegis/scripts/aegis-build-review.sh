#!/bin/bash
# aegis-sdd — Lightweight artifact review for build checkpoints
# Usage: aegis-build-review.sh <output_dir> <task_ids_csv>
#
# Checks traceability, security stubs, and test alignment for recently
# completed tasks. Outputs delimited sections consumed by aegis-build-stop.sh.

set -uo pipefail

OUTPUT_DIR="${1:?Usage: aegis-build-review.sh <output_dir> <task_ids_csv>}"
TASK_IDS="${2:?Usage: aegis-build-review.sh <output_dir> <task_ids_csv>}"

TASKS_FILE="$OUTPUT_DIR/tasks.md"
DESIGN_FILE="$OUTPUT_DIR/design.md"
TESTS_FILE="$OUTPUT_DIR/tests.md"

if [ ! -f "$TASKS_FILE" ]; then
  echo "===REVIEW_SUMMARY==="
  echo "TRACEABILITY=skip"
  echo "SECURITY=skip"
  echo "TESTS=skip"
  echo "ISSUES=0"
  exit 0
fi

# --- Collect PROP, SEC-PROP, and TEST references from completed tasks ---

PROP_REFS=""
SEC_PROP_REFS=""
TEST_REFS=""

IFS=',' read -ra TASK_ARR <<< "$TASK_IDS"
for task_id in "${TASK_ARR[@]}"; do
  task_id=$(echo "$task_id" | tr -d ' ')
  [ -z "$task_id" ] && continue

  # Extract the Implements: line for this task
  task_num=$(echo "$task_id" | sed 's/TASK-//')
  impls=$(sed -n "/TASK-${task_num}/,/^\\(###\\|\\*\\*TASK-\\|- \\[\\)/p" "$TASKS_FILE" \
    | grep -i 'Implements:' | head -1 | sed 's/.*Implements:[[:space:]]*//' || true)

  # Extract PROP-NNN references
  props=$(echo "$impls" | grep -oE 'PROP-[0-9]{3}' || true)
  for p in $props; do
    case ",$PROP_REFS," in
      *",$p,"*) ;;
      *) PROP_REFS="${PROP_REFS:+$PROP_REFS,}$p" ;;
    esac
  done

  # Extract SEC-PROP-* references
  sec_props=$(echo "$impls" | grep -oE 'SEC-PROP-[A-Z_-]+' || true)
  for sp in $sec_props; do
    case ",$SEC_PROP_REFS," in
      *",$sp,"*) ;;
      *) SEC_PROP_REFS="${SEC_PROP_REFS:+$SEC_PROP_REFS,}$sp" ;;
    esac
  done

  # Extract Tests: line for this task
  tests=$(sed -n "/TASK-${task_num}/,/^\\(###\\|\\*\\*TASK-\\|- \\[\\)/p" "$TASKS_FILE" \
    | grep -i 'Tests:' | head -1 | sed 's/.*Tests:[[:space:]]*//' || true)

  test_ids=$(echo "$tests" | grep -oE 'TEST-[A-Z]+-[A-Z0-9_-]+' || true)
  for t in $test_ids; do
    case ",$TEST_REFS," in
      *",$t,"*) ;;
      *) TEST_REFS="${TEST_REFS:+$TEST_REFS,}$t" ;;
    esac
  done
done

# --- 1. Traceability check ---
# Verify each PROP-NNN appears somewhere in the project source

TRACE_PASS=0
TRACE_WARN=0
TRACE_DETAIL=""

if [ -n "$PROP_REFS" ]; then
  IFS=',' read -ra PARR <<< "$PROP_REFS"
  for prop in "${PARR[@]}"; do
    prop=$(echo "$prop" | tr -d ' ')
    [ -z "$prop" ] && continue
    # Search project source (exclude .aegis output dir and .git)
    found=$(grep -rl "$prop" . --include='*.ts' --include='*.tsx' --include='*.js' --include='*.jsx' \
      --include='*.py' --include='*.go' --include='*.rs' --include='*.java' --include='*.rb' \
      --include='*.cs' --include='*.swift' --include='*.kt' \
      2>/dev/null | grep -v '\.aegis/' | grep -v '\.git/' | head -1 || true)
    if [ -n "$found" ]; then
      TRACE_PASS=$((TRACE_PASS + 1))
      TRACE_DETAIL="${TRACE_DETAIL}| $prop | PASS | Found in $found |\n"
    else
      TRACE_WARN=$((TRACE_WARN + 1))
      TRACE_DETAIL="${TRACE_DETAIL}| $prop | WARN | Not found in project source |\n"
    fi
  done
fi

TRACE_TOTAL=$((TRACE_PASS + TRACE_WARN))
if [ "$TRACE_TOTAL" -eq 0 ]; then
  TRACE_STATUS="skip"
elif [ "$TRACE_WARN" -eq 0 ]; then
  TRACE_STATUS="pass"
else
  TRACE_STATUS="warn"
fi

# --- 2. Security stub check ---
# Verify SEC-PROP-* implementations don't contain TODO/FIXME stubs

SEC_PASS=0
SEC_WARN=0
SEC_DETAIL=""
SEC_ACTIONS=""

if [ -n "$SEC_PROP_REFS" ]; then
  IFS=',' read -ra SARR <<< "$SEC_PROP_REFS"
  for sec_prop in "${SARR[@]}"; do
    sec_prop=$(echo "$sec_prop" | tr -d ' ')
    [ -z "$sec_prop" ] && continue
    # Find files referencing this SEC-PROP
    ref_files=$(grep -rl "$sec_prop" . --include='*.ts' --include='*.tsx' --include='*.js' --include='*.jsx' \
      --include='*.py' --include='*.go' --include='*.rs' --include='*.java' --include='*.rb' \
      --include='*.cs' --include='*.swift' --include='*.kt' \
      2>/dev/null | grep -v '\.aegis/' | grep -v '\.git/' || true)

    if [ -z "$ref_files" ]; then
      SEC_WARN=$((SEC_WARN + 1))
      SEC_DETAIL="${SEC_DETAIL}| $sec_prop | WARN | Not found in project source |\n"
      SEC_ACTIONS="${SEC_ACTIONS}- $sec_prop: no implementation found in source\n"
      continue
    fi

    # Check for stubs in those files
    has_stub="no"
    stub_location=""
    for f in $ref_files; do
      stub_match=$(grep -nE '(TODO|FIXME|HACK|stub|placeholder|not.implemented)' "$f" 2>/dev/null | head -1 || true)
      if [ -n "$stub_match" ]; then
        has_stub="yes"
        stub_location="$f:$(echo "$stub_match" | cut -d: -f1)"
        break
      fi
    done

    if [ "$has_stub" = "yes" ]; then
      SEC_WARN=$((SEC_WARN + 1))
      SEC_DETAIL="${SEC_DETAIL}| $sec_prop | WARN | Stub found at $stub_location |\n"
      SEC_ACTIONS="${SEC_ACTIONS}- $sec_prop: replace stub at $stub_location\n"
    else
      SEC_PASS=$((SEC_PASS + 1))
      SEC_DETAIL="${SEC_DETAIL}| $sec_prop | PASS | Implemented without stubs |\n"
    fi
  done
fi

SEC_TOTAL=$((SEC_PASS + SEC_WARN))
if [ "$SEC_TOTAL" -eq 0 ]; then
  SEC_STATUS="skip"
elif [ "$SEC_WARN" -eq 0 ]; then
  SEC_STATUS="pass"
else
  SEC_STATUS="warn"
fi

# --- 3. Test file existence and assertion check ---

TEST_PASS=0
TEST_WARN=0
TEST_DETAIL=""
TEST_ACTIONS=""

if [ -n "$TEST_REFS" ]; then
  IFS=',' read -ra TARR <<< "$TEST_REFS"
  for test_ref in "${TARR[@]}"; do
    test_ref=$(echo "$test_ref" | tr -d ' ')
    [ -z "$test_ref" ] && continue
    # Find test files referencing this TEST-* ID
    test_files=$(grep -rl "$test_ref" . --include='*.test.*' --include='*.spec.*' --include='*_test.*' \
      --include='test_*' --include='*.test.ts' --include='*.test.js' --include='*.spec.ts' \
      --include='*.spec.js' --include='*.test.py' --include='*_test.go' \
      2>/dev/null | grep -v '\.aegis/' | grep -v '\.git/' | grep -v 'node_modules/' || true)

    if [ -z "$test_files" ]; then
      TEST_WARN=$((TEST_WARN + 1))
      TEST_DETAIL="${TEST_DETAIL}| $test_ref | WARN | No test file found |\n"
      TEST_ACTIONS="${TEST_ACTIONS}- $test_ref: test file missing\n"
      continue
    fi

    # Check if test files have assertions
    has_assertions="no"
    for tf in $test_files; do
      if grep -qE '(assert|expect|should|must|verify|check)\s*[\.(]' "$tf" 2>/dev/null; then
        has_assertions="yes"
        break
      fi
    done

    if [ "$has_assertions" = "yes" ]; then
      TEST_PASS=$((TEST_PASS + 1))
      TEST_DETAIL="${TEST_DETAIL}| $test_ref | PASS | Test file exists with assertions |\n"
    else
      TEST_WARN=$((TEST_WARN + 1))
      TEST_DETAIL="${TEST_DETAIL}| $test_ref | WARN | Test file exists but no assertions found |\n"
      TEST_ACTIONS="${TEST_ACTIONS}- $test_ref: test file has no assertions\n"
    fi
  done
fi

TEST_TOTAL=$((TEST_PASS + TEST_WARN))
if [ "$TEST_TOTAL" -eq 0 ]; then
  TEST_STATUS="skip"
elif [ "$TEST_WARN" -eq 0 ]; then
  TEST_STATUS="pass"
else
  TEST_STATUS="warn"
fi

# --- 4. Aggregate and output ---

TOTAL_ISSUES=$((TRACE_WARN + SEC_WARN + TEST_WARN))

# Build summary line for build-progress.md
TRACE_SUMMARY=""
if [ "$TRACE_STATUS" != "skip" ]; then
  TRACE_SUMMARY="$TRACE_PASS/$TRACE_TOTAL PROP references found"
fi
SEC_SUMMARY=""
if [ "$SEC_STATUS" != "skip" ]; then
  SEC_SUMMARY="$SEC_PASS/$SEC_TOTAL SEC-PROP clean"
fi
TEST_SUMMARY=""
if [ "$TEST_STATUS" != "skip" ]; then
  TEST_SUMMARY="$TEST_PASS/$TEST_TOTAL test refs verified"
fi

echo "===REVIEW_SUMMARY==="
echo "TRACEABILITY=$TRACE_STATUS"
echo "SECURITY=$SEC_STATUS"
echo "TESTS=$TEST_STATUS"
echo "ISSUES=$TOTAL_ISSUES"

echo "===REVIEW_DETAIL==="
echo "| Check | Status | Detail |"
echo "|-------|--------|--------|"
[ -n "$TRACE_SUMMARY" ] && echo "| Traceability | $(echo "$TRACE_STATUS" | tr '[:lower:]' '[:upper:]') | $TRACE_SUMMARY |"
[ -n "$SEC_SUMMARY" ] && echo "| Security | $(echo "$SEC_STATUS" | tr '[:lower:]' '[:upper:]') | $SEC_SUMMARY |"
[ -n "$TEST_SUMMARY" ] && echo "| Tests | $(echo "$TEST_STATUS" | tr '[:lower:]' '[:upper:]') | $TEST_SUMMARY |"
if [ -n "$TRACE_DETAIL" ] || [ -n "$SEC_DETAIL" ] || [ -n "$TEST_DETAIL" ]; then
  echo ""
  echo "| Item | Status | Detail |"
  echo "|------|--------|--------|"
  [ -n "$TRACE_DETAIL" ] && printf "%b" "$TRACE_DETAIL"
  [ -n "$SEC_DETAIL" ] && printf "%b" "$SEC_DETAIL"
  [ -n "$TEST_DETAIL" ] && printf "%b" "$TEST_DETAIL"
fi

echo "===ACTION_ITEMS==="
ALL_ACTIONS="${SEC_ACTIONS}${TEST_ACTIONS}${TRACE_DETAIL:+}"
if [ "$TOTAL_ISSUES" -gt 0 ]; then
  [ -n "$SEC_ACTIONS" ] && printf "%b" "$SEC_ACTIONS"
  [ -n "$TEST_ACTIONS" ] && printf "%b" "$TEST_ACTIONS"
  # Only include traceability warnings as action items if there are no other issues
  if [ "$SEC_WARN" -eq 0 ] && [ "$TEST_WARN" -eq 0 ] && [ "$TRACE_WARN" -gt 0 ]; then
    IFS=',' read -ra PARR <<< "$PROP_REFS"
    for prop in "${PARR[@]}"; do
      prop=$(echo "$prop" | tr -d ' ')
      found=$(grep -rl "$prop" . --include='*.ts' --include='*.tsx' --include='*.js' --include='*.jsx' \
        --include='*.py' --include='*.go' --include='*.rs' --include='*.java' \
        2>/dev/null | grep -v '\.aegis/' | grep -v '\.git/' | head -1 || true)
      [ -z "$found" ] && echo "- $prop: no reference found in project source"
    done
  fi
else
  echo "No issues found."
fi

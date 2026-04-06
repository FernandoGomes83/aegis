#!/bin/bash
# aegis-sdd — Run test framework and report structured results
# Usage: aegis-run-tests.sh <framework> <test_dir>

set -uo pipefail

FRAMEWORK="${1:?Usage: aegis-run-tests.sh <framework> <test_dir>}"
TEST_DIR="${2:?Missing test directory}"

# Map framework name to command
case "$FRAMEWORK" in
  vitest)   CMD="npx vitest run" ;;
  jest)     CMD="npx jest" ;;
  pytest)   CMD="python -m pytest" ;;
  go)       CMD="go test" ;;
  rspec)    CMD="bundle exec rspec" ;;
  mocha)    CMD="npx mocha" ;;
  *)
    echo "ERROR=unknown_framework"
    echo "Unknown test framework: $FRAMEWORK"
    echo "Supported: vitest, jest, pytest, go, rspec, mocha"
    exit 2
    ;;
esac

# Extract the base command for existence check
BASE_CMD=$(echo "$CMD" | awk '{print $1}')
if ! command -v "$BASE_CMD" &>/dev/null; then
  echo "ERROR=command_not_found"
  echo "Command not found: $BASE_CMD"
  echo "Ensure the test framework is installed."
  exit 2
fi

# Adjust test dir for Go's module pattern
if [ "$FRAMEWORK" = "go" ]; then
  if [[ "$TEST_DIR" = /* ]]; then
    TEST_DIR="${TEST_DIR}..."
  else
    TEST_DIR="./$TEST_DIR..."
  fi
fi

# Run tests with timeout (default 300s / 5 minutes)
TIMEOUT_SECS="${AEGIS_TEST_TIMEOUT:-300}"

if command -v timeout &>/dev/null; then
  timeout "$TIMEOUT_SECS" $CMD "$TEST_DIR" 2>&1
elif command -v perl &>/dev/null; then
  perl -e "alarm $TIMEOUT_SECS; exec @ARGV" $CMD "$TEST_DIR" 2>&1
else
  $CMD "$TEST_DIR" 2>&1
fi
EXIT_CODE=$?

if [ $EXIT_CODE -eq 124 ] || [ $EXIT_CODE -eq 142 ]; then
  echo ""
  echo "ERROR=timeout"
  echo "Tests exceeded ${TIMEOUT_SECS}s timeout."
fi

# Structured summary
echo ""
echo "---AEGIS_TEST_SUMMARY---"
echo "EXIT_CODE=$EXIT_CODE"
echo "FRAMEWORK=$FRAMEWORK"
echo "TEST_DIR=$TEST_DIR"

exit $EXIT_CODE

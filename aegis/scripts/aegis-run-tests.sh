#!/bin/bash
# aegis-sdd v1.3.0 — Run test framework and report structured results
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
  TEST_DIR="./$TEST_DIR..."
fi

# Run tests
$CMD "$TEST_DIR" 2>&1
EXIT_CODE=$?

# Structured summary
echo ""
echo "---AEGIS_TEST_SUMMARY---"
echo "EXIT_CODE=$EXIT_CODE"
echo "FRAMEWORK=$FRAMEWORK"
echo "TEST_DIR=$TEST_DIR"

exit $EXIT_CODE

#!/bin/bash
# aegis-sdd — Context7 batch lookup: resolve + fetch docs for all libraries
# Usage: aegis-context7.sh <api_key> <query> <lib1> [lib2] ...
# Output: plain text with === delimiters (no JSON)

set -uo pipefail

if ! command -v curl &>/dev/null; then
  echo "ERROR: curl is required but not found in PATH."
  exit 1
fi

API_KEY="${1:?Usage: aegis-context7.sh <api_key> <query> <lib1> [lib2] ...}"
QUERY="${2:?Missing query}"
shift 2

if [ $# -eq 0 ]; then
  echo "ERROR: No library names provided."
  exit 1
fi

LIBS=("$@")
BASE_URL="https://context7.com/api/v2"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# --- Pre-flight: validate API key before spawning parallel requests ---
preflight_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 \
  -H "Authorization: Bearer $API_KEY" \
  -G --data-urlencode "query=react" \
  "$BASE_URL/libs/search" 2>/dev/null || echo "000")
if [ "$preflight_code" = "401" ] || [ "$preflight_code" = "403" ]; then
  echo "ERROR: Context7 API key is invalid or expired. Check CONTEXT7_API_KEY in .env."
  exit 1
fi
if [ "$preflight_code" = "000" ]; then
  echo "ERROR: Context7 API is unreachable. Check network connectivity."
  exit 1
fi

TOTAL=${#LIBS[@]}
RESOLVED=0
FAILED=0

# --- Phase 1: Resolve library IDs (parallel) ---

for i in "${!LIBS[@]}"; do
  lib="${LIBS[$i]}"
  (
    response=$(curl -s -w "\n%{http_code}" --max-time 10 -G \
      -H "Authorization: Bearer $API_KEY" \
      --data-urlencode "query=$lib" \
      "$BASE_URL/libs/search" 2>/dev/null || echo -e "\n000")

    http_code=$(echo "$response" | tail -1)
    body=$(echo "$response" | sed '$d')

    echo "$http_code" > "$TMPDIR/phase1_${i}_status"
    echo "$body" > "$TMPDIR/phase1_${i}_body"
  ) &
done
wait

# Check for auth failure in any response
for i in "${!LIBS[@]}"; do
  status_file="$TMPDIR/phase1_${i}_status"
  [ -f "$status_file" ] || continue
  code=$(cat "$status_file")
  if [ "$code" = "401" ] || [ "$code" = "403" ]; then
    echo "ERROR: Context7 API key is invalid or expired. Check CONTEXT7_API_KEY in .env."
    exit 1
  fi
done

# Extract library IDs from Phase 1 results (using temp files for bash 3.2 compat)

for i in "${!LIBS[@]}"; do
  status_file="$TMPDIR/phase1_${i}_status"
  body_file="$TMPDIR/phase1_${i}_body"

  [ -f "$status_file" ] || continue

  code=$(cat "$status_file")
  body=$(cat "$body_file")

  if [ "$code" != "200" ]; then
    echo "not_found" > "$TMPDIR/result_${i}"
    continue
  fi

  # Extract first library ID — try jq, fall back to grep
  lib_id=""
  if command -v jq &>/dev/null; then
    lib_id=$(echo "$body" | jq -r '.results[0].id // .[0].id // empty' 2>/dev/null || true)
  fi
  if [ -z "$lib_id" ]; then
    lib_id=$(echo "$body" | grep -o '"id"\s*:\s*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"$/\1/' || true)
  fi

  if [ -z "$lib_id" ]; then
    echo "not_found" > "$TMPDIR/result_${i}"
  else
    echo "$lib_id" > "$TMPDIR/libid_${i}"
  fi
done

# --- Phase 2: Fetch documentation (parallel) ---

for i in "${!LIBS[@]}"; do
  [ -f "$TMPDIR/libid_${i}" ] || continue
  lib_id=$(cat "$TMPDIR/libid_${i}")
  (
    response=$(curl -s -w "\n%{http_code}" --max-time 15 -G \
      -H "Authorization: Bearer $API_KEY" \
      --data-urlencode "libraryId=$lib_id" \
      --data-urlencode "query=$QUERY" \
      --data-urlencode "type=txt" \
      "$BASE_URL/context" 2>/dev/null || echo -e "\n000")

    http_code=$(echo "$response" | tail -1)
    body=$(echo "$response" | sed '$d')

    if [ "$http_code" = "200" ]; then
      echo "$body" > "$TMPDIR/result_${i}"
    else
      echo "fetch_failed" > "$TMPDIR/result_${i}"
    fi
  ) &
done
wait

# --- Assemble plain text output ---

for i in "${!LIBS[@]}"; do
  lib="${LIBS[$i]}"
  result_file="$TMPDIR/result_${i}"

  if [ -f "$result_file" ]; then
    content=$(cat "$result_file")
    if [ "$content" = "not_found" ] || [ "$content" = "fetch_failed" ]; then
      FAILED=$((FAILED + 1))
      echo "=== FAILED: $lib ($content) ==="
      echo ""
    else
      RESOLVED=$((RESOLVED + 1))
      lib_id="unknown"
      [ -f "$TMPDIR/libid_${i}" ] && lib_id=$(cat "$TMPDIR/libid_${i}")
      echo "=== $lib [$lib_id] ==="
      echo "$content"
      echo ""
    fi
  else
    FAILED=$((FAILED + 1))
    echo "=== FAILED: $lib (no_response) ==="
    echo ""
  fi
done

echo "--- SUMMARY: $RESOLVED/$TOTAL resolved, $FAILED failed ---"

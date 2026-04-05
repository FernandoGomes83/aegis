#!/bin/bash
# aegis-sdd v1.3.0 — Context7 batch lookup: resolve + fetch docs for all libraries
# Usage: aegis-context7.sh <api_key> <topic> <tokens_per_lib> <lib1> [lib2] ...

set -uo pipefail

API_KEY="${1:?Usage: aegis-context7.sh <api_key> <topic> <tokens_per_lib> <lib1> [lib2] ...}"
TOPIC="${2:?Missing topic}"
TOKENS="${3:?Missing tokens_per_lib}"
shift 3

if [ $# -eq 0 ]; then
  echo '{"error":"no_libraries","message":"No library names provided."}'
  exit 1
fi

LIBS=("$@")
BASE_URL="https://context7.com/api/v2"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

AUTH_FAILED=false
TOTAL=${#LIBS[@]}
RESOLVED=0
FAILED=0

# --- Phase 1: Resolve library IDs (parallel) ---

for i in "${!LIBS[@]}"; do
  lib="${LIBS[$i]}"
  (
    response=$(curl -s -w "\n%{http_code}" --max-time 10 \
      -H "Authorization: Bearer $API_KEY" \
      "$BASE_URL/libs/search?query=$lib" 2>/dev/null || echo -e "\n000")

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
    AUTH_FAILED=true
    break
  fi
done

if [ "$AUTH_FAILED" = true ]; then
  echo '{"error":"auth_failed","message":"Context7 API key is invalid or expired. Check CONTEXT7_API_KEY in .env."}'
  exit 1
fi

# Extract library IDs from Phase 1 results
declare -A LIB_IDS

for i in "${!LIBS[@]}"; do
  lib="${LIBS[$i]}"
  status_file="$TMPDIR/phase1_${i}_status"
  body_file="$TMPDIR/phase1_${i}_body"

  [ -f "$status_file" ] || { FAILED=$((FAILED + 1)); continue; }

  code=$(cat "$status_file")
  body=$(cat "$body_file")

  if [ "$code" != "200" ]; then
    FAILED=$((FAILED + 1))
    echo "not_found" > "$TMPDIR/result_${i}"
    continue
  fi

  # Extract first library ID — try jq, fall back to grep
  lib_id=""
  if command -v jq &>/dev/null; then
    lib_id=$(echo "$body" | jq -r '.[0].id // empty' 2>/dev/null || true)
  fi
  if [ -z "$lib_id" ]; then
    lib_id=$(echo "$body" | grep -o '"id"\s*:\s*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"$/\1/' || true)
  fi

  if [ -z "$lib_id" ]; then
    FAILED=$((FAILED + 1))
    echo "not_found" > "$TMPDIR/result_${i}"
  else
    LIB_IDS[$i]="$lib_id"
  fi
done

# --- Phase 2: Fetch documentation (parallel) ---

for i in "${!LIB_IDS[@]}"; do
  lib_id="${LIB_IDS[$i]}"
  encoded_topic=$(printf '%s' "$TOPIC" | sed 's/ /%20/g; s/,/%2C/g')
  (
    response=$(curl -s -w "\n%{http_code}" --max-time 15 \
      -H "Authorization: Bearer $API_KEY" \
      "$BASE_URL/context?libraryId=$lib_id&topic=$encoded_topic&tokens=$TOKENS" 2>/dev/null || echo -e "\n000")

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

# --- Assemble JSON output ---

echo "{"
echo '  "results": {'

first=true
for i in "${!LIBS[@]}"; do
  lib="${LIBS[$i]}"
  result_file="$TMPDIR/result_${i}"

  if [ "$first" = true ]; then
    first=false
  else
    echo ","
  fi

  if [ -f "$result_file" ]; then
    content=$(cat "$result_file")
    if [ "$content" = "not_found" ] || [ "$content" = "fetch_failed" ]; then
      FAILED=$((FAILED + 1))
      printf '    "%s": {"status": "%s"}' "$lib" "$content"
    else
      RESOLVED=$((RESOLVED + 1))
      lib_id="${LIB_IDS[$i]:-unknown}"
      # Escape content for JSON: backslashes, quotes, newlines, tabs
      escaped=$(printf '%s' "$content" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g' | tr '\n' '\a' | sed 's/\a/\\n/g')
      printf '    "%s": {"status": "ok", "library_id": "%s", "content": "%s"}' "$lib" "$lib_id" "$escaped"
    fi
  else
    FAILED=$((FAILED + 1))
    printf '    "%s": {"status": "not_found"}' "$lib"
  fi
done

echo ""
echo "  },"
printf '  "summary": {"total": %d, "resolved": %d, "failed": %d}\n' "$TOTAL" "$RESOLVED" "$FAILED"
echo "}"

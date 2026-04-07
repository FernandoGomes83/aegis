#!/bin/bash
# aegis-sdd — Code quality pass
# Removes common AI-generated code patterns from changed files.
#
# Usage: aegis-build-quality.sh [--dry-run]
# Output: CLEANED=N  PATTERNS=P1,P2,...
#
# Pattern catalog:
#   P1  Obvious restating comments    (// get the value, # set counter)
#   P2  Empty docstrings / JSDoc      (/** */, """""")
#   P3  Removed-code comments         (// removed, # deleted)
#   P4  TODO placeholder comments     (// TODO: implement)
#   P5  Excessive blank lines         (3+ consecutive → 2)
#   P6  Trailing summary comments     (// End of module)
#
# Config (in .aegis/config.yaml under build:):
#   qualityPass: true|false   (default: true)
#   qualityPatterns: "all" | "P1,P2,P5"

set -uo pipefail

DRY_RUN="no"
[ "${1:-}" = "--dry-run" ] && DRY_RUN="yes"

OUTPUT_DIR="${AEGIS_OUTPUT_DIR:-.aegis}"
CONFIG="$OUTPUT_DIR/config.yaml"

# --- Config ---
QP_ENABLED="true"
QP_PATTERNS="all"
if [ -f "$CONFIG" ]; then
  v=$(sed -n 's/^[[:space:]]*qualityPass:[[:space:]]*//p' "$CONFIG" | head -1 | tr -d "\"'")
  case "${v:-}" in false|no|0) QP_ENABLED="false" ;; esac
  p=$(sed -n 's/^[[:space:]]*qualityPatterns:[[:space:]]*//p' "$CONFIG" | head -1 | tr -d "\"'")
  [ -n "${p:-}" ] && QP_PATTERNS="$p"
fi

if [ "$QP_ENABLED" = "false" ]; then
  echo "CLEANED=0"
  echo "PATTERNS="
  exit 0
fi

# --- Collect changed files ---
# Files from the last commit (build agent commits before signaling TASK_COMPLETE)
COMMITTED=$(git diff-tree --no-commit-id --name-only -r HEAD 2>/dev/null || true)
# Plus any uncommitted changes (safety net)
UNCOMMITTED=$(git diff --name-only 2>/dev/null || true)
STAGED=$(git diff --cached --name-only 2>/dev/null || true)
ALL=$(printf '%s\n%s\n%s' "$COMMITTED" "$UNCOMMITTED" "$STAGED" | sort -u | sed '/^$/d')

if [ -z "$ALL" ]; then
  echo "CLEANED=0"
  echo "PATTERNS="
  exit 0
fi

# --- Filter to eligible code files ---
SKIP_EXT='\.(md|yaml|yml|json|lock|toml|svg|png|jpg|jpeg|gif|ico|webp|woff2?|ttf|eot|map|min\.js|min\.css)$'
SKIP_DIR='^(node_modules|dist|build|\.next|vendor|__pycache__|\.git|coverage|\.aegis)/'
CODE_EXT='\.(js|jsx|ts|tsx|mjs|cjs|py|rb|go|rs|java|kt|swift|c|cpp|h|hpp|cs|php|vue|svelte|css|scss|less|html|sh|bash|zsh|sql|graphql|prisma|ex|exs|lua|dart|scala)$'
MAX_LINES=500

FILES=""
while IFS= read -r f; do
  [ -z "$f" ] && continue
  [ ! -f "$f" ] && continue
  echo "$f" | grep -qE "$SKIP_EXT" && continue
  echo "$f" | grep -qE "$SKIP_DIR" && continue
  lc=$(wc -l < "$f" 2>/dev/null | tr -d ' ')
  [ "${lc:-0}" -gt "$MAX_LINES" ] && continue
  # Skip binary files (always include known code extensions)
  if ! echo "$f" | grep -qiE "$CODE_EXT"; then
    file --mime "$f" 2>/dev/null | grep -qv 'text/' && continue
  fi
  FILES="${FILES}${f}
"
done <<< "$ALL"

FILES=$(echo "$FILES" | sed '/^$/d')
if [ -z "$FILES" ]; then
  echo "CLEANED=0"
  echo "PATTERNS="
  exit 0
fi

# --- Pattern helpers ---
pat_on() {
  [ "$QP_PATTERNS" = "all" ] && return 0
  echo ",$QP_PATTERNS," | grep -q ",$1,"
}

TOTAL_CLEANED=0
ALL_PAT=""

while IFS= read -r file; do
  [ -z "$file" ] && continue

  TMP=$(mktemp)
  cp "$file" "$TMP"
  FPAT=""

  # P1: Obvious restating comments (// get the value, # set counter)
  if pat_on "P1"; then
    S=$(cksum "$TMP" | cut -d' ' -f1)
    sed -E '/^[[:space:]]*\/\/[[:space:]]*(get|set|return|increment|decrement|initialize|create|update|delete|import|define|declare|assign|call|invoke|check|ensure|make|add)[[:space:]]+(the[[:space:]]+)?[[:alnum:]_]+[[:space:]]*$/d' \
      "$TMP" > "${TMP}.o" && mv "${TMP}.o" "$TMP"
    sed -E '/^[[:space:]]*#[[:space:]]*(get|set|return|increment|decrement|initialize|create|update|delete|import|define|declare|assign|call|invoke|check|ensure|make|add)[[:space:]]+(the[[:space:]]+)?[[:alnum:]_]+[[:space:]]*$/d' \
      "$TMP" > "${TMP}.o" && mv "${TMP}.o" "$TMP"
    [ "$S" != "$(cksum "$TMP" | cut -d' ' -f1)" ] && FPAT="${FPAT:+$FPAT,}P1"
  fi

  # P2: Empty docstrings / JSDoc blocks
  if pat_on "P2"; then
    S=$(cksum "$TMP" | cut -d' ' -f1)
    # Single-line empty JSDoc: /** */ or /***/
    sed -E '/^[[:space:]]*\/\*\*[[:space:]]*\**\/[[:space:]]*$/d' \
      "$TMP" > "${TMP}.o" && mv "${TMP}.o" "$TMP"
    # Two-line empty JSDoc: /** then */
    awk '
      prev ~ /^[[:space:]]*\/\*\*[[:space:]]*$/ && $0 ~ /^[[:space:]]*\*?\*\/[[:space:]]*$/ {
        prev = ""; next
      }
      prev != "" { print prev }
      { prev = $0 }
      END { if (prev != "") print prev }
    ' "$TMP" > "${TMP}.o" && mv "${TMP}.o" "$TMP"
    # Three-line empty JSDoc: /** then * (blank) then */
    awk '
      BEGIN { p1 = ""; p2 = "" }
      NR > 2 {
        if (p1 ~ /^[[:space:]]*\/\*\*[[:space:]]*$/ && \
            p2 ~ /^[[:space:]]*\*[[:space:]]*$/ && \
            $0 ~ /^[[:space:]]*\*\/[[:space:]]*$/) {
          p1 = ""; p2 = ""; next
        }
        if (p1 != "") print p1
        p1 = p2; p2 = $0; next
      }
      { if (NR == 1) p1 = $0; else p2 = $0 }
      END { if (p1 != "") print p1; if (p2 != "") print p2 }
    ' "$TMP" > "${TMP}.o" && mv "${TMP}.o" "$TMP"
    # Single-line empty Python docstring: """"""
    sed -E '/^[[:space:]]*""""""[[:space:]]*$/d' \
      "$TMP" > "${TMP}.o" && mv "${TMP}.o" "$TMP"
    # Two-line empty Python docstring: """ then """
    awk '
      prev ~ /^[[:space:]]*"""[[:space:]]*$/ && $0 ~ /^[[:space:]]*"""[[:space:]]*$/ {
        prev = ""; next
      }
      prev != "" { print prev }
      { prev = $0 }
      END { if (prev != "") print prev }
    ' "$TMP" > "${TMP}.o" && mv "${TMP}.o" "$TMP"
    [ "$S" != "$(cksum "$TMP" | cut -d' ' -f1)" ] && FPAT="${FPAT:+$FPAT,}P2"
  fi

  # P3: Removed-code comments (case-insensitive via awk)
  if pat_on "P3"; then
    S=$(cksum "$TMP" | cut -d' ' -f1)
    awk '
      tolower($0) ~ /^[[:space:]]*(\/\/|#)[[:space:]]*(removed|deleted|no longer needed|no longer used|was removed|previously removed)[[:space:]]*$/ { next }
      { print }
    ' "$TMP" > "${TMP}.o" && mv "${TMP}.o" "$TMP"
    [ "$S" != "$(cksum "$TMP" | cut -d' ' -f1)" ] && FPAT="${FPAT:+$FPAT,}P3"
  fi

  # P4: TODO placeholder comments
  if pat_on "P4"; then
    S=$(cksum "$TMP" | cut -d' ' -f1)
    sed -E '/^[[:space:]]*(\/\/|#)[[:space:]]*TODO:[[:space:]]*(implement|add|fill in|complete|finish|write)[[:space:]]*.*$/d' \
      "$TMP" > "${TMP}.o" && mv "${TMP}.o" "$TMP"
    [ "$S" != "$(cksum "$TMP" | cut -d' ' -f1)" ] && FPAT="${FPAT:+$FPAT,}P4"
  fi

  # P5: Excessive blank lines (3+ consecutive → 2)
  if pat_on "P5"; then
    S=$(cksum "$TMP" | cut -d' ' -f1)
    awk '
      /^[[:space:]]*$/ { blank++; if (blank <= 2) print; next }
      { blank = 0; print }
    ' "$TMP" > "${TMP}.o" && mv "${TMP}.o" "$TMP"
    [ "$S" != "$(cksum "$TMP" | cut -d' ' -f1)" ] && FPAT="${FPAT:+$FPAT,}P5"
  fi

  # P6: Trailing summary comments (case-insensitive via awk)
  if pat_on "P6"; then
    S=$(cksum "$TMP" | cut -d' ' -f1)
    awk '
      tolower($0) ~ /^[[:space:]]*(\/\/|#)[[:space:]]*end of[[:space:]]+/ { next }
      { print }
    ' "$TMP" > "${TMP}.o" && mv "${TMP}.o" "$TMP"
    [ "$S" != "$(cksum "$TMP" | cut -d' ' -f1)" ] && FPAT="${FPAT:+$FPAT,}P6"
  fi

  # Apply changes if file was modified
  if ! cmp -s "$file" "$TMP"; then
    TOTAL_CLEANED=$((TOTAL_CLEANED + 1))
    [ -n "$FPAT" ] && ALL_PAT="${ALL_PAT:+$ALL_PAT,}$FPAT"
    [ "$DRY_RUN" = "no" ] && cp "$TMP" "$file"
  fi

  rm -f "$TMP" "${TMP}.o"
done <<< "$FILES"

# Deduplicate found patterns
if [ -n "$ALL_PAT" ]; then
  ALL_PAT=$(echo "$ALL_PAT" | tr ',' '\n' | sort -u | tr '\n' ',' | sed 's/,$//')
fi

echo "CLEANED=$TOTAL_CLEANED"
echo "PATTERNS=$ALL_PAT"
exit 0

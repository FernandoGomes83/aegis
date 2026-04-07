#!/bin/bash
# aegis-sdd — Build progress status line
# Outputs a single line for Claude Code's status line display

STATE_PATH=".aegis/build-state.json"

if [ ! -f "$STATE_PATH" ]; then
  exit 0
fi

active=$(sed -n 's/.*"active"[[:space:]]*:[[:space:]]*\([a-z]*\).*/\1/p' "$STATE_PATH" | head -1)
if [ "$active" != "true" ]; then
  exit 0
fi

# Read state values
taskIndex=$(sed -n 's/.*"taskIndex"[[:space:]]*:[[:space:]]*\([0-9]*\).*/\1/p' "$STATE_PATH" | head -1)
taskQueue=$(sed -n 's/.*"taskQueue"[[:space:]]*:[[:space:]]*\[\([^]]*\)\].*/\1/p' "$STATE_PATH" | sed 's/"//g' | tr -d ' ')
taskIteration=$(sed -n 's/.*"taskIteration"[[:space:]]*:[[:space:]]*\([0-9]*\).*/\1/p' "$STATE_PATH" | head -1)
maxTaskIterations=$(sed -n 's/.*"maxTaskIterations"[[:space:]]*:[[:space:]]*\([0-9]*\).*/\1/p' "$STATE_PATH" | head -1)
parallelActive=$(sed -n 's/.*"parallelActive"[[:space:]]*:[[:space:]]*\(true\|false\).*/\1/p' "$STATE_PATH" | head -1)

: "${taskIndex:=0}"
: "${taskIteration:=0}"
: "${maxTaskIterations:=5}"

# Count tasks
TOTAL=$(echo "$taskQueue" | tr ',' '\n' | grep -c '.' || echo 0)
DONE=$taskIndex
CURRENT_TASK=$(echo "$taskQueue" | cut -d',' -f"$((taskIndex + 1))" 2>/dev/null || echo "?")

# Build status string
if [ "$parallelActive" = "true" ]; then
  echo "Aegis build: $CURRENT_TASK [P] ($DONE/$TOTAL done)"
else
  echo "Aegis build: $CURRENT_TASK ($DONE/$TOTAL done) iter:$taskIteration/$maxTaskIterations"
fi

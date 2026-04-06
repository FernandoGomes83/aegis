#!/bin/bash
# aegis-sdd — Build state file CRUD (JSON via sed/awk, no jq)
# Usage: aegis-build-state.sh <state_path> <action> [args]

set -euo pipefail

STATE_PATH="${1:?Usage: aegis-build-state.sh <state_path> <action> [args]}"
ACTION="${2:?Missing action: init|read|advance|retry|retry-reset|deactivate|parallel-start|parallel-end|add-fix|check-fix|sync-fail|set-native-map|get-native-id}"
shift 2

# Ensure parent directory exists
mkdir -p "$(dirname "$STATE_PATH")"

# --- Helper: read a JSON field value (string or number) ---
json_field() {
  local file="$1"
  local key="$2"
  # Handle both "key": "value" and "key": number/true/false
  sed -n "s/.*\"$key\"[[:space:]]*:[[:space:]]*\"\{0,1\}\([^,\"}]*\)\"\{0,1\}.*/\1/p" "$file" | head -1
}

# --- Helper: set a JSON field to a numeric value ---
json_set_num() {
  local file="$1"
  local key="$2"
  local value="$3"
  local tmp="${file}.tmp"
  sed "s/\"$key\"[[:space:]]*:[[:space:]]*[0-9]*/\"$key\": $value/" "$file" > "$tmp"
  mv "$tmp" "$file"
}

# --- Helper: set a JSON field to a boolean value ---
json_set_bool() {
  local file="$1"
  local key="$2"
  local value="$3"
  local tmp="${file}.tmp"
  sed "s/\"$key\"[[:space:]]*:[[:space:]]*[a-z]*/\"$key\": $value/" "$file" > "$tmp"
  mv "$tmp" "$file"
}

case "$ACTION" in
  init)
    JSON_STRING="${1:?Missing JSON string for init}"
    echo "$JSON_STRING" > "$STATE_PATH"
    echo "STATE=initialized"
    ;;

  read)
    if [ ! -f "$STATE_PATH" ]; then
      echo "ERROR=state_not_found"
      exit 1
    fi

    active=$(json_field "$STATE_PATH" "active")
    sessionId=$(json_field "$STATE_PATH" "sessionId")
    taskIndex=$(json_field "$STATE_PATH" "taskIndex")
    taskIteration=$(json_field "$STATE_PATH" "taskIteration")
    globalIteration=$(json_field "$STATE_PATH" "globalIteration")
    maxTaskIterations=$(json_field "$STATE_PATH" "maxTaskIterations")
    level=$(json_field "$STATE_PATH" "level")
    outputDir=$(json_field "$STATE_PATH" "outputDir")

    # Extract taskQueue array as comma-separated string
    taskQueue=$(sed -n 's/.*"taskQueue"[[:space:]]*:[[:space:]]*\[\([^]]*\)\].*/\1/p' "$STATE_PATH" | sed 's/"//g' | tr -d ' ')

    echo "active=$active"
    echo "sessionId=$sessionId"
    echo "taskIndex=$taskIndex"
    echo "taskIteration=$taskIteration"
    echo "globalIteration=$globalIteration"
    echo "maxTaskIterations=$maxTaskIterations"
    echo "level=$level"
    echo "outputDir=$outputDir"
    echo "taskQueue=$taskQueue"

    # Native task sync fields
    nativeSyncEnabled=$(json_field "$STATE_PATH" "nativeSyncEnabled")
    nativeSyncFailures=$(json_field "$STATE_PATH" "nativeSyncFailures")
    echo "nativeSyncEnabled=${nativeSyncEnabled:-true}"
    echo "nativeSyncFailures=${nativeSyncFailures:-0}"

    # Recovery mode fields
    recoveryMode=$(json_field "$STATE_PATH" "recoveryMode")
    echo "recoveryMode=${recoveryMode:-true}"

    # Parallel execution fields
    parallelActive=$(json_field "$STATE_PATH" "parallelActive")
    parallelMode=$(json_field "$STATE_PATH" "parallelMode")
    echo "parallelActive=${parallelActive:-false}"
    echo "parallelMode=${parallelMode:-agent}"

    # Compute current task from queue and index
    if [ -n "$taskQueue" ] && [ -n "$taskIndex" ]; then
      current=$(echo "$taskQueue" | cut -d',' -f"$((taskIndex + 1))" 2>/dev/null || echo "")
      echo "currentTask=$current"
      total=$(echo "$taskQueue" | tr ',' '\n' | wc -l | tr -d ' ')
      echo "totalQueued=$total"
      remaining=$((total - taskIndex))
      echo "remainingTasks=$remaining"
    fi
    ;;

  advance)
    if [ ! -f "$STATE_PATH" ]; then
      echo "ERROR=state_not_found"
      exit 1
    fi

    taskIndex=$(json_field "$STATE_PATH" "taskIndex")
    globalIteration=$(json_field "$STATE_PATH" "globalIteration")

    new_index=$((taskIndex + 1))
    new_global=$((globalIteration + 1))

    json_set_num "$STATE_PATH" "taskIndex" "$new_index"
    json_set_num "$STATE_PATH" "taskIteration" "1"
    json_set_num "$STATE_PATH" "globalIteration" "$new_global"

    echo "STATE=advanced"
    echo "taskIndex=$new_index"
    echo "taskIteration=1"
    echo "globalIteration=$new_global"
    ;;

  retry)
    if [ ! -f "$STATE_PATH" ]; then
      echo "ERROR=state_not_found"
      exit 1
    fi

    taskIteration=$(json_field "$STATE_PATH" "taskIteration")
    new_iter=$((taskIteration + 1))

    json_set_num "$STATE_PATH" "taskIteration" "$new_iter"

    echo "STATE=retried"
    echo "taskIteration=$new_iter"
    ;;

  retry-reset)
    if [ ! -f "$STATE_PATH" ]; then
      echo "ERROR=state_not_found"
      exit 1
    fi

    json_set_num "$STATE_PATH" "taskIteration" "1"

    echo "STATE=retry_reset"
    echo "taskIteration=1"
    ;;

  deactivate)
    if [ ! -f "$STATE_PATH" ]; then
      echo "ERROR=state_not_found"
      exit 1
    fi

    json_set_bool "$STATE_PATH" "active" "false"

    echo "STATE=deactivated"
    ;;

  sync-fail)
    if [ ! -f "$STATE_PATH" ]; then
      echo "ERROR=state_not_found"
      exit 1
    fi

    failures=$(json_field "$STATE_PATH" "nativeSyncFailures")
    : "${failures:=0}"
    new_failures=$((failures + 1))

    json_set_num "$STATE_PATH" "nativeSyncFailures" "$new_failures"

    if [ "$new_failures" -ge 3 ]; then
      json_set_bool "$STATE_PATH" "nativeSyncEnabled" "false"
      echo "SYNC_DISABLED=true"
    else
      echo "SYNC_DISABLED=false"
    fi
    echo "nativeSyncFailures=$new_failures"
    ;;

  set-native-map)
    TASK_ID="${1:?Missing task ID}"
    NATIVE_ID="${2:?Missing native task ID}"

    if [ ! -f "$STATE_PATH" ]; then
      echo "ERROR=state_not_found"
      exit 1
    fi

    tmp="${STATE_PATH}.tmp"

    if grep -q '"nativeTaskMap"[[:space:]]*:[[:space:]]*{}' "$STATE_PATH"; then
      sed "s|\"nativeTaskMap\"[[:space:]]*:[[:space:]]*{}|\"nativeTaskMap\": {\"$TASK_ID\": \"$NATIVE_ID\"}|" "$STATE_PATH" > "$tmp"
    else
      sed "s|\(\"nativeTaskMap\"[[:space:]]*:[[:space:]]*{[^}]*\)}|\1, \"$TASK_ID\": \"$NATIVE_ID\"}|" "$STATE_PATH" > "$tmp"
    fi
    mv "$tmp" "$STATE_PATH"
    echo "NATIVE_MAP_SET=$TASK_ID"
    ;;

  get-native-id)
    TASK_ID="${1:?Missing task ID}"

    if [ ! -f "$STATE_PATH" ]; then
      echo "ERROR=state_not_found"
      exit 1
    fi

    NATIVE_ID=$(grep -o "\"$TASK_ID\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$STATE_PATH" | sed 's/.*:[[:space:]]*"//;s/"$//' | head -1) || true
    echo "NATIVE_ID=${NATIVE_ID:-}"
    ;;

  add-fix)
    TASK_ID="${1:?Missing task ID}"
    FIX_ID="${2:?Missing fix task ID}"

    if [ ! -f "$STATE_PATH" ]; then
      echo "ERROR=state_not_found"
      exit 1
    fi

    tmp="${STATE_PATH}.tmp"

    # Check if fixTaskMap already has an entry for this task
    # Pattern "TASK-ID": { only matches fixTaskMap entries (not taskQueue or nativeTaskMap)
    if grep -q "\"$TASK_ID\"[[:space:]]*:[[:space:]]*{" "$STATE_PATH" 2>/dev/null; then
      # Increment attempts for existing entry
      current_attempts=$(sed -n "s/.*\"$TASK_ID\"[[:space:]]*:[[:space:]]*{[^}]*\"attempts\"[[:space:]]*:[[:space:]]*\([0-9]*\).*/\1/p" "$STATE_PATH" | head -1)
      : "${current_attempts:=0}"
      new_attempts=$((current_attempts + 1))
      sed "s/\(\"$TASK_ID\"[[:space:]]*:[[:space:]]*{[^}]*\"attempts\"[[:space:]]*:[[:space:]]*\)[0-9]*/\1$new_attempts/" "$STATE_PATH" > "$tmp"
      mv "$tmp" "$STATE_PATH"
      # Append fix ID to fixTaskIds array
      tmp2="${STATE_PATH}.tmp"
      sed "s/\(\"$TASK_ID\"[[:space:]]*:[[:space:]]*{[^}]*\"fixTaskIds\"[[:space:]]*:[[:space:]]*\[[^]]*\)\]/\1, \"$FIX_ID\"]/" "$STATE_PATH" > "$tmp2"
      mv "$tmp2" "$STATE_PATH"
    else
      # Add new entry to fixTaskMap
      if grep -q '"fixTaskMap"[[:space:]]*:[[:space:]]*{}' "$STATE_PATH"; then
        sed "s|\"fixTaskMap\"[[:space:]]*:[[:space:]]*{}|\"fixTaskMap\": {\"$TASK_ID\": {\"attempts\": 1, \"maxAttempts\": 3, \"fixTaskIds\": [\"$FIX_ID\"]}}|" "$STATE_PATH" > "$tmp"
      else
        sed "s|\(\"fixTaskMap\"[[:space:]]*:[[:space:]]*{[^}]*\)}|\1, \"$TASK_ID\": {\"attempts\": 1, \"maxAttempts\": 3, \"fixTaskIds\": [\"$FIX_ID\"]}}|" "$STATE_PATH" > "$tmp"
      fi
      mv "$tmp" "$STATE_PATH"
    fi

    echo "FIX_RECORDED=$TASK_ID"
    echo "FIX_ID=$FIX_ID"
    ;;

  check-fix)
    TASK_ID="${1:?Missing task ID}"

    if [ ! -f "$STATE_PATH" ]; then
      echo "ERROR=state_not_found"
      exit 1
    fi

    recovery=$(json_field "$STATE_PATH" "recoveryMode")
    : "${recovery:=true}"

    if [ "$recovery" != "true" ]; then
      echo "CAN_FIX=no"
      echo "REASON=recovery_disabled"
      echo "ATTEMPTS=0"
      echo "MAX_ATTEMPTS=0"
      exit 0
    fi

    # Check if task has fix entries in fixTaskMap
    # Pattern "TASK-ID": { only matches fixTaskMap entries (not taskQueue or nativeTaskMap)
    if grep -q "\"$TASK_ID\"[[:space:]]*:[[:space:]]*{" "$STATE_PATH" 2>/dev/null; then
      attempts=$(sed -n "s/.*\"$TASK_ID\"[[:space:]]*:[[:space:]]*{[^}]*\"attempts\"[[:space:]]*:[[:space:]]*\([0-9]*\).*/\1/p" "$STATE_PATH" | head -1)
      max_attempts=$(sed -n "s/.*\"$TASK_ID\"[[:space:]]*:[[:space:]]*{[^}]*\"maxAttempts\"[[:space:]]*:[[:space:]]*\([0-9]*\).*/\1/p" "$STATE_PATH" | head -1)
      : "${attempts:=0}"
      : "${max_attempts:=3}"
    else
      attempts=0
      max_attempts=3
    fi

    echo "ATTEMPTS=$attempts"
    echo "MAX_ATTEMPTS=$max_attempts"

    if [ "$attempts" -lt "$max_attempts" ]; then
      echo "CAN_FIX=yes"
    else
      echo "CAN_FIX=no"
      echo "REASON=max_attempts_reached"
    fi
    ;;

  parallel-start)
    if [ ! -f "$STATE_PATH" ]; then
      echo "ERROR=state_not_found"
      exit 1
    fi

    json_set_bool "$STATE_PATH" "parallelActive" "true"

    echo "STATE=parallel_started"
    echo "parallelActive=true"
    ;;

  parallel-end)
    if [ ! -f "$STATE_PATH" ]; then
      echo "ERROR=state_not_found"
      exit 1
    fi

    json_set_bool "$STATE_PATH" "parallelActive" "false"

    echo "STATE=parallel_ended"
    echo "parallelActive=false"
    ;;

  *)
    echo "ERROR=unknown_action"
    echo "Unknown action: $ACTION"
    echo "Valid actions: init, read, advance, retry, retry-reset, deactivate, parallel-start, parallel-end, add-fix, check-fix, sync-fail, set-native-map, get-native-id"
    exit 1
    ;;
esac

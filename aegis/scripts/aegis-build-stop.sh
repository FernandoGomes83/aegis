#!/bin/bash
# aegis-sdd — Stop hook for the build loop
# Reads hook input from stdin (JSON with session_id and transcript_path)
# Outputs JSON decision or exits silently

set -uo pipefail

# Resolve script directory for sibling script calls
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

STATE_PATH=".aegis/build-state.json"

# --- Read hook input from stdin ---
HOOK_INPUT=""
if [ ! -t 0 ]; then
  HOOK_INPUT=$(cat)
fi

# --- 1. Check state file exists and is active ---

if [ ! -f "$STATE_PATH" ]; then
  exit 0
fi

active=$(sed -n 's/.*"active"[[:space:]]*:[[:space:]]*\([a-z]*\).*/\1/p' "$STATE_PATH" | head -1)
if [ "$active" != "true" ]; then
  exit 0
fi

# --- 1b. Check if parallel execution is active ---
# When the coordinator is managing parallel agents, the stop hook must not
# interfere — each agent runs in its own worktree and the coordinator handles
# advancement and merging after all agents complete.
parallel_active=$(sed -n 's/.*"parallelActive"[[:space:]]*:[[:space:]]*\(true\|false\).*/\1/p' "$STATE_PATH" | head -1)
if [ "$parallel_active" = "true" ]; then
  exit 0
fi

# --- 2. Session isolation ---

state_session=$(sed -n 's/.*"sessionId"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$STATE_PATH" | head -1)

hook_session=""
if [ -n "$HOOK_INPUT" ]; then
  hook_session=$(echo "$HOOK_INPUT" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
fi

if [ -n "$hook_session" ] && [ -n "$state_session" ] && [ "$hook_session" != "$state_session" ]; then
  exit 0
fi

# --- 3. Read transcript and extract last assistant text ---

transcript_path=""
if [ -n "$HOOK_INPUT" ]; then
  transcript_path=$(echo "$HOOK_INPUT" | sed -n 's/.*"transcript_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
fi

LAST_OUTPUT=""
if [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
  # Extract last assistant message — look for the last "role":"assistant" block
  # and grab its content text
  LAST_OUTPUT=$(tail -200 "$transcript_path" | grep -o '"content"[[:space:]]*:[[:space:]]*"[^"]*"' | tail -1 | sed 's/"content"[[:space:]]*:[[:space:]]*"//;s/"$//' || true)

  # Fallback: grab last 100 lines as raw text
  if [ -z "$LAST_OUTPUT" ]; then
    LAST_OUTPUT=$(tail -100 "$transcript_path" 2>/dev/null || true)
  fi
fi

# --- Read state values ---

taskIndex=$(sed -n 's/.*"taskIndex"[[:space:]]*:[[:space:]]*\([0-9]*\).*/\1/p' "$STATE_PATH" | head -1)
taskIteration=$(sed -n 's/.*"taskIteration"[[:space:]]*:[[:space:]]*\([0-9]*\).*/\1/p' "$STATE_PATH" | head -1)
maxTaskIterations=$(sed -n 's/.*"maxTaskIterations"[[:space:]]*:[[:space:]]*\([0-9]*\).*/\1/p' "$STATE_PATH" | head -1)
level=$(sed -n 's/.*"level"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$STATE_PATH" | head -1)
outputDir=$(sed -n 's/.*"outputDir"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$STATE_PATH" | head -1)
taskQueue=$(sed -n 's/.*"taskQueue"[[:space:]]*:[[:space:]]*\[\([^]]*\)\].*/\1/p' "$STATE_PATH" | sed 's/"//g' | tr -d ' ')
reviewInterval=$(sed -n 's/.*"reviewInterval"[[:space:]]*:[[:space:]]*\([0-9]*\).*/\1/p' "$STATE_PATH" | head -1)

: "${maxTaskIterations:=5}"
: "${outputDir:=.aegis}"
: "${reviewInterval:=5}"

# --- 4. Verification layers ---

HAS_TASK_COMPLETE="no"
HAS_BUILD_COMPLETE="no"
HAS_MODIFICATION="no"
HAS_CONTRADICTION="no"
HAS_SECRETS="no"

if [ -n "$LAST_OUTPUT" ]; then
  # Primary: XML tag detection; Fallback: bare string at word boundary (legacy)
  if echo "$LAST_OUTPUT" | grep -q '<aegis:signal>TASK_COMPLETE</aegis:signal>'; then
    HAS_TASK_COMPLETE="yes"
  elif echo "$LAST_OUTPUT" | grep -qE '(^|[[:space:]])TASK_COMPLETE([[:space:]]|$)'; then
    HAS_TASK_COMPLETE="yes"
  fi
  if echo "$LAST_OUTPUT" | grep -q '<aegis:signal>BUILD_COMPLETE</aegis:signal>'; then
    HAS_BUILD_COMPLETE="yes"
  elif echo "$LAST_OUTPUT" | grep -qE '(^|[[:space:]])BUILD_COMPLETE([[:space:]]|$)'; then
    HAS_BUILD_COMPLETE="yes"
  fi
  if echo "$LAST_OUTPUT" | grep -q '<aegis:signal>TASK_MODIFICATION_REQUEST</aegis:signal>'; then
    HAS_MODIFICATION="yes"
  elif echo "$LAST_OUTPUT" | grep -qE '(^|[[:space:]])TASK_MODIFICATION_REQUEST([[:space:]]|$)'; then
    HAS_MODIFICATION="yes"
  fi

  # 4b. Contradiction scan
  if [ "$HAS_TASK_COMPLETE" = "yes" ]; then
    if echo "$LAST_OUTPUT" | grep -qiE '(requires manual|cannot be automated|not possible to implement|out of scope)'; then
      HAS_CONTRADICTION="yes"
    fi
  fi
fi

# 4c. Secrets check — scan staged files
if git diff --cached --name-only 2>/dev/null | grep -qE '\.(env|pem|key)$|credentials|secrets'; then
  HAS_SECRETS="yes"
fi

# --- 4d. Build verification gate ---
# When build.verifyCommand is configured, run it after TASK_COMPLETE.
# If it fails, reject the signal — the agent must fix the regression.

HAS_VERIFY_FAILURE="no"
if [ "$HAS_TASK_COMPLETE" = "yes" ] && [ "$HAS_CONTRADICTION" = "no" ] && [ "$HAS_SECRETS" = "no" ]; then
  CONFIG_PATH="${outputDir}/config.yaml"
  VERIFY_CMD=""
  if [ -f "$CONFIG_PATH" ]; then
    VERIFY_CMD=$(sed -n 's/^[[:space:]]*verifyCommand:[[:space:]]*"\(.*\)"/\1/p' "$CONFIG_PATH" | head -1)
    # Also handle unquoted values
    if [ -z "$VERIFY_CMD" ]; then
      VERIFY_CMD=$(sed -n 's/^[[:space:]]*verifyCommand:[[:space:]]*\(.*\)/\1/p' "$CONFIG_PATH" | head -1)
      # Strip null/~ values
      case "$VERIFY_CMD" in null|~|"") VERIFY_CMD="" ;; esac
    fi
  fi

  if [ -n "$VERIFY_CMD" ]; then
    VERIFY_TMPFILE=$(mktemp)
    eval "$VERIFY_CMD" >"$VERIFY_TMPFILE" 2>&1 || HAS_VERIFY_FAILURE="yes"
    VERIFY_OUTPUT=$(tail -30 "$VERIFY_TMPFILE")
    rm -f "$VERIFY_TMPFILE"
    if [ "$HAS_VERIFY_FAILURE" = "yes" ]; then
      CURRENT_TASK=$(echo "$taskQueue" | cut -d',' -f"$((taskIndex + 1))" 2>/dev/null || echo "unknown")
      # Escape output for JSON
      VERIFY_ESCAPED=$(echo "$VERIFY_OUTPUT" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | tr '\n' ' ')
      echo "{\"decision\":\"block\",\"reason\":\"TASK_COMPLETE rejected for $CURRENT_TASK — verify command failed. The build must be green before a task can be marked done. Fix the errors and re-signal. Output: $VERIFY_ESCAPED\",\"systemMessage\":\"Verify failed for $CURRENT_TASK — fix errors before re-signaling\"}"
      exit 0
    fi
  fi
fi

# --- 5. TASK_COMPLETE verified ---

if [ "$HAS_TASK_COMPLETE" = "yes" ] && [ "$HAS_CONTRADICTION" = "no" ] && [ "$HAS_SECRETS" = "no" ]; then
  # Advance state
  bash "$SCRIPT_DIR/aegis-build-state.sh" "$STATE_PATH" advance >/dev/null 2>&1

  # Check remaining tasks
  PARSE_OUTPUT=$(bash "$SCRIPT_DIR/aegis-build-parse.sh" "$outputDir/tasks.md" 2>/dev/null || true)
  ACTIONABLE=$(echo "$PARSE_OUTPUT" | grep '^ACTIONABLE=' | sed 's/ACTIONABLE=//')
  TOTAL=$(echo "$PARSE_OUTPUT" | grep '^TOTAL_TASKS=' | sed 's/TOTAL_TASKS=//')
  DONE_COUNT=$(echo "$PARSE_OUTPUT" | grep '^DONE_TASKS=' | sed 's/DONE_TASKS=//')

  # --- Checkpoint review ---
  REVIEW_INSTRUCTION=""
  SHOULD_REVIEW="no"

  # Every Nth task
  if [ "$((DONE_COUNT % reviewInterval))" -eq 0 ] && [ "$DONE_COUNT" -gt 0 ]; then
    SHOULD_REVIEW="yes"
  fi
  # Final task
  if [ -z "$ACTIONABLE" ] || [ "$DONE_COUNT" = "$TOTAL" ]; then
    SHOULD_REVIEW="yes"
  fi

  if [ "$SHOULD_REVIEW" = "yes" ]; then
    # Get recent completed task IDs for review scope
    RECENT_TASKS=$(echo "$PARSE_OUTPUT" \
      | grep '_STATUS=done' | tail -"$reviewInterval" \
      | sed 's/_STATUS=done//' | sed 's/^TASK_/TASK-/' | tr '\n' ',' | sed 's/,$//')

    REVIEW_OUTPUT=$(bash "$SCRIPT_DIR/aegis-build-review.sh" "$outputDir" "$RECENT_TASKS" 2>/dev/null || true)

    # Append review to build-progress.md
    if [ -n "$REVIEW_OUTPUT" ] && [ -f "$outputDir/build-progress.md" ]; then
      REVIEW_DETAIL=$(echo "$REVIEW_OUTPUT" | sed -n '/===REVIEW_DETAIL===/,/===/{/===/d;p}')
      {
        echo ""
        echo "### Checkpoint Review — after $DONE_COUNT/$TOTAL done"
        echo ""
        echo "$REVIEW_DETAIL"
      } >> "$outputDir/build-progress.md"
    fi

    # Extract action items if issues found
    if echo "$REVIEW_OUTPUT" | grep -q "ISSUES=[1-9]"; then
      ACTION_ITEMS=$(echo "$REVIEW_OUTPUT" | sed -n '/===ACTION_ITEMS===/,/===/{/===/d;p}' | tr '\n' ' ')
      REVIEW_INSTRUCTION="Checkpoint review found issues. Before starting the next task, address: $ACTION_ITEMS"
    fi
  fi

  if [ -z "$ACTIONABLE" ] || [ "$DONE_COUNT" = "$TOTAL" ]; then
    # All done
    bash "$SCRIPT_DIR/aegis-build-state.sh" "$STATE_PATH" deactivate >/dev/null 2>&1
    echo "{\"decision\":\"block\",\"reason\":\"BUILD_COMPLETE: All $TOTAL tasks implemented ($DONE_COUNT/$TOTAL done). Run /aegis:validate for a full coverage report.\",\"systemMessage\":\"Build complete — $DONE_COUNT/$TOTAL tasks done.\"}"
    exit 0
  fi

  # More tasks remain — get next task context
  NEXT_TASK=$(echo "$ACTIONABLE" | cut -d',' -f1)

  CONTEXT_OUTPUT=$(bash "$SCRIPT_DIR/aegis-build-context.sh" "$outputDir" "$NEXT_TASK" 2>/dev/null || true)

  # Load recent progress (last 30 lines for context window efficiency)
  PROGRESS_TAIL=""
  if [ -f "$outputDir/build-progress.md" ]; then
    PROGRESS_TAIL=$(tail -30 "$outputDir/build-progress.md" 2>/dev/null || true)
  fi

  # Native task sync instruction for continuation
  SYNC_INSTRUCTION=""
  nativeSyncEnabled=$(sed -n 's/.*"nativeSyncEnabled"[[:space:]]*:[[:space:]]*\([a-z]*\).*/\1/p' "$STATE_PATH" | head -1)
  if [ "${nativeSyncEnabled:-}" = "true" ]; then
    COMPLETED_TASK=$(echo "$taskQueue" | cut -d',' -f"$((taskIndex + 1))" 2>/dev/null || echo "")
    COMPLETED_NATIVE=$(bash "$SCRIPT_DIR/aegis-build-state.sh" "$STATE_PATH" get-native-id "$COMPLETED_TASK" 2>/dev/null | sed 's/NATIVE_ID=//' || true)
    NEXT_NATIVE=$(bash "$SCRIPT_DIR/aegis-build-state.sh" "$STATE_PATH" get-native-id "$NEXT_TASK" 2>/dev/null | sed 's/NATIVE_ID=//' || true)
    [ -n "$COMPLETED_NATIVE" ] && SYNC_INSTRUCTION="Native task sync: Mark $COMPLETED_TASK complete via TaskUpdate(taskId: \"$COMPLETED_NATIVE\", status: \"completed\")."
    [ -n "$NEXT_NATIVE" ] && SYNC_INSTRUCTION="$SYNC_INSTRUCTION Mark $NEXT_TASK in progress via TaskUpdate(taskId: \"$NEXT_NATIVE\", status: \"in_progress\")."
  fi

  # Build continuation prompt
  PROMPT="Continue build — advancing to $NEXT_TASK ($((DONE_COUNT + 1))/$TOTAL).

$CONTEXT_OUTPUT

Recent progress:
$PROGRESS_TAIL
$SYNC_INSTRUCTION
$REVIEW_INSTRUCTION

Follow the build-agent rules already loaded. Key reminders:
- Implement this task completely, then mark done with aegis-build-mark.sh
- One focused commit including tasks.md + build-progress.md
- Output <aegis:signal>TASK_COMPLETE</aegis:signal> with commit hash when verified
- SEC-PROP/SEC-REQ references require full implementation — never stub"

  # Escape for JSON
  PROMPT_ESCAPED=$(echo "$PROMPT" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | tr '\n' ' ')
  STATUS_MSG="Advancing to $NEXT_TASK ($((DONE_COUNT + 1))/$TOTAL)"

  echo "{\"decision\":\"block\",\"reason\":\"$PROMPT_ESCAPED\",\"systemMessage\":\"$STATUS_MSG\"}"
  exit 0
fi

# --- Handle contradiction ---

if [ "$HAS_CONTRADICTION" = "yes" ]; then
  bash "$SCRIPT_DIR/aegis-build-state.sh" "$STATE_PATH" deactivate >/dev/null 2>&1
  echo "{\"decision\":\"block\",\"reason\":\"Build stopped: task reported TASK_COMPLETE but also indicated it cannot be automated. Review the task manually.\",\"systemMessage\":\"Build halted — contradiction detected.\"}"
  exit 0
fi

# --- Handle secrets ---

if [ "$HAS_SECRETS" = "yes" ]; then
  bash "$SCRIPT_DIR/aegis-build-state.sh" "$STATE_PATH" deactivate >/dev/null 2>&1
  echo "{\"decision\":\"block\",\"reason\":\"Build stopped: staged files contain potential secrets (.env, .pem, .key, credentials). Unstage sensitive files before continuing.\",\"systemMessage\":\"Build halted — secrets detected in staged files.\"}"
  exit 0
fi

# --- 6. BUILD_COMPLETE signal ---

if [ "$HAS_BUILD_COMPLETE" = "yes" ]; then
  bash "$SCRIPT_DIR/aegis-build-state.sh" "$STATE_PATH" deactivate >/dev/null 2>&1
  exit 0
fi

# --- 6b. TASK_MODIFICATION_REQUEST handling ---

if [ "$HAS_MODIFICATION" = "yes" ]; then
  MOD_TYPE=$(echo "$LAST_OUTPUT" | grep -oE 'type: (SPLIT_TASK|ADD_PREREQUISITE|ADD_FOLLOWUP)' | head -1 | sed 's/type: //')

  if [ "$MOD_TYPE" = "ADD_FOLLOWUP" ]; then
    # ADD_FOLLOWUP means current task IS complete — advance
    bash "$SCRIPT_DIR/aegis-build-state.sh" "$STATE_PATH" advance >/dev/null 2>&1

    PARSE_OUTPUT=$(bash "$SCRIPT_DIR/aegis-build-parse.sh" "$outputDir/tasks.md" 2>/dev/null || true)
    ACTIONABLE=$(echo "$PARSE_OUTPUT" | grep '^ACTIONABLE=' | sed 's/ACTIONABLE=//')
    TOTAL=$(echo "$PARSE_OUTPUT" | grep '^TOTAL_TASKS=' | sed 's/TOTAL_TASKS=//')
    DONE_COUNT=$(echo "$PARSE_OUTPUT" | grep '^DONE_TASKS=' | sed 's/DONE_TASKS=//')

    if [ -z "$ACTIONABLE" ] || [ "$DONE_COUNT" = "$TOTAL" ]; then
      bash "$SCRIPT_DIR/aegis-build-state.sh" "$STATE_PATH" deactivate >/dev/null 2>&1
      echo "{\"decision\":\"block\",\"reason\":\"BUILD_COMPLETE: All $TOTAL tasks implemented ($DONE_COUNT/$TOTAL done). Followup tasks were proposed — add them to tasks.md and run /aegis:build again. Run /aegis:validate for coverage.\",\"systemMessage\":\"Build complete — $DONE_COUNT/$TOTAL tasks done (followup proposed).\"}"
      exit 0
    fi

    NEXT_TASK=$(echo "$ACTIONABLE" | cut -d',' -f1)
    CONTEXT_OUTPUT=$(bash "$SCRIPT_DIR/aegis-build-context.sh" "$outputDir" "$NEXT_TASK" 2>/dev/null || true)

    # Native task sync for ADD_FOLLOWUP transition
    SYNC_INSTRUCTION=""
    nativeSyncEnabled=$(sed -n 's/.*"nativeSyncEnabled"[[:space:]]*:[[:space:]]*\([a-z]*\).*/\1/p' "$STATE_PATH" | head -1)
    if [ "${nativeSyncEnabled:-}" = "true" ]; then
      COMPLETED_TASK=$(echo "$taskQueue" | cut -d',' -f"$((taskIndex + 1))" 2>/dev/null || echo "")
      COMPLETED_NATIVE=$(bash "$SCRIPT_DIR/aegis-build-state.sh" "$STATE_PATH" get-native-id "$COMPLETED_TASK" 2>/dev/null | sed 's/NATIVE_ID=//' || true)
      NEXT_NATIVE=$(bash "$SCRIPT_DIR/aegis-build-state.sh" "$STATE_PATH" get-native-id "$NEXT_TASK" 2>/dev/null | sed 's/NATIVE_ID=//' || true)
      [ -n "$COMPLETED_NATIVE" ] && SYNC_INSTRUCTION="Native task sync: TaskUpdate(taskId: \"$COMPLETED_NATIVE\", status: \"completed\"). "
      [ -n "$NEXT_NATIVE" ] && SYNC_INSTRUCTION="${SYNC_INSTRUCTION}TaskUpdate(taskId: \"$NEXT_NATIVE\", status: \"in_progress\"). "
    fi

    PROMPT="Modification accepted (ADD_FOLLOWUP) — current task done. ${SYNC_INSTRUCTION}Advancing to $NEXT_TASK ($((DONE_COUNT + 1))/$TOTAL). $CONTEXT_OUTPUT Follow build-agent rules. Implement $NEXT_TASK completely."
    PROMPT_ESCAPED=$(echo "$PROMPT" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | tr '\n' ' ')
    echo "{\"decision\":\"block\",\"reason\":\"$PROMPT_ESCAPED\",\"systemMessage\":\"ADD_FOLLOWUP accepted — advancing to $NEXT_TASK\"}"
    exit 0
  else
    # SPLIT_TASK or ADD_PREREQUISITE — do not advance
    CURRENT_TASK=$(echo "$taskQueue" | cut -d',' -f"$((taskIndex + 1))" 2>/dev/null || echo "unknown")
    PROMPT="Modification request received ($MOD_TYPE for $CURRENT_TASK). Implement the proposed subtasks or prerequisites within the current task scope. After implementation, signal <aegis:signal>TASK_COMPLETE</aegis:signal>."
    PROMPT_ESCAPED=$(echo "$PROMPT" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | tr '\n' ' ')
    echo "{\"decision\":\"block\",\"reason\":\"$PROMPT_ESCAPED\",\"systemMessage\":\"$MOD_TYPE received for $CURRENT_TASK — implement proposed changes\"}"
    exit 0
  fi
fi

# --- 7. No TASK_COMPLETE — retry logic ---

bash "$SCRIPT_DIR/aegis-build-state.sh" "$STATE_PATH" retry >/dev/null 2>&1

# Re-read updated iteration
taskIteration=$(sed -n 's/.*"taskIteration"[[:space:]]*:[[:space:]]*\([0-9]*\).*/\1/p' "$STATE_PATH" | head -1)

if [ "$taskIteration" -gt "$maxTaskIterations" ]; then
  CURRENT_TASK=$(echo "$taskQueue" | cut -d',' -f"$((taskIndex + 1))" 2>/dev/null || echo "unknown")

  # Check recovery mode — can we generate a fix attempt?
  CHECK_OUTPUT=$(bash "$SCRIPT_DIR/aegis-build-state.sh" "$STATE_PATH" check-fix "$CURRENT_TASK" 2>/dev/null || true)
  CAN_FIX=$(echo "$CHECK_OUTPUT" | grep '^CAN_FIX=' | sed 's/CAN_FIX=//')

  if [ "$CAN_FIX" = "yes" ]; then
    ATTEMPTS=$(echo "$CHECK_OUTPUT" | grep '^ATTEMPTS=' | sed 's/ATTEMPTS=//')
    MAX_FIX=$(echo "$CHECK_OUTPUT" | grep '^MAX_ATTEMPTS=' | sed 's/MAX_ATTEMPTS=//')
    FIX_ID="${CURRENT_TASK}-FIX-$((ATTEMPTS + 1))"

    # Record fix attempt and reset iteration counter
    bash "$SCRIPT_DIR/aegis-build-state.sh" "$STATE_PATH" add-fix "$CURRENT_TASK" "$FIX_ID" >/dev/null 2>&1
    bash "$SCRIPT_DIR/aegis-build-state.sh" "$STATE_PATH" retry-reset >/dev/null 2>&1

    # Get context for the fix attempt
    CONTEXT_OUTPUT=$(bash "$SCRIPT_DIR/aegis-build-context.sh" "$outputDir" "$CURRENT_TASK" 2>/dev/null || true)

    RETRY_PROGRESS=""
    if [ -f "$outputDir/build-progress.md" ]; then
      RETRY_PROGRESS=$(tail -20 "$outputDir/build-progress.md" 2>/dev/null || true)
    fi

    FIX_PROMPT="Recovery mode: $CURRENT_TASK failed after $maxTaskIterations iterations. Fix attempt $((ATTEMPTS + 1))/$MAX_FIX ($FIX_ID). Review what was implemented so far, identify the root cause of failure, and apply a targeted fix. Do NOT reimplement from scratch. Check: 1) What was committed 2) What errors or test failures exist 3) What build-progress.md says about the failure. $CONTEXT_OUTPUT Recent progress: $RETRY_PROGRESS Continue implementing $CURRENT_TASK — output <aegis:signal>TASK_COMPLETE</aegis:signal> when verified."
    FIX_ESCAPED=$(echo "$FIX_PROMPT" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | tr '\n' ' ')

    echo "{\"decision\":\"block\",\"reason\":\"$FIX_ESCAPED\",\"systemMessage\":\"Recovery: fix attempt $((ATTEMPTS + 1))/$MAX_FIX for $CURRENT_TASK ($FIX_ID)\"}"
    exit 0
  fi

  # No recovery or max fix attempts reached — deactivate
  bash "$SCRIPT_DIR/aegis-build-state.sh" "$STATE_PATH" deactivate >/dev/null 2>&1
  FIX_NOTE=""
  ATTEMPTS=$(echo "$CHECK_OUTPUT" | grep '^ATTEMPTS=' | sed 's/ATTEMPTS=//')
  if [ -n "$ATTEMPTS" ] && [ "$ATTEMPTS" -gt "0" ] 2>/dev/null; then
    FIX_NOTE=" Recovery mode exhausted ($ATTEMPTS fix attempts)."
  fi
  echo "{\"decision\":\"block\",\"reason\":\"Build stopped: task $CURRENT_TASK exceeded max iterations ($maxTaskIterations).${FIX_NOTE} The task may need manual intervention or decomposition into smaller subtasks.\",\"systemMessage\":\"Build halted — max iterations exceeded for $CURRENT_TASK.\"}"
  exit 0
fi

# Feed retry prompt with progress context
CURRENT_TASK=$(echo "$taskQueue" | cut -d',' -f"$((taskIndex + 1))" 2>/dev/null || echo "unknown")

# Load recent progress for retry context
RETRY_PROGRESS=""
if [ -f "$outputDir/build-progress.md" ]; then
  RETRY_PROGRESS=$(tail -15 "$outputDir/build-progress.md" 2>/dev/null || true)
fi

RETRY_MSG="Retry $taskIteration/$maxTaskIterations for $CURRENT_TASK. Previous attempt did not produce <aegis:signal>TASK_COMPLETE</aegis:signal>. Check: is the implementation complete? Are tests passing? Is the task marked done? Recent progress: $RETRY_PROGRESS Continue implementing $CURRENT_TASK — output <aegis:signal>TASK_COMPLETE</aegis:signal> only when fully verified and committed."
RETRY_ESCAPED=$(echo "$RETRY_MSG" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | tr '\n' ' ')

echo "{\"decision\":\"block\",\"reason\":\"$RETRY_ESCAPED\",\"systemMessage\":\"Retry $taskIteration/$maxTaskIterations for $CURRENT_TASK\"}"
exit 0

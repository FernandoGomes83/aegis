---
name: aegis:build
description: Implement tasks from tasks.md — autonomous build loop
---

## Bootstrap

Resolve the Aegis framework root path (**AEGIS_HOME**) by running one Bash command:

```bash
for d in "<project_root>/.claude/aegis" "$HOME/.claude/aegis"; do [ -x "$d/scripts/aegis-bootstrap.sh" ] && exec bash "$d/scripts/aegis-bootstrap.sh" "<project_root>" resolve; done; echo "ERROR=not_found"
```

Parse the output:
- If `ERROR=not_found` → tell the user to install Aegis with `npx aegis-sdd` and stop.
- Otherwise, extract **AEGIS_HOME** from the `AEGIS_HOME=<path>` line.

Now read `{AEGIS_HOME}/shared/preamble.md` and apply all path mappings and core rules defined there before proceeding with the steps below.

---

# /aegis:build

Implement tasks from `tasks.md` using an autonomous build loop controlled by
a stop hook. Each task is implemented in sequence (or in parallel for `[P]`
groups), with automatic advancement to the next task on completion.

---

## Prerequisites

Before executing any step, verify the following. If any condition is not met,
stop and report the issue to the user with a clear message.

- `.aegis/config.yaml` must exist at the project root. If missing, tell the
  user to run `/aegis:init` first.
- `tasks.md` must exist in the configured output directory (`output.dir` from
  config, default: `.aegis/`). If missing, tell the user to run `/aegis:tasks`.
- `design.md` must exist in the configured output directory. If missing, tell
  the user to run `/aegis:design`.

Optional but recommended:
- `tests.md` in the output directory — used to provide test context for each
  task. If absent, the build proceeds without test context.

---

## Flow

### Step 1: Load configuration and parse tasks

Read `.aegis/config.yaml`. Extract:
- `formalism` → determines task format and done-marking style (light / standard / formal)
- `project.name` and `project.stack` → used in implementation prompts
- `output.dir` → path to read artifacts from (default: `.aegis/`)

Run the task parser via Bash:

```bash
bash "{AEGIS_HOME}/scripts/aegis-build-parse.sh" "<output.dir>/tasks.md"
```

Parse the output key=value pairs. Extract:
- `TOTAL_TASKS` and `DONE_TASKS` — overall progress
- `ACTIONABLE` — comma-separated list of task IDs ready to implement
- `PARALLEL_GROUP_*` — parallel task groups (if any)
- Per-task data: `TASK_NNN_STATUS`, `TASK_NNN_DEPENDS`, `TASK_NNN_PARALLEL`

If `ACTIONABLE` is empty and `DONE_TASKS < TOTAL_TASKS`, there is a
dependency deadlock — report the blocked tasks and their unsatisfied
dependencies, then stop.

If `DONE_TASKS == TOTAL_TASKS`, all tasks are already done — report and stop.

---

### Step 1.5: Baseline build verification

If `build.verifyCommand` is set in `.aegis/config.yaml` (not null or empty),
run the verify command to confirm the project starts from a green baseline:

```bash
<verify command from config>
```

If it exits non-zero, stop and report:

```
/aegis:build — Baseline verification failed

The verify command failed before the build loop started.
The project must build and pass tests before /aegis:build can run.

Command: <verify command>
Output:  <last 30 lines of output>

Fix the errors and re-run /aegis:build.
```

Do not proceed to task dispatch if the baseline is not green. This ensures the
build agent can be held accountable for any regressions — if the verify command
passed before the loop started and fails after a task, the agent broke it.

---

### Step 2: Register stop hook (automatic)

The build loop requires the aegis build stop hook to be registered in the
Claude Code settings. Check if `.claude/settings.local.json` exists and
contains a hook entry with a command pointing to `aegis-build-stop.sh`.

**If already registered** → proceed to Step 3.

**If not registered** → auto-register it:

1. Read `.claude/settings.local.json` if it exists. If the file does not exist,
   start with an empty JSON object `{}`.
2. Merge the stop hook into the existing JSON, preserving all existing settings
   (permissions, other hooks, etc.). The hook entry to add:
   ```json
   {
     "hooks": {
       "Stop": [
         {
           "matcher": "",
           "hooks": [
             {
               "type": "command",
               "command": "bash {AEGIS_HOME}/scripts/aegis-build-stop.sh"
             }
           ]
         }
       ]
     }
   }
   ```
   If `hooks` already exists, add the `Stop` array to it. If `hooks.Stop`
   already exists, append the aegis entry to the existing array.
3. Write the merged JSON back to `.claude/settings.local.json`.
4. Tell the user:
   > Stop hook registered automatically. Re-run `/aegis:build` so the hook
   > takes effect.
5. **Stop execution.** The hook is not active until Claude Code reloads settings
   on the next invocation. Do not proceed to Step 3 — the user must re-run.

---

### Step 3: Select task(s)

Handle the following modes based on arguments passed to the command:

**`--task TASK-NNN`** — implement a single specific task. Verify it exists in
the actionable list. If it is not actionable (done or has unmet deps), warn
the user and ask whether to proceed anyway.

**`--all`** — implement all actionable tasks in sequence. The stop hook handles
advancing from one task to the next.

**`--no-recovery`** — disable recovery mode. When a task exceeds max iterations,
the build halts immediately instead of generating fix attempts.

**`--review-interval N`** — run a lightweight checkpoint review every N
completed tasks (default: 5). The review checks traceability, security stubs,
and test alignment. Set to 0 to disable checkpoint reviews.

**`--parallel-mode agent|worktree`** — select how `[P]` parallel groups are
executed (default: `agent`).
- `agent` — uses Claude Code Agent tool with `isolation: "worktree"` for true
  concurrent execution. Each parallel task runs in its own agent with an
  isolated worktree. The coordinator merges results after all agents complete.
- `worktree` — uses git worktrees with sequential execution (legacy approach).

**Interactive (no args)** — if exactly 1 task is actionable, auto-start it
without showing a menu:

```
Auto-starting TASK-001: Project scaffolding (only actionable task)
```

Build the task queue with that single task and proceed to Step 4.

If 2 or more tasks are actionable, present the list to the user:

```
Actionable tasks (dependencies satisfied):

  1. TASK-003: Setup authentication middleware
  2. TASK-004: [P] Implement user model
  3. TASK-005: [P] Implement post model
  ...

[P] = can run in parallel

Enter task number, range (e.g. 1-3), or 'all':
```

Build the **task queue** — an ordered list of task IDs to implement.

---

### Step 4: Initialize build state

Create the build state file by running:

```bash
bash "{AEGIS_HOME}/scripts/aegis-build-state.sh" ".aegis/build-state.json" init '<json>'
```

Where `<json>` is:

```json
{
  "active": true,
  "sessionId": "<current_session_id>",
  "taskQueue": ["TASK-003", "TASK-004"],
  "taskIndex": 0,
  "taskIteration": 1,
  "globalIteration": 1,
  "maxTaskIterations": 5,
  "level": "<formalism>",
  "outputDir": "<output.dir>",
  "nativeTaskMap": {},
  "nativeSyncEnabled": true,
  "nativeSyncFailures": 0,
  "recoveryMode": true,
  "fixTaskMap": {},
  "reviewInterval": 5,
  "parallelMode": "agent",
  "parallelActive": false
}
```

The `sessionId` should be a unique identifier for this session to prevent
stale hooks from interfering with new sessions.

If `--no-recovery` was specified, set `"recoveryMode": false` in the JSON.

If `--review-interval N` was specified, set `"reviewInterval": N` in the JSON.
If `--review-interval 0` was specified, checkpoint reviews are disabled.

If `--parallel-mode worktree` was specified, set `"parallelMode": "worktree"`.

---

### Step 4.5: Register native tasks for progress tracking

For each task ID in the task queue, create a Claude Code native task for
real-time progress visibility in the sidebar.

For each TASK-NNN in the queue:
1. Call `TaskCreate` with:
   - `subject`: `"TASK-NNN: <task title>"`
   - `description`: `"Implements: <implements refs from task entry>"`
2. Store the returned task ID in build state:
   ```bash
   bash "{AEGIS_HOME}/scripts/aegis-build-state.sh" ".aegis/build-state.json" set-native-map "TASK-NNN" "<returned_task_id>"
   ```

**Graceful degradation:** If `TaskCreate` fails for any task, record the failure:

```bash
bash "{AEGIS_HOME}/scripts/aegis-build-state.sh" ".aegis/build-state.json" sync-fail
```

If the output shows `SYNC_DISABLED=true` (3 consecutive failures), skip remaining
registrations. The build proceeds without native task visibility — this is
non-blocking and must never prevent the build from running.

---

### Step 5: Handle parallel groups

If the selected task queue contains consecutive `[P]` tasks forming a parallel
group (identified in Step 1 as `PARALLEL_GROUP_*`), dispatch them based on the
configured `parallelMode` from build state.

If the user selected `--task` for a single task, skip this step.

**Agent mode** (`parallelMode: "agent"`, default):

1. Set parallel active flag:
   ```bash
   bash "{AEGIS_HOME}/scripts/aegis-build-state.sh" ".aegis/build-state.json" parallel-start
   ```

2. For each task in the parallel group, gather its context:
   ```bash
   bash "{AEGIS_HOME}/scripts/aegis-build-context.sh" "<output.dir>" "TASK-NNN"
   ```

3. Read the build agent definition from `{AEGIS_HOME}/agents/build-agent.md`.

4. Launch all agents in a **single message** using the Agent tool (enables
   true concurrent execution). For each TASK-NNN in the parallel group:

   ```
   Agent(
     description: "Build TASK-NNN",
     subagent_type: "general-purpose",
     isolation: "worktree",
     prompt: |
       You are a parallel build agent for the Aegis Framework. Implement
       TASK-NNN following these rules:

       <full build-agent.md rules>

       IMPORTANT — Parallel mode overrides:
       - Do NOT modify tasks.md — the coordinator marks tasks done after merge
       - DO append to build-progress.md in your worktree
       - Commit implementation files + build-progress.md only

       Task context:
       <===TASK_ENTRY=== output for TASK-NNN>

       Design context:
       <===DESIGN_CONTEXT=== output for TASK-NNN>

       Test context:
       <===TEST_CONTEXT=== output for TASK-NNN>

       Project: <project.name> | Stack: <project.stack> | Level: <formalism>
       Output dir: <output.dir>

       Output <aegis:signal>TASK_COMPLETE</aegis:signal> with commit hash
       when verified.
   )
   ```

5. Wait for all agents to complete. Collect their results (worktree paths,
   branch names, whether changes were made).

6. Merge results sequentially:
   - For each completed agent that made changes: merge its branch into the
     current branch
   - If a merge conflict occurs: abort that merge, record the conflict, and
     mark the task as needing manual resolution
   - After all merges: mark all successfully merged tasks as done using
     `aegis-build-mark.sh` for each task
   - Append all agents' progress entries to `build-progress.md`
   - Commit the merged `tasks.md` and `build-progress.md` updates
   - Advance the build state index past all parallel tasks

7. Clear parallel active flag:
   ```bash
   bash "{AEGIS_HOME}/scripts/aegis-build-state.sh" ".aegis/build-state.json" parallel-end
   ```

8. If any merges failed with conflicts, report them to the user and stop for
   manual resolution. Otherwise, continue to the next sequential task.

**Worktree mode** (fallback, or `--parallel-mode worktree`):

Use the legacy git worktree approach with sequential execution:

```bash
bash "{AEGIS_HOME}/scripts/aegis-build-worktree.sh" create "aegis-build" TASK-004 TASK-005
```

This creates isolated worktrees so parallel tasks do not conflict. Tasks are
executed sequentially within their worktrees by the normal build loop.

If git worktree creation fails (e.g., not a git repo, dirty working tree),
warn the user and fall back to sequential execution.

**Automatic fallback:** If agent mode is selected but the Agent tool is
unavailable (permission denied, tool error on first dispatch), automatically
fall back to worktree mode with a warning message.

---

### Step 6: Gather implementation context

For the first task in the queue, run the context extractor:

```bash
bash "{AEGIS_HOME}/scripts/aegis-build-context.sh" "<output.dir>" "TASK-NNN"
```

Parse the delimited output sections:
- `===TASK_ENTRY===` — the full task specification
- `===DESIGN_CONTEXT===` — referenced design properties and their details
- `===TEST_CONTEXT===` — referenced test specifications (if tests.md exists)

---

### Step 6.5: Initialize progress tracking

If `<output.dir>/build-progress.md` does not exist, create it:

```markdown
# Build Progress

Accumulated context from the build loop. Each task appends its status,
changed files, and learnings here. Read this before starting each task.

---
```

If it already exists (from a prior build session), keep it — accumulated
learnings carry forward.

---

### Step 7: Dispatch to build agent

Read the build agent definition:

```
{AEGIS_HOME}/agents/build-agent.md
```

**Update native task status** (if `nativeSyncEnabled` is true in build state):

If the current task has a mapping in `nativeTaskMap`, call `TaskUpdate` with
`status: "in_progress"`. If `TaskUpdate` fails, record via `sync-fail` action
and continue — sync failures are non-blocking.

Dispatch to the build agent with the following inputs:

- **task_id**: current task from the queue
- **task_entry**: content from `===TASK_ENTRY===`
- **design_context**: content from `===DESIGN_CONTEXT===`
- **test_context**: content from `===TEST_CONTEXT===` (may be empty)
- **project_name**: `project.name` from config
- **stack**: `project.stack` from config
- **level**: `formalism` from config
- **output_dir**: `output.dir` from config
- **aegis_home**: AEGIS_HOME resolved in Bootstrap
- **progress**: contents of `<output.dir>/build-progress.md`
- **iteration**: `taskIteration` from build state

Follow the build agent's rules to implement the task. The build agent defines:
- File modification safety (Edit vs Write)
- Commit discipline (one task = one commit)
- Done marking (via `aegis-build-mark.sh`)
- Signal protocol (`<aegis:signal>TASK_COMPLETE</aegis:signal>` with verification)
- Progress tracking (append to `build-progress.md`)
- Task modification requests (`<aegis:signal>TASK_MODIFICATION_REQUEST</aegis:signal>`)

Do not implement tasks directly — follow the build agent's rules and signal
protocol. The coordinator (this command) manages orchestration; the agent
handles implementation.

The stop hook (`aegis-build-stop.sh`) manages the loop between tasks:
- Running `build.verifyCommand` (if configured) and rejecting TASK_COMPLETE if it fails
- Detecting `<aegis:signal>TASK_COMPLETE</aegis:signal>` and advancing to the next task
- Feeding context for the next task back into the session
- Handling `<aegis:signal>TASK_MODIFICATION_REQUEST</aegis:signal>` (advance on ADD_FOLLOWUP, retry on SPLIT_TASK/ADD_PREREQUISITE)
- Retrying if completion signal is not produced within max iterations
- Stopping after max iterations are exceeded
- Detecting and blocking secret file commits
- Detecting contradictions (claiming complete while also blocked)

---

### Step 8: Post-completion

After the build loop ends (either all tasks done or interrupted), perform
these cleanup steps:

**If parallel agents were used (agent mode):**

Agent-mode merge happens inline in Step 5 after all agents complete. No
additional merge step is needed here. The coordinator already merged branches,
marked tasks done, and cleaned up worktrees (the Agent tool handles worktree
cleanup automatically when using `isolation: "worktree"`).

**If parallel worktrees were used (worktree mode):**

Merge all worktree branches back:
```bash
bash "{AEGIS_HOME}/scripts/aegis-build-worktree.sh" merge "aegis-build"
```

If any merge conflicts occur, report them to the user and stop for manual
resolution.

After successful merge, clean up:
```bash
bash "{AEGIS_HOME}/scripts/aegis-build-worktree.sh" cleanup "aegis-build"
```

**Final native task sync** (if `nativeSyncEnabled` is true in build state):

For each task in the task queue:
- If done in `tasks.md`: `TaskUpdate(taskId, status: "completed")`
- If not done: leave the native task as-is (user sees remaining work)

Sync failures are non-blocking — skip and continue if `TaskUpdate` fails.

**Report summary:**

Re-run the task parser to get final counts:
```bash
bash "{AEGIS_HOME}/scripts/aegis-build-parse.sh" "<output.dir>/tasks.md"
```

Display:

```
/aegis:build — Complete

Progress
  [DONE]/[TOTAL] tasks implemented
  [REMAINING] tasks remaining (if any)

Completed this session
  TASK-003: Setup authentication middleware
  TASK-004: Implement user model
  ...

Remaining (if any)
  TASK-010: Analytics integration
  TASK-011: Monitoring setup
  ...

Next steps
  - Run /aegis:validate for a full coverage report
  - Run /aegis:build to continue with remaining tasks
  - Run /aegis:tests to verify RED→GREEN transition
```

---

## Error Handling

| Condition | Action |
|-----------|--------|
| Baseline verify command fails | Stop. Project must be green before build loop starts. |
| Verify command fails after TASK_COMPLETE | Reject signal. Agent must fix the regression before re-signaling. |
| `.aegis/config.yaml` missing | Stop. Tell user to run `/aegis:init`. |
| `tasks.md` missing | Stop. Tell user to run `/aegis:tasks`. |
| `design.md` missing | Stop. Tell user to run `/aegis:design`. |
| Stop hook not registered | Show registration instructions and stop. |
| Dependency deadlock | Report blocked tasks and unsatisfied deps. |
| All tasks already done | Report completion status. |
| Max iterations exceeded | If recovery mode enabled, generate fix attempt (up to 3). Otherwise stop loop, report stuck task. |
| Recovery fix attempts exhausted | Stop loop, report task and number of fix attempts tried. |
| Secrets detected in staged files | Stop loop, report files. |
| Contradiction in completion signal | Stop loop, report contradiction. |
| Modification request (SPLIT/PREREQ) | Retry with proposed changes. |
| Modification request (ADD_FOLLOWUP) | Advance — current task is done. |
| Git worktree creation fails | Warn and fall back to sequential execution. |
| Merge conflicts after parallel | Report conflicts for manual resolution. |
| Native task sync failure | Log, disable after 3 consecutive, build continues. |
| Checkpoint review critical failure | Include action items in next task prompt. |

---
name: aegis:status
description: Show current Aegis state, coverage, next steps
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

# `/aegis:status` — Show Aegis Project State

You are executing the `/aegis:status` command. Your job is to read the project configuration and all available Aegis artifacts, compute a lightweight coverage snapshot, and display a concise status report. This command is **read-only** — it does not generate, modify, or delete any file.

Follow every step in order. Complete all steps before printing output. Do not ask the user any questions.

---

## Step 1: Check Initialization

Look for `.aegis/config.yaml` at the project root.

- If the file does **not** exist, print exactly the following and stop:

  ```
  Aegis not initialized. Run /aegis:init to get started.
  ```

- If the file exists, read it fully and extract:
  - `project.name`
  - `project.language` (default: `en` if not set)
  - `formalism` (default: `standard` if not set)
  - `output.dir` (default: `.aegis/` if not set)

---

## Step 2: Locate Artifacts

Using the `output.dir` value from config, check which artifact files exist:

| Artifact       | Expected path                    |
|----------------|----------------------------------|
| requirements   | `<output.dir>/requirements.md`   |
| design         | `<output.dir>/design.md`         |
| ui-design      | `<output.dir>/ui-design.md`      |
| tasks          | `<output.dir>/tasks.md`          |
| tests          | `<output.dir>/tests.md`          |

Get all artifact timestamps in one call by running via the Bash tool:

```bash
bash "{AEGIS_HOME}/scripts/aegis-timestamps.sh" "<output.dir>"
```

Parse the output: each line is `<filename>=<YYYY-MM-DD>` or `<filename>=NOT_FOUND`. Record the timestamps for existing artifacts.

---

## Step 3: Extract Stats from Each Artifact

For each artifact file that exists, parse its content and collect the following stats. All counts are done by scanning for the canonical ID patterns defined in `aegis/framework/SPEC.md §4`.

### requirements.md

- **REQ count**: count all lines matching the pattern `^REQ-\d{3}:` (three-digit zero-padded IDs)
- **SEC-REQ count**: count all lines matching `^SEC-REQ-[A-Z0-9_-]+:`
- **Stale check**: record the file's last modified timestamp for use in Step 4

### design.md

- **PROP count**: count all lines matching `^PROP-\d{3}:`
- **SEC-PROP count**: count all lines matching `^SEC-PROP-[A-Z0-9_-]+:`
- **Component count**: count all level-2 headings (`^## `) that are not named "Validation Notes", "Security Properties", or "Overview"; these represent design components
- **Stale check**: record the file's last modified timestamp

### tasks.md

- **TASK count (total)**: count all lines matching `^TASK-\d{3}:`
- **TASK count (completed)**: count all lines matching `^TASK-\d{3}:` that are followed (within the same task block) by a line containing `Status: done`, `Status: complete`, or `[x]` in a markdown checkbox context — use a case-insensitive match
- **Stale check**: record the file's last modified timestamp

### ui-design.md (optional)

- **UI count**: count all lines matching `^UI-\d{3}:`
- **Stale check**: record the file's last modified timestamp

### tests.md

- **TEST-REQ count**: count all lines matching `^TEST-REQ-\d{3}:`
- **TEST-PROP count**: count all lines matching `^TEST-PROP-\d{3}:`
- **TEST-SEC count**: count all lines matching `^TEST-SEC-[A-Z0-9_-]+:`
- **Stale check**: record the file's last modified timestamp

---

## Step 4: Quick Coverage Check

This step only runs if **two or more** artifacts exist. It computes a lightweight coverage percentage without doing full cross-artifact validation (that is reserved for `/aegis:validate`).

### Coverage Rule

Coverage is defined as: the fraction of REQs that have at least one traceable element in a downstream artifact.

Use this simplified proxy formula:

```
coverage % = (REQs_with_downstream / total_REQs) × 100
```

Where `REQs_with_downstream` is estimated as follows:

- If **requirements.md and design.md** both exist:
  - Scan design.md for all `Derives from:` references.
  - Collect the set of unique REQ-NNN and SEC-REQ-* IDs mentioned in those references.
  - `REQs_covered_by_design` = size of that set.

- If **design.md and tasks.md** both exist:
  - Scan tasks.md for all `Implements:` references.
  - Collect the set of unique PROP-NNN and SEC-PROP-* IDs mentioned.
  - Map those PROP IDs back to the REQ IDs they `Derives from` in design.md.
  - Union this with `REQs_covered_by_design`.

- If **design.md and tests.md** both exist:
  - Scan tests.md for all `Tests:` references.
  - Collect the set of unique PROP-NNN, SEC-PROP-*, REQ-NNN, and SEC-REQ-* IDs mentioned.
  - Union this into the covered-REQs set.

- `total_REQs` = REQ count + SEC-REQ count from requirements.md (or 0 if requirements.md does not exist)

If requirements.md does not exist but other artifacts do, skip the coverage percentage and print `N/A (requirements.md not generated)`.

Round the final percentage to one decimal place.

### Stale Artifact Detection

An artifact is **stale** if its upstream source was modified **after** the artifact itself was last modified. Apply the propagation rules from `aegis/framework/SPEC.md §9`:

| Source changed    | Potentially stale                              |
|-------------------|------------------------------------------------|
| requirements.md   | design.md, ui-design.md, tasks.md, tests.md    |
| design.md         | ui-design.md, tasks.md, tests.md               |
| ui-design.md      | tasks.md                                       |

For each artifact that exists, compare its last-modified timestamp against the last-modified timestamp of each of its upstream sources. If a source is newer than the artifact, mark the artifact as stale and record which source triggered it (e.g., "requirements.md added since last generation").

Also check if the artifact contains a `> NEEDS REVIEW` notice at the top (from `/aegis:update`). If present, mark it as stale regardless of timestamps.

---

## Step 5: Determine Next Step

Based on which artifacts exist and their stale status, determine the single most useful next action:

| Situation                                       | Recommendation                                              |
|-------------------------------------------------|-------------------------------------------------------------|
| No artifacts exist                              | `/aegis:requirements`                                         |
| Only requirements.md exists                     | `/aegis:design`                                               |
| requirements.md + design.md exist              | `/aegis:ui-design` (if frontend project) or `/aegis:tasks`   |
| requirements.md + design.md + ui-design.md exist| `/aegis:tasks` and/or `/aegis:tests`                          |
| requirements.md + design.md + tasks.md exist   | `/aegis:tests`                                                |
| All core artifacts exist, none stale           | `/aegis:validate` or start implementation                     |
| Any artifact is stale                           | `/aegis:update [stale artifact name]` to propagate changes    |
| Coverage < 60%                                  | `/aegis:validate` to find and fix coverage gaps               |

If multiple recommendations apply, use the first matching rule in the table above (top to bottom).

---

## Step 6: Display Status Report

Print the status report using the format below. Replace all `[placeholders]` with computed values. Follow the formatting rules exactly.

### Artifact Status Icons

| Condition                       | Icon |
|---------------------------------|------|
| Artifact exists, not stale      | ✅   |
| Artifact exists, stale          | ⚠️   |
| Artifact does not exist         | ❌   |

### Output Format

```
Aegis Status — [project.name]
Level: [formalism] | Language: [language]

Artifacts:
  [icon] requirements.md  ([REQ count] REQs, [SEC-REQ count] SEC-REQs, last updated [date])
  [icon] design.md         ([component count] components, [PROP count] PROPs + [SEC-PROP count] SEC-PROPs, last updated [date])
  [icon] ui-design.md      ([UI count] UI specs, last updated [date])
  [icon] tasks.md          ([completed count]/[total count] tasks complete, last updated [date])
  [icon] tests.md          ([TEST-REQ count] req tests, [TEST-PROP count] prop tests, [TEST-SEC count] security tests, last updated [date])

Coverage: [N]% (see /aegis:validate for details)
Next step: [recommendation]
```

### Formatting Rules

1. For artifacts that **do not exist**, replace the stats and date fields with `(not generated yet)`. Example:
   ```
     ❌ tests.md          (not generated yet)
   ```

2. For artifacts that are **stale**, add a parenthetical note after the stats that names the upstream source. Use the most specific reason available. Example:
   ```
     ⚠️  tasks.md          (12/15 tasks complete — needs review: requirements.md updated since last generation, last updated 2026-03-28)
   ```

3. If `tests.md` does not exist, omit the security test count from coverage and note it inline:
   ```
   Coverage: N/A (tests.md not generated yet)
   ```

4. If only one artifact exists (and it is not requirements.md), coverage is still N/A but include the artifact in the Artifacts block.

5. The `date` field uses ISO format `YYYY-MM-DD`.

6. Align the artifact rows for readability using spaces. Match the width shown in the format template above.

7. Print nothing else — no headers, no extra commentary, no markdown fences around the output.

---

## Implementation Notes

- This command does not invoke any sub-agent. All parsing is done inline by you, the skill.
- Use the Read tool to read artifact files. Use the Bash tool only for the `aegis-timestamps.sh` script call to get all file modification timestamps in a single invocation.
- Do not validate artifact content beyond the pattern-matching described in Step 3. Deep validation is reserved for `/aegis:validate`.
- If a file read fails (e.g., the file is unreadable), treat it as not existing and mark it `❌`.
- The counts in Step 3 are approximate — they rely on ID pattern matching, not full parsing. This is intentional: `/aegis:status` must be fast. Exact counts are the domain of `/aegis:validate`.
- Regex patterns to use for ID detection (apply to each line):
  - REQ: `^REQ-\d{3}:`
  - SEC-REQ: `^SEC-REQ-[A-Z0-9_-]+:`
  - PROP: `^PROP-\d{3}:`
  - SEC-PROP: `^SEC-PROP-[A-Z0-9_-]+:`
  - UI: `^UI-\d{3}:`
  - TASK: `^TASK-\d{3}:`
  - TEST-REQ: `^TEST-REQ-\d{3}:`
  - TEST-PROP: `^TEST-PROP-\d{3}:`
  - TEST-SEC: `^TEST-SEC-[A-Z0-9_-]+:`
  - Cross-reference scan: `Derives from:`, `Implements:`, `Tests:`

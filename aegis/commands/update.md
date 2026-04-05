---
name: aegis:update
description: Update an artifact and check downstream impact
---

## Bootstrap

Before executing this command, resolve the Aegis framework root path (**AEGIS_HOME**) using absolute paths only (the Read and Glob tools do not resolve `~`):

1. Run `echo $HOME` via the Bash tool to obtain the user's absolute home directory path (e.g., `/Users/alice`).
2. Check if `<project_root>/.claude/aegis/framework/SPEC.md` exists → if yes, **AEGIS_HOME** = `<project_root>/.claude/aegis`
3. Else check if `<HOME>/.claude/aegis/framework/SPEC.md` exists → if yes, **AEGIS_HOME** = `<HOME>/.claude/aegis`
4. Else → tell the user to install Aegis with `npx aegis-sdd` and stop.

Now read `{AEGIS_HOME}/shared/preamble.md` and apply all path mappings and core rules defined there before proceeding with the steps below.

---

# `/aegis:update [artifact]` — Update Artifact and Check Downstream Impact

You are executing the `/aegis:update` command. Your job is to re-generate a chosen artifact after its sources have changed, preserve user customizations where possible, and show the downstream impact on dependent artifacts — offering to cascade updates. Follow every step in order. Do not skip steps. Do not combine steps into a single prompt.

---

## Usage

```
/aegis:update requirements   — re-read input docs, regenerate requirements.md
/aegis:update design         — re-read requirements.md, regenerate design.md
/aegis:update ui-design      — re-read requirements.md + design.md, regenerate ui-design.md
/aegis:update tasks          — re-read design.md + requirements.md, regenerate tasks.md
/aegis:update tests          — re-read all upstream artifacts, regenerate tests.md
```

---

## Pre-flight: Read Configuration

Before anything else, read `.aegis/config.yaml` at the project root. If it does not exist, stop immediately and tell the user:

```
.aegis/config.yaml not found. Run /aegis:init first.
```

If the file exists, load and store all values (project name, language, formalism, inputs, output dir, security_features). All later steps use this configuration.

---

## Step 1: Parse Argument

Determine which artifact to update from the command argument.

**If an argument was provided**, match it against the artifact names:
- `requirements` → artifact = requirements.md
- `design` → artifact = design.md
- `ui-design` → artifact = ui-design.md
- `tasks` → artifact = tasks.md
- `tests` → artifact = tests.md

If the argument does not match any of the names, display an error and the usage block above, then stop.

**If no argument was provided**, ask the user:

```
Which artifact do you want to update?

  a) requirements — re-read input docs, regenerate requirements.md
  b) design       — re-read requirements.md, regenerate design.md
  c) ui-design    — re-read requirements.md + design.md, regenerate ui-design.md
  d) tasks        — re-read design.md + requirements.md, regenerate tasks.md
  e) tests        — re-read all upstream artifacts, regenerate tests.md

Enter a, b, c, d, or e:
```

Wait for the user's selection. Map it to the artifact name before continuing.

---

## Step 2: Read Current State

Read the existing artifact file from the output directory declared in `.aegis/config.yaml` (default: `.aegis/`).

If the artifact file does not exist, tell the user:

```
<artifact>.md not found in <output.dir>.
Nothing to update — run /aegis <command> first to generate it.
```

Then stop.

**For each artifact, also read its sources:**

| Artifact being updated | Sources to read |
|---|---|
| requirements.md | All input documents listed in `.aegis/config.yaml` under `inputs` |
| design.md | `.aegis/requirements.md` |
| ui-design.md | `.aegis/requirements.md` and `.aegis/design.md` |
| tasks.md | `.aegis/design.md`, `.aegis/ui-design.md` (if exists), and `.aegis/requirements.md` |
| tests.md | `.aegis/design.md` and `.aegis/requirements.md` |

If a source file is missing, warn the user:

```
Warning: <source>.md not found. Change detection will be limited.
```

Continue with whatever sources are available.

---

## Step 3: Detect Changes

Compare the content of the current sources against the state recorded in the existing artifact. The artifact was generated from its sources at a prior point in time — you are now identifying what has drifted.

**For requirements.md**, compare the input documents to the existing requirements:
- New REQ-NNN IDs that have no corresponding derivation in design.md
- REQ-NNN IDs present in requirements.md but missing from current input docs content
- Acceptance criteria or user story text that differs from what is summarized in requirements.md
- New SEC-REQ-* that are now applicable based on `security_features` in `.aegis/config.yaml` but are absent from requirements.md

**For design.md**, compare requirements.md to the existing design:
- REQ-NNN or SEC-REQ-* entries in requirements.md with no `Derives from` link in any PROP-NNN or SEC-PROP-*
- PROP-NNN or SEC-PROP-* entries in design.md whose source requirement has been removed or heavily modified

**For tasks.md**, compare design.md to the existing tasks:
- PROP-NNN or SEC-PROP-* entries in design.md with no `Implements` link in any TASK-NNN
- TASK-NNN entries in tasks.md whose source property no longer exists in design.md

**For tests.md**, compare design.md and requirements.md to the existing tests:
- PROP-NNN or SEC-PROP-* entries with no TEST-* entry
- SEC-PROP-* entries with no TEST-SEC-* entry
- TEST-* entries referencing IDs that no longer exist in design.md or requirements.md

**Present the detected changes to the user before regenerating:**

```
Change detection complete.

Artifact: requirements.md
Sources scanned: docs/PROJECT_SPEC.md, docs/BRAND.md

Changes detected:
  + REQ-012 appears to be new content (section "Export to CSV" in spec has no matching requirement)
  ~ REQ-005 acceptance criteria may have changed (spec §3.2 was updated)
  - REQ-009 source content not found in current input docs (possible removal)
  + SEC-REQ-UPLOAD-01 should be present (has_file_upload = true) but is missing

No changes detected in 9 other requirements.

Proceed with regeneration? (y/n):
```

If the user replies `n`, stop. If the user replies `y`, continue to Step 4.

If no changes are detected at all, tell the user:

```
No changes detected. <artifact>.md appears to be up to date with its sources.

Run /aegis:validate for a full cross-artifact audit.
```

Then stop.

---

## Step 4: Regenerate

Re-generate the artifact using the same logic as the original generation command, with these modifications:

**Pre-fill from previous answers.** For every question that the original command would ask, check whether the existing artifact contains sufficient information to answer it. If so, silently use that answer — do not ask the question again. Only ask questions when:
- The answer is not determinable from the existing artifact, OR
- The question relates to new or changed content detected in Step 3

**Show the user which questions are being pre-filled:**

```
Regenerating requirements.md.

Pre-filling from existing artifact:
  - Formalism level: standard (from config)
  - Language: en (from config)
  - Stack context: Next.js + PostgreSQL (from .aegis/config.yaml)
  - 11 existing requirements preserved without changes

New questions for changed/new content:
```

Then ask only the new questions, one at a time, waiting for an answer before the next.

**Preserve user customizations.** Before overwriting, identify any content in the existing artifact that does not appear to be auto-generated — for example, manually written notes, custom sections not in the template, or content in `<!-- custom -->` markers. Flag these sections:

```
The following sections in the existing artifact appear to be custom content
(not generated by /aegis). They will be preserved in the updated artifact:

  - "## Architecture Decision Notes" (lines 87–102) — not in template
  - "## Team Notes" (lines 134–138) — not in template

Preserving them. If you want to remove them, edit the file manually after update.
```

Silently preserve these sections by appending them at the bottom of the regenerated artifact under a `## Preserved Custom Content` heading.

**Security.** Always re-inject security content at full rigor, regardless of what was in the previous artifact. Read `aegis/framework/security/SECURITY_UNIVERSAL.md` and the relevant YAML files. Do not preserve old SEC-REQ-* or SEC-PROP-* verbatim — they are replaced with the current output of the security agent.

**Write the updated artifact.** Overwrite the existing file at its current path. Do not print the full artifact content to the user — confirm the write with a single line:

```
Written: .aegis/requirements.md
```

**Run light validation.** After writing, run the same light validation checks that the original generation command would run (as defined in `aegis/framework/SPEC.md §6`). Report the results inline:

```
Light validation:
  PASS  SEC-REQ section present
  PASS  Minimum SEC-REQ entries (8 present)
  PASS  No duplicate IDs
  WARN  REQ-014 has no acceptance criteria (standard level expects WHEN/SHALL/THEN)
```

If any critical check fails, stop and report the failure. Do not proceed to Step 5 until the artifact passes all critical checks.

---

## Step 5: Impact Analysis

After successful regeneration and validation, identify which downstream artifacts are now potentially stale.

**Downstream dependency map:**

| Updated Artifact | Downstream Artifacts Needing Review |
|---|---|
| requirements.md | design.md, ui-design.md, tasks.md, tests.md |
| design.md | ui-design.md, tasks.md, tests.md |
| ui-design.md | tasks.md |
| tasks.md | (none — leaf artifact) |
| tests.md | (none — leaf artifact) |

If there are no downstream artifacts (tasks or tests were updated), skip to the end of this step and display:

```
No downstream artifacts — <artifact>.md is a leaf in the dependency chain.
Update complete.
```

Then stop.

For artifacts with downstream dependencies, analyze each downstream artifact to identify specific stale elements:

**For design.md** (when requirements.md was updated):
- List any new REQ-NNN from Step 3 that have no PROP-NNN `Derives from` link in design.md
- List any PROP-NNN in design.md whose source REQ-NNN was modified in Step 3
- List any new SEC-REQ-* that have no corresponding SEC-PROP-* in design.md

**For tasks.md** (when requirements.md or design.md was updated):
- List any new PROP-NNN from the upstream change that have no TASK-NNN `Implements` link
- List any TASK-NNN that implements a PROP-NNN which was modified or removed

**For tests.md** (when requirements.md or design.md was updated):
- List any new PROP-NNN or REQ-NNN from the upstream change with no TEST-* entry
- List any TEST-* entries referencing IDs that changed significantly
- List any new SEC-PROP-* with no TEST-SEC-* entry

**Present the impact analysis:**

```
requirements.md updated.

Impact analysis:
  Changes made:
    + REQ-012 added (Export to CSV)
    ~ REQ-005 acceptance criteria updated (tighter file size constraint)
    + SEC-REQ-UPLOAD-01 injected (upload security requirement)

  Downstream artifacts affected:

  design.md:
    - No PROP-NNN for REQ-012 (new requirement unaddressed in design)
    - PROP-003 derives from REQ-005 — review for criteria change impact
    - No SEC-PROP-UPLOAD for SEC-REQ-UPLOAD-01 (new security requirement)

  tasks.md:
    - No TASK-NNN for REQ-012 (no task for new requirement)
    - TASK-011 implements PROP-003 — may need update

  tests.md:
    - No TEST-PROP for REQ-012 / PROP-NNN (not yet designed)
    - TEST-PROP-003 — may need update if PROP-003 changes

  3 downstream artifacts need review.
```

**Write the "needs review" notice** to the top of each downstream artifact that has affected entries. Prepend the following block to the file (do not modify the rest of the file):

```markdown
> NEEDS REVIEW — requirements.md was updated on <ISO date>.
> Affected entries: REQ-012 (new), REQ-005 (changed), SEC-REQ-UPLOAD-01 (new).
> Re-run `/aegis:design`, `/aegis:tasks`, and `/aegis:tests` to propagate changes,
> or manually review and update this artifact to reflect the new requirements.
> Remove this notice when the review is complete.
```

Use today's date in ISO format (YYYY-MM-DD) for `<ISO date>`.

---

## Step 6: Cascade (If Requested)

After the impact analysis, ask the user which downstream artifacts to update now:

```
Would you like to update any downstream artifacts now?

  a) design.md
  b) ui-design.md
  c) tasks.md
  d) tests.md
  e) all of the above
  f) none — I'll review manually

Enter a letter or comma-separated letters (e.g., "a,c"):
```

Wait for the user's selection.

**If the user selects `f` (none):**

```
Understood. The "NEEDS REVIEW" notices have been written to downstream artifacts.
Run /aegis:update <artifact> when you're ready to propagate changes.
```

Stop.

**If the user selects one or more artifacts:**

Run the update for each selected artifact in dependency order:
1. design.md (must come before ui-design.md, tasks.md, and tests.md)
2. ui-design.md (must come before tasks.md)
3. tasks.md
4. tests.md

For each artifact in the sequence:
1. Announce the start:

```
---
Updating design.md...
```

2. Execute Steps 2–5 of this command for that artifact, treating the just-updated upstream artifact as the source. The same change detection, regeneration, and validation rules apply.

3. After each artifact completes its Step 5 impact analysis, continue automatically to the next artifact in the sequence without re-asking the cascade question. The cascade is already authorized by the user's selection in this step.

4. Remove the "NEEDS REVIEW" notice from any artifact that was successfully updated during this cascade.

**After all selected artifacts have been updated, display a final summary:**

```
Update cascade complete.

  Updated artifacts:
    requirements.md  — regenerated, 12 REQs + 8 SEC-REQs
    design.md        — regenerated, 11 PROPs + 5 SEC-PROPs
    tasks.md         — regenerated, 23 TASKs

  Remaining with NEEDS REVIEW notice:
    tests.md  — not updated in this session

  Next step: run /aegis:update tests or /aegis:tests to complete propagation.
```

If all selected artifacts were updated successfully and no "NEEDS REVIEW" notices remain, display instead:

```
Update cascade complete. All artifacts are up to date.

Run /aegis:validate for a full cross-artifact audit.
```

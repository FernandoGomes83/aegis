---
name: aegis:tasks
description: Generate tasks.md from design + requirements
---

## Bootstrap

Before executing this command, resolve the Aegis framework root path (**AEGIS_HOME**) using absolute paths only (the Read and Glob tools do not resolve `~`):

1. Run `echo $HOME` via the Bash tool to obtain the user's absolute home directory path (e.g., `/Users/alice`).
2. Check if `<project_root>/.claude/aegis/framework/SPEC.md` exists → if yes, **AEGIS_HOME** = `<project_root>/.claude/aegis`
3. Else check if `<HOME>/.claude/aegis/framework/SPEC.md` exists → if yes, **AEGIS_HOME** = `<HOME>/.claude/aegis`
4. Else → tell the user to install Aegis with `npx aegis-sdd` and stop.

Now read `{AEGIS_HOME}/shared/preamble.md` and apply all path mappings and core rules defined there before proceeding with the steps below.

---

# /aegis:tasks

Generate `tasks.md` — an ordered implementation plan derived from `design.md`
and `requirements.md`, with full bidirectional traceability to all PROP-NNN,
SEC-PROP-*, REQ-NNN, and SEC-REQ-* IDs.

---

## Prerequisites

Before executing any step, verify the following. If any condition is not met,
stop and report the issue to the user with a clear message.

- `.aegis/config.yaml` must exist at the project root. If missing, tell the user
  to run `/aegis:init` first.
- `requirements.md` must exist in the configured output directory
  (`output.dir` from config, default: `.aegis/`).
- `design.md` must exist in the configured output directory.

If either artifact is marked with a `> NEEDS REVIEW` notice at the top, warn
the user that the source has changed and ask whether to proceed with the current
content or re-run the upstream command first.

---

## Flow

### Step 1: Load configuration and artifacts

Read `.aegis/config.yaml`. Extract:
- `formalism` → determines task format (light / standard / formal)
- `language` → load i18n labels from `aegis/framework/i18n/<language>.yaml`
- `project.name` and `project.stack` → used in artifact header
- `output.dir` → path to read requirements.md and design.md

Read `<output.dir>/requirements.md`. Extract and index:
- All **REQ-NNN** IDs and their titles
- All **SEC-REQ-*** IDs and their titles
- Total requirement count

Read `<output.dir>/design.md`. Extract and index:
- All **PROP-NNN** IDs, their titles, and which REQ-NNN IDs they derive from
- All **SEC-PROP-*** IDs and which SEC-REQ-* IDs they derive from
- All named **components** (component sections / design areas)

If `<output.dir>/ui-design.md` exists, also read and extract:
- All **UI-NNN** IDs, their titles, and which REQ-NNN or PROP-NNN IDs they derive from
- Design system specifications (for frontend implementation tasks)
- Page/screen specifications (for page-level implementation tasks)

Build a dependency map: for each PROP-NNN, note which other PROP-NNN entries
it depends on (based on component ownership and data-flow descriptions in
design.md). For each SEC-PROP-*, note which SEC-PROP-* entries it depends on
(e.g., authentication must precede IDOR enforcement). For each UI-NNN, note
which PROP-NNN or REQ-NNN it depends on.

---

### Step 2: Determine task ordering strategy

Analyze the extracted components and properties to define a logical build
sequence. Apply the following ordering heuristics — they reflect real
implementation dependencies and are not configurable by the user:

1. **Infrastructure and configuration first** — environment setup, database
   connections, CI configuration, secrets management, deployment scaffolding.
   These tasks have no upstream code dependencies and unblock everything else.

2. **Security middleware early** — authentication, session management, and
   rate limiting middleware must be in place before any business-logic route
   is implemented. SEC-PROP-* tasks for authentication and rate limiting belong
   in Block 1 or Block 2 at most.

3. **Data models before business logic** — schema migrations and ORM model
   definitions must precede any service or handler that reads or writes data.

4. **Business logic before UI** — service-layer and API handler tasks must
   precede any frontend component or page that calls them.

5. **Design system before UI components** — if `ui-design.md` exists, tasks
   for implementing the design system (tokens, theme, global styles) must
   precede individual UI component tasks. UI-NNN entries are implemented in
   order: design system → shared components → page-specific components → pages.

6. **Integrations after core logic** — third-party service integrations
   (payment processors, email providers, storage, analytics) come after the
   internal logic they wrap is stable.

6. **Analytics and observability last** — logging, metrics, and monitoring
   instrumentation are added after the features they observe are built.

7. **Checkpoints between logical blocks** — at **Formal** level, a
   CHECKPOINT task is required after each group of 3–7 related tasks. At
   Standard and Light levels, checkpoints are optional but recommended when
   there are more than 10 total tasks.

Produce a block-by-block ordering plan (internal, not shown to the user) that
maps each PROP-NNN and SEC-PROP-* to a named block and a position within that
block. This ordering plan is passed to the agent in Step 3.

---

### Step 3: Generate tasks.md

Dispatch to `aegis/agents/tasks-agent.md` with the following context package:

```
requirements_content:    <full text of requirements.md>
design_content:          <full text of design.md>
template_path:           aegis/framework/templates/tasks/<level>.template.md
i18n_labels:             <labels object loaded from i18n/<language>.yaml>
level_rules_path:        aegis/framework/levels/<level>.md
stack:                   <project.stack from config>
project_name:            <project.name from config>
ordering_strategy:       <block-by-block plan from Step 2>
req_ids:                 <indexed list of all REQ-NNN and SEC-REQ-* IDs>
prop_ids:                <indexed list of all PROP-NNN and SEC-PROP-* IDs>
components:              <indexed list of component names from design.md>
```

The agent is responsible for:

- Generating one TASK-NNN per logical unit of work, following the ordering
  strategy. Each task must include an `Implements:` field referencing one or
  more PROP-NNN, SEC-PROP-*, REQ-NNN, or SEC-REQ-* IDs.
- At **Standard** and **Formal** levels: decomposing each task into numbered
  subtasks (TASK-NNN.1, TASK-NNN.2, …). Subtasks that write test or
  verification logic must carry a `Tests:` reference to the corresponding
  TEST-* ID (even though tests.md has not been generated yet — the agent uses
  the naming convention `TEST-PROP-NNN` / `TEST-SEC-*` derived from the
  PROP/SEC-PROP IDs).
- At **Formal** level: adding PERT estimates to every task (`Nh (PERT: O=Xh,
  M=Yh, P=Zh)`) and inserting CHECKPOINT tasks between logical blocks.
- At **Standard** level: adding numeric or T-shirt-size estimates to every
  task.
- At **Light** level: generating a flat checklist with optional T-shirt size
  estimates.
- Including all applicable SEC-PROP-* tasks regardless of formalism level.
  Security tasks are never omitted. Every security task must have at least one
  subtask (Standard/Formal) or description (Light) with a `Tests:` reference
  pointing to the corresponding `TEST-SEC-*` ID.
- Writing the completed artifact to `<output.dir>/tasks.md`.

The template at `aegis/framework/templates/tasks/<level>.template.md` defines
the exact structural format. The agent must follow it precisely, substituting
all `{{placeholder}}` variables with real project content.

---

### Step 4: Light validation (after_tasks checks)

After the agent writes `tasks.md`, run the validation checks defined under
`after_tasks` in `aegis/framework/validation/rules.yaml`. Report results inline.

#### Checks to run:

**VAL-TASK-01 — Every TASK has an Implements reference** (error)
Parse every TASK-NNN entry. Verify that each has an `Implements:` field
referencing at least one ID that exists in either design.md or requirements.md.
If any TASK is missing `Implements:`, flag it with its ID and line number.

**VAL-TASK-02 — Every REQ has at least one TASK** (warning)
For each REQ-NNN and SEC-REQ-* in requirements.md, trace forward: does any
TASK-NNN implement a PROP-NNN that derives from this REQ, or does any TASK-NNN
implement this REQ directly? Build the full forward-trace chain. Report any
REQ-NNN or SEC-REQ-* with no reachable task.

**VAL-TASK-03 — No duplicate TASK IDs** (error)
Collect all TASK-NNN identifiers. Detect and report any collisions with their
line numbers.

**VAL-TASK-04 — Dependency graph is acyclic** (error)
Parse all `Depends on:` fields. Perform a depth-first traversal of the
dependency graph. Report any detected cycles with the full cycle path.

**VAL-TASK-05 — Estimates present (Standard and Formal only)** (warning)
At Standard and Formal levels, every TASK-NNN must include an `Estimate:`
field. Flag tasks without estimates at these levels.

**Additional check — Every PROP referenced by at least one TASK's Tests field**
For each PROP-NNN and SEC-PROP-* in design.md, verify that at least one TASK
subtask (or the task itself at Light level) includes a `Tests:` reference
pointing to the corresponding TEST-PROP-NNN or TEST-SEC-* ID. This check
ensures the implementation plan captures test intent, even before tests.md is
generated.

#### Reporting gaps:

If any **error-severity** check fails (VAL-TASK-01, VAL-TASK-03, VAL-TASK-04),
present the gaps clearly and ask the user:

> Validation found [N] error(s) in `tasks.md`. Would you like to:
> a) Fix the errors now (I will patch tasks.md)
> b) Backtrack to design.md (re-run `/aegis:design` to add missing properties)
> c) Proceed anyway (not recommended — downstream artifacts will have gaps)

If only **warning-severity** checks produce results, report them as an advisory
section and proceed.

---

### Step 5: Present for review

After validation passes (or the user accepts warnings), display a summary in
this exact format:

```
tasks.md generated!

Tasks
  [N] implementation tasks (TASK-001 to TASK-NNN)
  [M] subtasks across all tasks
  [K] security tasks (implementing SEC-PROP-*)
  [J] checkpoint tasks (Formal level only)

Coverage
  [P]% of PROP-NNN entries have a direct TASK reference
  [Q]% of REQ-NNN entries reachable from at least one TASK
  [R]% of SEC-PROP-* entries have at least one security task
  Estimated total effort: [X]h (if estimates are present)

Validation
  VAL-TASK-01: [PASS / N gaps]
  VAL-TASK-02: [PASS / N gaps]
  VAL-TASK-03: [PASS / N gaps]
  VAL-TASK-04: [PASS / N gaps]
  VAL-TASK-05: [PASS / N gaps / N/A for Light]
  Tests field coverage: [PASS / N props not yet linked]

Next step: /aegis:tests
```

Tell the user:

> Review `tasks.md` before proceeding. When you are satisfied, run `/aegis:tests`
> to generate the test specification and RED test files.

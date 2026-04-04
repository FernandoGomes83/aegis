# {{i18n.artifact_titles.tasks}} — {{project.name}}

> {{i18n.messages.auto_generated}}

---

## {{i18n.section_titles.overview}}

**Stack**: {{project.stack}}
**Approach**: {{project.approach}}

<!-- Standard level: two to four sentences. Describe the implementation strategy,
     key dependencies, and any mandatory notes that affect all tasks.
     Example: "Next.js 14 app router with PostgreSQL via Prisma. Auth handled by
     NextAuth v5. All tasks target Node 20 LTS. Database migrations must be
     backward-compatible with the previous schema version." -->

> **Note**: {{project.mandatory_note}}

<!-- mandatory_note: surface any project-wide constraint that every implementer
     must be aware of (e.g., zero-downtime requirement, multi-tenant data isolation,
     pending API contract freeze). Remove this block if no mandatory note applies. -->

---

## {{i18n.section_titles.requirements}}

<!-- Standard level: tasks with subtasks.
     Top-level format:
       ### TASK-NNN: <title>
       Implements: PROP-NNN and/or REQ-NNN (required)
       Estimate: Nh or N story points
       Depends on: TASK-NNN (title hint) — omit line if no dependencies

     Subtask format (indented two spaces):
       TASK-NNN.N: <what to implement>

     Rules:
     - Both Implements and Tests references are required at Standard level.
     - "Tests" references on subtasks that add verification logic (TEST-* IDs).
     - Subtasks inherit the parent Implements if not stated separately.
     - Security tasks (implementing SEC-PROP-*) follow the same format.
     - Estimates are required at Standard level.

     Repeat the ### TASK-NNN block below for every task in the project.     -->

### TASK-001: {{task_001.title}}
{{i18n.labels.implements}}: {{task_001.implements}}
Estimate: {{task_001.estimate}}
Depends on: {{task_001.depends_on}}

  TASK-001.1: {{task_001.sub1.description}}
  TASK-001.2: {{task_001.sub2.description}}
  TASK-001.3: {{task_001.sub3.description}}
  TASK-001.4: {{task_001.sub4.description}}

<!-- Repeat subtask lines: TASK-NNN.N: <description of what to implement> -->

---

### TASK-002: {{task_002.title}}
{{i18n.labels.implements}}: {{task_002.implements}}
Estimate: {{task_002.estimate}}
Depends on: {{task_002.depends_on}}

  TASK-002.1: {{task_002.sub1.description}}
  TASK-002.2: {{task_002.sub2.description}}
  TASK-002.3: {{task_002.sub3.description}}
    {{i18n.labels.tests}}: {{task_002.sub3.tests}}

<!-- Subtasks that write test or verification logic carry a Tests: reference.
     Example:
       TASK-002.3: Write integration tests for invite token lifecycle
         Tests: TEST-PROP-005, TEST-REQ-001-HAPPY                            -->

---

<!-- Repeat pattern:
     ### TASK-NNN: title
     Implements / Estimate / Depends on
       TASK-NNN.1 … TASK-NNN.N (with optional Tests: on test subtasks)      -->

### TASK-NNN: {{task_sec_001.title}}
{{i18n.labels.implements}}: SEC-PROP-{{task_sec_001.sec_prop_key}}
Estimate: {{task_sec_001.estimate}}
Depends on: {{task_sec_001.depends_on}}

  TASK-NNN.1: {{task_sec_001.sub1.description}}
    {{i18n.labels.implements}}: SEC-PROP-{{task_sec_001.sec_prop_key}}
  TASK-NNN.2: {{task_sec_001.sub2.description}}
    {{i18n.labels.tests}}: TEST-SEC-{{task_sec_001.sec_prop_key}}

<!-- Security tasks are always present regardless of formalism level.
     Generated from security-properties.yaml at artifact creation time.
     Each security task must include at least one Tests: reference on the
     subtask that writes the corresponding TEST-SEC-* verification.        -->

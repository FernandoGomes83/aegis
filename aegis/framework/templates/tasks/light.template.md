# {{i18n.artifact_titles.tasks}} — {{project.name}}

> {{i18n.messages.auto_generated}}

---

## {{i18n.section_titles.overview}}

**Stack**: {{project.stack}}
**Approach**: {{project.approach}}

<!-- Light level: one or two sentences describing the overall implementation strategy.
     Example: "Single-pass CLI with lazy I/O. No external services. Pure Python 3.12." -->

---

## {{i18n.section_titles.requirements}}

<!-- Light level: flat checklist. One entry per task.
     Format:  - [ ] TASK-NNN: <title> — <brief description>
              Implements: REQ-NNN (or PROP-NNN)
              Tests: PROP-NNN  (optional — include when the task adds test coverage)

     Rules:
     - IDs are three-digit zero-padded: TASK-001, TASK-002, …
     - Every task MUST have at least one Implements reference.
     - Tests reference is optional at Light level; include it when a task adds
       verification logic (e.g., a test script or assertions).
     - No subtasks. No dependency declarations. No hour estimates.
     - T-shirt size effort is optional: append "(S)", "(M)", "(L)", or "(XL)".
     - Security tasks (implementing SEC-PROP-*) follow the same format —
       do not omit them.

     Repeat the pattern below for every task in the project.         -->

- [ ] TASK-001: {{task_001.title}}
  {{task_001.description}}
  {{i18n.labels.implements}}: {{task_001.implements}}

- [ ] TASK-002: {{task_002.title}}
  {{task_002.description}}
  {{i18n.labels.implements}}: {{task_002.implements}}
  {{i18n.labels.tests}}: {{task_002.tests}}

<!-- Repeat pattern: - [ ] TASK-NNN: title / description / Implements / (optional Tests) -->

- [ ] TASK-NNN: {{task_sec_001.title}}
  {{task_sec_001.description}}
  {{i18n.labels.implements}}: SEC-PROP-{{task_sec_001.sec_prop_key}}

<!-- Security tasks are always present regardless of formalism level.
     Generated from security-properties.yaml at artifact creation time. -->

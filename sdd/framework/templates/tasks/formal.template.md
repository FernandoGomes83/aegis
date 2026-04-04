# {{i18n.artifact_titles.tasks}} — {{project.name}}

> {{i18n.messages.auto_generated}}

---

## {{i18n.section_titles.overview}}

**Stack**: {{project.stack}}
**Approach**: {{project.approach}}

> **Prerequisites**: The following artifacts must be reviewed and approved before
> implementation begins: `requirements.md` (all SEC-REQ-* entries present),
> `design.md` (all PROP-NNN and SEC-PROP-* entries present, full validation
> passing). No task block may begin until its declared `Depends on:` tasks are
> merged, passing CI, and acknowledged at the preceding checkpoint.

<!-- Formal level: prerequisites note is mandatory.
     Add any project-specific prerequisites below — compliance sign-off,
     architecture review board approval, environment provisioning gates, etc.
     Example: "PCI-DSS scoping review must be completed before Block 2 begins." -->

---

## {{i18n.section_titles.requirements}}

<!-- Formal level: tasks with subtasks, PERT estimates, cross-references, and
     checkpoint tasks between logical blocks.

     Top-level task format:
       **TASK-NNN: <title>**
       Implements: PROP-NNN and/or REQ-NNN (required)
       Estimate: Nh (PERT: O=Xh, M=Yh, P=Zh)
       Depends on: TASK-NNN (title hint)

     Subtask format (indented two spaces):
       TASK-NNN.N: <what to implement> (Xh)
         Implements: PROP-NNN  (if different from parent)
         Validates:  TEST-*    (required on subtasks that write test logic)

     Checkpoint format (between blocks, mandatory):
       ---
       **TASK-NNN: {{i18n.labels.checkpoint}} — <description>**
       Before proceeding to <next block name>, verify:
       - [ ] <verification criterion 1>
       - [ ] <verification criterion 2>
       ---

     Rules:
     - Every task MUST have Implements. Every test subtask MUST have Validates.
     - Checkpoints are required between every logical block (typically 3–7 tasks).
     - Checkpoints may not be skipped; they serve as formal gates in the plan.
     - PERT estimates are required: O=optimistic, M=most likely, P=pessimistic.
     - Security tasks follow the same format — never omitted at Formal level.

     Repeat the **TASK-NNN** block pattern for every task in the project.   -->

### Block 1: {{block_1.name}}

**TASK-001: {{task_001.title}}**
{{i18n.labels.implements}}: {{task_001.implements}}
Estimate: {{task_001.estimate_total}} (PERT: O={{task_001.pert_o}}, M={{task_001.pert_m}}, P={{task_001.pert_p}})
Depends on: {{task_001.depends_on}}

  TASK-001.1: {{task_001.sub1.description}} ({{task_001.sub1.hours}})
    {{i18n.labels.implements}}: {{task_001.sub1.implements}}
  TASK-001.2: {{task_001.sub2.description}} ({{task_001.sub2.hours}})
    {{i18n.labels.implements}}: {{task_001.sub2.implements}}
  TASK-001.3: {{task_001.sub3.description}} ({{task_001.sub3.hours}})
    {{i18n.labels.implements}}: {{task_001.sub3.implements}}
  TASK-001.4: {{task_001.sub4.description}} ({{task_001.sub4.hours}})
    {{i18n.labels.validates}}: {{task_001.sub4.validates}}

<!-- Repeat subtask lines: TASK-NNN.N: description (hours)
     Implements and Validates are placed on the lines directly below the subtask.
     Test subtasks must have Validates pointing to specific TEST-* IDs.     -->

---

**TASK-002: {{task_002.title}}**
{{i18n.labels.implements}}: {{task_002.implements}}
Estimate: {{task_002.estimate_total}} (PERT: O={{task_002.pert_o}}, M={{task_002.pert_m}}, P={{task_002.pert_p}})
Depends on: {{task_002.depends_on}}

  TASK-002.1: {{task_002.sub1.description}} ({{task_002.sub1.hours}})
    {{i18n.labels.implements}}: {{task_002.sub1.implements}}
  TASK-002.2: {{task_002.sub2.description}} ({{task_002.sub2.hours}})
    {{i18n.labels.implements}}: {{task_002.sub2.implements}}
  TASK-002.3: {{task_002.sub3.description}} ({{task_002.sub3.hours}})
    {{i18n.labels.validates}}: {{task_002.sub3.validates}}

---

<!-- Checkpoint between blocks: mandatory at Formal level.
     Purpose: establishes a formal gate that the team verifies before proceeding.
     The checkpoint lists explicit pass/fail criteria — not aspirational goals.
     Criteria must be observable and automatable where possible.            -->

---
**TASK-003: {{i18n.labels.checkpoint}} — {{checkpoint_1.description}}**
Before proceeding to {{checkpoint_1.next_block}}, verify:
- [ ] All TASK-001 and TASK-002 subtasks are merged and passing CI.
- [ ] {{checkpoint_1.criterion_1}}
- [ ] {{checkpoint_1.criterion_2}}
- [ ] No open TODO or FIXME comments in files touched by this block.
---

<!-- Repeat block + checkpoint pattern for every logical group of tasks. -->

### Block 2: {{block_2.name}}

**TASK-004: {{task_004.title}}**
{{i18n.labels.implements}}: {{task_004.implements}}
Estimate: {{task_004.estimate_total}} (PERT: O={{task_004.pert_o}}, M={{task_004.pert_m}}, P={{task_004.pert_p}})
Depends on: TASK-003

  TASK-004.1: {{task_004.sub1.description}} ({{task_004.sub1.hours}})
    {{i18n.labels.implements}}: {{task_004.sub1.implements}}
  TASK-004.2: {{task_004.sub2.description}} ({{task_004.sub2.hours}})
    {{i18n.labels.implements}}: {{task_004.sub2.implements}}
  TASK-004.3: {{task_004.sub3.description}} ({{task_004.sub3.hours}})
    {{i18n.labels.validates}}: {{task_004.sub3.validates}}

---

**TASK-NNN: {{task_sec_001.title}}**
{{i18n.labels.implements}}: SEC-PROP-{{task_sec_001.sec_prop_key}}
Estimate: {{task_sec_001.estimate_total}} (PERT: O={{task_sec_001.pert_o}}, M={{task_sec_001.pert_m}}, P={{task_sec_001.pert_p}})
Depends on: {{task_sec_001.depends_on}}

  TASK-NNN.1: {{task_sec_001.sub1.description}} ({{task_sec_001.sub1.hours}})
    {{i18n.labels.implements}}: SEC-PROP-{{task_sec_001.sec_prop_key}}
  TASK-NNN.2: {{task_sec_001.sub2.description}} ({{task_sec_001.sub2.hours}})
    {{i18n.labels.validates}}: TEST-SEC-{{task_sec_001.sec_prop_key}}

<!-- Security tasks are always present regardless of formalism level.
     Every security task must have at least one subtask with Validates pointing
     to the corresponding TEST-SEC-* ID. This creates a bidirectional link
     between the task plan and the test specification.                       -->

---

---
**TASK-NNN: {{i18n.labels.checkpoint}} — {{checkpoint_2.description}}**
Before proceeding to {{checkpoint_2.next_block}}, verify:
- [ ] All Block 2 subtasks are merged and passing CI.
- [ ] {{checkpoint_2.criterion_1}}
- [ ] {{checkpoint_2.criterion_2}}
- [ ] All TEST-SEC-* referenced in this block pass against the target environment.
---

<!-- Final checkpoint: repeat this pattern after the last block.
     The final checkpoint should also confirm overall coverage:
     - Every PROP-NNN referenced in Implements has at least one TEST-* passing.
     - Coverage matrix shows no critical gaps before handoff to QA / release.  -->

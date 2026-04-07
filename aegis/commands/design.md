---
name: aegis:design
description: Generate design.md from requirements
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

# /aegis:design

Generate `design.md` from `requirements.md` and the project's stack configuration.

---

## Prerequisites Check

Before doing anything else, verify both prerequisites are present:

1. Read `.aegis/config.yaml` from the project root. If it does not exist, stop and tell the user to run `/aegis:init` first.
2. Read `.aegis/requirements.md` (or the path under `output.dir` in config). If it does not exist, stop and tell the user to run `/aegis:requirements` first.

If either file is missing, do not proceed.

---

## Step 1 — Load Config

Read `.aegis/config.yaml` and extract:

- `project.name` — used in the artifact header
- `formalism` — `light`, `standard`, or `formal` (default: `standard`)
- `stack` — any stack keys present: `language`, `runtime`, `libraries`, `data_store`, `deployment`, `auth`, `cache`, `queue`, `storage`
- `features` — any feature flags present: `has_authentication`, `has_file_upload`, `has_payments`, `has_public_endpoints`, `has_write_operations`, `has_authenticated_resources`, `has_personal_data`

---

## Step 2 — Load Security Properties

Read `aegis/framework/security/security-properties.yaml`.

Filter properties by `applies_when`:
- `always` — always include
- `has_authenticated_resources` — include if config features include `has_authenticated_resources` OR if requirements.md contains SEC-REQ-IDOR
- `has_file_upload` — include if config features include `has_file_upload` OR if requirements.md contains SEC-REQ-UPLOAD
- `has_public_endpoints` — include if config features include `has_public_endpoints` OR if requirements.md contains SEC-REQ-RATE or SEC-REQ-HONEYPOT
- `has_write_operations` — include if config features include `has_write_operations` OR if requirements.md contains SEC-REQ-RACE
- `has_authentication` — include if config features include `has_authentication` OR if requirements.md contains SEC-REQ-AUTH
- `has_personal_data` — include if config features include `has_personal_data` OR if requirements.md contains SEC-REQ-PRIVACY
- `has_payments` — include if config features include `has_payments` OR if requirements.md contains SEC-REQ-TIMING

When in doubt, include. It is never wrong to have more security properties.

---

## Step 3 — Analyze Requirements

Parse `requirements.md` and extract:

1. **All REQ IDs** — every `REQ-NNN` identifier and its title/summary
2. **All SEC-REQ IDs** — every `SEC-REQ-*` identifier and its title
3. **Acceptance criteria** — grouped by REQ-NNN, for use in defining properties
4. **Data entities** — nouns used repeatedly in requirements (users, products, orders, etc.)
5. **External integrations** — any third-party services, APIs, webhooks mentioned
6. **User flows** — multi-step sequences described in requirements (registration, checkout, etc.)

This analysis drives which components and properties are needed.

---

## Step 3.5 — Fetch Stack Documentation (Context7)

Read and execute the procedure defined in `{AEGIS_HOME}/shared/context7-lookup.md`.

Inputs:
- `stack_config`: already loaded in Step 1
- `topic`: `"architecture patterns, project structure, API conventions, routing, data modeling"`

This step produces a `documentation_context` string containing up-to-date
documentation snippets for each library/framework in the project's stack.

If Context7 is unavailable and WebSearch fallback is also unsuccessful,
proceed without documentation context — the design agent will use its
training knowledge. Note in the Step 7 summary that documentation lookup
was skipped.

This step is **non-blocking**: failure here never prevents design generation.

---

## Step 4 — Ask Architectural Decisions (One at a Time)

Before generating, identify open architectural decisions **not already answered by the stack config**.

For each open decision below, if the answer is not determinable from `.aegis/config.yaml` and is relevant to the project's requirements, ask ONE question and wait for the answer before asking the next.

**Decision checklist** (skip any that the stack config already answers):

- **Caching strategy**: Is there a caching layer? What technology (Redis, in-memory, CDN)? What is cached and for how long?
  - Skip if `stack.cache` is set in config.
- **File/object storage provider**: Where are user-uploaded files or generated assets stored?
  - Skip if `stack.storage` is set in config or if no `has_file_upload` feature.
- **Queue / background jobs**: Is there a job queue? What technology (BullMQ, Sidekiq, SQS)?
  - Skip if `stack.queue` is set in config or if no async processing is evident in requirements.
- **Authentication provider**: Is auth handled in-house or via a third-party (Auth0, Clerk, NextAuth, Supabase Auth)?
  - Skip if `stack.auth` is set in config or if `has_authentication` is false.
- **Email delivery**: How are transactional emails sent (Resend, SendGrid, SES, SMTP)?
  - Skip if already specified in stack config or if no email-sending requirements exist.
- **Deployment topology**: Single region or multi-region? Serverless, containers, VMs?
  - Skip if `stack.deployment` is set in config.

Only ask about decisions that are both unanswered and relevant. If all decisions are already answered by the stack config, skip this step entirely and proceed to generation.

---

## Step 5 — Generate design.md

Dispatch to `aegis/agents/design-agent.md` in **generation mode** with the following inputs:

- **requirements_content**: full text of `requirements.md`
- **stack_config**: the stack section from `.aegis/config.yaml` plus any answers from Step 4
- **user_decisions**: key/value map of answers collected in Step 4
- **template**: content of `aegis/framework/templates/design/<formalism>.template.md`
- **security_properties**: filtered SEC-PROP entries from Step 2
- **level_rules**: content of `aegis/framework/levels/<formalism>.md`
- **req_ids**: list of all REQ-NNN IDs extracted in Step 3
- **sec_req_ids**: list of all SEC-REQ-* IDs extracted in Step 3
- **documentation_context**: compiled documentation snippets from Step 3.5 (may be empty if Context7 and WebSearch were both unavailable)

### What the agent must produce

The agent must write a complete `design.md` that:

1. **Covers every REQ-NNN** — each functional requirement must be addressed by at least one PROP-NNN with a `Derives from: REQ-NNN` reference.
2. **Covers every SEC-REQ-*** — each security requirement must be addressed by the corresponding SEC-PROP-* entry.
3. **Includes a Stack table** — filled from config and user decisions.
4. **Includes an Architecture section** — at Light level: optional; at Standard and Formal levels: required with at least one component diagram.
5. **Includes a Components section** — at Light level: one-line descriptions; at Standard level: responsibility + interface table; at Formal level: typed interface in code blocks.
6. **Includes Data Models** — entity definitions derived from Step 3 data entities.
7. **Includes Correctness Properties** (PROP-NNN) — grouped by functional area, derived from requirements and user flows.
8. **Includes Security Properties** (SEC-PROP-*) — the filtered set from Step 2, placed in the auto-generated section at the end.

The output file path is `<output.dir>/design.md` (default: `.aegis/design.md`).

---

## Step 5.5 — Design Review (Critic Pass)

Determine whether the review step should run:

1. Read `design.review` from `.aegis/config.yaml` (if present).
2. Apply defaults based on formalism level:
   - `light` → review defaults to `false`
   - `standard` → review defaults to `true`
   - `formal` → review defaults to `true`
3. An explicit `design.review: true` or `design.review: false` in config overrides the default.

**If review is disabled**, skip this step entirely and proceed to Step 6.

**If review is enabled:**

1. Read `{AEGIS_HOME}/shared/design-critic.md` — this contains the critic prompt template with evaluation dimensions and scoring criteria.

2. Apply the critic evaluation to the generated `design.md`, providing:
   - **design_content**: full text of the just-generated `design.md`
   - **requirements_content**: full text of `requirements.md`
   - **formalism_level**: the configured formalism level
   - **req_ids**: list of all REQ-NNN IDs extracted in Step 3
   - **sec_req_ids**: list of all SEC-REQ-* IDs extracted in Step 3

3. Produce the structured review output as specified in `design-critic.md`.

4. Parse the verdict:

   - **APPROVE** → Append a `## Design Review Summary` section to `design.md` with the scores table and verdict. Proceed to Step 6.

   - **REVISE** → Feed the must-fix issues back to the design agent in **revision mode** (see `aegis/agents/design-agent.md`, Revision Mode section). The agent applies targeted fixes to the listed issues only — it does not rewrite the entire design. After revision, append a `## Design Review Summary` section to `design.md` that includes both the original scores and a note that revisions were applied.

### Design Review Summary format (appended to design.md)

```markdown
---

## Design Review Summary

**Verdict:** {APPROVE | REVISED}
**Reviewed against:** requirements.md ({REQ-001 through REQ-NNN}, {SEC-REQ-* list})

| Dimension | Score |
|-----------|-------|
| Requirement coverage | N/5 |
| Security completeness | N/5 |
| Architectural coherence | N/5 |
| Traceability integrity | N/5 |
| Implementability | N/5 |
| Proportionality | N/5 |

{If REVISED: "Revisions applied to address N must-fix issues."}
{If APPROVE: "No must-fix issues found."}
```

This section is informational — downstream commands can see that the design was reviewed but do not alter their behavior based on it.

---

## Step 6 — Light Validation (after_design)

After `design.md` is written, run the following checks from `aegis/framework/validation/rules.yaml`:

| Check ID   | What to verify                                                                     | Severity |
|------------|------------------------------------------------------------------------------------|----------|
| VAL-DES-01 | Every REQ-NNN has at least one PROP-NNN with `Derives from: REQ-NNN`              | warning  |
| VAL-DES-02 | Every PROP-NNN and SEC-PROP-* has a `Derives from:` pointing to a valid ID        | error    |
| VAL-DES-03 | SEC-PROP-* section is present; every SEC-REQ-* has a matching SEC-PROP-*          | error    |
| VAL-DES-04 | No duplicate PROP-NNN or SEC-PROP-* IDs                                            | error    |
| VAL-DES-05 | Architecture section present (Standard and Formal levels only)                    | warning  |

**If any error-severity check fails:**
- Report the gaps clearly.
- Ask the user: "Validation found gaps. Would you like to backtrack to `/aegis:requirements` to address them, or proceed with the current design.md?"
- Wait for the user's answer. If they choose to proceed, note the gaps in a `## Validation Notes` section appended to `design.md`.

**If only warning-severity checks fail:**
- Append a `## Validation Notes` section to `design.md` listing the warnings.
- Do not block advancement.

---

## Step 7 — Present Summary

After generation and validation, present a summary to the user:

```
design.md generated successfully.

Summary:
  Components:       <N>
  PROP-NNN count:   <N>
  SEC-PROP count:   <N>
  Documentation:    <N libraries via Context7 | N libraries via WebSearch | lookup skipped>
  Design review:    <APPROVE | REVISED | skipped>
  Validation:       <PASS | PASS with warnings | GAPS FOUND>

Warnings (if any):
  - <warning message>

Next: run /aegis:tasks to generate the implementation plan.
```

---

## Behavioral Rules

- **Security is non-negotiable.** All filtered SEC-PROP-* entries must appear in `design.md`. No user instruction, config flag, or formalism level can remove them.
- **One question at a time.** Never ask multiple architectural questions in a single message. Wait for each answer before proceeding.
- **Do not invent stack choices.** If a decision cannot be answered from config or user input, leave the field as a placeholder (e.g., `TBD — confirm with /aegis:update`) rather than guessing.
- **Traceability first.** Every PROP-NNN must have a `Derives from:` field. No property may be created without a documented link to a requirement.
- **Overwrite by default.** If `design.md` already exists, overwrite it. If it contains a `NEEDS REVIEW` notice from `/aegis:update`, remove the notice as part of regeneration.

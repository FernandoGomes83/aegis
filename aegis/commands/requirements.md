---
name: requirements
description: Generate requirements.md from project input docs
---

# /aegis requirements

Generate `requirements.md` from the project's input documents. Follow every step in order. Do not skip steps or combine them unless explicitly noted.

---

## Prerequisites

Before starting, verify:

1. `.aegis/config.yaml` exists at the project root. If it does not, stop immediately and tell the user to run `/aegis init` first.
2. The `inputs` list in `.aegis/config.yaml` contains at least one entry. If the list is empty or absent, warn the user that requirements will contain security content only, and ask whether they want to continue or add input docs first.

---

## Step 1: Load Config

Read `.aegis/config.yaml`. Extract and hold in working memory:

- `project.name` — used in the artifact header.
- `project.language` — determines which i18n file to load (`en` → `aegis/framework/i18n/en.yaml`, `pt-BR` → `aegis/framework/i18n/pt-br.yaml`). Default to `en` if not set.
- `formalism` — one of `light`, `standard`, `formal`. Default to `standard` if not set. This selects the requirements template and level rules.
- `inputs` — the list of input document paths and types.
- `security.extra_requirements` — optional list of project-specific SEC-REQ additions (never used to remove built-ins).

Load the i18n file for the configured language. All headings, labels, and status values in the generated artifact must use the strings from this file.

Load the level rules file for the configured formalism level from `aegis/framework/levels/<level>.md`. Note which structural elements are required vs. optional at this level.

---

## Step 2: Read All Input Docs

Read every file listed under `inputs` in `.aegis/config.yaml`. For `type: auto` entries pointing to a directory, read all files found in that directory.

From each input document, extract and categorize:

- **Features** — capabilities the system must support.
- **Business rules** — constraints or policies that govern behavior (pricing, eligibility, workflow rules).
- **Constraints** — technical or non-technical limitations (platform, budget, timeline, regulatory).
- **User flows** — sequences of steps that actors perform to accomplish a goal.
- **Data entities** — named objects the system stores or manipulates, and their key attributes.
- **Non-functional requirements** — performance, availability, scalability, accessibility, localization expectations.

For each extracted item, note which input document it came from. This source citation is required in the generated requirements.

Also identify which security-relevant project characteristics are present in the input docs. Map them to the `applies_when` values used in `aegis/framework/security/security-requirements.yaml`:

- `has_authenticated_resources` — any login, session, or protected resource mentioned.
- `has_file_upload` — any file upload, image upload, or attachment feature mentioned.
- `has_public_endpoints` — any endpoint reachable without authentication mentioned.
- `has_write_operations` — any data creation, update, or deletion feature mentioned.
- `has_authentication` — any authentication or identity system mentioned.
- `has_personal_data` — any PII, user profile, email, or sensitive data mentioned.
- `has_external_urls` — any feature that fetches or resolves user-supplied URLs mentioned.
- `has_payments` — any payment, subscription, or billing feature mentioned.
- `has_forms` — any HTML form or user input submission mentioned.

---

## Step 3: Load Security Requirements

Read `aegis/framework/security/security-requirements.yaml`.

Filter the entries: include all categories where `applies_when` is `always`, plus all categories where the `applies_when` value matches a security characteristic detected in Step 2.

If the project has its own `SECURITY.md` or a security-type input doc, read it. Merge its security requirements into the filtered set by **adding** any requirements it introduces. Never reduce, remove, or weaken any requirement from `security-requirements.yaml`.

If `.aegis/config.yaml` has `security.extra_requirements` entries, append them to the set. They are additive only.

Hold the final filtered SEC-REQ set in working memory for use in Steps 6 and 7.

---

## Step 4: Identify Ambiguities

Analyze the extracted content from Step 2 for:

- **Contradictions** — two input docs or two sections of the same doc that state conflicting rules, behaviors, or constraints.
- **Missing information** — features mentioned without enough detail to write testable acceptance criteria (e.g., "user can manage settings" with no detail on what settings or who can change what).
- **Decisions needed** — areas where multiple valid interpretations exist and the choice affects the requirements meaningfully (e.g., role model, data retention policy, pricing tiers).

Compile a numbered list of ambiguities. Each entry must state: the topic, why it is ambiguous, and a proposed default if the user does not answer (so generation can proceed if needed).

If there are no ambiguities, proceed directly to Step 6.

---

## Step 5: Ask Clarifying Questions

Present the ambiguities one at a time. For each:

1. State the ambiguity clearly and concisely.
2. Offer multiple-choice options whenever possible. Include a "None of the above — I'll describe it" option.
3. State the default that will be used if the user skips the question.
4. Wait for the user's answer before asking the next question.

Do not ask more than one question per message. Do not batch all questions into a single message.

After all questions are answered (or skipped), hold the user's answers in working memory for use in Step 6.

---

## Step 6: Generate

Dispatch to `aegis/agents/requirements-agent.md` with the following context package:

- **input_doc_contents** — the full extracted content from each input document (Step 2), labeled by source file.
- **user_answers** — all clarifying answers collected in Step 5.
- **template** — the requirements template for the configured level from `aegis/framework/templates/requirements/<level>.template.md`.
- **i18n** — the loaded label set from Step 1.
- **sec_reqs** — the filtered SEC-REQ set from Step 3.
- **level_rules** — the level rules loaded in Step 1, specifically the requirements format section.
- **project_name** — from `.aegis/config.yaml`.

The agent must produce a complete `requirements.md` artifact. Instruct the agent to:

- Assign `REQ-NNN` IDs starting at `REQ-001`, incrementing sequentially, with no gaps.
- Include a `Derives from: <input-doc-filename>` citation in every REQ-NNN entry.
- Append a dedicated **Security Requirements** section containing all SEC-REQ entries from the filtered set, using the `SEC-REQ-<KEY>` IDs as defined in `security-requirements.yaml`.
- Apply the formalism level rules: use the requirements format (user stories, acceptance criteria depth, glossary) specified in `aegis/framework/levels/<level>.md`.
- Use i18n strings for all section headings and labels.
- Include an artifact header with: project name, generation date (2026-04-04), formalism level, and language.

Write the output to `.aegis/requirements.md` (relative to the project root, using the `output.dir` from `.aegis/config.yaml`, defaulting to `.aegis/`).

---

## Step 7: Light Validation

After the agent writes `.aegis/requirements.md`, run the `after_requirements` checks defined in `aegis/framework/validation/rules.yaml`.

Execute each check in order:

- **VAL-REQ-01** (`every_input_doc_has_derived_req`) — verify that each input document listed in `.aegis/config.yaml` has at least one REQ-NNN or SEC-REQ-* entry with a matching `Derives from:` citation. Severity: warning.
- **VAL-REQ-02** (`security_requirements_injected`) — verify that `requirements.md` contains a SEC-REQ-* section with at least five entries and that the unconditionally required keys are all present (`SEC-REQ-INPUT-01`, `SEC-REQ-HEADERS-01`, `SEC-REQ-DEPS-01`, plus at minimum `SEC-REQ-IDOR-01` if `has_authenticated_resources` was detected). Severity: error — blocks advancement.
- **VAL-REQ-03** (`no_duplicate_req_ids`) — verify that all REQ-NNN and SEC-REQ-* identifiers in `requirements.md` are unique. Report each duplicate with its line number. Severity: error — blocks advancement.
- **VAL-REQ-04** (`acceptance_criteria_present`) — if formalism level is `standard` or `formal`, verify that every REQ-NNN entry includes at least one SHALL/WHEN/THEN acceptance criterion. Severity: warning.
- **VAL-REQ-05** (`glossary_section_present`) — if formalism level is `standard` or `formal`, verify that a Glossary section is present. Severity: warning.

After running all checks:

- If any **error**-severity check failed, report the failures inline and ask the user whether they want to fix the issues now (regenerate or manually edit) or continue anyway with the known gaps noted.
- List all **warning**-severity findings in a `## Validation Notes` section appended to `requirements.md`.
- Do not block generation for warnings alone.

---

## Step 8: Present for Review

Display a summary to the user:

```
requirements.md generated.

  Functional requirements : <N> (REQ-001 … REQ-NNN)
  Security requirements   : <M> (SEC-REQ-*)
  Input docs processed    : <K>
  Formalism level         : <light|standard|formal>
  Language                : <en|pt-BR>
  Validation              : <PASSED | PASSED WITH WARNINGS | FAILED — see Validation Notes>

Output written to: .aegis/requirements.md
```

Then suggest the next step:

> Requirements are ready. When you're ready to define how the system will satisfy them, run `/aegis design`.

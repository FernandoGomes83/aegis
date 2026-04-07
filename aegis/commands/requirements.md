---
name: aegis:requirements
description: Generate requirements.md from project input docs
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

# /aegis:requirements

Generate `requirements.md` from the project's input documents. Follow every step in order. Do not skip steps or combine them unless explicitly noted.

---

## Prerequisites

Before starting, verify:

1. `.aegis/config.yaml` exists at the project root. If it does not, stop immediately and tell the user to run `/aegis:init` first.
2. The `inputs` list in `.aegis/config.yaml` contains at least one entry. If the list is empty or absent, warn the user that requirements will contain security content only, and ask whether they want to continue or add input docs first.

---

## Step 1: Load Config

Read `.aegis/config.yaml`. Extract and hold in working memory:

- `project.name` — used in the artifact header.
- `formalism` — one of `light`, `standard`, `formal`. Default to `standard` if not set. This selects the requirements template and level rules.
- `inputs` — the list of input document paths and types.
- `security.extra_requirements` — optional list of project-specific SEC-REQ additions (never used to remove built-ins).

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

## Step 2.5: Research Unknown Terms

Analyze the extracted content from Step 2 for proper nouns, product names, technology names, and domain-specific terms that may refer to concepts outside the model's training data or knowledge cutoff.

### Identification

Scan all extracted content for:

- Product names (e.g., "Nano Banana 2", "TurboWidget Pro") that are not widely known.
- Technology or platform names that may have launched after the model's knowledge cutoff.
- Domain-specific jargon unique to the project's industry without clear definitions in the input docs.
- Version-specific references to products or frameworks where the version is unknown to the model.
- Acronyms or abbreviations that cannot be confidently expanded from context alone.

### Self-assessment

For each identified term, assess confidence:

- **Known** — well-understood and in training data. Skip.
- **Uncertain** — exists in training data but may be outdated, partially known, or ambiguous. Research.
- **Unknown** — not in training data at all. Research.

Compile a list of terms classified as Uncertain or Unknown.

If the list is empty (all terms are Known), set `research_context` to an empty string and proceed to Step 3.

### Research via WebSearch

For each Uncertain or Unknown term, use the **WebSearch** tool with:

```
"<term> official site OR documentation OR product page <current year>"
```

Where `<current year>` is the actual current year (e.g., 2026).

From the search results, extract:
- What the product/technology is (one-sentence definition).
- Key capabilities or features relevant to the project.
- Version or release information if applicable.
- Any constraints, pricing model, or platform requirements.

Limit to the **top 2** most relevant results per term. Summarize each in **300 tokens maximum**. Prefer official sources over blogs or forums.

**Maximum 5 terms per run.** If more than 5 terms are Uncertain/Unknown, prioritize by:

1. Terms that appear most frequently in the input docs.
2. Terms that are central to a feature or user flow.
3. Terms where misunderstanding would produce incorrect requirements.

### Compile research context

Assemble `research_context` from all researched terms:

```markdown
### <Term> — Research Summary

<summary content>

---
```

This block is passed to the requirements agent alongside other context in Step 6.

### Non-blocking

This step is **non-blocking**. If WebSearch is unavailable or returns no useful results for a given term, skip that term. If all lookups fail, set `research_context` to an empty string and proceed. The agent falls back to its training knowledge when research is unavailable. Never stop or error on research failure.

---

## Step 2.8: Interview Mode (when enabled)

Check if interview mode should activate:

1. **Explicit flag:** If the user ran `/aegis:requirements --interview` → activate. Parse `--depth=<profile>` if present (default: `standard`).
2. **Config flag:** If `.aegis/config.yaml` contains `requirements.interview: true` or `requirements.interview.enabled: true` → activate. Read `requirements.interview.depth` for the depth profile (default: `standard`).
3. **Auto-detection:** If neither flag is set, estimate input quality from Step 2:
   - Count total words across all input documents.
   - Check for presence of key sections: goals/objectives, users/actors, constraints, scope boundaries.
   - If total words < 200 OR 2+ key sections are missing → **suggest** interview mode (do not auto-activate).

### When auto-detection triggers

Display to the user:

> Input appears to be a brief sketch (~N words, missing: [list of missing sections]). I recommend running interview mode to clarify scope and constraints before generating requirements. Proceed with interview? (The alternative is to generate requirements from what's available, with assumptions marked.)

Wait for user response. If they decline, proceed to Step 3 — the requirements agent will mark inferred decisions with `[ASSUMED]` tags (see Rule 10 in the agent).

### When interview mode is active

1. Read `{AEGIS_HOME}/shared/interview-dimensions.md` for dimension definitions, scoring criteria, question strategies, and depth profiles.

2. **Score each dimension** from the input documents:
   - For each of the 5 dimensions (Intent, Scope, Users, Constraints, Success Criteria), assign an initial clarity score based on what the input docs contain:
     - Dimension mentioned with specifics → 0.8–1.0
     - Dimension mentioned vaguely → 0.4–0.6
     - Dimension not mentioned → 0.0–0.2

3. **Compute initial ambiguity:**
   ```
   weighted_avg = (intent × 0.25) + (scope × 0.25) + (users × 0.20)
                + (constraints × 0.15) + (success_criteria × 0.15)
   ambiguity = 1.0 − weighted_avg
   ```

4. **Display initial assessment:**
   ```
   Input ambiguity: 0.XX — interview active (depth: <profile>, max rounds: <N>)

   Dimension scores:
     Intent:           0.X
     Scope:            0.X
     Users:            0.X
     Constraints:      0.X
     Success criteria:  0.X
   ```

5. **Run interview loop:**
   - Look up the depth profile to get `max_rounds` and `threshold` (quick: 3/0.35, standard: 8/0.25, deep: 15/0.15).
   - While ambiguity > threshold AND rounds < max_rounds:
     a. Pick the dimension with the **lowest clarity score**.
     b. Select the next question from that dimension's pressure ladder (see interview-dimensions.md).
     c. Ask **ONE focused question**. Do not batch multiple questions.
     d. Wait for the user's response.
     e. Update the dimension's clarity score based on answer quality.
     f. Re-compute overall ambiguity.
     g. If the user gives non-informative answers for the same dimension twice, stop asking about it and move to the next.
   - If the user says they want to skip or stop the interview at any point, respect immediately and proceed with what has been clarified so far.

6. **Readiness gates:** After the loop completes, check:
   - Has at least one **non-goal** been explicitly stated?
   - Has at least one **success criterion** been explicitly stated?
   - If either is missing, ask the user directly: "Before I generate requirements, I need to confirm: (1) What is explicitly NOT in scope? (2) How will you know this is working correctly?"
   - If the user declines, mark both as `[ASSUMED]`.

7. **Compile interview context:** Assemble `interview_context` following the output format in interview-dimensions.md. This is passed to the requirements agent in Step 6.

### When interview mode is NOT active

Set `interview_context` to an empty string and proceed to Step 3.

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
- **sec_reqs** — the filtered SEC-REQ set from Step 3.
- **level_rules** — the level rules loaded in Step 1, specifically the requirements format section.
- **project_name** — from `.aegis/config.yaml`.
- **research_context** — compiled research summaries for domain terms, products, or technologies that were unknown or uncertain to the model (Step 2.5). May be an empty string if no unknown terms were found or WebSearch was unavailable.
- **interview_context** — compiled interview clarifications from Step 2.8, structured as dimension: answer pairs. May be an empty string if interview mode was not active. When non-empty, the agent must use these clarifications as primary context and apply `[ASSUMED]` marking per Rule 10.

The agent must produce a complete `requirements.md` artifact. Instruct the agent to:

- Assign `REQ-NNN` IDs starting at `REQ-001`, incrementing sequentially, with no gaps.
- Include a `Derives from: <input-doc-filename>` citation in every REQ-NNN entry.
- Append a dedicated **Security Requirements** section containing all SEC-REQ entries from the filtered set, using the `SEC-REQ-<KEY>` IDs as defined in `security-requirements.yaml`.
- Apply the formalism level rules: use the requirements format (user stories, acceptance criteria depth, glossary) specified in `aegis/framework/levels/<level>.md`.
- Include an artifact header with: project name, generation date, formalism level, and language.
- If interview mode was active, include a metadata comment after the artifact header: `<!-- Generated with interview mode (<depth_profile>, <rounds> rounds, ambiguity: <final_ambiguity>) -->`

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
  Terms researched        : <R> (or "none needed")
  Interview mode          : <depth profile, N rounds, ambiguity: 0.XX> (or "not used")
  Assumed items           : <N> [ASSUMED] tags (or "none")
  Formalism level         : <light|standard|formal>
  Validation              : <PASSED | PASSED WITH WARNINGS | FAILED — see Validation Notes>

Output written to: .aegis/requirements.md
```

Then suggest the next step:

> Requirements are ready. When you're ready to define how the system will satisfy them, run `/aegis:design`.

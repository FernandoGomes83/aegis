---
name: aegis:ui-design
description: Generate ui-design.md — frontend/UI design specification
---

## Bootstrap

Before executing this command, resolve the Aegis framework root path (**AEGIS_HOME**) using absolute paths only (the Read and Glob tools do not resolve `~`):

1. Run `echo $HOME` via the Bash tool to obtain the user's absolute home directory path (e.g., `/Users/alice`).
2. Check if `<project_root>/.claude/aegis/framework/SPEC.md` exists → if yes, **AEGIS_HOME** = `<project_root>/.claude/aegis`
3. Else check if `<HOME>/.claude/aegis/framework/SPEC.md` exists → if yes, **AEGIS_HOME** = `<HOME>/.claude/aegis`
4. Else → tell the user to install Aegis with `npx aegis-sdd` and stop.

Now read `{AEGIS_HOME}/shared/preamble.md` and apply all path mappings and core rules defined there before proceeding with the steps below.

---

# /aegis:ui-design

Generate `ui-design.md` — a detailed frontend/UI design specification from `requirements.md`, `design.md`, and project context. The output is a complete visual and interaction specification that another agent or developer can implement directly, without design ambiguity.

---

## Prerequisites Check

Before doing anything else, verify all prerequisites are present:

1. Read `.aegis/config.yaml` from the project root. If it does not exist, stop and tell the user to run `/aegis:init` first.
2. Read `.aegis/requirements.md` (or the path under `output.dir` in config). If it does not exist, stop and tell the user to run `/aegis:requirements` first.
3. Read `.aegis/design.md` (or the path under `output.dir` in config). If it does not exist, stop and tell the user to run `/aegis:design` first.

If any file is missing, do not proceed.

---

## Step 1 — Load Config

Read `.aegis/config.yaml` and extract:

- `project.name` — used in the artifact header
- `project.language` — select i18n label set from `aegis/framework/i18n/`
- `formalism` — `light`, `standard`, or `formal` (default: `standard`)
- `stack` — any stack keys present, especially: `framework` (React, Vue, Svelte, etc.), `language` (TypeScript, etc.), `libraries` (Tailwind, CSS modules, styled-components, etc.)
- `features` — any feature flags present

Load the i18n label set for the configured language.

---

## Step 2 — Analyze Requirements + Design

### From requirements.md, extract:

1. **All REQ-NNN IDs** — every functional requirement and its title/summary
2. **UI-relevant requirements** — requirements that describe: user-facing pages, screens, forms, dashboards, notifications, modals, navigation, search, filtering, visual feedback, onboarding flows, error messages, empty states, loading states
3. **User flows** — multi-step sequences that imply page transitions and interaction patterns
4. **User personas** — if described, extract their characteristics (technical level, accessibility needs, device preferences)

### From design.md, extract:

1. **All PROP-NNN IDs** — design properties, especially those related to frontend components
2. **Stack info** — framework (Next.js, React, Vue, Svelte, etc.), CSS approach (Tailwind, CSS modules, styled-components), UI library (if any)
3. **Components list** — existing component definitions from the architecture
4. **Data models** — entity shapes that inform form fields, table columns, card layouts

### From input docs (if brand-guide exists):

If any input document in `.aegis/config.yaml` is classified as `brand-guide`, read it and extract:

- Existing color palette
- Typography guidelines
- Tone of voice / visual identity rules
- Logo usage rules
- Do/don't design rules

---

## Step 3 — Ask Design Direction Questions (One at a Time)

Before generating, identify design direction decisions that cannot be derived from existing documents. For each open question below, ask ONE question and wait for the answer before asking the next.

**Question checklist** (skip any already answered by brand guide or input docs):

1. **Aesthetic direction**: What visual tone should this project convey? Offer specific options — e.g., brutally minimal, maximalist, retro-futuristic, organic/natural, luxury/refined, playful, editorial/magazine, brutalist/raw, art deco/geometric, soft/pastel, industrial/utilitarian — or ask the user to describe their vision. Never default to generic corporate.
   - Skip if a brand-guide input doc already establishes the tone.

2. **Key differentiator**: What is the ONE visual element someone should remember after seeing this interface? (e.g., a dramatic hero animation, a unique navigation pattern, a distinctive color use, an unconventional layout)
   - Always ask — this is what prevents generic output.

3. **Reference sites or inspirations**: Are there existing websites, apps, or design styles the user wants to reference? (e.g., "Linear's clean feel", "Stripe's documentation", "Notion's playfulness")
   - Skip if a brand-guide already provides visual references.

4. **Dark/Light mode**: Should the interface support dark mode, light mode, or both? What is the primary mode?
   - Skip if already specified in brand-guide or requirements.

5. **Responsive strategy**: Mobile-first or desktop-first? What are the primary target devices?
   - Skip if already specified in requirements or can be inferred from the project type (e.g., a dashboard is typically desktop-first).

6. **Accessibility level**: What WCAG conformance level is required? (A, AA, or AAA)
   - Default to AA if no specific requirement. Skip if already in requirements.

Only ask about decisions that are both unanswered and relevant. If all decisions are already answered, skip this step entirely and proceed to generation.

---

## Step 4 — Generate ui-design.md

Dispatch to `aegis/agents/ui-design-agent.md` with the following inputs:

- **requirements_content**: full text of `requirements.md`
- **design_content**: full text of `design.md`
- **stack_config**: the stack section from `.aegis/config.yaml`
- **brand_guide**: content of the brand-guide input doc (if any), else `null`
- **user_decisions**: key/value map of answers collected in Step 3
- **template**: content of `aegis/framework/templates/ui-design/<formalism>.template.md`
- **i18n**: loaded label set from Step 1
- **level_rules**: content of `aegis/framework/levels/<formalism>.md`
- **req_ids**: list of all REQ-NNN IDs extracted in Step 2
- **ui_req_ids**: subset of REQ-NNN IDs that are UI-relevant (from Step 2)
- **prop_ids**: list of all PROP-NNN IDs extracted in Step 2
- **components**: list of components from design.md
- **data_models**: data model definitions from design.md

### What the agent must produce

The agent must write a complete `ui-design.md` that:

1. **Establishes a bold, intentional aesthetic direction** — not a generic template. The design must have a clear point-of-view derived from the user's answers and project context.
2. **Defines a complete design system** — typography, colors, spacing, grid, motion, and effects with specific implementable values (hex codes, pixel values, timing functions, font names).
3. **Specifies every UI component as a UI-NNN entry** — each with enough detail for a developer to implement it without design decisions. Includes all visual states, responsive behavior, and accessibility attributes.
4. **Specifies page/screen layouts** — how components compose into pages, their grid placement, and responsive behavior at each breakpoint.
5. **Covers every UI-relevant REQ-NNN** — each must be addressed by at least one UI-NNN entry with a `Derives from: REQ-NNN` reference.
6. **Is fully implementable** — every value must be concrete. No "choose a nice blue" — use `#1A73E8`. No "add some animation" — use `transform: scale(1.02); transition: 200ms ease-out`.

The output file path is `<output.dir>/ui-design.md` (default: `.aegis/ui-design.md`).

---

## Step 5 — Light Validation (after_ui_design)

After `ui-design.md` is written, run the following checks from `aegis/framework/validation/rules.yaml`:

| Check ID   | What to verify                                                                     | Severity |
|------------|------------------------------------------------------------------------------------|----------|
| VAL-UI-01  | Every UI-relevant REQ-NNN has at least one UI-NNN with `Derives from: REQ-NNN`    | warning  |
| VAL-UI-02  | Every UI-NNN has a `Derives from:` pointing to a valid REQ-NNN or PROP-NNN        | error    |
| VAL-UI-03  | No duplicate UI-NNN IDs                                                            | error    |
| VAL-UI-04  | Design system section present with typography, colors, and spacing defined         | warning  |
| VAL-UI-05  | Interactive components include accessibility specs (Standard and Formal only)      | warning  |

**If any error-severity check fails:**
- Report the gaps clearly.
- Ask the user: "Validation found gaps. Would you like to fix them now or proceed with the current ui-design.md?"
- Wait for the user's answer. If they choose to proceed, note the gaps in a `## Validation Notes` section appended to `ui-design.md`.

**If only warning-severity checks fail:**
- Append a `## Validation Notes` section to `ui-design.md` listing the warnings.
- Do not block advancement.

---

## Step 6 — Present Summary

After generation and validation, present a summary to the user:

```
ui-design.md generated successfully.

Summary:
  Aesthetic direction:  <direction chosen>
  UI-NNN count:         <N>
  Pages/screens:        <N>
  Design system:        <Complete | Partial>
  Validation:           <PASS | PASS with warnings | GAPS FOUND>

Warnings (if any):
  - <warning message>

Next: run /aegis:tasks to generate the implementation plan.
```

Use the i18n label set for all section headings in the summary if the project language is not English.

---

## Behavioral Rules

- **Distinctiveness is non-negotiable.** The generated specification must commit to a bold aesthetic direction. Generic, template-like output with safe default choices (Inter font, purple gradients, card-based layouts with rounded corners) is a failure. Every design must feel intentionally crafted for the specific project.
- **One question at a time.** Never ask multiple design direction questions in a single message. Wait for each answer before proceeding.
- **Specificity over abstraction.** Every value in the specification must be concrete and implementable: hex colors, pixel values, font names, timing functions, easing curves. Never use vague descriptors like "a warm tone" or "smooth animation".
- **Traceability first.** Every UI-NNN must have a `Derives from:` field. No UI specification may be created without a documented link to a requirement or design property.
- **Overwrite by default.** If `ui-design.md` already exists, overwrite it. If it contains a `NEEDS REVIEW` notice from `/aegis:update`, remove the notice as part of regeneration.
- **No code generation.** This phase produces a specification, not code. Describe what to implement with exact values, but do not write CSS, HTML, or component code. The implementation is done by the developer or another agent using this specification as input.

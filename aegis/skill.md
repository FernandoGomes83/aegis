---
name: aegis
description: >
  Aegis Framework — Generate and maintain structured software design documents
  (requirements, design, tasks, tests) from project input docs. Includes
  embedded security, bidirectional traceability, and TDD test generation.
  Use /aegis to see available commands.
---

# Aegis Framework Skill

You are the Aegis Framework skill. Your role is to generate and maintain four structured software design artifacts — **requirements**, **design**, **tasks**, and **tests** — from project input documents. You enforce bidirectional traceability, inject security requirements unconditionally, and produce TDD-ready test files.

---

## Framework File Resolution

The Aegis framework files are installed under `.claude/aegis/` (project-local) or `~/.claude/aegis/` (global). **Before executing any command**, determine the framework root:

1. If `.claude/aegis/framework/SPEC.md` exists (relative to project root) → **AEGIS_HOME** = `.claude/aegis`
2. Else if `~/.claude/aegis/framework/SPEC.md` exists → **AEGIS_HOME** = `~/.claude/aegis`
3. Else → tell the user to install Aegis with `npx aegis-sdd`

**Path mapping for all framework files** (applies throughout this skill, its commands, and agents):

| Path prefix in instructions | Resolve to |
|---|---|
| `aegis/framework/…` | `{AEGIS_HOME}/framework/…` |
| `aegis/commands/…` | `{AEGIS_HOME}/commands/…` |
| `aegis/agents/…` | `{AEGIS_HOME}/agents/…` |

**Project output paths** like `aegis/requirements.md`, `aegis/design.md`, `aegis.config.yaml`, and `docs/aegis/reports/` are always relative to the **project root** — they are NOT under AEGIS_HOME.

---

## Available Commands

| Command | Description |
|---------|-------------|
| `/aegis init` | Initialize Aegis in a project — set level, language, stack, inputs |
| `/aegis requirements` | Generate requirements.md from input docs |
| `/aegis design` | Generate design.md from requirements |
| `/aegis tasks` | Generate tasks.md from design + requirements |
| `/aegis tests` | Generate tests.md + RED test files |
| `/aegis validate` | Full validation — coverage matrix, security audit, gaps |
| `/aegis update [artifact]` | Update an artifact and check downstream impact |
| `/aegis status` | Show current Aegis state, coverage, next steps |

---

## Routing

- If the user invokes `/aegis` with **no arguments**, display the Available Commands table above and wait for their selection.
- If the user invokes `/aegis <command>`, read `{AEGIS_HOME}/commands/<command>.md` and follow its instructions exactly.
- If `{AEGIS_HOME}/commands/<command>.md` does not exist, tell the user the command is not yet implemented and list the available commands.

---

## Core Rules

1. **Read config first.** Every command except `init` must read `aegis.config.yaml` before doing anything. If the file does not exist, stop and tell the user to run `/aegis init` first.

2. **Security is non-negotiable.** Always inject security requirements and properties at full rigor, regardless of the configured formalism level. Before generating any artifact, read `{AEGIS_HOME}/framework/security/SECURITY_UNIVERSAL.md` and apply its rules unconditionally.

3. **Traceability is mandatory.** Every generated element — requirement, component, task, test — must carry the cross-reference IDs defined in `{AEGIS_HOME}/framework/SPEC.md §4`. No element may be created without a documented link to its parent artifact.

4. **Interactive by default.** Before generating, identify ambiguities in the inputs or config. Ask one clarifying question at a time and wait for the user's answer before proceeding.

5. **Validate after generation.** After producing any artifact, run a light validation pass (coverage completeness, security presence, ID consistency). Report gaps inline in a `## Validation Notes` section at the end of the artifact.

6. **Language from config.** Use the `language` value in `aegis.config.yaml` to select the correct i18n label set from `{AEGIS_HOME}/framework/i18n/` and apply it to all generated content headings, labels, and status values.

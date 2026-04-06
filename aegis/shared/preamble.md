# Aegis Framework — Shared Context

You are executing an Aegis Framework command. Apply all rules below before proceeding with the command instructions.

---

## Path Mapping

All framework file references in commands and agents use shorthand prefixes. Resolve them using the **AEGIS_HOME** value determined during bootstrap:

| Path prefix in instructions | Resolve to |
|---|---|
| `aegis/framework/…` | `{AEGIS_HOME}/framework/…` |
| `aegis/agents/…` | `{AEGIS_HOME}/agents/…` |

**Project output paths** like `.aegis/requirements.md`, `.aegis/design.md`, `.aegis/config.yaml`, and `.aegis/reports/` are always relative to the **project root** — they are NOT under AEGIS_HOME.

---

## Available Commands

| Command | Description |
|---------|-------------|
| `/aegis:init` | Initialize Aegis in a project — set level, language, stack, inputs |
| `/aegis:requirements` | Generate requirements.md from input docs |
| `/aegis:design` | Generate design.md from requirements |
| `/aegis:ui-design` | Generate ui-design.md — frontend/UI design specification |
| `/aegis:tasks` | Generate tasks.md from design + requirements |
| `/aegis:tests` | Generate tests.md + RED test files |
| `/aegis:build` | Implement tasks from tasks.md — autonomous build loop |
| `/aegis:validate` | Full validation — coverage matrix, security audit, gaps |
| `/aegis:update [artifact]` | Update an artifact and check downstream impact |
| `/aegis:status` | Show current Aegis state, coverage, next steps |

---

## Core Rules

1. **Read config first.** Every command except `init` must read `.aegis/config.yaml` before doing anything. If the file does not exist, stop and tell the user to run `/aegis:init` first.

2. **Security is non-negotiable.** Always inject security requirements and properties at full rigor, regardless of the configured formalism level. Before generating any artifact, read `{AEGIS_HOME}/framework/security/SECURITY_UNIVERSAL.md` and apply its rules unconditionally.

3. **Traceability is mandatory.** Every generated element — requirement, component, task, test — must carry the cross-reference IDs defined in `{AEGIS_HOME}/framework/SPEC.md §4`. No element may be created without a documented link to its parent artifact.

4. **Interactive by default.** Before generating, identify ambiguities in the inputs or config. Ask one clarifying question at a time and wait for the user's answer before proceeding.

5. **Validate after generation.** After producing any artifact, run a light validation pass (coverage completeness, security presence, ID consistency). Report gaps inline in a `## Validation Notes` section at the end of the artifact.

6. **All documentation in English.** All Aegis artifacts (requirements.md, design.md, tasks.md, tests.md, ui-design.md) are always generated in English.

# Aegis — Secure Software Design Documents

A framework for generating structured software design documents with embedded security. Works as a standalone spec (tool-agnostic) and as a Claude Code skill.

## What it does

Aegis generates up to 5 artifacts from your project docs:

1. **requirements.md** — What the system must do (functional + security requirements)
2. **design.md** — How it will be built (architecture, data models, correctness properties)
3. **ui-design.md** — What the interface looks and feels like (design system, component specs, page layouts) *(optional — for projects with a frontend/UI)*
4. **tasks.md** — Implementation plan with dependency graph, `[P]` parallel markers, and execution phases
5. **tests.md** — TDD test specs + RED test files (all tests fail before implementation)

Then **builds it** — `/aegis:build` implements tasks autonomously with a stop-hook-controlled loop, one commit per task.

Every artifact has bidirectional traceability. Every project gets full security coverage regardless of documentation level.

## Security is non-negotiable

Aegis embeds a universal security baseline (OWASP-aligned) that is injected automatically:

- **Requirements:** Security requirements auto-added based on project characteristics
- **Design:** Security correctness properties auto-injected
- **Tests:** Security tests auto-generated
- **Build:** Stop hook rejects commits containing `.env` files or secrets

You choose the formalism level (light, standard, formal) for your docs. Security is always **FULL**.

## Install

```bash
npx aegis-sdd
```

The installer asks where to install:

- **Global** (`~/.claude/commands/aegis.md` + `~/.claude/aegis/`) — available in all your projects
- **Local** (`.claude/commands/aegis.md` + `.claude/aegis/`) — this project only

Or skip the prompt with flags:

```bash
npx aegis-sdd --global    # all projects
npx aegis-sdd --local     # current project only
```

Requires [Claude Code](https://claude.ai/claude-code) installed.

## Usage

In any project with Claude Code:

```
/aegis:init          → Configure project (level, stack, inputs)
/aegis:requirements  → Generate requirements.md
/aegis:design        → Generate design.md
/aegis:ui-design     → Generate ui-design.md (frontend/UI design specification)
/aegis:tasks         → Generate tasks.md with [P] markers + execution graph
/aegis:tests         → Generate tests.md + RED test files
/aegis:build         → Implement tasks autonomously (stop-hook loop)
/aegis:validate      → Full validation report (coverage, security audit, gaps)
/aegis:update        → Update an artifact + check downstream impact
/aegis:status        → Show current state and next steps
```

## Build loop

`/aegis:build` implements tasks from `tasks.md` using an autonomous loop:

1. Parses the dependency graph and finds actionable tasks (all deps done)
2. You pick a task (or `--all` for unattended execution)
3. A stop hook feeds the implementation prompt back on each iteration
4. Each task gets one atomic commit: `feat(TASK-NNN): <title>`
5. `[P]` parallel tasks get isolated git worktrees, merged back on completion
6. Verification layers check for contradictions, test existence, and secret leaks
7. Recovery mode auto-generates fix tasks when implementation fails

## Three formalism levels

| Level | When to use | Requirements format |
|-------|------------|-------------------|
| **Light** | Scripts, POCs, simple tools | Feature list + bullet criteria |
| **Standard** | SaaS, apps, APIs | User stories + acceptance criteria |
| **Formal** | Fintech, healthcare, critical systems | SHALL/WHEN/IF + glossary |

Security coverage is identical across all levels.

## Stack agnostic

Aegis works with any stack. It auto-detects your project's language and framework:

Node.js/TypeScript, Python, Go, Rust, Java, PHP, HTML/CSS/JS, and more.

## Framework layer (tool-agnostic)

The `aegis/framework/` directory contains the standalone specification:

- `SPEC.md` — The formal framework specification
- `levels/` — Formalism level definitions
- `templates/` — Artifact templates (15 templates: 5 artifacts x 3 levels)
- `security/` — SECURITY_UNIVERSAL.md + security requirements/properties YAML
- `validation/` — Validation rules and coverage matrix docs
- `inputs/` — Recommended input doc types and templates

This layer can be used with any LLM or manually, without Claude Code.

## License

MIT

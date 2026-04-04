# Aegis — Secure Software Design Documents

A framework for generating structured software design documents with embedded security. Works as a standalone spec (tool-agnostic) and as a Claude Code skill.

## What it does

Aegis generates 4 artifacts from your project docs:

1. **requirements.md** — What the system must do (functional + security requirements)
2. **design.md** — How it will be built (architecture, data models, correctness properties)
3. **tasks.md** — Implementation plan (ordered tasks with traceability)
4. **tests.md** — TDD test specs + RED test files (all tests fail before implementation)

Every artifact has bidirectional traceability. Every project gets full security coverage regardless of documentation level.

## Security is non-negotiable

Aegis embeds a universal security baseline (OWASP-aligned) that is injected automatically:

- **Requirements:** Security requirements auto-added based on project characteristics
- **Design:** Security correctness properties auto-injected
- **Tests:** Security tests auto-generated

You choose the formalism level (light, standard, formal) for your docs. Security is always **FULL**.

## Install

```bash
npx aegis-sdd
```

The installer asks where to install:

- **Global** (`~/.claude/plugins/aegis/`) — available in all your projects
- **Local** (`.claude/plugins/aegis/`) — this project only

Or skip the prompt with flags:

```bash
npx aegis-sdd --global    # all projects
npx aegis-sdd --local     # current project only
```

Requires [Claude Code](https://claude.ai/claude-code) installed.

## Usage

In any project with Claude Code:

```
/aegis init          → Configure project (level, language, stack, inputs)
/aegis requirements  → Generate requirements.md
/aegis design        → Generate design.md
/aegis tasks         → Generate tasks.md
/aegis tests         → Generate tests.md + RED test files
/aegis validate      → Full validation report (coverage, security audit, gaps)
/aegis update        → Update an artifact + check downstream impact
/aegis status        → Show current state and next steps
```

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
- `templates/` — Artifact templates (12 templates: 4 artifacts x 3 levels)
- `security/` — SECURITY_UNIVERSAL.md + security requirements/properties YAML
- `validation/` — Validation rules and coverage matrix docs
- `i18n/` — English and Portuguese Brazilian labels
- `inputs/` — Recommended input doc types and templates

This layer can be used with any LLM or manually, without Claude Code.

## License

MIT

# Aegis — Secure Software Design Documents

A framework for generating structured software design documents with embedded security. Works as a standalone spec (tool-agnostic) and as a [Claude Code](https://claude.ai/claude-code) skill.

> **New to Aegis?** Read the [User Manual](docs/USER_MANUAL.md) for a complete walkthrough.

## What it does

Aegis generates up to 5 artifacts from your project docs:

1. **requirements.md** — What the system must do (functional + security requirements)
2. **design.md** — How it will be built (architecture, data models, correctness properties)
3. **ui-design.md** — What the interface looks and feels like (design system, component specs, page layouts) *(optional — for projects with a frontend/UI)*
4. **tasks.md** — Implementation plan with dependency graph, `[P]` parallel markers, and execution phases
5. **tests.md** — TDD test specs + RED test files (all tests fail before implementation)

Then **builds it** — `/aegis:build` implements tasks autonomously with a stop-hook-controlled loop, one commit per task.

Every artifact has **bidirectional traceability** (REQ &rarr; PROP &rarr; TASK &rarr; TEST). Every project gets full security coverage regardless of documentation level.

## Security is non-negotiable

Aegis embeds a universal security baseline (OWASP-aligned) that is injected automatically at three moments:

| Moment | What happens |
|--------|-------------|
| **Requirements** | SEC-REQ-* auto-added based on project characteristics (IDOR, CSRF, rate limiting, etc.) |
| **Design** | SEC-PROP-* auto-injected — implementation properties derived from SEC-REQ-* |
| **Tests** | TEST-SEC-* auto-generated for every SEC-PROP-* |
| **Build** | Stop hook rejects commits containing `.env` files or secret patterns |

You choose the formalism level (light, standard, formal) for your docs. Security is always **FULL** — 11 threat categories from the SECURITY_UNIVERSAL.md baseline.

## Install

```bash
npx aegis-sdd
```

The installer asks where to install:

- **Global** (`~/.claude/aegis/` + commands) — available in all your projects
- **Local** (`.claude/aegis/` + commands) — this project only

Or skip the prompt with flags:

```bash
npx aegis-sdd --global
npx aegis-sdd --local
```

**Requires** [Claude Code](https://claude.ai/claude-code) installed.  
**Zero dependencies** — the installer uses only Node.js built-ins.

## Usage

In any project with Claude Code:

```
/aegis:init          → Configure project (level, stack, inputs)
/aegis:requirements  → Generate requirements.md
/aegis:design        → Generate design.md
/aegis:ui-design     → Generate ui-design.md (frontend/UI design spec)
/aegis:tasks         → Generate tasks.md with [P] markers + execution graph
/aegis:tests         → Generate tests.md + RED test files
/aegis:build         → Implement tasks autonomously (stop-hook loop)
/aegis:validate      → Full validation report (coverage, security audit, gaps)
/aegis:update        → Update an artifact + check downstream impact
/aegis:status        → Show current state and next steps
```

See the [User Manual](docs/USER_MANUAL.md) for detailed documentation of each command.

## Build loop

`/aegis:build` implements tasks from `tasks.md` using an autonomous loop:

1. Parses the dependency graph and finds actionable tasks (all deps done)
2. Runs baseline verification (`build.verifyCommand` if configured)
3. You pick a task (or `--all` for unattended execution)
4. The build agent implements each task, then the stop hook verifies:
   - `TASK_COMPLETE` signal present
   - No contradictions or secret leaks
   - `build.verifyCommand` passes (if set)
5. Each completed task gets one atomic commit: `feat(TASK-NNN): <title>`
6. `[P]` parallel tasks get isolated git worktrees, merged back on completion
7. Failed tasks are auto-retried (up to 5 attempts) with recovery mode

## Three formalism levels

| Level | When to use | Requirements format | Design format | Estimates |
|-------|------------|-------------------|---------------|-----------|
| **Light** | Scripts, POCs, simple tools | Feature list + bullet criteria | Component list, no ADRs | T-shirt (S/M/L/XL) |
| **Standard** | SaaS, apps, APIs | User stories + acceptance criteria | Architecture + ADRs | Hours/points |
| **Formal** | Fintech, healthcare, critical systems | IEEE-830 + glossary + risk matrix | Full ADR set + data dictionary | PERT estimates |

Security coverage is identical across all levels.

## Traceability

Every generated element carries cross-reference IDs with strict formats:

```
requirements.md    →  REQ-001, SEC-REQ-IDOR
design.md          →  PROP-001 (derives from REQ-001), SEC-PROP-RATELIMIT
ui-design.md       →  UI-001
tasks.md           →  TASK-001 (implements PROP-001)
tests.md           →  TEST-REQ-001, TEST-PROP-001, TEST-SEC-IDOR
```

Forward and backward traces are complete — every requirement is covered by properties, tasks, and tests.

## Stack agnostic

Aegis works with any stack. During `/aegis:init`, it auto-detects your project's language and framework by checking for `package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `pom.xml`, `composer.json`, and more.

Supported ecosystems: Node.js/TypeScript, Python, Go, Rust, Java, PHP, HTML/CSS/JS, and others.

## Context7 integration

Optional integration for fetching up-to-date library documentation via API. Configured in `.aegis/config.yaml`:

```yaml
context7:
  api_key: "YOUR_KEY_HERE"
```

When available, library docs are injected into agents as the primary source of truth (design, build, tests). Falls back to WebSearch or training knowledge when unavailable — never blocks artifact generation.

## Configuration

After `/aegis:init`, your project gets `.aegis/config.yaml`:

```yaml
version: "1"

project:
  name: "My Project"
  language: "en"                    # product target language (for UI text)

formalism: standard                 # light | standard | formal

inputs:
  - path: docs/PROJECT_SPEC.md
    type: product-spec
  - path: docs/BRAND.md
    type: brand-guide

output:
  dir: .aegis/

build:
  verifyCommand: "pnpm build && pnpm test"   # optional
```

### Project output structure

```
.aegis/
  config.yaml
  requirements.md
  design.md
  ui-design.md           # if project has UI
  tasks.md
  tests.md
  tests/                 # RED test files
  reports/               # validation reports
  build-state.json       # build progress tracking
```

## Validation

`/aegis:validate` produces a multi-section report:

- **Coverage matrix** — every REQ and SEC-REQ mapped against PROP, TASK, and TEST coverage
- **Security audit** — status of every SEC-REQ-* and SEC-PROP-* across all artifacts
- **Gaps report** — broken references, orphan IDs, coverage holes
- **Stats** — total counts, coverage percentage, effort summary

## Framework layer (tool-agnostic)

The `aegis/framework/` directory contains the standalone specification usable with any LLM or manually:

```
framework/
  SPEC.md              — Authoritative framework specification
  levels/              — Formalism level definitions (light, standard, formal)
  templates/           — 15 artifact templates (5 artifacts x 3 levels)
  security/            — SECURITY_UNIVERSAL.md + YAML catalogs
  validation/          — Validation rules and coverage matrix definitions
  inputs/              — Recommended input doc types + starter templates
```

## Repository structure

```
aegis-sdd/
├── bin/install.mjs              # Zero-dependency NPM installer
├── aegis/
│   ├── skill.md                 # Main skill index
│   ├── commands/                # 10 slash-command definitions
│   ├── agents/                  # 7 generation agents
│   ├── shared/                  # 5 cross-cutting modules (preamble, context7, design-critic, aesthetics, interview)
│   ├── scripts/                 # 13 shell scripts (build loop, parsing, state, quality, statusline)
│   └── framework/               # Tool-agnostic spec (see above)
├── docs/                        # Example input documents + user manual
├── plans/                       # Roadmap for future enhancements
├── package.json
├── CLAUDE.md                    # Guidance for Claude Code contributors
└── CONTRIBUTING.md
```

## Documentation

- [User Manual](docs/USER_MANUAL.md) — Complete guide: installation, configuration, commands, build loop, troubleshooting
- [SPEC.md](aegis/framework/SPEC.md) — Authoritative framework specification
- [CONTRIBUTING.md](CONTRIBUTING.md) — How to contribute
- [CLAUDE.md](CLAUDE.md) — Instructions for Claude Code when working on this repo

## License

MIT

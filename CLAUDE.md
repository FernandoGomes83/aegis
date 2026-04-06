# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What is Aegis

Aegis is a Claude Code skill (slash-command framework) that generates structured software design documents with embedded security. It ships as an npm package (`npx aegis-sdd`) that installs markdown-based commands and agents into `~/.claude/` (global) or `.claude/` (local). There is no build step, no runtime dependencies, and no test suite — the "test" is installing locally and running the skill flow in a Claude Code session.

## Repository structure

The repo has two layers:

- **Layer 1 — Framework** (`aegis/framework/`): Tool-agnostic spec. Markdown templates, YAML configs, security baselines, and validation rules. Can be used without Claude Code.
- **Layer 2 — Skill** (`aegis/commands/`, `aegis/agents/`, `aegis/shared/`, `aegis/scripts/`): Claude Code automation. Commands are slash-command definitions (`/aegis:*`), agents are dispatched by commands to generate artifacts, shared modules provide cross-cutting context (preamble, context7 lookup), scripts handle parsing/state/context to minimize token usage.

The installer (`bin/install.mjs`) copies `aegis/` into the user's `.claude/aegis/` directory and creates command files in `.claude/commands/`. It also makes shell scripts executable.

## Key commands

```bash
# Install locally for testing
node bin/install.mjs --local

# Install globally
node bin/install.mjs --global
```

After installing, restart Claude Code and test the flow:
`/aegis:init` -> `/aegis:requirements` -> `/aegis:design` -> `/aegis:ui-design` -> `/aegis:tasks` -> `/aegis:tests` -> `/aegis:build` -> `/aegis:validate`

## Architecture decisions

**Zero dependencies.** The package.json has no `dependencies`. The installer is a single ESM script using only Node.js built-ins. Never add npm dependencies.

**Two-copy design.** The `aegis/` directory in this repo is the source of truth. The installer copies it to `.claude/aegis/` at install time. The `.claude/` directory in the repo is the local install target (gitignored). When editing framework files, edit in `aegis/`, then re-run `node bin/install.mjs --local` to sync.

**Security is non-negotiable.** Every artifact gets full security treatment regardless of formalism level (light/standard/formal). SEC-REQ-*, SEC-PROP-*, and TEST-SEC-* sections cannot be removed, suppressed, or reduced. Never weaken security content. See `SECURITY_UNIVERSAL.md` and the YAML catalogs in `aegis/framework/security/`.

**Bidirectional traceability.** Every generated element must carry cross-reference IDs per SPEC.md section 4: REQ-NNN, PROP-NNN, UI-NNN, TASK-NNN, TEST-*. Forward and backward traces must be complete.

**Shell scripts for reduced permission prompts and token usage.** Reusable operations live in `aegis/scripts/*.sh` rather than inline Bash in command markdown. This reduces Claude Code permission prompts and keeps command files lean. Build scripts handle task parsing, context extraction, state management, progress marking, worktree management, and the stop hook loop.

**All documentation in English.** All Aegis artifacts (requirements.md, design.md, tasks.md, tests.md, ui-design.md) are always generated in English. The `language` config field indicates the product target language (for UI text in the app being built), not the documentation language.

## Conventions

- Commit messages follow Conventional Commits: `feat:`, `fix:`, `docs:`, `refactor:`, `chore:`
- ID formats are strict: REQ-NNN, SEC-REQ-*, PROP-NNN, SEC-PROP-*, UI-NNN, TASK-NNN, TEST-REQ-NNN, TEST-PROP-NNN, TEST-SEC-* (three-digit zero-padded where applicable)
- Templates exist at three levels: `light.template.md`, `standard.template.md`, `formal.template.md` for each artifact type
- Tasks use `[P]` markers for parallel-eligible tasks and include an Execution Graph section with dependency phases
- The build command uses a stop hook (`aegis-build-stop.sh`) for autonomous iteration, one commit per task
- The Context7 integration (`aegis/shared/context7-lookup.md` + `aegis/scripts/aegis-context7.sh`) fetches up-to-date library docs via API, falling back to WebSearch. It is non-blocking — failures never prevent artifact generation

## File editing guidance

- Agent files (`aegis/agents/*.md`) define the rules and output contracts for each generation phase. Changes here affect what the skill produces.
- Command files (`aegis/commands/*.md`) define the user-facing slash commands, including bootstrap, prerequisite loading, and agent dispatch.
- `aegis/framework/SPEC.md` is the authoritative reference. If there's a conflict between SPEC.md and any other file, SPEC.md wins.
- `aegis/shared/preamble.md` is loaded by every command — changes here affect all commands.
- Security YAML files (`security-requirements.yaml`, `security-properties.yaml`) are machine-readable catalogs read by agents at generation time. Additions welcome, removals forbidden.
- Build scripts (`aegis/scripts/aegis-build-*.sh`) handle the build loop mechanics. The stop hook (`aegis-build-stop.sh`) is the loop controller — changes here affect autonomous execution.

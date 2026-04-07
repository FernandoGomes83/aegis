# Contributing to Aegis

Thanks for your interest in contributing to Aegis!

## How to contribute

1. **Fork** the repository
2. **Create a branch** from `main`: `git checkout -b feat/your-feature`
3. **Make your changes** following the guidelines below
4. **Test** your changes (see Testing section)
5. **Commit** with a clear message following [Conventional Commits](https://www.conventionalcommits.org/)
6. **Push** to your fork and open a **Pull Request** against `main`

## What you can contribute

- New security requirements/properties in `aegis/framework/security/`
- Improvements to templates in `aegis/framework/templates/`
- Bug fixes in commands or agents
- Shell script improvements in `aegis/scripts/`
- Documentation improvements
- New input document templates in `aegis/framework/inputs/templates/`

## Architecture overview

Aegis has two layers:

- **Framework** (`aegis/framework/`) — Tool-agnostic spec: templates, security baselines, validation rules. Can be used without Claude Code.
- **Skill** (`aegis/commands/`, `aegis/agents/`, `aegis/shared/`, `aegis/scripts/`) — Claude Code automation.

### Key directories

| Directory | Content | Impact of changes |
|-----------|---------|-------------------|
| `aegis/commands/` | 10 slash-command definitions | User-facing behavior |
| `aegis/agents/` | 7 generation agents | Output format and rules |
| `aegis/shared/` | 5 cross-cutting modules | All commands that load them |
| `aegis/scripts/` | 13 shell scripts | Build loop mechanics, state |
| `aegis/framework/SPEC.md` | Authoritative spec | Everything — SPEC.md wins conflicts |
| `aegis/framework/templates/` | 15 artifact templates | Generated artifact structure |
| `aegis/framework/security/` | Security baselines + catalogs | Security content in all artifacts |

### How it flows

```
User runs /aegis:requirements
  → Command (aegis/commands/requirements.md) loads preamble + config
  → Command dispatches agent (aegis/agents/requirements-agent.md)
  → Agent reads templates, security YAML, level rules
  → Agent generates .aegis/requirements.md
  → Command runs light validation
```

## Guidelines

### Do

- Follow existing file conventions and naming patterns
- Keep security requirements at full rigor — security is never optional
- Use the ID conventions from `aegis/framework/SPEC.md` (REQ-NNN, PROP-NNN, UI-NNN, etc.)
- Write clear commit messages: `feat:`, `fix:`, `docs:`, `refactor:`
- Keep PRs focused — one feature or fix per PR
- Write all documentation and artifact content in English
- Keep shell scripts compatible with Bash 3.2 (macOS default)

### Don't

- Remove or weaken any existing security requirement or property
- Change the SECURITY_UNIVERSAL.md baseline (additions welcome, removals not)
- Add dependencies — Aegis is zero-dependency by design
- Modify the installer to require elevated permissions
- Include project-specific or proprietary content in templates
- Add npm packages to package.json `dependencies`

### Security rules are sacred

The core principle of Aegis is that security is non-negotiable. PRs that reduce security coverage in any way will be rejected. If you think a security rule should change, open an issue to discuss first.

### Shell script conventions

Scripts in `aegis/scripts/` follow these conventions:

- **Prefix**: All scripts start with `aegis-`
- **Shebang**: `#!/usr/bin/env bash`
- **Compatibility**: Bash 3.2+ (no associative arrays, no `readarray`)
- **Exit codes**: 0 = success, non-zero = error with message to stderr
- **Output**: Structured key=value pairs on stdout for command parsing
- **Purpose**: Minimize token usage by handling parsing/state externally

### Template conventions

Templates in `aegis/framework/templates/` use:

- Placeholder syntax: `{{project.name}}`, `{{generation_date}}`
- Three levels per artifact: `light.template.md`, `standard.template.md`, `formal.template.md`
- Guidance comments: `<!-- ... -->` for agent instructions
- Section markers that match the corresponding level definition

## Testing

Aegis has no automated test suite — testing is manual through the skill flow.

### After making changes

1. Install locally: `node bin/install.mjs --local`
2. Start a **new** Claude Code session in a test project
3. Run through the flow: `/aegis:init` → `/aegis:requirements` → `/aegis:design` → `/aegis:tasks` → `/aegis:tests` → `/aegis:build` → `/aegis:validate`
4. Verify your changes work as expected

### What to check

- Commands load without errors
- Generated artifacts follow the correct template for the formalism level
- Security sections (SEC-REQ-*, SEC-PROP-*, TEST-SEC-*) are present
- Traceability IDs are consistent across artifacts
- Shell scripts execute without permission issues
- The build loop completes at least one task cycle

### Quick smoke test

For small changes, you can do a focused test:

1. `node bin/install.mjs --local`
2. Start a new Claude Code session
3. Run `/aegis:status` (verifies bootstrap and config loading)
4. Run the specific command affected by your change

## Development workflow

### Editing source files

Always edit files in the `aegis/` directory (source of truth), not in `.claude/aegis/` (install target). After editing:

```bash
node bin/install.mjs --local
```

This syncs the source to the local install target. Start a new Claude Code session to pick up changes.

### Adding a new script

1. Create the script in `aegis/scripts/` with `aegis-` prefix
2. The installer automatically copies all files from `aegis/scripts/` and makes them executable
3. Update CLAUDE.md if the script introduces new concepts
4. Update this file's architecture table if needed

### Adding a new shared module

1. Create the module in `aegis/shared/`
2. Reference it from the commands that need it (commands load shared modules explicitly)
3. The installer automatically copies all files from `aegis/shared/`

### Modifying templates

1. Edit the template in `aegis/framework/templates/{artifact}/{level}.template.md`
2. Ensure all three levels remain consistent in structure
3. Test by generating the artifact at the modified level

## Reporting issues

Open an issue with:
- What you expected to happen
- What actually happened
- Steps to reproduce
- Which command you were using (`/aegis:init`, `/aegis:requirements`, etc.)
- Your formalism level (light/standard/formal)

## Code of Conduct

Be respectful. We follow the [Contributor Covenant](https://www.contributor-covenant.org/version/2/1/code_of_conduct/).

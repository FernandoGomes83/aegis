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
- New i18n translations in `aegis/framework/i18n/`
- Improvements to templates in `aegis/framework/templates/`
- Bug fixes in commands or agents
- Documentation improvements

## Guidelines

### Do

- Follow existing file conventions and naming patterns
- Keep security requirements at full rigor — security is never optional
- Use the ID conventions from `aegis/framework/SPEC.md` (REQ-NNN, PROP-NNN, etc.)
- Write clear commit messages: `feat:`, `fix:`, `docs:`, `refactor:`
- Keep PRs focused — one feature or fix per PR

### Don't

- Remove or weaken any existing security requirement or property
- Change the SECURITY_UNIVERSAL.md baseline (additions welcome, removals not)
- Add dependencies — Aegis is zero-dependency by design
- Modify the installer to require elevated permissions
- Include project-specific or proprietary content in templates

### Security rules are sacred

The core principle of Aegis is that security is non-negotiable. PRs that reduce security coverage in any way will be rejected. If you think a security rule should change, open an issue to discuss first.

## Testing

After making changes:

1. Install locally: `node bin/install.mjs --local`
2. Start a new Claude Code session in a test project
3. Run through the flow: `/aegis init` → `/aegis requirements` → etc.
4. Verify your changes work as expected

## Reporting issues

Open an issue with:
- What you expected to happen
- What actually happened
- Steps to reproduce
- Which command you were using (`/aegis init`, `/aegis requirements`, etc.)

## Code of Conduct

Be respectful. We follow the [Contributor Covenant](https://www.contributor-covenant.org/version/2/1/code_of_conduct/).

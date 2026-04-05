# Aegis Framework Specification

> Version 1.0 — 2026-04-04
> This document is the authoritative reference for the Software Design Documents (Aegis) framework.
> It defines artifacts, rules, conventions, and behaviors that all tooling must conform to.

---

## Table of Contents

1. [Purpose](#1-purpose)
2. [Artifacts](#2-artifacts)
3. [Formalism Levels](#3-formalism-levels)
4. [ID Conventions and Traceability](#4-id-conventions-and-traceability)
5. [Security](#5-security)
6. [Validation](#6-validation)
7. [Input Docs](#7-input-docs)
8. [Configuration](#8-configuration)
9. [Change Propagation](#9-change-propagation)

---

## 1. Purpose

The Aegis framework is a structured, artifact-based approach to software design documentation. It exists to close the gap between product intent and implementation by making design decisions explicit, traceable, and auditable — before and during development.

The framework operates in two layers:

- **Layer 1 — Framework**: Tool-agnostic. Markdown templates, YAML configs, and this SPEC.md. Can be used manually by any team.
- **Layer 2 — Skill**: Claude Code automation. A `/aegis` skill that reads project inputs, applies the framework rules, and generates all four artifacts with full traceability.

The framework enforces three principles unconditionally:

1. **Traceability**: Every task traces back to a requirement. Every test traces to a property. Nothing is implemented without a documented reason.
2. **Security is non-negotiable**: Security requirements and properties are injected at generation time and cannot be disabled, overridden, or reduced by any formalism level setting.
3. **Validation before advancement**: Artifacts are validated after generation. A project cannot declare design complete if requirements are untraced or security checks are missing.

---

## 2. Artifacts

The framework produces exactly four artifacts per project. They are always generated in order because each derives from the previous.

### Artifact Table

| Artifact           | File              | Answers                                              | Derives From                         |
|--------------------|-------------------|------------------------------------------------------|--------------------------------------|
| Requirements       | requirements.md   | What must the system do? Who needs it? Why?          | Input docs (spec, brief, plan, etc.) |
| Design             | design.md         | How will the system do it? What are the properties?  | requirements.md                      |
| Tasks              | tasks.md          | What work units implement the design? In what order? | design.md                            |
| Tests              | tests.md          | How do we verify each property is satisfied?         | design.md + requirements.md          |

### Generation Flow

The following diagram shows the generation order and data flow between artifacts:

```
  Input Documents
  (spec, brand, plan, security, api-docs, ...)
          |
          v
  +------------------+
  |  requirements.md |  <-- generated first
  |                  |      REQ-NNN: functional
  |                  |      SEC-REQ-*: security (always injected)
  +------------------+
          |
          v
  +------------------+
  |    design.md     |  <-- generated second
  |                  |      PROP-NNN: design properties
  |                  |      SEC-PROP-*: security properties (always injected)
  +------------------+
         / \
        /   \
       v     v
  +----------+  +-----------+
  | tasks.md |  |  tests.md |  <-- generated third (can be parallel)
  |          |  |           |
  | TASK-NNN |  | TEST-*    |
  +----------+  +-----------+
```

### Artifact Descriptions

**requirements.md** — Declares what the system must do. Organized by functional area. Each requirement has a unique REQ-NNN ID, a user story or stakeholder statement, and acceptance criteria in SHALL/WHEN/THEN form. Security requirements (SEC-REQ-*) are a mandatory section regardless of formalism level.

**design.md** — Declares how the system satisfies requirements. Organized by component or concern. Each design decision is captured as a property (PROP-NNN) that derives from one or more requirements. Architecture diagrams and data flow descriptions live here. Security properties (SEC-PROP-*) are always present.

**tasks.md** — Decomposes the design into executable work units (TASK-NNN). Each task references the PROP-NNN it implements. Tasks are ordered by dependency and include effort estimates (at Standard and Formal levels). The tasks file is the handoff to engineering.

**tests.md** — Defines verification strategy. Each test (TEST-*) references the PROP-NNN or REQ-NNN it validates. Includes unit tests, integration tests, and — always — security tests regardless of formalism level.

---

## 3. Formalism Levels

The formalism level controls the depth, verbosity, and completeness of non-security content. Security is always FULL at every level.

### Level Definitions

#### Light

**When to use**: Prototypes, internal tools, MVPs with a single developer, weekend projects, or any project where speed of iteration outweighs documentation completeness.

**Characteristics**:
- Requirements: user stories only, no acceptance criteria tables, no stakeholder matrix
- Design: component list with one-line descriptions, no ADRs, no sequence diagrams
- Tasks: flat list with estimates in T-shirt sizes (S/M/L/XL)
- Tests: happy-path tests only, no edge-case matrix
- Security: **FULL** — all SEC-REQ-* and SEC-PROP-* sections, all injection moments, full checklist from SECURITY_UNIVERSAL §14

#### Standard

**When to use**: Team projects, client work, production systems without regulatory constraints, most commercial products.

**Characteristics**:
- Requirements: user stories + SHALL/WHEN/THEN acceptance criteria, glossary, stakeholder summary
- Design: component descriptions, data models, sequence diagrams for critical flows, at least one ADR per major technology choice
- Tasks: structured task list with numeric estimates (hours or story points), dependency ordering, assignee fields
- Tests: functional tests + edge cases, integration test plan, performance criteria
- Security: **FULL** — identical to Light security treatment

#### Formal

**When to use**: Regulated industries (fintech, health, legal), systems with compliance requirements (SOC 2, PCI-DSS, LGPD, HIPAA), multi-team architectures, or any project where the cost of a design defect is high.

**Characteristics**:
- Requirements: full IEEE-830-inspired structure, stakeholder matrix, priority/risk classification, review and approval fields
- Design: full ADR set, formal data dictionary, API contract (OpenAPI or equivalent), deployment topology diagram, failure mode analysis
- Tasks: full work breakdown structure with PERT estimates, risk-adjusted effort, dependency graph, milestone mapping
- Tests: complete test plan document, coverage targets, performance benchmarks, penetration test requirements, compliance test mapping
- Security: **FULL** — identical to Light and Standard security treatment, plus compliance mapping section

### Security at All Levels — Explicit Statement

**Security is not controlled by formalism level. It is embedded in the framework core.**

This means:
- A Light-level project gets the same security requirements and properties as a Formal-level project.
- No configuration flag, no command option, and no user instruction can reduce or skip security content.
- The formalism level setting exclusively affects the depth of functional, design, and test content.

---

## 4. ID Conventions and Traceability

### ID Formats

| ID Pattern    | Used In           | Example           | Description                                               |
|---------------|-------------------|-------------------|-----------------------------------------------------------|
| REQ-NNN       | requirements.md   | REQ-001           | Functional requirement, three-digit zero-padded           |
| SEC-REQ-*     | requirements.md   | SEC-REQ-IDOR      | Security requirement, keyed by threat/control name        |
| PROP-NNN      | design.md         | PROP-007          | Design property, three-digit zero-padded                  |
| SEC-PROP-*    | design.md         | SEC-PROP-RATELIMIT| Security design property, keyed by control name           |
| TASK-NNN      | tasks.md          | TASK-012          | Work task, three-digit zero-padded                        |
| TEST-REQ-NNN  | tests.md          | TEST-REQ-001      | Test targeting a functional requirement                   |
| TEST-PROP-NNN | tests.md          | TEST-PROP-007     | Test targeting a design property                          |
| TEST-SEC-*    | tests.md          | TEST-SEC-IDOR     | Security test, always present                             |

### Cross-Reference Syntax

All cross-references use a consistent prefix word followed by the ID. This makes them machine-parseable and human-readable.

| Keyword       | Used In         | Meaning                                                    |
|---------------|-----------------|------------------------------------------------------------|
| `Derives from`| design.md       | This property was derived from the listed requirement(s)   |
| `Implements`  | tasks.md        | This task implements the listed property/requirement       |
| `Validates`   | tasks.md        | This task adds validation logic for the listed requirement |
| `Tests`       | tests.md        | This test verifies the listed property or requirement      |

### Bidirectional Trace Example

The following example shows how a single user need flows through all four artifacts with full bidirectional traceability.

```
requirements.md
---------------
REQ-004: Rate Limiting on Public Endpoints
  User Story: As the platform operator, I need all public endpoints to be
  rate-limited so that automated abuse cannot exhaust compute or AI credits.
  Acceptance Criteria:
    SHALL apply rate limiting to every endpoint reachable without authentication.
    WHEN a client exceeds the limit, THE system SHALL return HTTP 429.
    WHEN a client exceeds the limit, THE system SHALL not process the request.

SEC-REQ-RATELIMIT: Rate Limit on Authentication Endpoints
  The system SHALL limit login and registration endpoints to 5 attempts per
  15-minute window per IP address.


design.md
---------
PROP-011: API Rate Limiting Strategy
  Derives from: REQ-004, SEC-REQ-RATELIMIT
  Description: All API routes use @upstash/ratelimit with a sliding window
  algorithm. Public endpoints: 60 req/min. Auth endpoints: 5 req/15min.
  Response on limit exceeded: HTTP 429 with Retry-After header.

SEC-PROP-RATELIMIT: Rate Limiter Implementation
  Derives from: SEC-REQ-RATELIMIT
  Description: Rate limiter applied as middleware before route handlers.
  Auth endpoints (POST /auth/login, POST /auth/register) use separate,
  stricter limits. IP address is the rate-limit key for unauthenticated
  endpoints; user ID is the key for authenticated endpoints.


tasks.md
--------
TASK-023: Implement API Rate Limiting Middleware
  Implements: PROP-011, SEC-PROP-RATELIMIT
  Description: Create rate limit middleware using @upstash/ratelimit.
  Configure sliding window limits per endpoint category. Apply to all routes.
  Estimate: M (4h)
  Depends on: TASK-008 (Redis/Upstash connection setup)


tests.md
--------
TEST-PROP-011: Rate Limiting — Public Endpoints
  Tests: PROP-011
  Type: Integration
  Scenario: Send 61 sequential requests to GET /api/products within 60 seconds.
  Expected: First 60 return 200. Request 61 returns 429 with Retry-After header.

TEST-SEC-RATELIMIT: Rate Limiting — Auth Brute Force
  Tests: SEC-PROP-RATELIMIT, SEC-REQ-RATELIMIT
  Type: Security
  Scenario: Send 6 POST /auth/login requests with wrong password within 15 min.
  Expected: Requests 1–5 return 401. Request 6 returns 429. No account lockout
  side-effects on future valid login after window expires.
```

**Forward trace**: REQ-004 -> PROP-011 -> TASK-023 -> TEST-PROP-011
**Backward trace**: TEST-SEC-RATELIMIT -> SEC-PROP-RATELIMIT -> SEC-REQ-RATELIMIT -> (all three artifacts covered)

---

## 5. Security

### Core Principle

Security is embedded in the framework core. It is not a plugin, not an optional section, and not controlled by the formalism level. Every project that uses this framework — regardless of size, team, or maturity level — gets full security treatment.

### Security Files

The framework ships three security files under `aegis/framework/security/`:

| File                        | Purpose                                                                   |
|-----------------------------|---------------------------------------------------------------------------|
| SECURITY_UNIVERSAL.md       | Comprehensive security guidelines: race conditions, IDOR, input validation, uploads, SSRF, authentication, rate limiting, payments, logging, CSP, and the feature-ready checklist (§14). This file is the canonical security reference. |
| security-requirements.yaml  | Machine-readable catalog of SEC-REQ-* entries grouped by threat category. The requirements agent reads this to inject security requirements into requirements.md. |
| security-properties.yaml    | Machine-readable catalog of SEC-PROP-* entries. The design agent reads this to inject security properties into design.md. Each entry references its source SEC-REQ-* IDs. |

### Security Injection Moments

Security content is injected at three specific moments during artifact generation:

```
  [1] Requirements Generation
      |
      +--> Agent reads security-requirements.yaml
      +--> Appends SEC-REQ-* section to requirements.md
      +--> SEC-REQ-* entries are project-relevant (filtered by project type)
      |    but never empty — every project gets at least: IDOR, input
      |    validation, rate limiting, authentication, secrets management

  [2] Design Generation
      |
      +--> Agent reads security-properties.yaml
      +--> Appends SEC-PROP-* section to design.md
      +--> Each SEC-PROP derives from a SEC-REQ from step [1]
      +--> Bidirectional link is established at generation time

  [3] Tests Generation
      |
      +--> Agent scans all SEC-PROP-* entries in design.md
      +--> Generates TEST-SEC-* entry for each security property
      +--> Security tests are always a dedicated section in tests.md
      +--> Feature-ready checklist from SECURITY_UNIVERSAL §14 is
           referenced as the minimum verification bar for each feature
```

### Security Checklist Reference

Before any feature is declared production-ready, it must pass the checklist defined in `SECURITY_UNIVERSAL §14` (Checklist de Segurança por Feature). The tests.md template includes this checklist as a required section for every feature block.

The checklist covers seven categories: Input e dados, Autorização, Proteção, Dados, Upload (if applicable), URLs e recursos externos (if applicable), and Infraestrutura.

### What Cannot Be Disabled

- SEC-REQ-* sections in requirements.md
- SEC-PROP-* sections in design.md
- TEST-SEC-* sections in tests.md
- The security checklist reference in tests.md
- The injection of security content by agents

No configuration flag, command-line option, formalism level, or user prompt can suppress security content.

---

## 6. Validation

Validation runs at two moments with different scopes and outputs.

### Light Validation (After Each Generation)

Runs automatically after each artifact is generated. Fast. Produces pass/fail per check. Blocks advancement if critical checks fail.

#### After requirements.md is generated

| Check                              | Critical | Description                                                           |
|------------------------------------|----------|-----------------------------------------------------------------------|
| SEC-REQ section present            | Yes      | requirements.md must contain a SEC-REQ-* section                     |
| Minimum SEC-REQ entries            | Yes      | At least 5 SEC-REQ-* entries must be present                         |
| All REQ-NNN have acceptance criteria| No      | Standard and Formal levels require WHEN/SHALL/THEN syntax             |
| No duplicate IDs                   | Yes      | REQ-NNN IDs must be unique within the file                            |
| Glossary present                   | No       | Standard and Formal levels require a Glossary section                 |

#### After design.md is generated

| Check                                  | Critical | Description                                                         |
|----------------------------------------|----------|---------------------------------------------------------------------|
| SEC-PROP section present               | Yes      | design.md must contain a SEC-PROP-* section                        |
| Every SEC-PROP traces to a SEC-REQ     | Yes      | Each SEC-PROP must have a "Derives from: SEC-REQ-*" reference      |
| Every PROP traces to at least one REQ  | No       | Orphan properties (no requirement) are flagged as warnings          |
| No duplicate IDs                       | Yes      | PROP-NNN IDs must be unique                                         |
| Architecture section present           | No       | Standard and Formal levels require an Architecture section          |

#### After tasks.md is generated

| Check                                  | Critical | Description                                                         |
|----------------------------------------|----------|---------------------------------------------------------------------|
| Every TASK traces to a PROP or REQ     | Yes      | No task without "Implements:" reference                             |
| No duplicate IDs                       | Yes      | TASK-NNN IDs must be unique                                         |
| Estimates present                      | No       | Standard and Formal levels require estimates on all tasks           |
| Dependency order is acyclic            | Yes      | No circular dependencies in "Depends on:" chains                   |

#### After tests.md is generated

| Check                                  | Critical | Description                                                         |
|----------------------------------------|----------|---------------------------------------------------------------------|
| TEST-SEC section present               | Yes      | tests.md must contain a TEST-SEC-* section                         |
| Every TEST-SEC traces to a SEC-PROP    | Yes      | Each TEST-SEC must have a "Tests: SEC-PROP-*" reference            |
| Every PROP-NNN has at least one test   | No       | Untested properties are flagged as coverage gaps                    |
| Security checklist referenced          | Yes      | SECURITY_UNIVERSAL §14 checklist must appear in tests.md           |
| No duplicate IDs                       | Yes      | TEST-* IDs must be unique                                           |

### Full Validation (On Demand)

Triggered explicitly via `/aegis validate`. Runs all light checks plus four additional reports. May take longer as it performs cross-artifact analysis.

#### Coverage Matrix

A table showing every REQ-NNN and SEC-REQ-* row against columns for: PROP (has at least one property), TASK (has at least one task), TEST (has at least one test). Cells are marked Present, Missing, or Partial.

```
  Coverage Matrix (example)
  +--------------+-------+-------+-------+
  | ID           | PROP  | TASK  | TEST  |
  +--------------+-------+-------+-------+
  | REQ-001      |  yes  |  yes  |  yes  |
  | REQ-002      |  yes  |  yes  |   -   |  <- gap: untested
  | SEC-REQ-IDOR |  yes  |  yes  |  yes  |
  | SEC-REQ-CSRF |  yes  |   -   |  yes  |  <- gap: no task
  +--------------+-------+-------+-------+
```

#### Security Audit

Lists all SEC-REQ-* and SEC-PROP-* entries and their status across all artifacts. Flags any security requirement without a corresponding property, property without a test, or test without the checklist reference.

#### Gaps Report

A consolidated list of all gaps found during full validation: missing traces, missing tests, coverage holes, and formalism-level violations (e.g., a Standard project missing ADRs). Each gap includes the artifact, the ID, and a suggested fix.

#### Stats

Summary numbers for the project:
- Total REQ-NNN count, SEC-REQ-* count
- Total PROP-NNN count, SEC-PROP-* count
- Total TASK-NNN count, total estimated effort (if estimates present)
- Total TEST-* count, security test count
- Coverage percentage (requirements with full forward trace)
- Formalism level in use

---

## 7. Input Docs

The framework accepts input documents to generate requirements. These are project-specific files — written by humans, produced by other tools, or imported from clients — that describe what the project is supposed to do.

### Recommended Input Document Types

| Type           | Typical Filename          | Contains                                                                 |
|----------------|---------------------------|--------------------------------------------------------------------------|
| product-spec   | PROJECT_SPEC.md           | Product vision, user personas, feature list, user journeys, pricing      |
| brand-guide    | BRAND.md                  | Visual identity, tone of voice, naming conventions, do/don't rules       |
| business-plan  | PLANO_DE_NEGOCIO.md       | Market context, competitive landscape, revenue model, success metrics    |
| security       | SECURITY_UNIVERSAL.md     | Security guidelines, threat model, compliance requirements               |
| api-docs       | api-spec.yaml / api.md    | External API contracts, webhook schemas, third-party integration details |
| auto           | (any file in .aegis/inputs/) | Automatically detected and classified by the requirements agent          |

### Input Document Handling

- Input documents are never modified by the framework.
- They are read-only references used during requirements generation.
- They must be listed in `.aegis/config.yaml` under the `inputs` key, or placed in `.aegis/inputs/` for auto-detection.
- The requirements agent extracts relevant information and cites the source document in the generated requirement where applicable.
- Multiple input documents of the same type are merged by the agent. Conflicts between documents are flagged as warnings during requirements generation, not errors.

### Input Templates

The framework ships starter templates for common input document types in `aegis/framework/inputs/templates/`. Projects that do not have an existing spec can use these templates as a starting point.

---

## 8. Configuration

Projects configure the Aegis framework via a `.aegis/config.yaml` file at the project root.

### File Location

```
<project-root>/
  .aegis/                <-- all Aegis project files live here
    config.yaml          <-- framework configuration
    requirements.md
    design.md
    tasks.md
    tests.md
    tests/               <-- RED test files
    reports/             <-- validation reports
```

### Schema

```yaml
# .aegis/config.yaml
version: "1"

project:
  name: "My Project"          # display name, used in artifact headers
  language: "en"              # document language: "en" or "pt-BR"

formalism: standard           # light | standard | formal

inputs:
  - path: docs/PROJECT_SPEC.md
    type: product-spec
  - path: docs/BRAND.md
    type: brand-guide
  - path: docs/SECURITY_UNIVERSAL.md
    type: security
  # "auto" entries: any file in ..aegis/inputs/ is auto-detected
  - path: ..aegis/inputs/
    type: auto

output:
  dir: .aegis/                   # where artifacts are written (default: .aegis/)

# Optional overrides — advanced use only
# security:
#   extra_requirements: []    # add project-specific SEC-REQ entries
#   extra_properties: []      # add project-specific SEC-PROP entries
```

### Configuration Rules

- `formalism` defaults to `standard` if not set.
- `language` defaults to `en` if not set.
- `inputs` must list at least one file or directory. If the list is empty, the requirements agent will warn and proceed with security-only content.
- The `output.dir` setting cannot be set to the project root (`.` or `/`) to prevent artifacts from polluting the root directory.
- Security configuration under the optional `security` key can only add entries — it cannot remove or suppress any built-in security requirements or properties.

---

## 9. Change Propagation

The Aegis framework uses a manual propagation model. When a source artifact changes, downstream artifacts are marked as "needs review" rather than automatically regenerated. This prevents silent overwrites of hand-edited content.

### Propagation Rules

| Changed Artifact  | Marks as "needs review"                          |
|-------------------|--------------------------------------------------|
| requirements.md   | design.md, tasks.md, tests.md                    |
| design.md         | tasks.md, tests.md                               |
| tasks.md          | (none — tasks.md is a leaf artifact)             |
| tests.md          | (none — tests.md is a leaf artifact)             |

### How "Needs Review" Works

When the `/aegis update` command detects that an artifact has changed, it writes a review notice to the top of each downstream artifact:

```
> NEEDS REVIEW — requirements.md was updated on 2026-04-04.
> Re-run `/aegis design`, `/aegis tasks`, and `/aegis tests` to propagate changes,
> or manually review and update this artifact to reflect the new requirements.
> Remove this notice when the review is complete.
```

### What Does Not Auto-Propagate

- Changes to requirements do not automatically regenerate design. The designer must review the change, decide whether existing properties still hold, and either re-run `/aegis design` or manually update `design.md`.
- Regeneration overwrites the existing artifact by default. Use `--merge` to run the agent in merge mode, which adds new content and flags conflicts rather than overwriting.
- Security content is always re-injected on regeneration. Security sections from a previous generation are never preserved verbatim — they are replaced with the current output of the security agent.

### Propagation Scenarios

**Scenario 1 — New requirement added**: A new REQ-NNN is added to requirements.md. The `/aegis update` command marks design.md, tasks.md, and tests.md as "needs review". The developer runs `/aegis design --merge` to add a PROP-NNN for the new requirement without overwriting existing properties.

**Scenario 2 — Requirement changed**: REQ-003's acceptance criteria are tightened. The dependent PROP-007 in design.md may or may not need changes. The developer reviews PROP-007, updates it if needed, and removes the "needs review" notice. tasks.md and tests.md are still marked until the developer confirms they are consistent.

**Scenario 3 — Security requirement added**: A new SEC-REQ-* is added (e.g., because SECURITY_UNIVERSAL.md was updated with a new threat category). Running `/aegis requirements --security-refresh` re-injects all SEC-REQ-* entries and marks design.md and tests.md as "needs review" for the security sections.

**Scenario 4 — Full regeneration**: The developer runs `/aegis requirements && /aegis design && /aegis tasks && /aegis tests` in sequence. All artifacts are regenerated from scratch. This is appropriate when input documents have changed significantly. Hand-edited content will be lost unless `--merge` is used.

---

## Appendix A: File Layout Reference

```
<project-root>/
  .aegis/
    config.yaml
    requirements.md
    design.md
    tasks.md
    tests.md
    tests/                    <-- RED test files
    reports/                  <-- validation reports

aegis/                        (framework installation, not per-project)
  framework/
    SPEC.md                   <- this file
    levels/
      light.yaml              <- Light level rules
      standard.yaml           <- Standard level rules
      formal.yaml             <- Formal level rules
    templates/
      requirements/
        base.md               <- requirements.md template (all levels)
      design/
        base.md               <- design.md template (all levels)
      tasks/
        base.md               <- tasks.md template (all levels)
      tests/
        base.md               <- tests.md template (all levels)
    inputs/
      templates/
        product-spec.md       <- starter template for product specs
        brand-guide.md        <- starter template for brand guides
        business-plan.md      <- starter template for business plans
    security/
      SECURITY_UNIVERSAL.md   <- canonical security guidelines (§14 = checklist)
      security-requirements.yaml
      security-properties.yaml
    validation/
      rules.yaml              <- validation rule definitions
    i18n/
      en.yaml                 <- English strings
      pt-BR.yaml              <- Portuguese (Brazil) strings
  commands/
    init.md                   <- /aegis init command spec
    requirements.md           <- /aegis requirements command spec
    design.md                 <- /aegis design command spec
    tasks.md                  <- /aegis tasks command spec
    tests.md                  <- /aegis tests command spec
    validate.md               <- /aegis validate command spec
    update.md                 <- /aegis update command spec
    status.md                 <- /aegis status command spec
  agents/
    requirements-agent.md     <- requirements generation agent
    design-agent.md           <- design generation agent
    tasks-agent.md            <- tasks generation agent
    tests-agent.md            <- tests generation agent
    validation-agent.md       <- validation agent
```

---

## Appendix B: Glossary

| Term               | Definition                                                                                       |
|--------------------|--------------------------------------------------------------------------------------------------|
| Artifact           | One of the four Aegis documents: requirements.md, design.md, tasks.md, tests.md                  |
| Forward trace      | A chain of references from a requirement forward through property, task, and test               |
| Backward trace     | A chain of references from a test backward to the property and requirement it validates         |
| Formalism level    | A setting (light/standard/formal) that controls the depth of non-security artifact content      |
| Injection moment   | One of three points in the generation pipeline where security content is added to an artifact   |
| SEC-REQ-*          | A security requirement, always present in requirements.md, named by threat or control           |
| SEC-PROP-*         | A security design property, always present in design.md, derived from SEC-REQ-* entries        |
| TEST-SEC-*         | A security test, always present in tests.md, verifying a SEC-PROP-* entry                      |
| Needs review       | A notice written to an artifact indicating its source has changed and it must be re-validated   |
| Coverage Matrix    | A cross-artifact table showing which requirements have corresponding properties, tasks, tests   |
| Input doc          | A project-specific document (spec, brief, plan) read by the requirements agent                  |
| Auto-detection     | Classification of input docs by file path, extension, and content patterns                      |

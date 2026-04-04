# SDD Framework — Design Specification

## 1. Overview

The SDD (Software Design Documents) Framework is a two-layer system for generating and maintaining structured software documentation from project input docs.

**Layer 1 — Framework (tool-agnostic):** A standalone specification defining templates, conventions, traceability rules, and validation — usable with any LLM, tool, or manually.

**Layer 2 — Skill (Claude Code):** Automation that implements the framework — interactive artifact generation, consistency validation, gap detection, security injection, and change propagation.

### Core Principles

- **Sequential with iteration:** requirements → design → tasks → tests, with backtracking when gaps are found
- **Adaptable formalism:** three levels (light, standard, formal) chosen per project
- **Correctness Properties always required:** the bridge between spec and tests, at every level
- **Security is hard, always:** universal security baseline is injected at full rigor regardless of formalism level. Light formalism means less verbose docs, NEVER less secure code. A "light" project gets the same SEC-REQs, SEC-PROPs, and security tests as a "formal" one.
- **Bidirectional traceability:** every node traces up (why it exists) and down (how it's implemented/tested)
- **Configurable language:** framework in English, generated artifacts in user's chosen language (pt-br, en)
- **Stack-agnostic templates:** the skill extracts the stack from the user and fills in the details

---

## 2. The 4 Artifacts

### 2.1 `requirements.md` — WHAT the system must do

**Derived from:** Input docs (product spec, brand, business plan, etc.) + SECURITY_UNIVERSAL
**Purpose:** Captures all functional and non-functional behavior.

**Structure (formal level — others are subsets):**

```markdown
# Requirements — [Project Name]

## Introduction
[1-paragraph system description derived from input docs]

## Glossary
[Domain-specific terms with precise definitions.
 Every term used in acceptance criteria MUST be defined here.]

## Requirements

### REQ-001: [Descriptive title]
**User Story:** As [actor], I want [action], so that [benefit].
**Derives from:** INPUT:product-spec §[section]

#### Acceptance Criteria
1. WHEN [condition], THE [component] SHALL [behavior].
2. IF [condition], THEN THE [component] SHALL [behavior].
...

## Security Requirements (auto-generated)

### SEC-REQ-INPUT-01: Schema validation on all endpoints
...
```

**Rules:**
- Each requirement has a unique ID (`REQ-NNN`)
- Each requirement traces its origin (`Derives from: INPUT:...`)
- Security requirements are auto-injected from SECURITY_UNIVERSAL based on project characteristics
- Light level: no glossary, no SHALL/WHEN — feature list + brief description
- Standard level: user stories + acceptance criteria
- Formal level: glossary + SHALL/WHEN/IF + numbered criteria

### 2.2 `design.md` — HOW the system will be built

**Derived from:** `requirements.md` + stack decisions
**Purpose:** Architecture, interfaces, data models, and correctness properties.

**Structure (formal level):**

```markdown
# Technical Design — [Project Name]

## Overview
[Technical summary: what the system does, chosen stack, main flow]

## Architecture
[High-level diagram — Mermaid or textual description]
[Application layers — directory structure]

## Components and Interfaces
### [Component name]
- Responsibility
- Interface (input/output types)
- Dependencies
- Refs: Implements REQ-NNN

## Data Models
[Database schema — in the project's ORM/language]
[Main types/interfaces]

## Correctness Properties
### PROP-001: [Property name]
[Formal property statement — "For any X..."]
**Validates:** REQ-NNN, REQ-MMM

### SEC-PROP-IDOR: Resource ownership verification
[Auto-injected from security-properties.yaml]
**Validates:** SEC-REQ-IDOR-01

## Error Handling
[General strategy + specific cases]
```

**Rules:**
- Each component references the requirements it implements
- Each Property references the requirements it validates
- Properties are mandatory at all levels (quantity varies)
- Security properties are auto-injected based on project characteristics
- Light level: overview + stack + data models + 1-3 properties
- Standard level: + components + architecture diagram
- Formal level: + detailed interfaces + error handling + Mermaid diagrams

### 2.3 `tasks.md` — WHEN and IN WHAT ORDER to build

**Derived from:** `design.md` + `requirements.md`
**Purpose:** Ordered implementation plan.

**Structure (formal level):**

```markdown
# Implementation Plan — [Project Name]

## Overview
[Stack, general approach, mandatory notes]

## Tasks

- [ ] TASK-001: [Title]
  [Description of what to implement]
  - [ ] TASK-001.1: [Subtask]
  - [ ] TASK-001.2: [Subtask]
  Implements: REQ-001, REQ-002
  Tests: PROP-001

- [ ] TASK-NNN: Checkpoint — [description]
  [Verification that everything up to here works]
```

**Rules:**
- Each task references requirements it implements (`Implements: REQ-NNN`)
- Each task references properties it tests (`Tests: PROP-NNN`)
- Subtasks use notation `TASK-NNN.N`
- Checkpoints between logical blocks
- Light level: simple checklist with req refs
- Standard level: + subtasks + property refs
- Formal level: + checkpoints + tests per subtask

### 2.4 `tests.md` — TDD layer (RED before implementation)

**Derived from:** `requirements.md` + `design.md` (properties + interfaces)
**Purpose:** Test specification + actual RED test files.

**Structure:**

```markdown
# Test Specification — [Project Name]

## Test Strategy
Stack: [test framework, e.g., Vitest + fast-check]
Coverage approach: [property-based + e2e + integration + unit]

## Pre-Implementation Tests (RED)

### Property-Based Tests
#### TEST-PROP-001: [Name] → PROP-001
Type: property-based
Description: [What to test — derived from property]
Validates: REQ-NNN, REQ-MMM
Generator: [Random input description]
Assertion: [What must hold for all inputs]

### E2E Tests
#### TEST-E2E-001: [Flow name]
Type: e2e
Description: [End-to-end scenario derived from user story]
Validates: REQ-NNN
Steps: [Test steps]
Expected: [Expected result]

### Integration / Contract Tests
#### TEST-INT-001: [Interface name]
Type: integration
Description: [API/interface contract test]
Validates: REQ-NNN
Endpoint/Interface: [Which]
Input: [Test payload]
Expected: [Expected response]

## Per-Task Tests (generated during implementation)
- TASK-003: [expected unit test description]
- TASK-005: [expected unit test description]
```

**Rules:**
- Every pre-implementation test traces to a Property or Requirement
- The skill generates actual test files (stack-specific) from this spec
- Pre-implementation tests: property-based, e2e, integration, contract — all RED
- Per-task tests: unit tests generated alongside each task during implementation
- Test sources by derivation:

| Source | Test type generated |
|--------|-------------------|
| Correctness Properties | Property-based / invariant tests |
| Requirements (acceptance criteria) | E2E / integration tests |
| Design (interfaces/APIs) | Contract / API tests |
| Tasks (specific subtasks) | Unit tests (during implementation) |

---

## 3. Formalism Levels

| Aspect | Light | Standard | Formal |
|--------|-------|----------|--------|
| **When to use** | Scripts, simple tools, POCs | SaaS, apps, mid-size APIs | Critical systems, fintech, healthcare |
| **Requirements** | Feature list + brief description | User stories + acceptance criteria | SHALL/WHEN/IF + glossary + numbered criteria |
| **Design** | Stack + high-level diagram + basic data models | Architecture + interfaces + data models + components | All of standard + detailed Properties + Mermaid diagrams + error handling |
| **Tasks** | Simple checklist with req refs | Tasks with subtasks + req refs + property refs | Tasks with subtasks + cross refs + property-linked tests + checkpoints |
| **Correctness Properties** | 1-3 essential properties (main invariants) | Properties per functional area | Exhaustive properties with req refs |
| **Tests** | Basic e2e + 1-3 property tests | E2e + property + integration tests | Exhaustive: property + e2e + integration + contract tests |
| **Security** | **FULL — same as formal** | **FULL — same as formal** | **FULL** |

> **Security is level-independent.** The formalism level controls documentation verbosity (how requirements are written, how much detail in diagrams, how many non-security properties). It NEVER reduces security coverage. A "light" project receives the exact same SEC-REQs, SEC-PROPs, security tests, and security checklist validation as a "formal" one. Less docs does not mean less security.

---

## 4. Traceability and ID Conventions

### ID Format

```
Requirements:   REQ-001, REQ-002, ...
Security Reqs:  SEC-REQ-INPUT-01, SEC-REQ-IDOR-01, ...
Properties:     PROP-001, PROP-002, ...
Security Props: SEC-PROP-IDOR, SEC-PROP-UPLOAD, ...
Tasks:          TASK-001, TASK-002, ...
Subtasks:       TASK-001.1, TASK-001.2, ...
Tests:          TEST-PROP-001, TEST-E2E-001, TEST-INT-001, ...
Input docs:     INPUT:product-spec, INPUT:brand-guide, ...
```

### Cross-references (in any artifact)

```
"Validates: REQ-007, REQ-012"
"Derives from: INPUT:product-spec §2.1"
"Tests: PROP-003"
"Implements: REQ-005"
```

### Bidirectional Trace

```
INPUT:product-spec §2.1
    ↓ derives
REQ-005: Upload photo
    ↓ implements
DESIGN: UploadHandler component
    ↓ validates
PROP-003: Upload rejects invalid files
    ↓ implements
TASK-005: Implement upload
    ↓ tests
TEST-PROP-003: Property-based upload test
TEST-E2E-002: E2E upload flow test
```

---

## 5. Embedded Security (SECURITY_UNIVERSAL)

### Position in Framework

Security is a core layer, not an optional input. The `SECURITY_UNIVERSAL.md` is embedded in the framework and injected automatically at three moments:

1. **Requirements generation** — injects SEC-REQs based on project characteristics
2. **Design generation** — injects SEC-PROPs and security-aligned error handling
3. **Tests generation** — generates security tests (rate limit 429, upload magic bytes, IDOR 404, etc.)

### Injection Flow

```
/sdd requirements
    ├── Reads user input docs
    ├── Detects project characteristics:
    │   has_file_upload? has_authentication? has_public_endpoints?
    │   has_write_operations? has_personal_data? has_payments?
    ├── Filters security-requirements.yaml by applies_when ONLY
    │   (security is NOT filtered by formalism level — always full rigor)
    ├── Injects ALL matching SEC-REQs into requirements.md
    └── If user has project SECURITY.md:
        ├── Merges: user rules ADD to baseline
        └── Never reduces — baseline requirements persist
```

### `security-requirements.yaml`

Pre-defined security requirements organized by category:

```yaml
# NOTE: Security requirements have NO level field.
# They are injected at full rigor regardless of the project's
# formalism level (light/standard/formal). The formalism level
# controls documentation verbosity, NEVER security coverage.
# The only filter is applies_when (project characteristics).

categories:
  - id: input-validation
    applies_when: always
    requirements:
      - id: SEC-REQ-INPUT-01
        title: Schema validation on all endpoints

  - id: idor
    applies_when: has_authenticated_resources
    requirements:
      - id: SEC-REQ-IDOR-01
        title: Ownership check on every endpoint with ID

  - id: upload
    applies_when: has_file_upload
    requirements:
      - id: SEC-REQ-UPLOAD-01
        title: Upload validation by magic bytes

  - id: rate-limiting
    applies_when: has_public_endpoints
    requirements:
      - id: SEC-REQ-RATE-01
        title: Rate limiting on public endpoints

  - id: race-conditions
    applies_when: has_write_operations
    requirements:
      - id: SEC-REQ-RACE-01
        title: Transactions for critical write operations

  - id: auth
    applies_when: has_authentication
    requirements:
      - id: SEC-REQ-AUTH-01
        title: Rate limit on login

  - id: headers
    applies_when: always
    requirements:
      - id: SEC-REQ-HEADERS-01
        title: Security headers on all responses

  - id: data-privacy
    applies_when: has_personal_data
    requirements:
      - id: SEC-REQ-PRIVACY-01
        title: Sensitive data never in logs

  - id: honeypots
    applies_when: has_public_endpoints
    requirements:
      - id: SEC-REQ-HONEYPOT-01
        title: Honeypot fields in public forms

  - id: urls
    applies_when: has_external_urls
    requirements:
      - id: SEC-REQ-URL-01
        title: URL allowlist for external resources

  - id: business-timing
    applies_when: has_payments
    requirements:
      - id: SEC-REQ-TIMING-01
        title: Action only after payment confirmation

  - id: dependencies
    applies_when: always
    requirements:
      - id: SEC-REQ-DEPS-01
        title: Dependency audit and lockfile
```

### `security-properties.yaml`

Pre-defined correctness properties:

```yaml
properties:
  - id: SEC-PROP-IDOR
    name: Resource ownership verification
    statement: >
      For any pair (resourceId, userId) where userId is not the owner,
      any endpoint receiving that resourceId SHALL return HTTP 404
      without revealing the resource's existence.
    validates: SEC-REQ-IDOR-01
    applies_when: has_authenticated_resources

  - id: SEC-PROP-UPLOAD
    name: Upload rejects invalid files
    statement: >
      For any file buffer whose magic bytes do not match allowed types,
      or whose size exceeds the limit, or whose dimensions exceed the
      maximum, the system SHALL return HTTP 400 and never store the file.
    validates: SEC-REQ-UPLOAD-01
    applies_when: has_file_upload

  - id: SEC-PROP-RATE
    name: Rate limiting enforced
    statement: >
      For any rate-limited endpoint and any IP, when requests exceed
      the window limit, all excess requests SHALL return HTTP 429
      with Retry-After header > 0.
    validates: SEC-REQ-RATE-01
    applies_when: has_public_endpoints

  - id: SEC-PROP-RACE
    name: Idempotent critical operations
    statement: >
      For any critical write operation, processing the same request
      N times (N >= 1) SHALL result in the same final state as
      processing it once.
    validates: SEC-REQ-RACE-01
    applies_when: has_write_operations

  - id: SEC-PROP-AUTH
    name: Login rate limiting
    statement: >
      For any IP or email, after 5 failed login attempts within
      15 minutes, subsequent attempts SHALL be rejected.
    validates: SEC-REQ-AUTH-01
    applies_when: has_authentication

  - id: SEC-PROP-PRIVACY
    name: No sensitive data in logs
    statement: >
      For any log entry produced by the system, the entry SHALL NOT
      contain passwords, tokens, credit card data, or complete
      personal data.
    validates: SEC-REQ-PRIVACY-01
    applies_when: has_personal_data
```

### Merge with User's SECURITY.md

```
SECURITY_UNIVERSAL (baseline)
    + project SECURITY.md (user additions)
    = Effective rules

Rules:
- User CAN ADD new categories (e.g., specific compliance)
- User CAN INCREASE rigor (e.g., stricter rate limits)
- User CANNOT REMOVE baseline rules
- User CAN mark rules as N/A with justification
  (e.g., "SEC-REQ-UPLOAD-01: N/A — project has no uploads")
```

### Security Checklist (used by /sdd validate)

The checklist from SECURITY_UNIVERSAL §14 is used as verification criteria:

- Input & data: schema validation, HTML sanitization, no interpolation
- Authorization: IDOR verified, permissions checked backend-side
- Protection: rate limiting, CSRF, transactions for critical writes
- Data: no sensitive data in responses/logs, temp data cleaned
- Upload: magic bytes, size limit, UUID rename, EXIF strip
- URLs: allowlist, no SSRF, validated redirects
- Infrastructure: security headers, restrictive CORS, secrets in env vars

---

## 6. Validation System

### Light Validation (automatic after each generation)

Runs after each artifact generation. Checks critical errors only:

| After generating | Checks |
|-----------------|--------|
| `requirements.md` | Every input doc has >= 1 derived REQ. Security requirements injected. |
| `design.md` | Every REQ has >= 1 component. Every PROP references existing REQs. Security properties present. |
| `tasks.md` | Every TASK references >= 1 REQ. Every REQ has >= 1 TASK. |
| `tests.md` | Every PROP has >= 1 test. Every critical REQ has coverage. Security tests present. |

Reports gaps inline and asks user if they want to fix before proceeding.

### Full Validation (`/sdd validate`)

Generates a complete report with 4 sections:

**1. Coverage Matrix:**
```
| REQ | Component | Property | Task | Test |
|-----|-----------|----------|------|------|
| REQ-001 | OrderService | PROP-001 | TASK-003 | TEST-PROP-001 |
| REQ-007 | — | — | — | — |  ⚠️ UNCOVERED
```

**2. Security Audit:**
```
- ✅ Race conditions: PROP-001, TASK-007
- ✅ IDOR: PROP-004, TEST-PROP-004
- ⚠️ Rate limiting: REQ-010 exists, but TASK missing rate limit on /api/foo
- ✅ Headers: REQ-010.6, TASK-001
```

**3. Gaps:** List of inconsistencies (REQ without TASK, PROP without test, broken reference)

**4. Stats:** Coverage percentage per artifact

### Change Propagation (`/sdd update`)

When a user updates an artifact:

```
update requirements → marks design, tasks, tests as "needs review"
update design       → marks tasks, tests as "needs review"
update tasks        → marks tests as "needs review"
```

The skill does NOT auto-propagate. It:
1. Diffs what changed (REQs added/removed/altered)
2. Identifies impacted downstream artifacts
3. Shows impact: "REQ-005 was altered. Impact: PROP-003, TASK-005, TEST-PROP-003 need review."
4. Asks if user wants to regenerate each one

---

## 7. Input Docs

### Recommended Types

| Type | Description | Template provided |
|------|-------------|-------------------|
| `product-spec` | Product specification — features, user flows, pricing | Yes |
| `brand-guide` | Brand identity — colors, typography, tone of voice | Yes |
| `business-plan` | Business plan — market, metrics, strategy, phases | Yes |
| `security` | Project-specific security guidelines (merged with SECURITY_UNIVERSAL — see §5) | Yes |
| `api-docs` | External API documentation | No |
| `auto` | Unclassified — skill auto-classifies | N/A |

### Auto-Classification

The skill reads unclassified docs and classifies based on content analysis:
- Contains color palettes, typography, tone of voice → `brand-guide`
- Contains user flows, pricing, product features → `product-spec`
- Contains market analysis, revenue projections → `business-plan`
- Contains security rules, OWASP, headers → `security`
- If uncertain → asks the user

---

## 8. Project Output Structure

### Generated in User's Project

```
project-root/
├── sdd.config.yaml              # SDD configuration
├── docs/
│   └── sdd/
│       ├── requirements.md      # Artifact 1
│       ├── design.md            # Artifact 2
│       ├── tasks.md             # Artifact 3
│       ├── tests.md             # Artifact 4 (spec)
│       └── reports/
│           └── validation-*.md  # /sdd validate reports
├── tests/                       # RED test files (stack-specific)
│   ├── properties/              # Property-based tests
│   ├── e2e/                     # E2E tests
│   └── integration/             # Integration/contract tests
└── (rest of project)
```

### `sdd.config.yaml`

```yaml
version: "1.0"

project:
  name: "My Project"
  description: "Brief description"

level: standard  # light | standard | formal
language: pt-br  # pt-br | en

stack:
  language: typescript
  runtime: node
  framework: next-16
  orm: prisma
  database: postgresql
  test_framework: vitest
  property_testing: fast-check
  auth: supabase
  storage: supabase

inputs:
  - path: docs/PROJECT_SPEC.md
    type: product-spec
  - path: docs/BRAND.md
    type: brand-guide
  - path: docs/SECURITY.md
    type: security
  - path: docs/PLANO.md
    type: auto

paths:
  output: docs/sdd
  tests: tests
  reports: docs/sdd/reports

security:
  features:
    has_authentication: true
    has_file_upload: true
    has_public_endpoints: true
    has_write_operations: true
    has_personal_data: true
    has_payments: true
  overrides: []
  project_security: docs/SECURITY.md
```

### Stack Auto-Detection

| File found | Inference |
|---|---|
| `package.json` | Node.js. Reads dependencies for framework (next, express, etc.) |
| `tsconfig.json` | TypeScript |
| `requirements.txt` / `pyproject.toml` | Python. Reads for framework (django, fastapi, flask) |
| `go.mod` | Go |
| `Cargo.toml` | Rust |
| `pom.xml` / `build.gradle` | Java. Reads for framework (spring-boot, quarkus, etc.) |
| `composer.json` | PHP. Reads for framework (laravel, symfony, etc.) |
| `index.html` (no framework) | HTML/CSS/JS vanilla |
| `prisma/schema.prisma` | Prisma ORM |
| `docker-compose.yml` | Detects services (postgres, redis, etc.) |
| `.env` / `.env.example` | Reads var names to infer integrations |

The skill presents what it detected and asks for confirmation before saving config.

---

## 9. Skill Architecture (Claude Code)

### Skill Directory Structure

```
sdd/
├── skill.md                         # Entry point — command router
├── commands/
│   ├── init.md                      # /sdd init
│   ├── requirements.md              # /sdd requirements
│   ├── design.md                    # /sdd design
│   ├── tasks.md                     # /sdd tasks
│   ├── tests.md                     # /sdd tests
│   ├── validate.md                  # /sdd validate
│   ├── update.md                    # /sdd update [artifact]
│   └── status.md                    # /sdd status
├── framework/
│   ├── SPEC.md
│   ├── levels/
│   ├── templates/
│   ├── inputs/
│   ├── security/
│   ├── validation/
│   └── i18n/
└── agents/
    ├── requirements-agent.md
    ├── design-agent.md
    ├── tasks-agent.md
    ├── tests-agent.md
    └── validation-agent.md
```

### Command Routing

```
/sdd              → help (list commands)
/sdd init         → commands/init.md
/sdd requirements → commands/requirements.md
/sdd design       → commands/design.md
/sdd tasks        → commands/tasks.md
/sdd tests        → commands/tests.md
/sdd validate     → commands/validate.md
/sdd update REQ   → commands/update.md (arg: "requirements")
/sdd status       → commands/status.md
```

### Agent Architecture

Each heavy command dispatches to a subagent for the actual generation:

```
commands/requirements.md (orchestrator)
    │
    ├── 1. Reads sdd.config.yaml
    ├── 2. Reads input docs
    ├── 3. Asks interactive questions to user
    ├── 4. Prepares complete context
    │
    └── 5. Dispatches to agents/requirements-agent.md
            │
            ├── Receives: context + answers + template + security reqs
            ├── Generates: requirements.md
            ├── Runs: light validation
            └── Returns: artifact + validation result
```

### `/sdd status` Output

```
SDD Status — My Project
Level: standard | Language: pt-br

Artifacts:
  ✅ requirements.md  (16 REQs + 8 SEC-REQs, last updated 2026-04-03)
  ✅ design.md         (12 components, 10 PROPs, last updated 2026-04-03)
  ⚠️  tasks.md          (needs review — REQ-012 added since last generation)
  ❌ tests.md          (not generated yet)

Coverage: 87% (see /sdd validate for details)
Next step: /sdd tasks (update) → /sdd tests (generate)
```

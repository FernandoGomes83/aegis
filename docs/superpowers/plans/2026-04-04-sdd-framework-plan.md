# SDD Framework — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a two-layer SDD (Software Design Documents) framework — a standalone tool-agnostic specification + a Claude Code skill that automates it.

**Architecture:** Layer 1 is the framework: markdown templates, YAML configs, and a formal SPEC.md that define how to produce 4 artifacts (requirements, design, tasks, tests) at 3 formalism levels with embedded security. Layer 2 is a Claude Code skill with 8 commands and 5 subagents that implement the framework interactively. The skill lives as a plugin under the user's Claude Code plugins directory.

**Tech Stack:** Markdown (skill files, templates, framework docs), YAML (config, security rules, validation rules, i18n)

**Spec:** `docs/superpowers/specs/2026-04-04-sdd-framework-design.md`

**Install target:** `~/.claude/plugins/sdd/` (Claude Code plugin directory)

---

## Phase 1: Framework Foundation

### Task 1: Directory structure and SPEC.md

**Files:**
- Create: `sdd/framework/SPEC.md`

- [ ] **Step 1: Create full directory structure**

```bash
mkdir -p sdd/{commands,framework/{levels,templates/{requirements,design,tasks,tests},inputs/templates,security,validation,i18n},agents}
```

- [ ] **Step 2: Write SPEC.md**

This is the heart of the framework. Create `sdd/framework/SPEC.md` with the following content:

```markdown
# SDD Framework Specification v1.0

## 1. Purpose

The SDD Framework defines a structured process for producing software design
documentation from project input docs. It generates 4 artifacts in sequence:
requirements, design, tasks, and tests — with bidirectional traceability
and embedded security at every level.

## 2. Artifacts

The framework produces 4 artifacts, each derived from the previous:

| # | Artifact | Answers | Derived from |
|---|----------|---------|-------------|
| 1 | `requirements.md` | WHAT the system must do | Input docs + SECURITY_UNIVERSAL |
| 2 | `design.md` | HOW it will be built | requirements.md + stack decisions |
| 3 | `tasks.md` | WHEN and IN WHAT ORDER to build | design.md + requirements.md |
| 4 | `tests.md` | HOW to verify it works (TDD RED) | requirements.md + design.md |

### Generation Flow

```
Input docs → requirements.md → design.md → tasks.md → tests.md
                 ↑                                        |
                 └──── iteration (backtracking) ──────────┘
```

Artifacts are generated sequentially. At any point, the process can
backtrack to update a previous artifact when a gap is discovered.
Changes propagate downstream — updating requirements marks design,
tasks, and tests as "needs review".

## 3. Formalism Levels

Each project chooses one of three levels. The level controls documentation
verbosity and detail — it NEVER affects security coverage.

### Light
- **When:** Scripts, simple tools, POCs
- **Requirements:** Feature list + brief description
- **Design:** Stack + high-level diagram + basic data models + 1-3 properties
- **Tasks:** Simple checklist with req refs
- **Tests:** Basic e2e + 1-3 property tests
- **Security:** FULL (same as formal)

### Standard
- **When:** SaaS, apps, mid-size APIs
- **Requirements:** User stories + acceptance criteria
- **Design:** Architecture + interfaces + data models + components + properties per area
- **Tasks:** Tasks with subtasks + req refs + property refs
- **Tests:** E2E + property + integration tests
- **Security:** FULL (same as formal)

### Formal
- **When:** Critical systems, fintech, healthcare
- **Requirements:** SHALL/WHEN/IF + glossary + numbered criteria
- **Design:** All of standard + detailed Properties + Mermaid diagrams + error handling
- **Tasks:** Tasks with subtasks + cross refs + property-linked tests + checkpoints
- **Tests:** Exhaustive: property + e2e + integration + contract tests
- **Security:** FULL

## 4. ID Conventions and Traceability

### ID Formats
- Requirements: `REQ-001`, `REQ-002`, ...
- Security Requirements: `SEC-REQ-INPUT-01`, `SEC-REQ-IDOR-01`, ...
- Properties: `PROP-001`, `PROP-002`, ...
- Security Properties: `SEC-PROP-IDOR`, `SEC-PROP-UPLOAD`, ...
- Tasks: `TASK-001`, `TASK-002`, ...
- Subtasks: `TASK-001.1`, `TASK-001.2`, ...
- Tests: `TEST-PROP-001`, `TEST-E2E-001`, `TEST-INT-001`, ...
- Input docs: `INPUT:product-spec`, `INPUT:brand-guide`, ...

### Cross-Reference Syntax
Use these labels in any artifact to reference another:
- `Derives from: INPUT:product-spec §2.1`
- `Implements: REQ-005`
- `Validates: REQ-007, REQ-012`
- `Tests: PROP-003`

### Bidirectional Trace
Every node can be traced up (why it exists) and down (how it is
implemented/tested):

```
INPUT:product-spec §2.1
    ↓ derives
REQ-005
    ↓ implements
DESIGN: Component
    ↓ validates
PROP-003
    ↓ implements
TASK-005
    ↓ tests
TEST-PROP-003
```

## 5. Security

Security is embedded in the framework core. It is NOT optional and NOT
controlled by the formalism level.

- `security/SECURITY_UNIVERSAL.md` — full security guidelines (read-only)
- `security/security-requirements.yaml` — pre-defined SEC-REQs, filtered by `applies_when` only
- `security/security-properties.yaml` — pre-defined SEC-PROPs, filtered by `applies_when` only

Security is injected at 3 moments:
1. Requirements generation — SEC-REQs added to requirements.md
2. Design generation — SEC-PROPs added to design.md
3. Tests generation — security tests added to tests.md

The security checklist from SECURITY_UNIVERSAL §14 is used by validation.

## 6. Validation

### Light Validation (after each generation)
- requirements.md: every input doc has >= 1 REQ, SEC-REQs injected
- design.md: every REQ has >= 1 component, every PROP refs valid REQs, SEC-PROPs present
- tasks.md: every TASK refs >= 1 REQ, every REQ has >= 1 TASK
- tests.md: every PROP has >= 1 test, critical REQs covered, security tests present

### Full Validation (on demand)
Produces a report with: Coverage Matrix, Security Audit, Gaps, Stats.

## 7. Input Docs

### Recommended Types
- `product-spec` — features, user flows, pricing
- `brand-guide` — colors, typography, tone of voice
- `business-plan` — market, metrics, strategy
- `security` — project-specific (merged with SECURITY_UNIVERSAL)
- `api-docs` — external API documentation
- `auto` — unclassified, auto-detected

## 8. Configuration

Projects using the framework store settings in `sdd.config.yaml` at the
project root. See templates/sdd.config.template.yaml for the full schema.

## 9. Change Propagation

When an artifact is updated:
- update requirements → design, tasks, tests marked "needs review"
- update design → tasks, tests marked "needs review"
- update tasks → tests marked "needs review"

Propagation is manual — the tool shows impact and asks before regenerating.
```

- [ ] **Step 3: Commit**

```bash
git add sdd/
git commit -m "feat(sdd): create directory structure and framework SPEC.md"
```

---

### Task 2: Formalism level definitions

**Files:**
- Create: `sdd/framework/levels/light.md`
- Create: `sdd/framework/levels/standard.md`
- Create: `sdd/framework/levels/formal.md`

- [ ] **Step 1: Write light.md**

Create `sdd/framework/levels/light.md`:

```markdown
# Light Level — SDD Framework

## When to Use
- Scripts and CLI tools
- Simple utilities and libraries
- Proof of concepts (POCs)
- Internal tools with small scope
- Projects with < 10 requirements

## Requirements Format
- Feature list with brief description (1-2 sentences each)
- No glossary required
- No SHALL/WHEN/IF formalism
- Acceptance criteria as simple bullet points
- Security requirements: FULL (auto-injected, not reduced)

### Example
```
### REQ-001: User login
Users can log in with email and password. Failed attempts are rate-limited.
Derives from: INPUT:product-spec §1

- Validates email format and password length
- Returns JWT on success
- Returns generic error on failure (no user enumeration)
```

## Design Format
- Stack summary (language, framework, database)
- High-level architecture (text or simple diagram)
- Basic data models (schema or type definitions)
- 1-3 Correctness Properties (main invariants)
- Security properties: FULL (auto-injected)

## Tasks Format
- Simple checklist with requirement references
- No subtasks required
- No checkpoints required

### Example
```
- [ ] TASK-001: Set up project and database schema
  Implements: REQ-001, REQ-002

- [ ] TASK-002: Implement auth endpoints
  Implements: REQ-001
  Tests: PROP-001
```

## Tests Format
- Basic e2e tests for main flows
- 1-3 property-based tests for main invariants
- Security tests: FULL (auto-injected)
```

- [ ] **Step 2: Write standard.md**

Create `sdd/framework/levels/standard.md`:

```markdown
# Standard Level — SDD Framework

## When to Use
- SaaS applications
- REST/GraphQL APIs
- Web and mobile apps
- Medium-complexity projects
- Projects with 10-50 requirements

## Requirements Format
- User stories: "As [actor], I want [action], so that [benefit]"
- Acceptance criteria as numbered list
- No SHALL/WHEN/IF required (but acceptable)
- Optional glossary for domain-specific terms
- Security requirements: FULL (auto-injected)

### Example
```
### REQ-001: User Registration
**User Story:** As a visitor, I want to create an account, so that I can
access the platform.
**Derives from:** INPUT:product-spec §2.1

#### Acceptance Criteria
1. Accepts email (valid format, max 254 chars) and password (min 8 chars).
2. Rejects duplicate emails with generic error.
3. Sends verification email on success.
4. Rate-limits registration to 5 attempts per IP per 15 minutes.
```

## Design Format
- Architecture section with diagram (Mermaid or textual)
- Components with responsibilities and interfaces
- Data models (full schema)
- Correctness Properties per functional area
- Security properties: FULL (auto-injected)

## Tasks Format
- Tasks with subtasks (TASK-NNN.N notation)
- Requirement references on every task
- Property references where applicable

## Tests Format
- E2E tests for all user flows
- Property-based tests per functional area
- Integration tests for external interfaces
- Security tests: FULL (auto-injected)
```

- [ ] **Step 3: Write formal.md**

Create `sdd/framework/levels/formal.md`:

```markdown
# Formal Level — SDD Framework

## When to Use
- Financial systems and fintech
- Healthcare and regulated industries
- Systems handling sensitive personal data
- High-availability critical infrastructure
- Projects with 50+ requirements

## Requirements Format
- Formal glossary: every term used in criteria MUST be defined
- SHALL/WHEN/IF vocabulary for acceptance criteria
- Numbered criteria per requirement
- Full origin tracing (Derives from: INPUT:... §section)
- Security requirements: FULL (auto-injected)

### Example
```
### REQ-001: Payment Webhook Processing
**User Story:** As the system operator, I want payment webhooks to be
processed idempotently, so that duplicate notifications never cause
double charges or duplicate deliveries.
**Derives from:** INPUT:product-spec §5.4

#### Acceptance Criteria
1. WHEN the System receives a webhook from Payment_Gateway with a
   payment_id, THE System SHALL verify the cryptographic signature
   before processing any action.
2. WHEN the System receives a valid webhook for a Payment already
   processed, THE System SHALL return HTTP 200 without reprocessing.
3. THE System SHALL execute payment status updates within a database
   transaction with Serializable isolation level.
```

## Design Format
- Architecture with Mermaid diagrams (overview + sequence flows)
- Components with full interface definitions (types, input/output)
- Complete data models with field constraints
- Exhaustive Correctness Properties with requirement references
- Error handling strategy (general + specific cases)
- Security properties: FULL (auto-injected)

## Tasks Format
- Tasks with subtasks and cross-references
- Property-linked tests per subtask
- Checkpoints between logical blocks
- Explicit test descriptions per subtask

## Tests Format
- Exhaustive: property-based + e2e + integration + contract tests
- Every Property has at least one test
- Every critical requirement has coverage
- Security tests: FULL (auto-injected)
```

- [ ] **Step 4: Commit**

```bash
git add sdd/framework/levels/
git commit -m "feat(sdd): add formalism level definitions (light, standard, formal)"
```

---

### Task 3: Security files

**Files:**
- Create: `sdd/framework/security/SECURITY_UNIVERSAL.md`
- Create: `sdd/framework/security/security-requirements.yaml`
- Create: `sdd/framework/security/security-properties.yaml`

- [ ] **Step 1: Copy SECURITY_UNIVERSAL.md into framework**

Copy the existing `docs/SECURITY_UNIVERSAL.md` from the project example into `sdd/framework/security/SECURITY_UNIVERSAL.md`. This file is the read-only universal security baseline.

```bash
cp docs/SECURITY_UNIVERSAL.md sdd/framework/security/SECURITY_UNIVERSAL.md
```

- [ ] **Step 2: Write security-requirements.yaml**

Create `sdd/framework/security/security-requirements.yaml`:

```yaml
# SDD Framework — Security Requirements (auto-injected)
#
# These requirements are injected into every project's requirements.md
# based on the applies_when filter. They are NOT filtered by formalism
# level — security is always at full rigor.
#
# The only filter is applies_when: the requirement is injected only if
# the project has the matching characteristic.

categories:
  - id: input-validation
    applies_when: always
    requirements:
      - id: SEC-REQ-INPUT-01
        title: Schema validation on all endpoints
        criteria: >
          THE System SHALL validate all API inputs with a schema validation
          library before any processing or database access. Every field SHALL
          have defined type, minimum length, maximum length, and format.
          Invalid input SHALL result in HTTP 400 with field-specific errors
          that do not expose internal implementation details.

  - id: idor
    applies_when: has_authenticated_resources
    requirements:
      - id: SEC-REQ-IDOR-01
        title: Ownership check on every endpoint with ID
        criteria: >
          THE System SHALL verify resource ownership for every endpoint that
          receives a resource ID. WHEN the resource does not belong to the
          authenticated user, THE System SHALL return HTTP 404 without
          revealing the resource's existence or any of its data.

  - id: upload
    applies_when: has_file_upload
    requirements:
      - id: SEC-REQ-UPLOAD-01
        title: Upload validation by magic bytes
        criteria: >
          THE System SHALL validate uploaded files by magic bytes, MIME type,
          extension, and decoding — never by extension alone. Files exceeding
          the size limit SHALL be rejected before processing. Uploaded files
          SHALL be renamed with UUID, stripped of EXIF/metadata, and stored
          in external storage with signed URLs.

  - id: rate-limiting
    applies_when: has_public_endpoints
    requirements:
      - id: SEC-REQ-RATE-01
        title: Rate limiting on public endpoints
        criteria: >
          THE System SHALL enforce rate limits on all public endpoints.
          WHEN the limit is exceeded, THE System SHALL return HTTP 429
          with a Retry-After header indicating wait time in seconds.
          Limits SHALL be applied per IP and, when available, per
          authenticated user.

  - id: race-conditions
    applies_when: has_write_operations
    requirements:
      - id: SEC-REQ-RACE-01
        title: Transactions for critical write operations
        criteria: >
          THE System SHALL use database transactions with appropriate
          isolation level for all critical write operations. Financial
          operations SHALL use Serializable isolation. Webhook processing
          SHALL use idempotency keys to prevent duplicate processing.

  - id: auth
    applies_when: has_authentication
    requirements:
      - id: SEC-REQ-AUTH-01
        title: Authentication security
        criteria: >
          THE System SHALL rate-limit login attempts to 5 per 15 minutes
          per IP/email. THE System SHALL never return different error
          messages for "email not found" vs "wrong password". Logout
          SHALL invalidate the session server-side. Sensitive actions
          SHALL require re-authentication.

  - id: headers
    applies_when: always
    requirements:
      - id: SEC-REQ-HEADERS-01
        title: Security headers on all responses
        criteria: >
          THE System SHALL include the following headers in all HTTP
          responses: Strict-Transport-Security, X-Frame-Options (SAMEORIGIN),
          X-Content-Type-Options (nosniff), Referrer-Policy
          (origin-when-cross-origin), Permissions-Policy (deny camera,
          microphone, geolocation). Content-Security-Policy SHALL start
          restrictive (default-src 'self') with documented exceptions.

  - id: data-privacy
    applies_when: has_personal_data
    requirements:
      - id: SEC-REQ-PRIVACY-01
        title: Sensitive data protection
        criteria: >
          THE System SHALL never log passwords, tokens, credit card data,
          or complete personal data. Error responses to clients SHALL be
          generic; detailed errors SHALL appear only in server logs.
          Temporary processing data (e.g., uploaded photos used for
          generation) SHALL be deleted after processing completes.

  - id: honeypots
    applies_when: has_public_endpoints
    requirements:
      - id: SEC-REQ-HONEYPOT-01
        title: Honeypot defenses
        criteria: >
          THE System SHALL include honeypot fields in public forms (hidden
          via CSS, no tabIndex, aria-hidden). WHEN a honeypot field is
          filled, THE System SHALL return HTTP 200 with fake success
          response without processing the request. THE System SHALL
          implement decoy endpoints that log access and optionally
          block the IP.

  - id: urls
    applies_when: has_external_urls
    requirements:
      - id: SEC-REQ-URL-01
        title: URL allowlist for external resources
        criteria: >
          THE System SHALL validate all URLs against a hostname allowlist.
          THE System SHALL never fetch arbitrary URLs provided by users
          on the server side. External fetches SHALL have short timeouts,
          response size limits, and SHALL block private IP ranges.

  - id: business-timing
    applies_when: has_payments
    requirements:
      - id: SEC-REQ-TIMING-01
        title: Action only after payment confirmation
        criteria: >
          THE System SHALL execute paid actions only after payment
          confirmation via gateway webhook, never based on client-side
          notification. THE System SHALL validate the paid amount against
          the expected amount on the server. Refunds SHALL revoke access
          to paid resources.

  - id: csrf
    applies_when: has_forms
    requirements:
      - id: SEC-REQ-CSRF-01
        title: CSRF protection on state-changing forms
        criteria: >
          THE System SHALL implement CSRF protection on all forms that
          change state. Tokens SHALL be validated server-side on every
          state-changing request.

  - id: dependencies
    applies_when: always
    requirements:
      - id: SEC-REQ-DEPS-01
        title: Dependency security
        criteria: >
          THE System SHALL use a lockfile committed to the repository.
          Dependencies SHALL be audited regularly. Secrets SHALL never
          be committed — they SHALL be stored in environment variables
          or a secret manager.
```

- [ ] **Step 3: Write security-properties.yaml**

Create `sdd/framework/security/security-properties.yaml`:

```yaml
# SDD Framework — Security Properties (auto-injected)
#
# These correctness properties are injected into every project's design.md
# based on the applies_when filter. NOT filtered by formalism level.

properties:
  - id: SEC-PROP-INPUT
    name: Input validation rejects invalid data
    statement: >
      For any API input where any field violates the defined schema
      (wrong type, exceeds length, invalid format, unrecognized enum value),
      the system SHALL return HTTP 400 and SHALL NOT create, modify, or
      query any resource in the database.
    validates: SEC-REQ-INPUT-01
    applies_when: always

  - id: SEC-PROP-IDOR
    name: Resource ownership verification
    statement: >
      For any pair (resourceId, userId) where userId is not the owner of
      the resource, any endpoint receiving that resourceId SHALL return
      HTTP 404 without revealing the resource's existence or returning
      any of its data.
    validates: SEC-REQ-IDOR-01
    applies_when: has_authenticated_resources

  - id: SEC-PROP-UPLOAD
    name: Upload rejects invalid files
    statement: >
      For any file buffer whose magic bytes do not match the allowed MIME
      types, or whose size exceeds the configured limit, or whose dimensions
      exceed the maximum, the system SHALL return HTTP 400 and SHALL NOT
      store the file in any storage.
    validates: SEC-REQ-UPLOAD-01
    applies_when: has_file_upload

  - id: SEC-PROP-RATE
    name: Rate limiting enforced
    statement: >
      For any rate-limited endpoint and any IP, when the number of requests
      exceeds the configured limit within the time window, all excess
      requests SHALL return HTTP 429 with a Retry-After header with a
      value greater than zero.
    validates: SEC-REQ-RATE-01
    applies_when: has_public_endpoints

  - id: SEC-PROP-RACE
    name: Idempotent critical operations
    statement: >
      For any critical write operation, processing the same request N times
      (N >= 1) SHALL result in the same final state as processing it exactly
      once. No duplicate resources SHALL be created, no duplicate side
      effects SHALL occur.
    validates: SEC-REQ-RACE-01
    applies_when: has_write_operations

  - id: SEC-PROP-AUTH
    name: Login rate limiting
    statement: >
      For any IP or email, after 5 failed login attempts within 15 minutes,
      all subsequent login attempts SHALL be rejected until the window
      expires. Error messages SHALL be identical for "user not found" and
      "wrong password".
    validates: SEC-REQ-AUTH-01
    applies_when: has_authentication

  - id: SEC-PROP-PRIVACY
    name: No sensitive data in logs or responses
    statement: >
      For any log entry or error response produced by the system, the
      output SHALL NOT contain passwords, session tokens, API keys,
      credit card numbers, or complete personal data records.
    validates: SEC-REQ-PRIVACY-01
    applies_when: has_personal_data

  - id: SEC-PROP-HONEYPOT
    name: Honeypot silently rejects bots
    statement: >
      For any non-empty string submitted in a honeypot field, the system
      SHALL return HTTP 200 with a fake success response and SHALL NOT
      create any resource or trigger any processing.
    validates: SEC-REQ-HONEYPOT-01
    applies_when: has_public_endpoints

  - id: SEC-PROP-TIMING
    name: No action before payment confirmation
    statement: >
      For any paid feature, the system SHALL NOT execute the paid action
      until the payment gateway confirms the payment via authenticated
      webhook. The amount charged SHALL match the server-side price table,
      never the client-submitted value.
    validates: SEC-REQ-TIMING-01
    applies_when: has_payments
```

- [ ] **Step 4: Commit**

```bash
git add sdd/framework/security/
git commit -m "feat(sdd): add SECURITY_UNIVERSAL and security requirements/properties YAML"
```

---

### Task 4: Validation rules

**Files:**
- Create: `sdd/framework/validation/rules.yaml`
- Create: `sdd/framework/validation/coverage-matrix.md`

- [ ] **Step 1: Write rules.yaml**

Create `sdd/framework/validation/rules.yaml`:

```yaml
# SDD Framework — Validation Rules
#
# Used by /sdd validate and by light validation after each generation.
# Each rule has a severity: error (blocks), warning (reports).

light_validation:
  after_requirements:
    - id: VAL-REQ-01
      check: every_input_doc_has_derived_req
      description: Every input doc in sdd.config.yaml must have at least 1 REQ with "Derives from" pointing to it
      severity: warning

    - id: VAL-REQ-02
      check: security_requirements_injected
      description: SEC-REQs matching project features must be present
      severity: error

  after_design:
    - id: VAL-DES-01
      check: every_req_has_component
      description: Every REQ must be referenced by at least 1 component (via "Implements")
      severity: warning

    - id: VAL-DES-02
      check: every_prop_refs_valid_reqs
      description: Every PROP must reference REQ IDs that exist in requirements.md
      severity: error

    - id: VAL-DES-03
      check: security_properties_injected
      description: SEC-PROPs matching project features must be present
      severity: error

  after_tasks:
    - id: VAL-TASK-01
      check: every_task_refs_req
      description: Every TASK must reference at least 1 REQ (via "Implements")
      severity: warning

    - id: VAL-TASK-02
      check: every_req_has_task
      description: Every REQ must be referenced by at least 1 TASK
      severity: warning

  after_tests:
    - id: VAL-TEST-01
      check: every_prop_has_test
      description: Every PROP (including SEC-PROP) must have at least 1 TEST
      severity: error

    - id: VAL-TEST-02
      check: critical_reqs_covered
      description: Every SEC-REQ must have at least 1 TEST
      severity: error

    - id: VAL-TEST-03
      check: security_tests_present
      description: Security tests for injected SEC-PROPs must be present
      severity: error

full_validation:
  coverage_matrix:
    - id: VAL-FULL-01
      check: generate_coverage_matrix
      description: Generate REQ × Component × PROP × TASK × TEST matrix

  security_audit:
    - id: VAL-FULL-02
      check: security_checklist_audit
      description: Cross-reference SECURITY_UNIVERSAL §14 checklist against artifacts

  gaps:
    - id: VAL-FULL-03
      check: find_broken_references
      description: Find any cross-reference pointing to a non-existent ID

    - id: VAL-FULL-04
      check: find_orphan_ids
      description: Find IDs that exist but are never referenced by any other artifact

  stats:
    - id: VAL-FULL-05
      check: calculate_coverage_stats
      description: Calculate coverage percentage per artifact
```

- [ ] **Step 2: Write coverage-matrix.md**

Create `sdd/framework/validation/coverage-matrix.md`:

```markdown
# Coverage Matrix — How to Read

The coverage matrix is generated by `/sdd validate`. It maps every
requirement to its implementation chain.

## Format

| REQ | Component | Property | Task | Test | Status |
|-----|-----------|----------|------|------|--------|
| REQ-001 | AuthService | PROP-001 | TASK-003 | TEST-PROP-001 | COVERED |
| REQ-002 | UploadHandler | PROP-003 | TASK-005 | TEST-E2E-002 | COVERED |
| REQ-007 | — | — | — | — | UNCOVERED |

## Status Values

- **COVERED** — REQ has at least: 1 component, 1 property, 1 task, 1 test
- **PARTIAL** — REQ is missing one or more chain links
- **UNCOVERED** — REQ has no downstream references at all

## Security Audit Section

The security audit cross-references the SECURITY_UNIVERSAL §14 checklist
categories against the artifacts:

```
- [PASS] Input validation: SEC-REQ-INPUT-01 → SEC-PROP-INPUT → TEST-PROP-INPUT
- [PASS] IDOR: SEC-REQ-IDOR-01 → SEC-PROP-IDOR → TEST-PROP-IDOR
- [FAIL] Rate limiting: SEC-REQ-RATE-01 exists but no TASK implements it
- [N/A]  Upload: project has no file upload (has_file_upload = false)
```

## Report File

Reports are saved to `docs/sdd/reports/validation-YYYY-MM-DD.md`
with timestamp and full details.
```

- [ ] **Step 3: Commit**

```bash
git add sdd/framework/validation/
git commit -m "feat(sdd): add validation rules and coverage matrix docs"
```

---

### Task 5: i18n files

**Files:**
- Create: `sdd/framework/i18n/en.yaml`
- Create: `sdd/framework/i18n/pt-br.yaml`

- [ ] **Step 1: Write en.yaml**

Create `sdd/framework/i18n/en.yaml`:

```yaml
# SDD Framework — English labels
# Used by the skill when generating artifacts in English

artifact_titles:
  requirements: "Requirements"
  design: "Technical Design"
  tasks: "Implementation Plan"
  tests: "Test Specification"

section_titles:
  introduction: "Introduction"
  glossary: "Glossary"
  requirements: "Requirements"
  security_requirements: "Security Requirements (auto-generated)"
  overview: "Overview"
  architecture: "Architecture"
  components: "Components and Interfaces"
  data_models: "Data Models"
  correctness_properties: "Correctness Properties"
  error_handling: "Error Handling"
  test_strategy: "Test Strategy"
  pre_implementation_tests: "Pre-Implementation Tests (RED)"
  per_task_tests: "Per-Task Tests (generated during implementation)"
  property_based_tests: "Property-Based Tests"
  e2e_tests: "E2E Tests"
  integration_tests: "Integration / Contract Tests"

labels:
  user_story: "User Story"
  derives_from: "Derives from"
  implements: "Implements"
  validates: "Validates"
  tests: "Tests"
  acceptance_criteria: "Acceptance Criteria"
  checkpoint: "Checkpoint"

status:
  covered: "COVERED"
  partial: "PARTIAL"
  uncovered: "UNCOVERED"
  pass: "PASS"
  fail: "FAIL"
  na: "N/A"
  needs_review: "needs review"
  not_generated: "not generated yet"

messages:
  security_note: "Security is always at full rigor regardless of formalism level."
  auto_generated: "Auto-generated from SECURITY_UNIVERSAL. Do not remove."
  validation_light: "Light validation passed."
  validation_gaps: "Gaps found. Review before proceeding."
```

- [ ] **Step 2: Write pt-br.yaml**

Create `sdd/framework/i18n/pt-br.yaml`:

```yaml
# SDD Framework — Rótulos em Português Brasileiro
# Usado pela skill ao gerar artefatos em PT-BR

artifact_titles:
  requirements: "Documento de Requisitos"
  design: "Design Técnico"
  tasks: "Plano de Implementação"
  tests: "Especificação de Testes"

section_titles:
  introduction: "Introdução"
  glossary: "Glossário"
  requirements: "Requisitos"
  security_requirements: "Requisitos de Segurança (auto-gerados)"
  overview: "Visão Geral"
  architecture: "Arquitetura"
  components: "Componentes e Interfaces"
  data_models: "Modelos de Dados"
  correctness_properties: "Propriedades de Corretude"
  error_handling: "Tratamento de Erros"
  test_strategy: "Estratégia de Testes"
  pre_implementation_tests: "Testes Pré-Implementação (RED)"
  per_task_tests: "Testes por Task (gerados durante implementação)"
  property_based_tests: "Testes de Propriedade"
  e2e_tests: "Testes E2E"
  integration_tests: "Testes de Integração / Contrato"

labels:
  user_story: "User Story"
  derives_from: "Derivado de"
  implements: "Implementa"
  validates: "Valida"
  tests: "Testa"
  acceptance_criteria: "Critérios de Aceitação"
  checkpoint: "Checkpoint"

status:
  covered: "COBERTO"
  partial: "PARCIAL"
  uncovered: "SEM COBERTURA"
  pass: "OK"
  fail: "FALHA"
  na: "N/A"
  needs_review: "precisa revisão"
  not_generated: "ainda não gerado"

messages:
  security_note: "Segurança é sempre aplicada com rigor total, independente do nível de formalismo."
  auto_generated: "Auto-gerado a partir do SECURITY_UNIVERSAL. Não remova."
  validation_light: "Validação leve passou."
  validation_gaps: "Gaps encontrados. Revise antes de prosseguir."
```

- [ ] **Step 3: Commit**

```bash
git add sdd/framework/i18n/
git commit -m "feat(sdd): add i18n files (en + pt-br)"
```

---

## Phase 2: Templates

### Task 6: Requirements templates

**Files:**
- Create: `sdd/framework/templates/requirements/light.template.md`
- Create: `sdd/framework/templates/requirements/standard.template.md`
- Create: `sdd/framework/templates/requirements/formal.template.md`

- [ ] **Step 1: Write light.template.md**

Create `sdd/framework/templates/requirements/light.template.md`:

```markdown
# {{i18n.artifact_titles.requirements}} — {{project.name}}

## {{i18n.section_titles.introduction}}

{{GENERATE: 1-paragraph system description from input docs}}

## {{i18n.section_titles.requirements}}

### REQ-001: {{title}}
{{Brief description — 1-3 sentences}}
{{i18n.labels.derives_from}}: INPUT:{{source}} §{{section}}

- {{Acceptance criterion 1}}
- {{Acceptance criterion 2}}

<!-- Repeat for each requirement -->

## {{i18n.section_titles.security_requirements}}

<!-- AUTO-INJECTED: Do not remove. Full security regardless of level. -->
<!-- Injected from security-requirements.yaml filtered by applies_when -->

### {{sec_req.id}}: {{sec_req.title}}
{{sec_req.criteria}}
```

- [ ] **Step 2: Write standard.template.md**

Create `sdd/framework/templates/requirements/standard.template.md`:

```markdown
# {{i18n.artifact_titles.requirements}} — {{project.name}}

## {{i18n.section_titles.introduction}}

{{GENERATE: 1-paragraph system description from input docs}}

## {{i18n.section_titles.glossary}}

<!-- Optional for standard level. Include if domain has ambiguous terms. -->
- **{{Term}}**: {{Definition}}

## {{i18n.section_titles.requirements}}

### REQ-001: {{title}}
**{{i18n.labels.user_story}}:** As {{actor}}, I want {{action}}, so that {{benefit}}.
**{{i18n.labels.derives_from}}:** INPUT:{{source}} §{{section}}

#### {{i18n.labels.acceptance_criteria}}
1. {{Criterion with specific, testable condition and expected behavior}}
2. {{Criterion}}

<!-- Repeat for each requirement -->

## {{i18n.section_titles.security_requirements}}

<!-- AUTO-INJECTED: Full security regardless of level. -->

### {{sec_req.id}}: {{sec_req.title}}
{{sec_req.criteria}}
**{{i18n.labels.derives_from}}:** SECURITY_UNIVERSAL §{{section}}
```

- [ ] **Step 3: Write formal.template.md**

Create `sdd/framework/templates/requirements/formal.template.md`:

```markdown
# {{i18n.artifact_titles.requirements}} — {{project.name}}

## {{i18n.section_titles.introduction}}

{{GENERATE: 1-paragraph system description from input docs}}

## {{i18n.section_titles.glossary}}

<!-- REQUIRED for formal level. Every term used in acceptance criteria
     MUST be defined here. -->

- **{{Term}}**: {{Precise definition as used in this document}}

## {{i18n.section_titles.requirements}}

### REQ-001: {{title}}
**{{i18n.labels.user_story}}:** As {{actor}}, I want {{action}}, so that {{benefit}}.
**{{i18n.labels.derives_from}}:** INPUT:{{source}} §{{section}}

#### {{i18n.labels.acceptance_criteria}}
1. WHEN {{condition}}, THE {{Component}} SHALL {{behavior}}.
2. IF {{condition}}, THEN THE {{Component}} SHALL {{behavior}}.
3. THE {{Component}} SHALL {{always-true behavior}}.

<!-- Use SHALL for mandatory behavior.
     Use WHEN for conditional triggers.
     Use IF/THEN for conditional logic.
     Reference Glossary terms exactly as defined. -->

---

## {{i18n.section_titles.security_requirements}}

<!-- AUTO-INJECTED: Full security regardless of level. -->
<!-- {{i18n.messages.auto_generated}} -->

### {{sec_req.id}}: {{sec_req.title}}
**{{i18n.labels.derives_from}}:** SECURITY_UNIVERSAL §{{section}}

#### {{i18n.labels.acceptance_criteria}}
{{sec_req.criteria}}
```

- [ ] **Step 4: Commit**

```bash
git add sdd/framework/templates/requirements/
git commit -m "feat(sdd): add requirements templates (light, standard, formal)"
```

---

### Task 7: Design templates

**Files:**
- Create: `sdd/framework/templates/design/light.template.md`
- Create: `sdd/framework/templates/design/standard.template.md`
- Create: `sdd/framework/templates/design/formal.template.md`

- [ ] **Step 1: Write light.template.md**

Create `sdd/framework/templates/design/light.template.md`:

```markdown
# {{i18n.artifact_titles.design}} — {{project.name}}

## {{i18n.section_titles.overview}}

{{GENERATE: Technical summary — what the system does, stack, main flow}}

### Stack
| Component | Technology |
|-----------|-----------|
| {{component}} | {{technology}} |

## {{i18n.section_titles.data_models}}

{{GENERATE: Basic data models — schema or type definitions for main entities}}

## {{i18n.section_titles.correctness_properties}}

<!-- 1-3 properties covering the main invariants of the system -->

### PROP-001: {{name}}
{{Formal statement: "For any X..."}}
**{{i18n.labels.validates}}:** REQ-{{NNN}}

<!-- Security properties — AUTO-INJECTED, full rigor -->

### {{sec_prop.id}}: {{sec_prop.name}}
{{sec_prop.statement}}
**{{i18n.labels.validates}}:** {{sec_prop.validates}}
```

- [ ] **Step 2: Write standard.template.md**

Create `sdd/framework/templates/design/standard.template.md`:

```markdown
# {{i18n.artifact_titles.design}} — {{project.name}}

## {{i18n.section_titles.overview}}

{{GENERATE: Technical summary — what the system does, stack, main flow}}

### Stack
| Component | Technology |
|-----------|-----------|
| {{component}} | {{technology}} |

## {{i18n.section_titles.architecture}}

{{GENERATE: Architecture diagram (Mermaid or textual) + directory structure}}

## {{i18n.section_titles.components}}

### {{Component Name}}
- **Responsibility:** {{what it does}}
- **Interface:** {{input/output types}}
- **Dependencies:** {{what it depends on}}
- **{{i18n.labels.implements}}:** REQ-{{NNN}}

## {{i18n.section_titles.data_models}}

{{GENERATE: Full schema — ORM models or database schema with field types and constraints}}

## {{i18n.section_titles.correctness_properties}}

### PROP-001: {{name}}
{{Formal statement: "For any X..."}}
**{{i18n.labels.validates}}:** REQ-{{NNN}}, REQ-{{MMM}}

<!-- Security properties — AUTO-INJECTED, full rigor -->

### {{sec_prop.id}}: {{sec_prop.name}}
{{sec_prop.statement}}
**{{i18n.labels.validates}}:** {{sec_prop.validates}}
```

- [ ] **Step 3: Write formal.template.md**

Create `sdd/framework/templates/design/formal.template.md`:

```markdown
# {{i18n.artifact_titles.design}} — {{project.name}}

## {{i18n.section_titles.overview}}

{{GENERATE: Technical summary — what the system does, stack, main flow.
Include main flow description in 2-3 sentences.}}

### Stack
| Component | Technology |
|-----------|-----------|
| {{component}} | {{technology}} |

## {{i18n.section_titles.architecture}}

### High-Level Architecture

{{GENERATE: Mermaid graph TD diagram showing main components and data flow}}

### Application Layers

```
{{GENERATE: Directory structure showing file organization}}
```

### Key Flows

{{GENERATE: Mermaid sequenceDiagram for main flows (e.g., purchase, generation)}}

## {{i18n.section_titles.components}}

### {{Component Name}}
- **Responsibility:** {{what it does}}
- **Interface:**
  ```
  {{input/output type definitions in project language}}
  ```
- **Dependencies:** {{what it depends on}}
- **{{i18n.labels.implements}}:** REQ-{{NNN}}
- **Behavior:** {{key behavior notes}}

## {{i18n.section_titles.data_models}}

{{GENERATE: Complete schema with all models, fields, types, constraints,
relations, and indexes. Use project's ORM syntax.}}

### Main Types

```
{{GENERATE: Type definitions in project language for main interfaces
(input types, output types, enums)}}
```

## {{i18n.section_titles.correctness_properties}}

### PROP-001: {{name}}
{{Formal statement: "For any X that satisfies [precondition],
[operation] SHALL [postcondition]. [Additional constraints]."}}
**{{i18n.labels.validates}}:** REQ-{{NNN}}, REQ-{{MMM}}

<!-- Security properties — AUTO-INJECTED, full rigor -->

### {{sec_prop.id}}: {{sec_prop.name}}
{{sec_prop.statement}}
**{{i18n.labels.validates}}:** {{sec_prop.validates}}

## {{i18n.section_titles.error_handling}}

### General Strategy
{{GENERATE: Error handling approach — generic errors to client,
detailed errors in logs, error types/codes}}

### Specific Cases
{{GENERATE: Table or list of specific error scenarios and their handling}}
```

- [ ] **Step 4: Commit**

```bash
git add sdd/framework/templates/design/
git commit -m "feat(sdd): add design templates (light, standard, formal)"
```

---

### Task 8: Tasks templates

**Files:**
- Create: `sdd/framework/templates/tasks/light.template.md`
- Create: `sdd/framework/templates/tasks/standard.template.md`
- Create: `sdd/framework/templates/tasks/formal.template.md`

- [ ] **Step 1: Write light.template.md**

Create `sdd/framework/templates/tasks/light.template.md`:

```markdown
# {{i18n.artifact_titles.tasks}} — {{project.name}}

## {{i18n.section_titles.overview}}

{{GENERATE: Brief summary — stack, approach}}

## Tasks

- [ ] TASK-001: {{title}}
  {{Brief description}}
  {{i18n.labels.implements}}: REQ-{{NNN}}

- [ ] TASK-002: {{title}}
  {{Brief description}}
  {{i18n.labels.implements}}: REQ-{{NNN}}
  {{i18n.labels.tests}}: PROP-{{NNN}}

<!-- Repeat for each task. Simple checklist, req refs required. -->
```

- [ ] **Step 2: Write standard.template.md**

Create `sdd/framework/templates/tasks/standard.template.md`:

```markdown
# {{i18n.artifact_titles.tasks}} — {{project.name}}

## {{i18n.section_titles.overview}}

{{GENERATE: Stack, approach, mandatory notes (e.g., "read SECURITY before implementing")}}

## Tasks

- [ ] TASK-001: {{title}}
  {{Description of what to implement}}
  - [ ] TASK-001.1: {{subtask}}
  - [ ] TASK-001.2: {{subtask}}
  {{i18n.labels.implements}}: REQ-{{NNN}}, REQ-{{MMM}}
  {{i18n.labels.tests}}: PROP-{{NNN}}

- [ ] TASK-002: {{title}}
  {{Description}}
  - [ ] TASK-002.1: {{subtask}}
  {{i18n.labels.implements}}: REQ-{{NNN}}

<!-- Repeat. Subtasks use TASK-NNN.N notation. -->
```

- [ ] **Step 3: Write formal.template.md**

Create `sdd/framework/templates/tasks/formal.template.md`:

```markdown
# {{i18n.artifact_titles.tasks}} — {{project.name}}

## {{i18n.section_titles.overview}}

{{GENERATE: Stack, approach, mandatory prerequisites, notes}}

> **MANDATORY**: {{any prerequisites — e.g., read security docs, check API docs}}

## Tasks

- [ ] TASK-001: {{title}}
  {{Detailed description of what to implement}}
  - [ ] TASK-001.1: {{subtask with specific action}}
  - [ ] TASK-001.2: {{subtask with specific action}}
  - [ ] TASK-001.3: Write tests
    - {{Test description — what to test, expected behavior}}
    - **Validates: PROP-{{NNN}}**
  {{i18n.labels.implements}}: REQ-{{NNN}}, REQ-{{MMM}}
  {{i18n.labels.tests}}: PROP-{{NNN}}

- [ ] TASK-NNN: {{i18n.labels.checkpoint}} — {{description}}
  {{What to verify before proceeding. Ask user if there are questions.}}

<!-- Repeat. Include checkpoints between logical blocks.
     Each subtask that involves tests should reference the PROP. -->
```

- [ ] **Step 4: Commit**

```bash
git add sdd/framework/templates/tasks/
git commit -m "feat(sdd): add tasks templates (light, standard, formal)"
```

---

### Task 9: Tests templates

**Files:**
- Create: `sdd/framework/templates/tests/light.template.md`
- Create: `sdd/framework/templates/tests/standard.template.md`
- Create: `sdd/framework/templates/tests/formal.template.md`

- [ ] **Step 1: Write light.template.md**

Create `sdd/framework/templates/tests/light.template.md`:

```markdown
# {{i18n.artifact_titles.tests}} — {{project.name}}

## {{i18n.section_titles.test_strategy}}
Stack: {{stack.test_framework}}
Approach: basic e2e + essential property tests

## {{i18n.section_titles.pre_implementation_tests}}

### {{i18n.section_titles.property_based_tests}}

#### TEST-PROP-001: {{name}} → PROP-001
Type: property-based
{{i18n.labels.validates}}: REQ-{{NNN}}
Description: {{what to test}}
Assertion: {{what must hold}}

### {{i18n.section_titles.e2e_tests}}

#### TEST-E2E-001: {{flow name}}
Type: e2e
{{i18n.labels.validates}}: REQ-{{NNN}}
Steps: {{test steps}}
Expected: {{expected result}}

## {{i18n.section_titles.per_task_tests}}
- TASK-{{NNN}}: {{expected unit test description}}
```

- [ ] **Step 2: Write standard.template.md**

Create `sdd/framework/templates/tests/standard.template.md`:

```markdown
# {{i18n.artifact_titles.tests}} — {{project.name}}

## {{i18n.section_titles.test_strategy}}
Stack: {{stack.test_framework}} + {{stack.property_testing}}
Approach: property-based + e2e + integration

## {{i18n.section_titles.pre_implementation_tests}}

### {{i18n.section_titles.property_based_tests}}

#### TEST-PROP-001: {{name}} → PROP-001
Type: property-based
Description: {{what to test — derived from property}}
{{i18n.labels.validates}}: REQ-{{NNN}}, REQ-{{MMM}}
Generator: {{random input description}}
Assertion: {{what must hold for all generated inputs}}

### {{i18n.section_titles.e2e_tests}}

#### TEST-E2E-001: {{flow name}}
Type: e2e
Description: {{end-to-end scenario derived from user story}}
{{i18n.labels.validates}}: REQ-{{NNN}}
Steps:
1. {{step}}
2. {{step}}
Expected: {{expected result}}

### {{i18n.section_titles.integration_tests}}

#### TEST-INT-001: {{interface name}}
Type: integration
Description: {{API/interface contract test}}
{{i18n.labels.validates}}: REQ-{{NNN}}
Endpoint/Interface: {{which}}
Input: {{test payload}}
Expected: {{expected response}}

## {{i18n.section_titles.per_task_tests}}
- TASK-{{NNN}}: {{expected unit test description}}
```

- [ ] **Step 3: Write formal.template.md**

Create `sdd/framework/templates/tests/formal.template.md`:

```markdown
# {{i18n.artifact_titles.tests}} — {{project.name}}

## {{i18n.section_titles.test_strategy}}
Stack: {{stack.test_framework}} + {{stack.property_testing}}
Approach: exhaustive — property-based + e2e + integration + contract
Minimum property test iterations: 100

## {{i18n.section_titles.pre_implementation_tests}}

### {{i18n.section_titles.property_based_tests}}

#### TEST-PROP-001: {{name}} → PROP-001
Type: property-based
Description: {{what to test — derived from property statement}}
{{i18n.labels.validates}}: REQ-{{NNN}}, REQ-{{MMM}}
Generator: {{detailed description of random inputs and their constraints}}
Preconditions: {{setup required before each test run}}
Assertion: {{formal statement of what must hold for all inputs}}
Edge cases: {{specific edge cases to cover beyond random generation}}
Tag: `// Feature: {{project.name}}, Property 1: {{property name}}`

### {{i18n.section_titles.e2e_tests}}

#### TEST-E2E-001: {{flow name}}
Type: e2e
Description: {{complete end-to-end scenario derived from user story}}
{{i18n.labels.validates}}: REQ-{{NNN}}
Preconditions: {{initial state required}}
Steps:
1. {{action + expected intermediate state}}
2. {{action + expected intermediate state}}
Final assertion: {{expected final state}}
Teardown: {{cleanup actions}}

### {{i18n.section_titles.integration_tests}}

#### TEST-INT-001: {{interface/endpoint name}}
Type: integration / contract
Description: {{API contract test — request shape + response shape}}
{{i18n.labels.validates}}: REQ-{{NNN}}
Endpoint: {{method + path}}
Input: {{full test payload}}
Expected response: {{status code + body shape}}
Error cases:
- {{invalid input → expected error response}}
- {{unauthorized → expected error response}}

## {{i18n.section_titles.per_task_tests}}
- TASK-{{NNN}}: {{expected unit test description with specific assertions}}
```

- [ ] **Step 4: Commit**

```bash
git add sdd/framework/templates/tests/
git commit -m "feat(sdd): add tests templates (light, standard, formal)"
```

---

### Task 10: Input doc templates and recommended types

**Files:**
- Create: `sdd/framework/inputs/recommended-types.md`
- Create: `sdd/framework/inputs/templates/product-spec.template.md`
- Create: `sdd/framework/inputs/templates/brand-guide.template.md`
- Create: `sdd/framework/inputs/templates/business-plan.template.md`
- Create: `sdd/framework/inputs/templates/security-guidelines.template.md`

- [ ] **Step 1: Write recommended-types.md**

Create `sdd/framework/inputs/recommended-types.md`:

```markdown
# Input Doc Types — SDD Framework

## Recommended Types

| Type | ID | Description | Auto-detection signals |
|------|----|-------------|----------------------|
| Product Spec | `product-spec` | Features, user flows, pricing, product details | "feature", "user flow", "pricing", "product" |
| Brand Guide | `brand-guide` | Colors, typography, tone of voice, visual identity | "color", "palette", "typography", "font", "brand" |
| Business Plan | `business-plan` | Market analysis, metrics, revenue, strategy, phases | "market", "revenue", "metric", "ROI", "strategy" |
| Security | `security` | Project-specific security rules (merged with SECURITY_UNIVERSAL) | "OWASP", "XSS", "CSRF", "injection", "security header" |
| API Docs | `api-docs` | External API documentation, endpoints, schemas | "endpoint", "API", "REST", "GraphQL", "webhook" |
| Auto | `auto` | Unclassified — skill auto-classifies based on content | N/A |

## Auto-Classification Logic

When a doc is typed as `auto`, the skill reads its content and classifies
based on keyword density. If confidence is below 70%, it asks the user.

## Merge Rules for Security Type

Docs typed as `security` are merged with SECURITY_UNIVERSAL:
- User rules ADD to the baseline
- User CAN increase rigor (e.g., stricter rate limits)
- User CANNOT remove baseline rules
- User CAN mark specific SEC-REQs as N/A with written justification
```

- [ ] **Step 2: Write product-spec.template.md**

Create `sdd/framework/inputs/templates/product-spec.template.md`:

```markdown
# Product Specification — [Project Name]

## Overview
[What the product does, who it's for, key differentiator — 2-3 paragraphs]

## Products / Features
[List each product or feature with description, pricing if applicable]

### Feature 1: [Name]
[Description, details, constraints]

## User Journey
[Step-by-step flow from first visit to completion]

### Step 1: [Name]
[What happens, what the user sees, what data is collected]

## Integrations
[External services, APIs, third-party tools]

## Metrics
[KPIs, success criteria, targets]
```

- [ ] **Step 3: Write brand-guide.template.md**

Create `sdd/framework/inputs/templates/brand-guide.template.md`:

```markdown
# Brand Guide — [Project Name]

## Essence
[Brand personality in 2-3 sentences]

## Color Palette
[Primary and secondary colors with hex values and usage rules]

## Typography
[Fonts, weights, scale, usage rules]

## Tone of Voice
[Personality, principles, examples of do/don't]

## Visual Components
[Buttons, cards, badges, icons — styles and rules]

## Logo
[Versions, sizes, spacing, application rules]
```

- [ ] **Step 4: Write business-plan.template.md**

Create `sdd/framework/inputs/templates/business-plan.template.md`:

```markdown
# Business Plan — [Project Name]

## Executive Summary
[What, why, how — 1 paragraph]

## Product
[Detailed product description]

## Market
[Target audience, market size, competitors]

## Revenue Model
[Pricing, revenue streams, projections]

## Strategy / Phases
[Implementation phases with timeline and goals]

## Metrics
[KPIs and targets]
```

- [ ] **Step 5: Write security-guidelines.template.md**

Create `sdd/framework/inputs/templates/security-guidelines.template.md`:

```markdown
# Security Guidelines — [Project Name]

> These guidelines are MERGED with the SDD Framework's SECURITY_UNIVERSAL.
> You can ADD rules and INCREASE rigor, but cannot REMOVE baseline rules.
> To mark a baseline rule as not applicable, use: SEC-REQ-XXX: N/A — [justification]

## Project-Specific Rules

### [Category]
[Rules specific to this project that go beyond the universal baseline]

## Overrides
[List any SEC-REQ IDs marked as N/A with justification]

- SEC-REQ-UPLOAD-01: N/A — this project has no file upload functionality
```

- [ ] **Step 6: Commit**

```bash
git add sdd/framework/inputs/
git commit -m "feat(sdd): add input doc types and templates"
```

---

## Phase 3: Skill Commands

### Task 11: Skill entry point (skill.md)

**Files:**
- Create: `sdd/skill.md`

- [ ] **Step 1: Write skill.md**

Create `sdd/skill.md`:

```markdown
---
name: sdd
description: >
  SDD Framework — Generate and maintain structured software design documents
  (requirements, design, tasks, tests) from project input docs. Includes
  embedded security, bidirectional traceability, and TDD test generation.
  Use /sdd to see available commands.
---

# SDD Framework

You are the SDD (Software Design Documents) framework skill. You help users
generate and maintain 4 structured artifacts from their project documentation:
requirements, design, tasks, and tests.

## Available Commands

| Command | Description |
|---------|-------------|
| `/sdd init` | Initialize SDD in a project — set level, language, stack, inputs |
| `/sdd requirements` | Generate requirements.md from input docs |
| `/sdd design` | Generate design.md from requirements |
| `/sdd tasks` | Generate tasks.md from design + requirements |
| `/sdd tests` | Generate tests.md + RED test files |
| `/sdd validate` | Full validation — coverage matrix, security audit, gaps |
| `/sdd update [artifact]` | Update an artifact and check downstream impact |
| `/sdd status` | Show current SDD state, coverage, next steps |

## Routing

When the user invokes `/sdd` with no arguments, display the table above
with a brief explanation of each command.

When the user invokes `/sdd <command>`, read the corresponding command
file from `commands/<command>.md` and follow its instructions.

## Core Rules

1. **Read sdd.config.yaml first** — every command (except init) must read
   the config before proceeding. If it doesn't exist, tell the user to
   run `/sdd init` first.

2. **Security is non-negotiable** — always inject security requirements,
   properties, and tests at full rigor regardless of formalism level.
   Read `framework/security/SECURITY_UNIVERSAL.md` before generating
   any artifact.

3. **Traceability is mandatory** — every generated element must have
   cross-references. Use the ID conventions from `framework/SPEC.md §4`.

4. **Interactive by default** — when generating artifacts, identify
   ambiguities and ask the user one question at a time before generating.

5. **Validate after generation** — run light validation after every
   artifact generation. Report gaps inline.

6. **Language from config** — use `framework/i18n/<language>.yaml` for
   all section titles, labels, and messages in generated artifacts.
```

- [ ] **Step 2: Commit**

```bash
git add sdd/skill.md
git commit -m "feat(sdd): add skill entry point with command routing"
```

---

### Task 12: /sdd init command

**Files:**
- Create: `sdd/commands/init.md`

- [ ] **Step 1: Write init.md**

Create `sdd/commands/init.md`:

```markdown
---
name: init
description: Initialize SDD Framework in a project
---

# /sdd init

Initialize the SDD Framework in the current project. Creates `sdd.config.yaml`
and the output directory structure.

## Flow

### Step 1: Detect existing docs

Search the project for markdown files that could be input docs:
- Glob for `*.md`, `docs/**/*.md`, `doc/**/*.md`
- Exclude: README.md, CHANGELOG.md, LICENSE.md, node_modules, .git
- Present the list to the user

### Step 2: Auto-detect stack

Check for the following files and infer the stack:

| File | Inference |
|------|-----------|
| `package.json` | Node.js — read dependencies for framework (next, express, react, etc.) |
| `tsconfig.json` | TypeScript |
| `requirements.txt` / `pyproject.toml` | Python — read for framework (django, fastapi, flask) |
| `go.mod` | Go |
| `Cargo.toml` | Rust |
| `pom.xml` / `build.gradle` | Java — read for framework (spring-boot, quarkus) |
| `composer.json` | PHP — read for framework (laravel, symfony) |
| `index.html` (no framework detected) | HTML/CSS/JS vanilla |
| `prisma/schema.prisma` | Prisma ORM |
| `docker-compose.yml` | Read services for database, cache, etc. |
| `.env` / `.env.example` | Read var names to infer integrations |

Present what you detected and ask the user to confirm or correct.

### Step 3: Ask formalism level

Ask the user (one question):

> What formalism level should I use for this project's documentation?
>
> a) **Light** — Simple feature lists, basic diagrams. Good for scripts, tools, POCs.
> b) **Standard** — User stories, architecture diagrams, component interfaces. Good for SaaS, apps, APIs.
> c) **Formal** — SHALL/WHEN/IF criteria, glossary, Mermaid diagrams, detailed error handling. Good for fintech, healthcare, critical systems.
>
> Note: Security coverage is always FULL regardless of level.

### Step 4: Ask language

> What language should the generated artifacts use?
>
> a) **English**
> b) **Português Brasileiro**

### Step 5: Classify input docs

For each doc found in step 1, try to auto-classify:
- Read the first 200 lines
- Match against signals in `framework/inputs/recommended-types.md`
- If confident (>70%), suggest the type
- If not confident, ask the user

Present the classification and ask for confirmation.

### Step 6: Detect security features

Based on the input docs and stack, detect which security features apply:
- `has_authentication` — mentions login, auth, users, sessions
- `has_file_upload` — mentions upload, file, image, photo
- `has_public_endpoints` — has API routes, public pages
- `has_write_operations` — has forms, CRUD, database writes
- `has_personal_data` — mentions email, name, user data, LGPD/GDPR
- `has_payments` — mentions payment, checkout, pricing, gateway
- `has_forms` — mentions forms, input, submit
- `has_external_urls` — mentions external API, fetch, webhook

Present detections and ask user to confirm or adjust.

### Step 7: Generate sdd.config.yaml

Write `sdd.config.yaml` at project root with all collected information.
Use the structure from the spec (§8).

### Step 8: Create output directories

```bash
mkdir -p docs/sdd/reports
mkdir -p tests/properties tests/e2e tests/integration
```

(Use paths from sdd.config.yaml if user customized them.)

### Step 9: Confirm

Display:
```
SDD initialized!

Config: sdd.config.yaml
Level: [level]
Language: [language]
Stack: [stack summary]
Inputs: [N] docs classified
Security features: [list]

Next step: /sdd requirements
```
```

- [ ] **Step 2: Commit**

```bash
git add sdd/commands/init.md
git commit -m "feat(sdd): add /sdd init command"
```

---

### Task 13: /sdd requirements command

**Files:**
- Create: `sdd/commands/requirements.md`

- [ ] **Step 1: Write requirements.md**

Create `sdd/commands/requirements.md`:

```markdown
---
name: requirements
description: Generate requirements.md from project input docs
---

# /sdd requirements

Generate `requirements.md` by reading project input docs, asking clarifying
questions, and applying the appropriate template with security injection.

## Prerequisites

- `sdd.config.yaml` must exist (run `/sdd init` first)
- At least one input doc must be configured

## Flow

### Step 1: Load configuration

Read `sdd.config.yaml`. Load:
- `level` → select template from `framework/templates/requirements/<level>.template.md`
- `language` → load labels from `framework/i18n/<language>.yaml`
- `inputs` → list of input docs with types
- `security.features` → which SEC-REQs to inject

### Step 2: Read all input docs

Read every file listed in `inputs`. For each doc, extract:
- Features and functionality described
- Business rules and constraints
- User flows and interactions
- Data entities mentioned
- Non-functional requirements (performance, scaling, etc.)

### Step 3: Load security requirements

Read `framework/security/security-requirements.yaml`.
Filter categories by `applies_when` matching `security.features` from config.
These SEC-REQs will be injected regardless of formalism level.

If `security.project_security` is set in config, read that file too.
Merge: user rules add to baseline, never reduce.

### Step 4: Identify ambiguities

Analyze the extracted information and identify:
- Contradictions between input docs
- Missing information needed for requirements (e.g., limits, edge cases)
- Decisions the user needs to make (e.g., "the doc mentions X but doesn't specify Y")

### Step 5: Ask clarifying questions

Present ambiguities to the user ONE AT A TIME.
Prefer multiple-choice questions when possible.
Wait for each answer before asking the next.

Example:
> The product spec mentions "scheduled delivery" but doesn't define
> the maximum scheduling window. What should the limit be?
>
> a) 3 months
> b) 6 months
> c) 9 months
> d) Other (specify)

### Step 6: Generate requirements.md

Dispatch to `agents/requirements-agent.md` with:
- All input doc contents
- User's answers to questions
- Selected template
- i18n labels
- Filtered SEC-REQs to inject
- Formalism level rules from `framework/levels/<level>.md`

The agent generates the full `requirements.md` and writes it to
`<paths.output>/requirements.md`.

### Step 7: Light validation

Run validation checks from `framework/validation/rules.yaml` → `after_requirements`:
- Every input doc has >= 1 derived REQ
- All applicable SEC-REQs are present

If gaps found, report them inline and ask if the user wants to fix.

### Step 8: Present for review

Show a summary:
```
requirements.md generated!

- [N] functional requirements (REQ-001 to REQ-NNN)
- [M] security requirements (SEC-REQ-*)
- Derived from [K] input docs
- Validation: [PASS/GAPS FOUND]

Next step: /sdd design
```

Ask the user to review the file before proceeding.
```

- [ ] **Step 2: Commit**

```bash
git add sdd/commands/requirements.md
git commit -m "feat(sdd): add /sdd requirements command"
```

---

### Task 14: /sdd design command

**Files:**
- Create: `sdd/commands/design.md`

- [ ] **Step 1: Write design.md**

Create `sdd/commands/design.md`:

```markdown
---
name: design
description: Generate design.md from requirements
---

# /sdd design

Generate `design.md` by reading requirements.md, asking architectural
decisions, and applying the appropriate template with security properties.

## Prerequisites

- `sdd.config.yaml` must exist
- `requirements.md` must exist in output dir

## Flow

### Step 1: Load configuration

Read `sdd.config.yaml`. Load level, language, stack, security features.
Read `<paths.output>/requirements.md`.

### Step 2: Load security properties

Read `framework/security/security-properties.yaml`.
Filter by `applies_when` matching security features from config.

### Step 3: Analyze requirements

Extract from requirements.md:
- All REQ IDs and their acceptance criteria
- Data entities and their relationships
- External integrations needed
- User-facing flows
- All SEC-REQ IDs

### Step 4: Ask architectural decisions

For aspects not resolved by the requirements or stack config, ask the user
ONE QUESTION AT A TIME:

Examples:
> The requirements mention caching. What caching strategy?
> a) Redis / Upstash
> b) In-memory (framework built-in)
> c) Database-level cache
> d) No cache needed

> The requirements include file storage. What storage provider?
> a) Supabase Storage
> b) AWS S3
> c) Cloudflare R2
> d) Local filesystem (dev only)

Only ask about decisions that aren't already answered by the stack in config.

### Step 5: Generate design.md

Dispatch to `agents/design-agent.md` with:
- requirements.md content
- Stack from config
- User's architectural decisions
- Selected template
- i18n labels
- Filtered SEC-PROPs to inject
- Level rules

The agent generates the full `design.md` and writes it to
`<paths.output>/design.md`.

### Step 6: Light validation

Run `after_design` checks:
- Every REQ has >= 1 component referencing it
- Every PROP references valid REQ IDs
- All applicable SEC-PROPs are present

If gaps found: report and ask if user wants to backtrack to requirements.

### Step 7: Present for review

Show summary with component count, property count, validation result.
Ask user to review before proceeding to `/sdd tasks`.
```

- [ ] **Step 2: Commit**

```bash
git add sdd/commands/design.md
git commit -m "feat(sdd): add /sdd design command"
```

---

### Task 15: /sdd tasks command

**Files:**
- Create: `sdd/commands/tasks.md`

- [ ] **Step 1: Write tasks.md**

Create `sdd/commands/tasks.md`:

```markdown
---
name: tasks
description: Generate tasks.md from design + requirements
---

# /sdd tasks

Generate `tasks.md` — an ordered implementation plan derived from
design.md and requirements.md.

## Prerequisites

- `sdd.config.yaml` must exist
- `requirements.md` and `design.md` must exist in output dir

## Flow

### Step 1: Load configuration and artifacts

Read config, requirements.md, and design.md.
Extract all REQ IDs, PROP IDs, SEC-REQ IDs, SEC-PROP IDs, components.

### Step 2: Determine task ordering

Analyze dependencies between components:
- Infrastructure/config tasks first
- Security middleware early
- Data models before business logic
- Business logic before UI
- Integration tests after all components
- Checkpoints between logical blocks (formal level only)

### Step 3: Generate tasks.md

Dispatch to `agents/tasks-agent.md` with:
- requirements.md content
- design.md content
- Selected template
- i18n labels
- Level rules
- Ordering strategy

The agent generates the full `tasks.md` and writes it to
`<paths.output>/tasks.md`.

### Step 4: Light validation

Run `after_tasks` checks:
- Every TASK references >= 1 REQ
- Every REQ has >= 1 TASK
- Every PROP is referenced by at least 1 TASK's Tests field

If gaps found: report and ask if user wants to add missing tasks
or backtrack to design.

### Step 5: Present for review

Show summary with task count, coverage, validation result.
Ask user to review before proceeding to `/sdd tests`.
```

- [ ] **Step 2: Commit**

```bash
git add sdd/commands/tasks.md
git commit -m "feat(sdd): add /sdd tasks command"
```

---

### Task 16: /sdd tests command

**Files:**
- Create: `sdd/commands/tests.md`

- [ ] **Step 1: Write tests.md**

Create `sdd/commands/tests.md`:

```markdown
---
name: tests
description: Generate tests.md spec + RED test files
---

# /sdd tests

Generate `tests.md` (test specification) and actual test files that
all fail (RED) — ready for TDD implementation.

## Prerequisites

- `sdd.config.yaml` must exist
- `requirements.md`, `design.md`, and `tasks.md` must exist

## Flow

### Step 1: Load all artifacts

Read config and all 3 existing artifacts.
Extract: all REQ IDs, PROP IDs, SEC-PROP IDs, component interfaces,
acceptance criteria, stack (test framework, property testing lib).

### Step 2: Map tests to sources

For each source, determine which tests to generate:

| Source | Test type | Generated when |
|--------|-----------|---------------|
| PROP-* and SEC-PROP-* | Property-based tests | Pre-implementation (RED) |
| REQ-* acceptance criteria | E2E tests | Pre-implementation (RED) |
| Design interfaces/APIs | Integration/contract tests | Pre-implementation (RED) |
| TASK-* subtasks | Unit tests | Per-task (during implementation) |

### Step 3: Generate tests.md (spec)

Dispatch to `agents/tests-agent.md` with:
- All artifacts
- Test mapping from step 2
- Selected template
- i18n labels
- Stack info (test framework, property testing lib)

The agent generates `tests.md` (the tool-agnostic spec) and writes it to
`<paths.output>/tests.md`.

### Step 4: Generate RED test files

Using the stack info from config, generate actual test files:

- Property-based tests → `<paths.tests>/properties/`
- E2E tests → `<paths.tests>/e2e/`
- Integration tests → `<paths.tests>/integration/`

All tests MUST:
- Import the function/module they will test (which doesn't exist yet → RED)
- Have meaningful assertions derived from the PROP/REQ
- Include a comment with the test ID: `// TEST-PROP-001: [name]`
- FAIL when run (because implementation doesn't exist)

### Step 5: Light validation

Run `after_tests` checks:
- Every PROP has >= 1 test
- Every SEC-PROP has >= 1 test
- Every critical REQ has coverage
- Security tests are present

### Step 6: Verify RED

Run the test suite to confirm all tests fail:
```
[test_framework run command]
Expected: ALL FAIL (no implementation exists yet)
```

### Step 7: Present for review

Show summary:
```
tests.md generated!

- [N] property-based tests (RED)
- [M] e2e tests (RED)
- [K] integration tests (RED)
- [J] unit tests (spec only — generated per task during implementation)
- All [N+M+K] pre-implementation tests FAILING as expected

Test files written to: <paths.tests>/
Next step: Start implementation — make tests GREEN one by one
```
```

- [ ] **Step 2: Commit**

```bash
git add sdd/commands/tests.md
git commit -m "feat(sdd): add /sdd tests command"
```

---

### Task 17: /sdd validate command

**Files:**
- Create: `sdd/commands/validate.md`

- [ ] **Step 1: Write validate.md**

Create `sdd/commands/validate.md`:

```markdown
---
name: validate
description: Full validation — coverage matrix, security audit, gaps
---

# /sdd validate

Run full validation across all 4 artifacts. Generate a detailed report
with coverage matrix, security audit, gap analysis, and stats.

## Prerequisites

- `sdd.config.yaml` must exist
- At least `requirements.md` must exist (validates whatever is available)

## Flow

### Step 1: Load all available artifacts

Read config. Read whichever artifacts exist:
- requirements.md → extract REQ IDs, SEC-REQ IDs
- design.md → extract component refs, PROP IDs, SEC-PROP IDs
- tasks.md → extract TASK IDs with their Implements/Tests refs
- tests.md → extract TEST IDs with their Validates refs

### Step 2: Build coverage matrix

For every REQ (including SEC-REQs), trace the full chain:

```
REQ → Component (from design) → Property → Task → Test
```

Classify each REQ as:
- **COVERED** — has all 4 downstream links
- **PARTIAL** — missing one or more links
- **UNCOVERED** — no downstream links at all

### Step 3: Security audit

Read `framework/security/security-requirements.yaml` and
`framework/security/security-properties.yaml`.

For each applicable security category:
- Check if SEC-REQ exists in requirements.md
- Check if SEC-PROP exists in design.md
- Check if TASK implements it
- Check if TEST covers it

Classify as PASS / FAIL / N/A.

Also cross-reference the SECURITY_UNIVERSAL §14 checklist categories
against the artifacts.

### Step 4: Find gaps

Scan for:
- Broken references (ID referenced but doesn't exist)
- Orphan IDs (ID exists but never referenced by any other artifact)
- Missing cross-references (TASK without Implements, PROP without Validates)

### Step 5: Calculate stats

```
Requirements: [total] | Covered: [N] ([%])
Properties: [total] | With tests: [N] ([%])
Tasks: [total] | With req refs: [N] ([%])
Tests: [total] | Mapped to props/reqs: [N] ([%])
Security: [applicable] / [present] ([%])
```

### Step 6: Generate report

Dispatch to `agents/validation-agent.md` to format the report.

Write to `<paths.reports>/validation-YYYY-MM-DD.md`.

### Step 7: Display summary

Show the stats and any critical gaps in the terminal.
If there are FAIL items in the security audit, highlight them prominently.
```

- [ ] **Step 2: Commit**

```bash
git add sdd/commands/validate.md
git commit -m "feat(sdd): add /sdd validate command"
```

---

### Task 18: /sdd update command

**Files:**
- Create: `sdd/commands/update.md`

- [ ] **Step 1: Write update.md**

Create `sdd/commands/update.md`:

```markdown
---
name: update
description: Update an artifact and check downstream impact
---

# /sdd update [artifact]

Update an existing artifact after changes. Check what downstream
artifacts are impacted and offer to regenerate them.

## Usage

```
/sdd update requirements   — re-read input docs, regenerate requirements.md
/sdd update design         — re-read requirements, regenerate design.md
/sdd update tasks          — re-read design + requirements, regenerate tasks.md
/sdd update tests          — re-read all artifacts, regenerate tests.md
```

## Flow

### Step 1: Parse argument

Determine which artifact to update. If no argument, ask the user:
> Which artifact do you want to update?
> a) requirements
> b) design
> c) tasks
> d) tests

### Step 2: Read current state

Read the existing artifact. Read the sources it derives from.

### Step 3: Detect changes

Compare the current sources against what the artifact was generated from.
If the artifact was generated from requirements.md and requirements.md
has since changed, identify what changed:

- New REQs added
- REQs removed
- REQ criteria modified
- New SEC-REQs applicable (if security features changed)

### Step 4: Regenerate

Follow the same flow as the original generation command
(`/sdd requirements`, `/sdd design`, etc.) but:
- Pre-fill answers from the previous generation where possible
- Only ask new questions for new/changed content
- Preserve user customizations in the artifact where feasible

### Step 5: Impact analysis

After regeneration, identify downstream artifacts that may be stale:

```
update requirements → design, tasks, tests need review
update design       → tasks, tests need review
update tasks        → tests need review
update tests        → (nothing downstream)
```

Show impact:
```
requirements.md updated.

Impact analysis:
- REQ-012 added (new)
- REQ-005 criteria changed

Downstream artifacts affected:
- design.md: component for REQ-012 missing, PROP-003 may need update
- tasks.md: no TASK for REQ-012
- tests.md: tests for PROP-003 may need update

Would you like to update:
  a) design.md
  b) tasks.md
  c) tests.md
  d) all of the above
  e) none for now
```

### Step 6: Cascade (if requested)

If the user chooses to update downstream artifacts, run each update
in sequence, repeating the impact analysis at each step.
```

- [ ] **Step 2: Commit**

```bash
git add sdd/commands/update.md
git commit -m "feat(sdd): add /sdd update command"
```

---

### Task 19: /sdd status command

**Files:**
- Create: `sdd/commands/status.md`

- [ ] **Step 1: Write status.md**

Create `sdd/commands/status.md`:

```markdown
---
name: status
description: Show current SDD state, coverage, next steps
---

# /sdd status

Display the current state of SDD artifacts in the project.

## Flow

### Step 1: Check if initialized

If `sdd.config.yaml` doesn't exist:
```
SDD not initialized. Run /sdd init to get started.
```

### Step 2: Read config and artifacts

Read `sdd.config.yaml`.
Check which artifacts exist in `<paths.output>`:
- requirements.md
- design.md
- tasks.md
- tests.md

For each existing artifact, extract basic stats:
- requirements.md: count REQs, count SEC-REQs, last modified date
- design.md: count components, count PROPs, last modified date
- tasks.md: count TASKs (total and completed), last modified date
- tests.md: count TESTs by type, last modified date

### Step 3: Quick coverage check

If multiple artifacts exist, run a quick cross-reference:
- Count REQs covered by at least 1 TASK
- Count PROPs covered by at least 1 TEST
- Calculate coverage percentage

### Step 4: Determine next step

Based on what exists:
- No artifacts → "Next step: /sdd requirements"
- Only requirements → "Next step: /sdd design"
- requirements + design → "Next step: /sdd tasks"
- requirements + design + tasks → "Next step: /sdd tests"
- All 4 → "Next step: /sdd validate or start implementation"

Check if any artifact is stale (source modified after artifact).

### Step 5: Display

```
SDD Status — [project.name]
Level: [level] | Language: [language]

Artifacts:
  ✅ requirements.md  ([N] REQs + [M] SEC-REQs, last updated [date])
  ✅ design.md         ([N] components, [M] PROPs, last updated [date])
  ⚠️  tasks.md          (needs review — REQ-012 added since last generation)
  ❌ tests.md          (not generated yet)

Coverage: [N]% (see /sdd validate for details)
Next step: [recommendation]
```
```

- [ ] **Step 2: Commit**

```bash
git add sdd/commands/status.md
git commit -m "feat(sdd): add /sdd status command"
```

---

## Phase 4: Agents

### Task 20: Requirements generation agent

**Files:**
- Create: `sdd/agents/requirements-agent.md`

- [ ] **Step 1: Write requirements-agent.md**

Create `sdd/agents/requirements-agent.md`:

```markdown
# Requirements Generation Agent

You are a requirements engineering agent for the SDD Framework. Your job is
to generate a `requirements.md` file from project input docs, user answers,
and security requirements.

## Inputs You Receive

1. **Input doc contents** — full text of all project input docs
2. **User answers** — answers to clarifying questions asked by the orchestrator
3. **Template** — the requirements template for the selected formalism level
4. **i18n labels** — section titles and labels in the target language
5. **SEC-REQs** — security requirements to inject (pre-filtered by applies_when)
6. **Level rules** — formalism rules from the level definition file

## Your Task

Generate a complete `requirements.md` following the template structure.

### Rules

1. **Every requirement gets a unique ID**: REQ-001, REQ-002, ...
   Security requirements keep their SEC-REQ-* IDs.

2. **Every requirement traces its origin**: `Derives from: INPUT:<type> §<section>`
   Security requirements trace to: `Derives from: SECURITY_UNIVERSAL §<section>`

3. **Follow the formalism level strictly**:
   - Light: feature list + brief description + bullet criteria
   - Standard: user stories + numbered acceptance criteria
   - Formal: glossary + SHALL/WHEN/IF + numbered criteria

4. **Inject ALL provided SEC-REQs** in a separate section at the end.
   Use the exact criteria text from the YAML. Add the i18n note that
   these are auto-generated and should not be removed.

5. **Use i18n labels** for all section titles, field labels, and messages.

6. **No placeholders**: every requirement must have concrete, testable criteria.
   If information is missing and wasn't resolved by user answers, flag it
   with a `<!-- REVIEW: [what's missing] -->` comment.

7. **Extract implicit requirements**: input docs often imply requirements
   without stating them explicitly. Extract these as separate REQs.
   Example: if the product spec describes a user flow with upload, derive
   upload validation requirements even if not explicitly stated.

8. **Group logically**: group related requirements together (e.g., all auth
   requirements, all payment requirements, all content generation requirements).

## Output

Write the complete `requirements.md` to the output path.
Return a summary: total REQs, total SEC-REQs, any flagged items.
```

- [ ] **Step 2: Commit**

```bash
git add sdd/agents/requirements-agent.md
git commit -m "feat(sdd): add requirements generation agent"
```

---

### Task 21: Design generation agent

**Files:**
- Create: `sdd/agents/design-agent.md`

- [ ] **Step 1: Write design-agent.md**

Create `sdd/agents/design-agent.md`:

```markdown
# Design Generation Agent

You are a technical design agent for the SDD Framework. Your job is to
generate a `design.md` file from requirements, stack decisions, and
security properties.

## Inputs You Receive

1. **requirements.md content** — all REQs and SEC-REQs
2. **Stack info** — from sdd.config.yaml (language, framework, ORM, database, etc.)
3. **User's architectural decisions** — answers to design questions
4. **Template** — design template for the selected formalism level
5. **i18n labels** — section titles and labels
6. **SEC-PROPs** — security properties to inject (pre-filtered by applies_when)
7. **Level rules** — formalism rules

## Your Task

Generate a complete `design.md` following the template structure.

### Rules

1. **Architecture must reflect the stack**: use the actual technologies
   from the config. If the stack is Next.js + Prisma, show Next.js
   directory structure and Prisma schema. If Django, show Django
   project structure and models.

2. **Every component references requirements**: each component, endpoint,
   or service must have `Implements: REQ-NNN` cross-references.

3. **Correctness Properties are mandatory**: generate properties for
   every significant invariant in the system. Each property must:
   - Have a unique ID: PROP-001, PROP-002, ...
   - State a universal quantification: "For any X that satisfies..."
   - Reference the REQs it validates: `Validates: REQ-NNN`

4. **Inject ALL provided SEC-PROPs**: use the exact statement text
   from the YAML. Keep their SEC-PROP-* IDs.

5. **Data models must be complete**: define all entities, fields, types,
   constraints, relations, and indexes in the project's ORM syntax.

6. **Use i18n labels** for all section titles.

7. **Follow level rules**:
   - Light: overview + stack table + basic models + 1-3 PROPs
   - Standard: + architecture diagram + components with interfaces
   - Formal: + Mermaid diagrams + full interfaces + error handling

8. **Interface definitions must be in the project language**: if the
   stack is TypeScript, show TypeScript interfaces. If Python, show
   type hints or dataclasses. If Java, show classes/interfaces.

9. **Design for security**: beyond injecting SEC-PROPs, ensure the
   architecture itself reflects security (e.g., validation layer,
   auth middleware, rate limiting middleware, IDOR guard pattern).

## Output

Write the complete `design.md` to the output path.
Return a summary: component count, PROP count, SEC-PROP count,
any items needing review.
```

- [ ] **Step 2: Commit**

```bash
git add sdd/agents/design-agent.md
git commit -m "feat(sdd): add design generation agent"
```

---

### Task 22: Tasks generation agent

**Files:**
- Create: `sdd/agents/tasks-agent.md`

- [ ] **Step 1: Write tasks-agent.md**

Create `sdd/agents/tasks-agent.md`:

```markdown
# Tasks Generation Agent

You are an implementation planning agent for the SDD Framework. Your job
is to generate `tasks.md` — an ordered implementation plan derived from
design.md and requirements.md.

## Inputs You Receive

1. **requirements.md content** — all REQs and SEC-REQs
2. **design.md content** — architecture, components, PROPs, data models
3. **Template** — tasks template for the selected formalism level
4. **i18n labels** — section titles and labels
5. **Level rules** — formalism rules
6. **Stack info** — from config

## Your Task

Generate a complete `tasks.md` with ordered, implementable tasks.

### Rules

1. **Task ordering matters**: dependencies determine order.
   General order:
   - Project setup and infrastructure (config, database, env vars)
   - Security middleware (rate limiting, IDOR guard, validation)
   - Authentication and storage
   - Data validation schemas
   - Core business logic (in dependency order)
   - UI components
   - Integration with external services
   - Analytics and monitoring
   - Final integration and E2E verification

2. **Every task references requirements**:
   `Implements: REQ-NNN, REQ-MMM`

3. **Every task that involves testable behavior references properties**:
   `Tests: PROP-NNN`

4. **Subtask granularity** (standard + formal levels):
   Each subtask should be a single implementable action.
   Include test-related subtasks where applicable.

5. **Checkpoints** (formal level only):
   Insert checkpoint tasks between logical blocks.
   Checkpoints verify that everything up to that point works.
   Example: "Checkpoint — verify security middleware + all tests pass"

6. **Security tasks early**: security infrastructure (middleware,
   validation, rate limiting) should be among the first tasks,
   not an afterthought.

7. **Use i18n labels** for section titles.

8. **Reference SECURITY_UNIVERSAL**: in the overview section, add a
   note that the security doc must be read before implementing any
   endpoint, form, upload, or payment logic.

## Output

Write the complete `tasks.md` to the output path.
Return a summary: total tasks, total subtasks, checkpoint count.
```

- [ ] **Step 2: Commit**

```bash
git add sdd/agents/tasks-agent.md
git commit -m "feat(sdd): add tasks generation agent"
```

---

### Task 23: Tests generation agent

**Files:**
- Create: `sdd/agents/tests-agent.md`

- [ ] **Step 1: Write tests-agent.md**

Create `sdd/agents/tests-agent.md`:

```markdown
# Tests Generation Agent

You are a test specification agent for the SDD Framework. Your job is to
generate `tests.md` (tool-agnostic spec) AND actual test files (stack-specific)
that all FAIL (RED) — ready for TDD implementation.

## Inputs You Receive

1. **requirements.md content** — REQs with acceptance criteria
2. **design.md content** — PROPs, SEC-PROPs, component interfaces
3. **tasks.md content** — TASK list with refs
4. **Template** — tests template for the selected formalism level
5. **i18n labels** — section titles and labels
6. **Stack info** — test_framework, property_testing, language

## Your Task

### Part 1: Generate tests.md (spec)

Follow the template structure. For each test:
- Assign a unique ID: TEST-PROP-NNN, TEST-E2E-NNN, TEST-INT-NNN
- Reference the PROP or REQ it validates
- Describe what to test, inputs, expected outcome

### Part 2: Generate RED test files

Create actual test files using the project's test framework.

**File placement:**
- Property-based tests → `<paths.tests>/properties/<name>.test.<ext>`
- E2E tests → `<paths.tests>/e2e/<name>.test.<ext>`
- Integration tests → `<paths.tests>/integration/<name>.test.<ext>`

**Test file rules:**

1. **Import what doesn't exist yet**: the test must import the function,
   class, or module it will test. Since implementation doesn't exist,
   this import will fail → RED.

2. **Write real assertions**: don't write `expect(true).toBe(false)`.
   Write the actual assertion that will pass once the code is implemented.
   The test fails because the import fails, not because of a fake assertion.

3. **Include the test ID as a comment**:
   ```
   // TEST-PROP-001: Idempotent webhook processing
   // Validates: REQ-005, REQ-006
   ```

4. **Property-based tests** must use the property testing library
   from the stack config (e.g., fast-check for JS/TS, hypothesis for
   Python). Define generators for random inputs and assert the property.

5. **E2E tests** should set up the scenario from the user story,
   execute the flow, and assert the final state.

6. **Integration tests** should call the endpoint/interface with a
   specific input and assert the response shape and status code.

7. **Per-task unit tests**: DO NOT generate these as files. List them
   in tests.md only. They will be generated during implementation
   alongside each task.

### Adaptation by stack

| Stack | Test framework | Property testing | File extension |
|-------|---------------|-----------------|---------------|
| Node/TS | vitest / jest | fast-check | `.test.ts` |
| Python | pytest | hypothesis | `_test.py` |
| Go | testing | rapid | `_test.go` |
| Java | JUnit | jqwik | `Test.java` |
| PHP | PHPUnit | — | `Test.php` |
| Rust | cargo test | proptest | `.rs` (in tests/) |

## Output

Write `tests.md` to the output path.
Write test files to the test directories.
Return a summary: counts by type, confirmation that all tests are RED.
```

- [ ] **Step 2: Commit**

```bash
git add sdd/agents/tests-agent.md
git commit -m "feat(sdd): add tests generation agent"
```

---

### Task 24: Validation agent

**Files:**
- Create: `sdd/agents/validation-agent.md`

- [ ] **Step 1: Write validation-agent.md**

Create `sdd/agents/validation-agent.md`:

```markdown
# Validation Agent

You are a validation agent for the SDD Framework. Your job is to
cross-reference all artifacts and generate a validation report.

## Inputs You Receive

1. **All existing artifacts** — requirements.md, design.md, tasks.md, tests.md
2. **Validation rules** — from `framework/validation/rules.yaml`
3. **Security requirements and properties YAMLs** — for security audit
4. **Security features** — from sdd.config.yaml
5. **i18n labels** — for report formatting

## Your Task

Generate a comprehensive validation report.

### Section 1: Coverage Matrix

Build a table mapping every REQ to its full implementation chain:

```markdown
| REQ | Component | Property | Task | Test | Status |
|-----|-----------|----------|------|------|--------|
```

For each REQ (including SEC-REQs):
- Find which component `Implements` it (from design.md)
- Find which PROP `Validates` it (from design.md)
- Find which TASK `Implements` it (from tasks.md)
- Find which TEST `Validates` it (from tests.md)
- Status: COVERED (all links), PARTIAL (some links), UNCOVERED (no links)

### Section 2: Security Audit

For each category in `security-requirements.yaml` where `applies_when`
matches the project's security features:

1. Check if the SEC-REQ is present in requirements.md
2. Check if the corresponding SEC-PROP is present in design.md
3. Check if a TASK implements it
4. Check if a TEST covers it

Classify as:
- **PASS** — full chain present
- **FAIL** — any link missing
- **N/A** — applies_when doesn't match project features

Also cross-reference the SECURITY_UNIVERSAL §14 checklist categories.

### Section 3: Gaps

Scan for:
- **Broken references**: an ID referenced by an artifact that doesn't exist
  in the artifact it should be in. E.g., TASK says "Implements: REQ-099"
  but REQ-099 doesn't exist.
- **Orphan IDs**: an ID that exists but is never referenced by any
  downstream artifact. E.g., PROP-007 exists in design.md but no
  TASK references it and no TEST validates it.
- **Missing cross-refs**: a TASK without any `Implements:` line, or
  a PROP without any `Validates:` line.

### Section 4: Stats

Calculate:
```
Requirements: [total] | Covered: [N] ([%])
Properties: [total] | With tests: [N] ([%])
Tasks: [total] | With req refs: [N] ([%])
Tests: [total] | Mapped: [N] ([%])
Security: [applicable] / [present] ([%])
Overall coverage: [%]
```

## Output

Write the validation report to `<paths.reports>/validation-YYYY-MM-DD.md`.
Return the stats summary and any critical issues (FAIL in security audit,
UNCOVERED requirements).
```

- [ ] **Step 2: Commit**

```bash
git add sdd/agents/validation-agent.md
git commit -m "feat(sdd): add validation agent"
```

---

## Phase 5: Final Integration

### Task 25: End-to-end verification

- [ ] **Step 1: Verify directory structure**

Run `find sdd/ -type f | sort` and verify all expected files exist:

```
sdd/skill.md
sdd/commands/init.md
sdd/commands/requirements.md
sdd/commands/design.md
sdd/commands/tasks.md
sdd/commands/tests.md
sdd/commands/validate.md
sdd/commands/update.md
sdd/commands/status.md
sdd/framework/SPEC.md
sdd/framework/levels/light.md
sdd/framework/levels/standard.md
sdd/framework/levels/formal.md
sdd/framework/templates/requirements/light.template.md
sdd/framework/templates/requirements/standard.template.md
sdd/framework/templates/requirements/formal.template.md
sdd/framework/templates/design/light.template.md
sdd/framework/templates/design/standard.template.md
sdd/framework/templates/design/formal.template.md
sdd/framework/templates/tasks/light.template.md
sdd/framework/templates/tasks/standard.template.md
sdd/framework/templates/tasks/formal.template.md
sdd/framework/templates/tests/light.template.md
sdd/framework/templates/tests/standard.template.md
sdd/framework/templates/tests/formal.template.md
sdd/framework/inputs/recommended-types.md
sdd/framework/inputs/templates/product-spec.template.md
sdd/framework/inputs/templates/brand-guide.template.md
sdd/framework/inputs/templates/business-plan.template.md
sdd/framework/inputs/templates/security-guidelines.template.md
sdd/framework/security/SECURITY_UNIVERSAL.md
sdd/framework/security/security-requirements.yaml
sdd/framework/security/security-properties.yaml
sdd/framework/validation/rules.yaml
sdd/framework/validation/coverage-matrix.md
sdd/framework/i18n/en.yaml
sdd/framework/i18n/pt-br.yaml
sdd/agents/requirements-agent.md
sdd/agents/design-agent.md
sdd/agents/tasks-agent.md
sdd/agents/tests-agent.md
sdd/agents/validation-agent.md
```

Expected: 38 files total.

- [ ] **Step 2: Verify cross-references in SPEC.md**

Read `sdd/framework/SPEC.md` and verify that every section it references
(levels, security, validation, templates) corresponds to actual files.

- [ ] **Step 3: Verify skill.md routes to all commands**

Read `sdd/skill.md` and verify that every command listed in the routing
table has a corresponding file in `sdd/commands/`.

- [ ] **Step 4: Verify security YAML IDs match**

Read `security-requirements.yaml` and `security-properties.yaml`.
Verify that every `validates` field in a SEC-PROP matches an existing
SEC-REQ `id` in the requirements YAML.

- [ ] **Step 5: Install skill for testing**

Copy or symlink the `sdd/` directory to the Claude Code plugins location:

```bash
cp -r sdd/ ~/.claude/plugins/sdd/
```

- [ ] **Step 6: Test /sdd command**

Invoke `/sdd` (no arguments) and verify it displays the help table
with all 8 commands.

- [ ] **Step 7: Commit final state**

```bash
git add -A
git commit -m "feat(sdd): complete SDD Framework v1.0 — framework + skill"
```

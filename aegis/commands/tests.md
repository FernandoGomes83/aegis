---
name: tests
description: Generate tests.md spec + RED test files
---

# `/aegis tests` Command

Generate the `tests.md` artifact and RED (failing) test files for every
verifiable property, requirement, and security control in the project.

---

## Prerequisites

Before running this command, verify that the following files exist in the
project root (or the `output.dir` configured in `.aegis/config.yaml`):

| File | Purpose |
|------|---------|
| `.aegis/config.yaml` | Framework configuration — stack, test_framework, property_testing |
| `requirements.md` | Source of REQ-NNN and SEC-REQ-* IDs and acceptance criteria |
| `design.md` | Source of PROP-NNN, SEC-PROP-* IDs and interface definitions |
| `tasks.md` | Source of TASK-NNN IDs and subtask breakdowns |

If any of these files is missing, stop and report which files are absent.
Tell the user which Aegis command to run first:

- Missing `.aegis/config.yaml` → run `/aegis init`
- Missing `requirements.md` → run `/aegis requirements`
- Missing `design.md` → run `/aegis design`
- Missing `tasks.md` → run `/aegis tasks`

---

## Step 1 — Load All Artifacts

Read and parse every artifact in order. Extract the following:

### From `.aegis/config.yaml`

- `project.name` — used in the tests.md header
- `project.language` — select the i18n label set from `aegis/framework/i18n/`
- `formalism` — controls test depth (light / standard / formal); never affects security
- `stack.test_framework` — the testing tool to use for RED test files (e.g., `vitest`, `pytest`, `jest`, `go test`, `rspec`)
- `stack.property_testing` — the property-based testing library (e.g., `fast-check`, `hypothesis`, `gopter`, `rantly`)
- `output.dir` — directory where tests.md and test files are written (default: `.aegis/`)

### From `requirements.md`

- All **REQ-NNN** IDs with their acceptance criteria (WHEN/SHALL/THEN clauses)
- All **SEC-REQ-*** IDs with their verification criteria
- Mark any REQ-NNN whose acceptance criteria contain conditional branches
  (WHEN/IF/UNLESS) — these require multiple E2E scenarios, one per branch

### From `design.md`

- All **PROP-NNN** IDs with their behavioral statements
- All **SEC-PROP-*** IDs with their formal property statements (the
  "For any X..." quantifications)
- All interface definitions, API contracts, and service-to-service
  interaction points — these become integration / contract tests
- The design's stack annotations (cross-check against config)

### From `tasks.md`

- All **TASK-NNN** IDs with their labels and subtask breakdowns
- Tasks that reference SEC-PROP-* must have corresponding TEST-SEC-* entries

---

## Step 2 — Map Tests to Sources

Use this mapping table to determine the test type and timing for each source ID:

| Source | Test type | Namespace | When to write |
|--------|-----------|-----------|---------------|
| PROP-NNN (behavioral statement) | Property-based | TEST-PROP-NNN | Pre-implementation (RED) |
| SEC-PROP-* (security property statement) | Property-based + Security | TEST-SEC-* | Pre-implementation (RED) |
| REQ-NNN acceptance criteria — primary path | E2E happy path | TEST-E2E-NNN-HAPPY | Pre-implementation (RED) |
| REQ-NNN acceptance criteria — error/failure paths | E2E failure path | TEST-E2E-NNN-FAIL | Pre-implementation (RED) |
| REQ-NNN acceptance criteria — each WHEN/IF branch | E2E branch | TEST-E2E-NNN-BRANCH-N | Pre-implementation (RED) |
| Design interfaces / API contracts | Integration / contract | TEST-INT-NNN | Pre-implementation (RED) |
| TASK-NNN subtasks | Unit tests | (no ID — written per task) | During implementation |

**Rules:**

1. Every PROP-NNN must produce at least one TEST-PROP-NNN.
2. Every SEC-PROP-* must produce at least one TEST-SEC-* entry — this is
   non-negotiable and cannot be suppressed at any formalism level.
3. Every REQ-NNN must produce at least one E2E test (happy path). For Standard
   and Formal levels, every named failure condition or WHEN/IF branch in the
   acceptance criteria must also have a corresponding E2E entry.
4. Design interfaces and cross-service boundaries must produce at least one
   integration test each. At Formal level, every external API dependency also
   requires a consumer-driven contract test.
5. TASK-NNN unit tests are listed descriptively in the per-task section of
   tests.md but do not have pre-assigned TEST-* IDs — they are written by the
   developer during task implementation.

---

## Step 3 — Generate tests.md

Dispatch to `aegis/agents/tests-agent.md` with the full parsed context from
Step 1 and the test map from Step 2.

The agent writes `tests.md` (path: `{output.dir}/tests.md`) using the
template for the configured formalism level:

- Light → `aegis/framework/templates/tests/light.template.md`
- Standard → `aegis/framework/templates/tests/standard.template.md`
- Formal → `aegis/framework/templates/tests/formal.template.md`

The generated file must be **tool-agnostic** — it describes WHAT to test and
asserts WHAT the outcome must be, without containing any framework-specific
test code. Actual test code lives in the files generated in Step 4.

### Required sections in tests.md (all levels)

1. **Test Strategy** — stack, test framework, property testing library, and
   a one-paragraph description of the overall test approach calibrated to
   the formalism level.

2. **Pre-Implementation Tests** — all RED tests organized by type:
   - Property-based tests (TEST-PROP-NNN and TEST-SEC-*)
   - End-to-end tests (TEST-E2E-NNN-*)
   - Integration / contract tests (TEST-INT-NNN) [Standard and Formal only]

3. **Security Tests** (auto-injected, never omitted) — one TEST-SEC-* block
   per SEC-PROP-* entry. Each block must include:
   - The SEC-PROP-* ID it targets
   - The SEC-REQ-* it traces back to
   - A concrete scenario with specific inputs, actions, and expected outcomes
   - A reference to SECURITY_UNIVERSAL §14 checklist

4. **Per-Task Tests** — a descriptive list of TASK-NNN entries from tasks.md
   indicating what unit tests must be written during implementation. No
   pre-assigned IDs. At Formal level, include explicit assertion descriptions.

5. **Validation Notes** — output of the light validation pass (Step 5).

### ID assignment

Assign TEST-* IDs sequentially within each namespace:

- `TEST-PROP-NNN` — three-digit zero-padded, matching the PROP-NNN they test
  (e.g., PROP-003 → TEST-PROP-003). If a property has multiple tests, append
  a suffix: TEST-PROP-003-A, TEST-PROP-003-B.
- `TEST-E2E-NNN-*` — NNN matches the REQ-NNN, suffix identifies scenario
  (HAPPY, FAIL, BRANCH-1, BRANCH-2, etc.).
- `TEST-INT-NNN` — sequential three-digit IDs starting at 001.
- `TEST-SEC-*` — key matches the SEC-PROP-* key (e.g., SEC-PROP-INPUT →
  TEST-SEC-INPUT).

---

## Step 4 — Generate RED Test Files

Write actual test files using the project's configured `test_framework` and
`property_testing` library. These files are the RED phase of TDD — they must
import code that does not exist yet and must fail when run.

### File locations

| Test type | Directory | File naming convention |
|-----------|-----------|----------------------|
| Property-based (PROP-* and SEC-PROP-*) | `tests/properties/` | `{prop-id}.test.{ext}` |
| End-to-end (REQ-*) | `tests/e2e/` | `{req-id}.test.{ext}` |
| Integration / contract | `tests/integration/` | `{int-id}.test.{ext}` |

Use the file extension appropriate for the project language:
`.test.ts` / `.test.js` for JavaScript/TypeScript, `.py` for Python,
`_test.go` for Go, `_spec.rb` for Ruby, etc.

### Rules for every generated test file

1. **Import what does not exist yet.** Import the modules, functions, classes,
   or API clients that the implementation will provide. These imports cause
   compilation or import errors on an empty codebase, confirming RED status.

2. **Write real assertions.** Use the test framework's native assertion
   mechanisms. Do not use `expect(true).toBe(true)` placeholders — write the
   actual condition the implementation must satisfy.

3. **Include the TEST-* ID as a comment** at the top of each test function or
   `it()`/`test()` block:
   ```
   // TEST-PROP-003
   // TEST-SEC-INPUT
   ```

4. **The test MUST fail on an empty codebase.** This is the fundamental RED
   requirement. Failure modes include:
   - Import/module-not-found errors (acceptable)
   - Assertion failures because the tested function returns `undefined` or throws
   - Type errors because the expected interface does not exist

5. **For property-based tests**, use the configured `property_testing` library
   to generate random inputs. The property under test must be expressed as a
   universal quantification: "for all valid inputs of type X, the system
   satisfies condition Y."

6. **For security tests**, the scenario must be adversarial:
   - Malformed or oversized inputs
   - IDs belonging to other users (IDOR)
   - Requests that exceed rate limits
   - Concurrent identical requests (race conditions)
   - Unauthenticated requests to protected resources

### Example — TypeScript / Vitest + fast-check (property test)

```typescript
// TEST-PROP-003-A: Input validation — schema rejects invalid payloads
import { describe, it, expect } from 'vitest'
import * as fc from 'fast-check'
import { validateUserInput } from '../../src/lib/validation' // does not exist yet → RED

describe('TEST-PROP-003-A: Input validation property', () => {
  it('rejects any payload where a field exceeds max length', () => {
    fc.assert(
      fc.property(
        fc.string({ minLength: 256, maxLength: 1000 }),
        (oversizedName) => {
          const result = validateUserInput({ name: oversizedName })
          expect(result.success).toBe(false)
          expect(result.errors).toContainEqual(
            expect.objectContaining({ field: 'name' })
          )
        }
      )
    )
  })
})
```

### Example — TypeScript / Vitest (E2E test)

```typescript
// TEST-E2E-001-HAPPY: New user completes registration flow
import { describe, it, expect, beforeEach, afterEach } from 'vitest'
import { createTestClient } from '../../src/test-utils/client' // does not exist yet → RED
import { resetTestDatabase } from '../../src/test-utils/db'   // does not exist yet → RED

describe('TEST-E2E-001-HAPPY: User registration — happy path', () => {
  beforeEach(() => resetTestDatabase())
  afterEach(() => resetTestDatabase())

  it('creates a verified user account and returns a session token', async () => {
    const client = createTestClient()
    const response = await client.post('/api/auth/register', {
      email: 'newuser@example.com',
      password: 'ValidP@ss123',
      name: 'Test User',
    })
    expect(response.status).toBe(201)
    expect(response.body).toHaveProperty('sessionToken')
    expect(response.body.user.email).toBe('newuser@example.com')
  })
})
```

### Example — TypeScript / Vitest (security / IDOR test)

```typescript
// TEST-SEC-IDOR: IDOR — user cannot access another user's resource
import { describe, it, expect } from 'vitest'
import { createAuthenticatedClient } from '../../src/test-utils/client' // RED
import { seedUsers, seedResource } from '../../src/test-utils/seeds'     // RED

describe('TEST-SEC-IDOR: Ownership enforcement on resource endpoints', () => {
  it('returns HTTP 404 when requesting a resource owned by another user', async () => {
    const [userA, userB] = await seedUsers(2)
    const resource = await seedResource({ ownerId: userA.id })
    const clientB = createAuthenticatedClient(userB)

    const response = await clientB.get(`/api/resources/${resource.id}`)

    // Must return 404, not 403 — unowned resources are indistinguishable from non-existent
    expect(response.status).toBe(404)
  })
})
```

If the project does not use TypeScript/JavaScript, adapt the examples to the
configured language and frameworks. The structural rules (imports RED, real
assertions, TEST-* ID comment, adversarial scenarios for security) are
language-agnostic and must always be followed.

---

## Step 5 — Light Validation

After generating tests.md and the RED test files, run the following validation
checks. Report each check as PASS or FAIL with details.

### Critical checks (block advancement if any fail)

| Check ID | Check | Failure message |
|----------|-------|-----------------|
| VAL-TEST-01 | Every PROP-NNN in design.md has at least one TEST-PROP-NNN | "PROP-{id} has no test — add TEST-PROP-{id} or TEST-PROP-{id}-A/B" |
| VAL-TEST-02 | Every SEC-REQ-* has a corresponding TEST-SEC-* | "SEC-REQ-{id} is not covered — add TEST-SEC-{key} targeting SEC-PROP-{key}" |
| VAL-TEST-03 | tests.md contains a TEST-SEC-* section | "TEST-SEC-* section is missing — security tests are mandatory" |
| VAL-TEST-03b | tests.md references SECURITY_UNIVERSAL §14 checklist | "§14 checklist reference missing — add it to the Security Tests section" |
| VAL-TEST-04 | No duplicate TEST-* IDs in tests.md | "Duplicate ID: TEST-{id} appears more than once" |
| VAL-TEST-05 | Every "Tests:" reference points to an ID in design.md or requirements.md | "Broken reference: TEST-{id} references {target} which does not exist" |

### Warning checks (report but do not block)

| Check ID | Check | Warning message |
|----------|-------|-----------------|
| VAL-TEST-W01 | Every REQ-NNN has at least one E2E test | "REQ-{id} has no E2E test — consider adding TEST-E2E-{id}-HAPPY" |
| VAL-TEST-W02 | Every REQ-NNN with WHEN/IF branches has one test per branch | "REQ-{id} has {n} branches but only {m} E2E tests — some branches may be untested" |
| VAL-TEST-W03 | At Formal level, every external API has a contract test | "Interface {name} has no contract test (TEST-INT-*) — required at Formal level" |

If any critical check fails, stop and report the failures. Do not proceed to
Step 6. Provide specific fix instructions for each failure.

---

## Step 6 — Verify RED Status

Run the test suite to confirm all generated tests are in the RED (failing) state.

```bash
# The exact command depends on the configured test_framework.
# Examples:
#   vitest run tests/
#   pytest tests/
#   go test ./tests/...
#   bundle exec rspec tests/
```

Parse the test runner output and confirm:

1. **Every generated test fails.** A test that passes on an empty codebase is
   broken — it is not testing anything real. Report it as an error.
2. **No test runner crashes** with an unrecoverable error (e.g., syntax error
   in the test file itself). If a test file has a syntax error, fix it and
   re-run. The import errors that cause RED are expected — they come from
   missing implementation modules, not from the test file itself.
3. If some tests pass accidentally, investigate whether:
   - The implementation already exists (in which case, those tests are GREEN
     and correct — note them as already-passing tests in the summary)
   - The test was incorrectly written (always-pass assertion) — fix the test

If the test runner is not available in the current environment, note that
manual RED verification is required before proceeding to implementation.

---

## Step 7 — Present Summary

Output a summary to the user with the following structure:

```
## /aegis tests — Complete

### Generated: tests.md
Path: {output.dir}/tests.md

### Generated: RED Test Files

| Type | Count | Directory |
|------|-------|-----------|
| Property-based (PROP-*) | N | tests/properties/ |
| Security (TEST-SEC-*) | N | tests/properties/ |
| End-to-End (TEST-E2E-*) | N | tests/e2e/ |
| Integration (TEST-INT-*) | N | tests/integration/ |
| **Total** | **N** | |

### Test Coverage

| Source | Total | Covered | Status |
|--------|-------|---------|--------|
| PROP-NNN | N | N | ✓ / gaps listed |
| SEC-PROP-* | N | N | ✓ (always required) |
| REQ-NNN (E2E) | N | N | ✓ / gaps listed |
| Interfaces (INT) | N | N | ✓ / gaps listed |

### Validation: {N_PASS}/{N_TOTAL} checks passed

{List any failed or warned checks with fix instructions}

### RED Status: {ALL FAILING / N tests already passing}

{If any tests pass on an empty codebase, list them with investigation notes}

### Next Step

All tests are RED. Start implementation with `/aegis tasks` to see the
ordered task list, or begin implementing TASK-001.

Run `/aegis validate` at any time for a full cross-artifact coverage report.
```

---

## Error Handling

| Condition | Action |
|-----------|--------|
| `.aegis/config.yaml` is missing | Stop. Tell user to run `/aegis init` first. |
| `requirements.md` is missing | Stop. Tell user to run `/aegis requirements` first. |
| `design.md` is missing | Stop. Tell user to run `/aegis design` first. |
| `tasks.md` is missing | Stop. Tell user to run `/aegis tasks` first. |
| `test_framework` not set in config | Ask the user which test framework they use before generating files. |
| `property_testing` not set in config | Default to the most idiomatic property testing library for the detected language. Inform the user. |
| No PROP-NNN entries in design.md | Warn but continue — write only E2E, integration, and security tests. |
| No SEC-PROP-* entries in design.md | Critical error — security properties are mandatory. Tell user to run `/aegis design` again. |
| Test runner not found in environment | Skip Step 6. Note that manual RED verification is required. |
| Tests pass unexpectedly | Report the passing tests with investigation notes. Do not mark RED verification as complete. |

---

## Formalism-Level Adjustments

Security treatment is **always FULL** regardless of formalism level.

| Aspect | Light | Standard | Formal |
|--------|-------|----------|--------|
| Property tests | 1 per PROP-NNN | 1+ per PROP-NNN | 1+ per PROP-NNN with edge cases |
| E2E tests | Happy path + 1 error path per REQ | Happy + all named failure paths | Happy + all branches + all error codes |
| Integration tests | Not required | Required per cross-service interaction | Required + consumer-driven contracts |
| Security tests (TEST-SEC-*) | FULL — 1 per SEC-PROP-* | FULL — 1 per SEC-PROP-* | FULL — 1 per SEC-PROP-*, must be at integration level |
| Per-task unit test descriptions | Brief bullet per task | Brief description per task | Explicit assertion list per subtask |
| §14 checklist reference | Required | Required | Required + compliance mapping table |

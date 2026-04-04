---
name: validate
description: Full validation — coverage matrix, security audit, gaps
---

# /aegis validate

Full cross-artifact validation. Produces a coverage matrix, security audit, gaps report, and stats. Writes the complete report to `docs/aegis/reports/validation-YYYY-MM-DD.md` and prints a summary to the terminal.

---

## Prerequisites

1. Read `aegis.config.yaml`. If it does not exist, stop and tell the user to run `/aegis init` first.
2. Note `project.name`, `formalism`, `language`, and any `security.not_applicable` declarations.

---

## Step 1 — Load Available Artifacts

Read whichever of the following files exist. Do not fail if a file is missing — record it as absent and continue.

| File | Artifact |
|------|----------|
| `aegis/requirements.md` (or the path from `output.dir` in config) | Requirements |
| `aegis/design.md` | Design |
| `aegis/tasks.md` | Tasks |
| `aegis/tests.md` | Tests |

Also read:
- `aegis/framework/security/security-requirements.yaml` — canonical SEC-REQ-* catalog
- `aegis/framework/security/security-properties.yaml` — canonical SEC-PROP-* catalog
- `aegis/framework/security/SECURITY_UNIVERSAL.md` — for §14 checklist items
- `aegis/framework/validation/rules.yaml` — validation rule definitions

**Extract all IDs** from each present artifact:

- From `requirements.md`: all `REQ-NNN` and `SEC-REQ-*` IDs, and each entry's title/first line.
- From `design.md`: all `PROP-NNN` and `SEC-PROP-*` IDs, the component each belongs to, and each `Derives from:` reference list.
- From `tasks.md`: all `TASK-NNN` IDs, each `Implements:` reference list, each `Depends on:` reference list.
- From `tests.md`: all `TEST-REQ-NNN`, `TEST-PROP-NNN`, and `TEST-SEC-*` IDs, and each `Tests:` reference list.

If fewer than two artifacts are present, warn the user:

> Warning: Only N artifact(s) found. Validation will be partial. Run `/aegis requirements`, `/aegis design`, `/aegis tasks`, and `/aegis tests` to generate missing artifacts before running a full validation.

Proceed regardless.

---

## Step 2 — Build Coverage Matrix (VAL-FULL-01)

For every REQ-NNN and SEC-REQ-* extracted in Step 1, build one row in the coverage matrix.

**For each requirement row, resolve:**

1. **Property** — Find all PROP-NNN or SEC-PROP-* in design.md whose `Derives from:` list includes this requirement ID. Record the primary one; if more than one, note the count (e.g., `PROP-011 (+2)`). If none, mark `—`.

2. **Component** — The component or concern heading under which the matched property lives in design.md. If no property, mark `—`.

3. **Task** — Find all TASK-NNN in tasks.md whose `Implements:` list references the matched property ID OR this requirement ID directly. Record the primary one. If none, mark `—`.

4. **Test** — Find all TEST-* in tests.md whose `Tests:` list references the matched property ID OR this requirement ID. Record the primary one. If none, mark `—`.

5. **Status** — Apply the rules from `aegis/framework/validation/coverage-matrix.md §3`:
   - **COVERED**: Property, Task, and Test are all non-`—`.
   - **PARTIAL**: At least one is non-`—` but not all three.
   - **UNCOVERED**: All three are `—`.

   Special rule: an UNCOVERED row for a SEC-REQ-* is always a **blocking error**. An UNCOVERED row for a REQ-NNN is a **warning**.

Output: a Markdown table with columns `REQ ID | Title | Component | Property | Task | Test | Status`.

---

## Step 3 — Security Audit (VAL-FULL-02)

Read the §14 checklist from `aegis/framework/security/SECURITY_UNIVERSAL.md`. The checklist covers seven categories: Input e dados, Autorização, Proteção, Dados, Upload, URLs e recursos externos, and Infraestrutura.

For each checklist item:

1. Find the matching SEC-REQ-* in requirements.md (if present).
2. Find the matching SEC-PROP-* in design.md that derives from that SEC-REQ-* (if present).
3. Find the matching TEST-SEC-* in tests.md that tests that SEC-PROP-* or SEC-REQ-* (if present).
4. Assign status:
   - **PASS**: All three — SEC-REQ, SEC-PROP, TEST-SEC — are present.
   - **FAIL**: The item is applicable to this project (based on `aegis.config.yaml` features and `security.not_applicable` declarations) and at least one of SEC-REQ, SEC-PROP, or TEST-SEC is missing. A FAIL in a mandatory category (Input e dados, Autorização, Proteção, Dados, Infraestrutura) is a **blocking error**.
   - **N/A**: The item's category is listed under `security.not_applicable` in `aegis.config.yaml`. N/A cannot be auto-assigned without an explicit config declaration.

Output: a Markdown table with columns `Category | Item | SEC-REQ | SEC-PROP | TEST-SEC | Status`.

Security FAIL items must be highlighted prominently in the terminal summary (see Step 7).

---

## Step 4 — Find Gaps (VAL-FULL-03 + VAL-FULL-04)

### 4a — Broken References

Scan all present artifacts for every cross-reference keyword and verify that the target ID exists:

| Keyword | Artifact | Target must exist in |
|---------|----------|----------------------|
| `Derives from:` | design.md | requirements.md |
| `Implements:` | tasks.md | design.md or requirements.md |
| `Validates:` | tasks.md | requirements.md |
| `Tests:` | tests.md | design.md or requirements.md |

For each broken reference, create a gap entry:

```
GAP-NNN [error] <artifact> > <containing-entry-ID>
  "<keyword>: <referenced-ID>" — <referenced-ID> not found in <target-artifact>.
  Fix: Check for typo in the ID, or create the missing entry in <target-artifact>.
```

Broken references to missing security IDs (SEC-REQ-*, SEC-PROP-*) are reported first, before functional broken references.

### 4b — Orphan IDs

Identify IDs that exist in one artifact but are never referenced by any other:

- **Orphan REQ-NNN**: exists in requirements.md but no PROP in design.md has `Derives from: REQ-NNN`. Status: warning.
- **Orphan PROP-NNN**: exists in design.md but no TASK has `Implements: PROP-NNN` and no TEST has `Tests: PROP-NNN`. Status: warning.
- **Orphan SEC-REQ-***: exists in requirements.md but no SEC-PROP-* derives from it. Status: **error**.
- **Orphan SEC-PROP-***: exists in design.md but no TEST-SEC-* tests it. Status: **error**.
- **Orphan TEST-***: exists in tests.md but its `Tests:` reference resolves to nothing in design.md or requirements.md. Status: error.
- **Orphan TASK-NNN**: exists in tasks.md but has no `Implements:` reference at all. Status: warning.

For each orphan, create a gap entry:

```
GAP-NNN [warning|error] <artifact> > <orphan-ID>
  <description of what is missing>
  Fix: <suggested action>
```

Assign sequential GAP-NNN numbers across all gap entries (broken references first, then orphans).

### 4c — Light Validation Checks

Run all light validation checks from `aegis/framework/validation/rules.yaml` against the present artifacts:

- `after_requirements` checks (VAL-REQ-01 through VAL-REQ-05) if requirements.md is present
- `after_design` checks (VAL-DES-01 through VAL-DES-05) if design.md is present
- `after_tasks` checks (VAL-TASK-01 through VAL-TASK-05) if tasks.md is present
- `after_tests` checks (VAL-TEST-01 through VAL-TEST-05) if tests.md is present

Apply `level_gate` filters: skip checks that do not apply to the project's `formalism` level.

Record each check as PASS or FAIL with its rule ID and a brief reason if it fails.

---

## Step 5 — Calculate Stats (VAL-FULL-05)

Compute the following numbers:

**Requirements**
- Total REQ-NNN count
- Total SEC-REQ-* count
- Number and percentage of REQ-NNN entries with a full forward trace (COVERED status)

**Design**
- Total PROP-NNN count
- Total SEC-PROP-* count
- Number and percentage of PROP-NNN entries with at least one TEST referencing them

**Tasks**
- Total TASK-NNN count
- Effort summary: if numeric estimates are present, sum them; if T-shirt sizes, show distribution (S: N, M: N, L: N, XL: N); if no estimates, note "No estimates present"

**Tests**
- Total TEST-* count
- TEST-SEC-* count (security tests)
- Number and percentage of TEST-* entries that resolve to a valid PROP or REQ

**Coverage**
- Overall coverage %: (COVERED rows / total rows in matrix) × 100, rounded to one decimal place
- Security coverage: X/Y SEC-REQ-* fully COVERED

**Meta**
- Formalism level in use
- Artifacts present vs. absent
- Date of validation

---

## Step 6 — Generate Report

Dispatch to `aegis/agents/validation-agent.md` with all data collected in Steps 1–5. The agent writes the full validation report.

**Report file path:**

```
docs/aegis/reports/validation-YYYY-MM-DD.md
```

Where `YYYY-MM-DD` is today's date. If the file already exists, append a counter suffix:

```
docs/aegis/reports/validation-2026-04-04.md       ← first run of the day
docs/aegis/reports/validation-2026-04-04-2.md     ← second run of the same day
docs/aegis/reports/validation-2026-04-04-3.md     ← third run, etc.
```

Create the `docs/aegis/reports/` directory if it does not exist.

**Report structure** (sections in this order):

1. **Header** — Project name, formalism level, validation date, artifacts present
2. **Stats Block** — All counts and percentages from Step 5
3. **Coverage Matrix** — Full table from Step 2
4. **Coverage Summary** — COVERED/PARTIAL/UNCOVERED counts and percentages; security coverage line
5. **Security Audit** — Full table from Step 3
6. **Gaps Report** — All gap entries from Step 4a and 4b, sorted by severity (errors first)
7. **Light Validation Results** — Pass/fail per rule ID from Step 4c
8. **Recommendations** — Prioritized action list (see priority order below)

**Recommendations priority order:**
1. UNCOVERED SEC-REQ-* rows — blocking; must resolve before advancing
2. FAIL items in security audit — blocking; must resolve before advancing
3. Broken references (error-severity gaps) — fix ID typos or create missing entries
4. UNCOVERED REQ-NNN rows — design gaps; create PROP-NNN entries
5. PARTIAL rows missing a Test — write the missing TEST-* entry
6. PARTIAL rows missing a Task — create TASK-NNN for designed-but-unplanned properties
7. Orphan IDs (warning-severity gaps) — review and connect or remove
8. Formalism-level warnings — address before review gates

---

## Step 7 — Display Terminal Summary

Print to the terminal after the report is written:

```
Aegis Validation Report — <project name> — <date>
================================================

Artifacts present: requirements.md, design.md, tasks.md, tests.md
Formalism level  : <level>

Coverage Summary
----------------
Total requirements : N  (REQ-NNN: N, SEC-REQ-*: N)
COVERED            : N  (N%)
PARTIAL            : N  (N%)
UNCOVERED          : N  (N%)

Security           : N/N PASS, N/N FAIL, N/N N/A

Gaps               : N errors, N warnings

Light Validation   : N passed, N failed

Overall coverage % : N%
Report written to  : docs/aegis/reports/validation-YYYY-MM-DD.md
```

**If any security FAIL items exist**, display them prominently before the summary block:

```
SECURITY FAILURES — ACTION REQUIRED
=====================================
The following security checklist items are FAIL status.
These are blocking errors and must be resolved before the project
can be declared design-complete.

  FAIL  [Input e dados]    <Item description>
        Missing: <SEC-REQ | SEC-PROP | TEST-SEC> — not found in <artifact>
        Fix: <suggested action>

  FAIL  [Autorização]      <Item description>
        Missing: <SEC-REQ | SEC-PROP | TEST-SEC> — not found in <artifact>
        Fix: <suggested action>

  ...
```

**If any UNCOVERED SEC-REQ-* rows exist**, list them as blocking errors in the same block as security failures.

**If there are no errors** (zero security FAILs, zero UNCOVERED SEC-REQ-*, zero error-severity gaps), close with:

```
No blocking errors found. Review warnings before handoff to engineering.
```

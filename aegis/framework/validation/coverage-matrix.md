# Aegis Coverage Matrix — Format and Interpretation Guide

> Version 1.0 — 2026-04-04
> This document explains how to read, generate, and act on the coverage matrix
> produced by `/aegis validate` (VAL-FULL-01).

---

## 1. Purpose

The coverage matrix is the primary cross-artifact audit tool in the Aegis framework. It answers a single question in tabular form:

> For every requirement, does the project have a design property, an implementation task, and a verification test?

A requirement without all three columns covered is an incomplete requirement — either undesigned, unimplemented, or unverified. The matrix makes these gaps visible at a glance so the team can act on them before declaring the design complete.

---

## 2. Matrix Format

The coverage matrix is a Markdown table. Each row is one requirement (REQ-NNN or SEC-REQ-*). The columns map the forward-trace chain from requirement to test.

### Column Definitions

| Column    | Source Artifact | Content                                                                 |
|-----------|-----------------|-------------------------------------------------------------------------|
| REQ ID    | requirements.md | The requirement identifier (REQ-NNN or SEC-REQ-*)                       |
| Title     | requirements.md | Short title or first line of the requirement                            |
| Component | design.md       | The component or concern that owns the deriving PROP-NNN/SEC-PROP-*     |
| Property  | design.md       | The PROP-NNN or SEC-PROP-* that derives from this requirement           |
| Task      | tasks.md        | The TASK-NNN(s) that implement the property or requirement              |
| Test      | tests.md        | The TEST-* entry/entries that verify the property or requirement        |
| Status    | (computed)      | COVERED, PARTIAL, or UNCOVERED — see §3 for rules                      |

### Example Table

```
| REQ ID             | Title                          | Component       | Property        | Task      | Test              | Status    |
|--------------------|--------------------------------|-----------------|-----------------|-----------|-------------------|-----------|
| REQ-001            | User Registration              | Auth            | PROP-001        | TASK-001  | TEST-PROP-001     | COVERED   |
| REQ-002            | Product Listing                | Catalog         | PROP-004        | TASK-005  | —                 | PARTIAL   |
| REQ-003            | Order Checkout                 | Commerce        | —               | —         | —                 | UNCOVERED |
| SEC-REQ-IDOR       | Object-Level Authorization     | Auth/API        | SEC-PROP-IDOR   | TASK-003  | TEST-SEC-IDOR     | COVERED   |
| SEC-REQ-RATELIMIT  | Rate Limiting on Auth Endpoints| API Gateway     | SEC-PROP-RATELIMT| TASK-007 | —                 | PARTIAL   |
| SEC-REQ-INPUT-VAL  | Input Validation               | All handlers    | SEC-PROP-INPUT  | TASK-002  | TEST-SEC-INPUT    | COVERED   |
```

When a cell has no entry, it is shown as `—` (an em-dash). When a requirement has multiple properties, tasks, or tests, the primary one is shown and the count of additional entries is noted (e.g., `PROP-011 (+2)`).

---

## 3. Status Values

Each row in the matrix receives exactly one status value. Status is computed from the presence or absence of entries in the Property, Task, and Test columns.

### COVERED

**Definition**: All three forward-trace links are present. The requirement has at least one design property, at least one implementation task that traces to that property, and at least one test that validates the property or requirement.

**Condition**: Property != `—` AND Task != `—` AND Test != `—`

**Meaning**: This requirement has complete end-to-end traceability. It has been designed, implemented, and made verifiable.

---

### PARTIAL

**Definition**: At least one forward-trace link is present, but not all three.

**Condition**: (Property != `—` OR Task != `—` OR Test != `—`) AND NOT all three present

**Common partial patterns**:

| Pattern                        | Likely cause                                                  |
|--------------------------------|---------------------------------------------------------------|
| Property present, no Task      | Design done but not yet broken into tasks                    |
| Property + Task, no Test       | Implemented but not yet verified — most common gap           |
| No Property, Task present      | Task added without a design property (shortcut, debt marker) |
| Property + Test, no Task       | Test written before implementation task was captured         |

**Meaning**: This requirement is in progress. Identify which link is missing and generate or add the corresponding artifact entry.

---

### UNCOVERED

**Definition**: No forward-trace link exists. The requirement has no corresponding property, task, or test.

**Condition**: Property == `—` AND Task == `—` AND Test == `—`

**Meaning**: This requirement was never addressed in the design. It may be new, forgotten, or out of scope. UNCOVERED rows in functional requirements (REQ-NNN) are warnings. UNCOVERED rows in security requirements (SEC-REQ-*) are always blocking errors — security requirements may not be left unaddressed.

---

## 4. Status Summary Block

Below the matrix table, the validation report includes a summary block:

```
Coverage Summary
----------------
Total requirements  : 24  (REQ-NNN: 18, SEC-REQ-*: 6)
COVERED             : 17  (70.8%)
PARTIAL             : 5   (20.8%)
UNCOVERED           : 2   (8.3%)

Security coverage   : 5/6 COVERED, 1/6 PARTIAL, 0/6 UNCOVERED
Overall coverage %  : 70.8%
```

The **overall coverage percentage** is defined as:

```
coverage % = (COVERED rows / total rows) × 100
```

Rounded to one decimal place. Security rows are counted separately in the summary but included in the total for the overall percentage.

---

## 5. Security Audit Section

Immediately after the coverage matrix, the validation report includes a security audit section produced by VAL-FULL-02. This section maps the project's security artifacts against the SECURITY_UNIVERSAL §14 checklist.

### Format

The security audit is a table with one row per checklist item. Columns:

| Column     | Content                                                                                  |
|------------|------------------------------------------------------------------------------------------|
| Category   | The §14 checklist category (Input e dados, Autorização, Proteção, Dados, Upload, URLs, Infra) |
| Item       | The specific checklist control being audited                                             |
| SEC-REQ    | The SEC-REQ-* entry covering this control (or `—` if missing)                            |
| SEC-PROP   | The SEC-PROP-* entry responding to this control (or `—` if missing)                      |
| TEST-SEC   | The TEST-SEC-* entry verifying this control (or `—` if missing)                          |
| Status     | PASS, FAIL, or N/A — see rules below                                                     |

### Status Values for the Security Audit

**PASS**: The checklist item has a SEC-REQ-*, a corresponding SEC-PROP-*, and a TEST-SEC-* that validates it. All three columns are non-empty.

**FAIL**: The checklist item is applicable to this project (based on features declared in .aegis/config.yaml) but at least one of SEC-REQ, SEC-PROP, or TEST-SEC is missing. Any FAIL in a mandatory category (Input e dados, Autorização, Proteção, Dados, Infraestrutura) is a blocking error.

**N/A**: The checklist item is not applicable to this project. For example, the Upload category is N/A for projects with no file upload feature; the URLs e recursos externos category is N/A for projects that make no external HTTP calls. N/A status requires an explicit declaration in .aegis/config.yaml (under `security.not_applicable`) and cannot be auto-assigned.

### Example Security Audit Table

```
| Category         | Item                          | SEC-REQ                  | SEC-PROP                  | TEST-SEC               | Status |
|------------------|-------------------------------|--------------------------|---------------------------|------------------------|--------|
| Input e dados    | Validate all user inputs      | SEC-REQ-INPUT-VALIDATION | SEC-PROP-INPUT            | TEST-SEC-INPUT         | PASS   |
| Input e dados    | Parameterized queries         | SEC-REQ-SQLI             | SEC-PROP-SQLI             | TEST-SEC-SQLI          | PASS   |
| Autorização      | Object-level auth (IDOR)      | SEC-REQ-IDOR             | SEC-PROP-IDOR             | TEST-SEC-IDOR          | PASS   |
| Autorização      | Function-level auth           | SEC-REQ-AUTHZ            | —                         | —                      | FAIL   |
| Proteção         | Rate limiting on auth         | SEC-REQ-RATELIMIT        | SEC-PROP-RATELIMIT        | TEST-SEC-RATELIMIT     | PASS   |
| Dados            | No secrets in source code     | SEC-REQ-SECRETS          | SEC-PROP-SECRETS          | TEST-SEC-SECRETS       | PASS   |
| Upload           | File type and size validation | —                        | —                         | —                      | N/A    |
| URLs             | SSRF prevention               | —                        | —                         | —                      | N/A    |
| Infraestrutura   | Security headers (CSP, HSTS)  | SEC-REQ-HEADERS          | SEC-PROP-HEADERS          | —                      | FAIL   |
```

---

## 6. Gaps Report Section

After the security audit, the validation report lists all broken references (VAL-FULL-03) and orphan IDs (VAL-FULL-04) in a consolidated gaps section.

Each gap entry includes:

- **Gap ID**: Auto-assigned sequential identifier (GAP-001, GAP-002, ...)
- **Severity**: error or warning
- **Artifact**: Which file contains the gap
- **Entry**: The ID of the artifact entry with the gap
- **Description**: What is missing or broken
- **Suggested fix**: A concrete action to resolve the gap

Example gaps section:

```
Gaps Found: 3
-------------

GAP-001 [error] design.md > PROP-009
  "Derives from: REQ-022" — REQ-022 not found in requirements.md.
  Fix: Check for typo in the requirement ID, or add REQ-022 to requirements.md.

GAP-002 [warning] tasks.md > TASK-014
  No "Implements:" reference found. This task has no traceability link.
  Fix: Add "Implements: PROP-NNN" or "Implements: REQ-NNN" to TASK-014.

GAP-003 [warning] design.md > PROP-017
  PROP-017 is not referenced by any TASK or TEST (orphan property).
  Fix: Create a TASK-NNN that implements PROP-017, or remove PROP-017 if it
  is no longer part of the design.
```

---

## 7. Report File Location

The full validation report is written to:

```
.aegis/reports/validation-YYYY-MM-DD.md
```

Where `YYYY-MM-DD` is the date the `/aegis validate` command was run.

If a report for the same date already exists, the new report appends a counter suffix:

```
.aegis/reports/validation-2026-04-04.md      ← first run of the day
.aegis/reports/validation-2026-04-04-2.md    ← second run of the same day
```

The `/aegis validate` command also prints a brief summary to stdout (counts of COVERED/PARTIAL/UNCOVERED, total gaps, PASS/FAIL/N/A for security) and writes the full report to the path above. The summary in stdout includes the path to the report file for easy access.

### Report Structure

A complete validation report has the following top-level sections, in order:

1. **Header** — project name, formalism level, date, `/aegis validate` command version
2. **Stats Block** — counts and overall coverage percentage (VAL-FULL-05)
3. **Coverage Matrix** — the full REQ × Component × PROP × TASK × TEST table (VAL-FULL-01)
4. **Coverage Summary** — COVERED/PARTIAL/UNCOVERED counts and percentages
5. **Security Audit** — §14 checklist cross-reference table (VAL-FULL-02)
6. **Gaps Report** — broken references and orphan IDs (VAL-FULL-03, VAL-FULL-04)
7. **Light Validation Results** — pass/fail per check from all `after_*` rule groups
8. **Recommendations** — prioritized list of actions derived from errors and warnings

---

## 8. Acting on the Matrix

The following priority order is recommended when acting on gaps found in the coverage matrix:

1. **UNCOVERED SEC-REQ-*** — blocking errors; resolve before advancing
2. **FAIL in security audit** — blocking errors; resolve before advancing
3. **Broken references** (VAL-FULL-03 errors) — fix ID typos or create missing entries
4. **UNCOVERED REQ-NNN** — design gaps; create PROP-NNN entries for unaddressed requirements
5. **PARTIAL rows missing a Test** — most common gap; write the missing TEST-* entry
6. **PARTIAL rows missing a Task** — create TASK-NNN entries for designed-but-unplanned properties
7. **Orphan IDs** (warnings) — review and either connect or remove
8. **Formalism-level warnings** — address if the project is approaching a review gate

Security gaps (items 1–2) must be resolved before the project can be declared design-complete. Functional coverage gaps (items 3–8) should be resolved before handoff to engineering.

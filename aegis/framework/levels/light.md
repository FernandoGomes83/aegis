# Aegis Formalism Level: Light

> Part of the Aegis Framework — `aegis/framework/levels/light.md`
> See `SPEC.md §3` for the full level comparison table.

---

## When to Use

Choose **Light** when:

- The project is a script, CLI tool, simple utility, proof-of-concept, or internal one-off tool.
- The total functional requirement count is **fewer than 10**.
- The team is a single developer or a very small group iterating quickly.
- Speed of delivery outweighs documentation depth.
- The cost of a design defect is low (no users, no regulated data, no production SLA).

Do **not** use Light for anything that handles user authentication, payments, personal data, or regulated information — those projects require Standard or Formal regardless of size.

---

## Requirements Format

### Structure

- **Feature list** with a brief one-paragraph description per feature. No stakeholder matrix. No glossary.
- **No SHALL / WHEN / IF vocabulary** is required. Plain language is sufficient.
- **Acceptance criteria** are written as simple bullet points under each feature, not structured tables.
- Security requirements (SEC-REQ-*) are always present — see Security section below.

### Example

```markdown
## Requirements

### Feature List

**F-001: CSV Import**
Read a CSV file from the local filesystem and load its rows into memory for processing.
The tool must handle files up to 100 MB without running out of memory.

Acceptance criteria:
- Accepts a file path as a CLI argument.
- Fails with a clear error message if the file does not exist or cannot be read.
- Skips blank rows silently; logs a count of skipped rows at the end.
- Processes 100 MB files in under 10 seconds on a standard laptop.

**F-002: Column Filtering**
Allow the user to specify one or more column names to keep; all other columns are dropped.

Acceptance criteria:
- Accepts a --columns flag with a comma-separated list of column names.
- Fails with a clear error if any specified column does not exist in the file.
- Outputs only the requested columns in the order they were specified.
```

---

## Design Format

### Structure

- **Stack declaration**: language, runtime, key libraries — one line each.
- **High-level diagram**: an ASCII or Mermaid block showing the main components and their data flow. One diagram is sufficient.
- **Basic data models**: plain struct or table definitions for the core entities. No full data dictionary required.
- **Correctness Properties**: define **1 to 3** PROP-NNN entries covering the most critical behavioral guarantees. Each property must reference the feature(s) it derives from.
- Security properties (SEC-PROP-*) are always present — see Security section below.

### Example

```markdown
## Design

### Stack

- Language: Python 3.12
- CLI framework: Typer
- CSV parsing: built-in csv module
- Logging: built-in logging (stderr)

### High-Level Diagram

```
CLI args
   |
   v
[Arg Parser] --> [CSV Loader] --> [Column Filter] --> [Output Writer]
                      |
                  [Error Handler] (file-not-found, permission denied)
```

### Data Models

```python
Row = dict[str, str]          # column name -> raw string value
FilteredRow = dict[str, str]  # subset of Row after column selection
```

### Correctness Properties

**PROP-001: Memory-Safe CSV Loading**
Derives from: F-001
Description: The CSV loader reads rows lazily (iterator-based), never loading the
entire file into memory at once. Peak memory usage must remain below 256 MB for
any valid input file regardless of size.

**PROP-002: Column Selection Integrity**
Derives from: F-002
Description: The output contains exactly the columns requested, in the order
requested, with no additional columns present. If any requested column is absent
from the input, the process terminates with exit code 1 before writing any output.
```

---

## Tasks Format

### Structure

- **Simple checklist**: one line per task with a checkbox, a TASK-NNN ID, a brief label, and a reference to the feature or property it implements.
- **No subtasks**. No dependency declarations. No checkpoints between blocks.
- Effort estimate is optional; if used, T-shirt sizes (S / M / L / XL) are sufficient.

### Example

```markdown
## Tasks

- [ ] TASK-001: Set up project skeleton and Typer CLI entry point — Implements: F-001
- [ ] TASK-002: Implement lazy CSV loader with error handling — Implements: PROP-001, F-001
- [ ] TASK-003: Implement column filter and --columns flag — Implements: PROP-002, F-002
- [ ] TASK-004: Wire loader and filter into output writer — Implements: F-001, F-002
- [ ] TASK-005: Add integration test for 100 MB file — Implements: PROP-001
- [ ] TASK-006: Add test for missing column error path — Implements: PROP-002
```

---

## Tests Format

### Structure

- **Basic end-to-end tests**: at least one test per feature covering the happy path and at least one error path.
- **1 to 3 property-based tests**: for correctness properties defined in the design.
- Security tests (TEST-SEC-*) are always present — see Security section below.
- No edge-case matrix required.

### Example

```markdown
## Tests

### End-to-End Tests

**TEST-REQ-F001-E2E: CSV import happy path**
Tests: F-001
Scenario: Run the tool against a valid 10-row CSV. Verify all rows are loaded and
output is written to stdout. Exit code must be 0.

**TEST-REQ-F001-MISSING-FILE: File not found error**
Tests: F-001
Scenario: Run the tool with a path that does not exist. Verify exit code is 1 and
stderr contains a human-readable error message.

**TEST-REQ-F002-E2E: Column filtering happy path**
Tests: F-002
Scenario: Run the tool with --columns "name,age" on a CSV with 5 columns. Verify
output contains only "name" and "age" columns in that order.

### Property Tests

**TEST-PROP-001: Memory ceiling under large file**
Tests: PROP-001
Scenario: Run the tool against a generated 100 MB CSV while sampling peak RSS.
Expected: Peak RSS stays below 256 MB.

**TEST-PROP-002: Column selection is exact**
Tests: PROP-002
Property: For any input CSV and any valid subset of its columns, the output
contains exactly those columns — no more, no fewer — in the requested order.
```

---

## Security

**Security treatment at the Light level is FULL — identical to Standard and Formal.**

This is unconditional. The formalism level controls the depth of functional, design, and test content only. Security is governed by the framework core and is not reduced, simplified, or made optional at any level.

Specifically, every Light-level project must include:

- **SEC-REQ-*** entries in `requirements.md` — generated by the requirements agent from `security-requirements.yaml`. At minimum: IDOR, input validation, rate limiting, authentication, secrets management.
- **SEC-PROP-*** entries in `design.md` — generated by the design agent from `security-properties.yaml`, each deriving from one or more SEC-REQ-* entries.
- **TEST-SEC-*** entries in `tests.md` — generated by the tests agent, one per SEC-PROP-* entry.
- The **SECURITY_UNIVERSAL §14 checklist** referenced in `tests.md` as the minimum verification bar for each feature.

No configuration flag, command-line option, or user instruction can suppress or reduce security content.

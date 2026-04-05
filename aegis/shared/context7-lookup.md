# Context7 Documentation Lookup

> Shared module — loaded by commands that need up-to-date library documentation.
> This module is **not** loaded automatically by `preamble.md`. Each command that
> uses it includes an explicit step to read and execute it.

---

## Input Required

The calling command must provide:

- `stack_config` — the `stack` section from `.aegis/config.yaml` (already loaded)
- `topic` — a string describing what documentation aspects to fetch, tailored to
  the calling phase (architecture patterns, testing utilities, setup guides, etc.)

---

## Step A — Read API Key

1. Read the `.env` file at the project root using the Read tool.
2. Look for a line matching `CONTEXT7_API_KEY=<value>` (the value after `=`,
   trimmed of surrounding quotes and whitespace).
3. If the `.env` file does not exist, or the variable is not present, or the
   value is empty → set `context7_available = false` and skip to **Step D**.
4. Store the value as `context7_key`.

---

## Step B — Extract Lookup Targets

From `stack_config`, extract every non-null, non-TBD library/framework name
into an ordered list called `lookup_targets`.

### Extraction rules

| Config field            | Example value       | Extract?                                     |
|-------------------------|---------------------|----------------------------------------------|
| `stack.framework`       | "Next.js 14"        | **Yes** — strip version → "nextjs"           |
| `stack.orm`             | "Prisma"            | **Yes** → "prisma"                           |
| `stack.auth`            | "NextAuth.js"       | **Yes** → "nextauth"                         |
| `stack.cache`           | "Redis"             | **Yes** → "redis"                            |
| `stack.queue`           | "BullMQ"            | **Yes** → "bullmq"                           |
| `stack.storage`         | "S3"                | **Yes** → "aws s3 sdk"                       |
| `stack.deployment`      | "Vercel"            | **Yes** → "vercel"                           |
| `stack.integrations[]`  | ["Stripe","SendGrid"] | **Yes** — one entry per integration        |
| `stack.test_framework`  | "Vitest"            | **Yes** (primarily for `/aegis:tests`)       |
| `stack.property_testing`| "fast-check"        | **Yes** (primarily for `/aegis:tests`)       |
| `stack.runtime`         | "Node.js 20"        | **Skip** — too broad, wastes tokens          |
| `stack.language`        | "TypeScript"        | **Skip** — too broad, wastes tokens          |
| `stack.data_store`      | "PostgreSQL 16"     | **Skip if ORM is set** — ORM docs cover DB patterns. If no ORM, look up the database driver (e.g., "pg" for Node.js + PostgreSQL, "psycopg" for Python + PostgreSQL) |

### Cleanup rules

- Strip version numbers from names (e.g., "Next.js 14" → "nextjs", "PostgreSQL 16" → "postgresql").
- Normalize casing to lowercase for the search query.
- Skip any value that is `null`, `"TBD"`, `"(none)"`, or empty.
- Deduplicate: if a library appears in multiple fields, include it only once.
- **Maximum 8 entries.** If more than 8, prioritize by architectural impact:
  framework > ORM > auth > integrations > cache > queue > storage > deployment.

---

## Step C — Fetch Documentation from Context7

Run all Context7 lookups in a **single** Bash command using the batch script:

### Token budget

Scale the `tokens` parameter based on target count to stay within budget:

| Target count | Tokens per library | Total budget |
|--------------|-------------------|--------------|
| 1–3          | 3000              | ~9,000       |
| 4–6          | 2500              | ~15,000      |
| 7–8          | 2000              | ~16,000      |

Never exceed **20,000 tokens total** for documentation context.

### Execution

Run via the Bash tool:

```bash
bash "{AEGIS_HOME}/scripts/aegis-context7.sh" "<context7_key>" "<topic>" <tokens_per_lib> <lib1> [lib2] ...
```

Where:
- `<context7_key>` is the API key from Step A
- `<topic>` is the value passed by the calling command
- `<tokens_per_lib>` is the per-library token limit from the budget table above
- `<lib1> [lib2] ...` are the normalized library names from `lookup_targets`

The script handles both phases (library ID resolution + documentation fetch)
internally with parallel execution and returns a single JSON response.

### Parsing the output

The script outputs JSON with this structure:

```json
{
  "results": {
    "<lib_name>": {"status": "ok", "library_id": "...", "content": "..."},
    "<lib_name>": {"status": "not_found"}
  },
  "summary": {"total": N, "resolved": N, "failed": N}
}
```

- For each library with `"status": "ok"`, store its `content` in `library_docs`.
- For libraries with `"status": "not_found"` or `"fetch_failed"`, proceed to Step D (WebSearch fallback).
- If the output contains `"error": "auth_failed"`, the API key is invalid or expired. Set `context7_available = false` and skip remaining lookups. Proceed to Step D for all targets.
- If more than half the lookups fail (check `summary.failed > summary.total / 2`), set `context7_degraded = true` and proceed to Step D for the failed libraries only.

---

## Step D — Fallback: WebSearch

This step runs for any library in `lookup_targets` that was NOT successfully
resolved via Context7. This includes cases where:

- `context7_available = false` (no API key, invalid key)
- The library was `NOT_FOUND` in Context7
- The API call failed (HTTP error, timeout)

For each unresolved library, use the **WebSearch tool** with:

```
Query: "<library name> official documentation <current year> API patterns architecture best practices"
```

Where `<current year>` is the actual current year (e.g., 2026) to ensure
results are up-to-date and not from outdated versions.

From the search results, extract the top 2 most relevant results and summarize
each in **500 tokens maximum**. Prefer official documentation sites over blog
posts or tutorials.

Store these summaries in `library_docs` alongside any successful Context7 results.

---

## Step E — Compile Documentation Context

Assemble a single string called `documentation_context` from all entries in
`library_docs`. Format each entry as:

```markdown
### <Library Name> — Documentation Reference

<documentation content>

---
```

Concatenate all entries. This compiled block is the **output** of this module.

The calling command passes `documentation_context` to its agent as part of the
context package. If all lookups failed and WebSearch also returned nothing,
`documentation_context` is an empty string — this is not an error condition.

---

## Notes for Calling Commands

- This module is **non-blocking**. Failure at any step never prevents the
  calling command from generating its artifact. The agent falls back to its
  training knowledge when documentation is unavailable.
- Report the lookup status in the command's final summary:
  - `"Documentation: N libraries resolved via Context7"` — if Context7 succeeded
  - `"Documentation: N libraries resolved via WebSearch (Context7 unavailable)"` — if fallback was used
  - `"Documentation: lookup skipped (no API key and WebSearch unavailable)"` — if both failed

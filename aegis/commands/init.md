---
name: aegis:init
description: Initialize Aegis Framework in a project
---

## Bootstrap

Resolve the Aegis framework root path (**AEGIS_HOME**) and create output directories by running one Bash command:

```bash
for d in "<project_root>/.claude/aegis" "$HOME/.claude/aegis"; do [ -x "$d/scripts/aegis-bootstrap.sh" ] && exec bash "$d/scripts/aegis-bootstrap.sh" "<project_root>" init; done; echo "ERROR=not_found"
```

Parse the output:
- If `ERROR=not_found` → tell the user to install Aegis with `npx aegis-sdd` and stop.
- Otherwise, extract **AEGIS_HOME** from the `AEGIS_HOME=<path>` line. The script also creates `.aegis/`, `.aegis/reports/`, and `.aegis/tests/` directories.

Now read `{AEGIS_HOME}/shared/preamble.md` and apply all path mappings and core rules defined there before proceeding with the steps below.

---

# `/aegis:init` — Initialize Aegis Framework

You are executing the `/aegis:init` command. Your job is to gather all project context interactively and write a valid `.aegis/config.yaml` at the project root. Follow every step in order. Do not skip steps. Do not combine steps into a single prompt.

---

## Step 1: Detect Existing Documentation

Glob for `*.md` files in the project root and the `docs/` directory (recursively). Exclude the following from the results:

- Files named `README.md`, `CHANGELOG.md`, `LICENSE.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`
- Any path containing `node_modules/`, `.git/`, `vendor/`, `dist/`, `build/`

Present the list to the user in a numbered format. If no docs are found, tell the user and continue. Example output:

```
Existing documentation found:
  1. docs/PROJECT_SPEC.md
  2. docs/BRAND.md
  3. ARCHITECTURE.md

These files will be candidates for input documents in Step 4.
```

---

## Step 2: Auto-Detect Technology Stack

Check for the presence of the following files in the project root (and one level deep). Build an inference list from every match found:

| File to Check | Inference |
|---|---|
| `package.json` | Node.js — read the `dependencies` and `devDependencies` fields to detect framework (e.g., Next.js, React, Express, NestJS, Vue, Angular) |
| `tsconfig.json` | TypeScript |
| `requirements.txt` | Python — read the file to detect framework (e.g., Django, Flask, FastAPI) |
| `pyproject.toml` | Python — read `[tool.poetry.dependencies]` or `[project]` section to detect framework |
| `go.mod` | Go |
| `Cargo.toml` | Rust |
| `pom.xml` | Java — read `<dependencies>` to detect framework (e.g., Spring Boot, Quarkus) |
| `build.gradle` | Java — read `dependencies` block to detect framework |
| `composer.json` | PHP — read `require` section to detect framework (e.g., Laravel, Symfony) |
| `index.html` (with no framework files) | HTML/CSS/JS vanilla |
| `prisma/schema.prisma` | Prisma ORM |
| `docker-compose.yml` | Containerized services — read `services:` section to list detected services (e.g., postgres, redis, nginx) |
| `.env` or `.env.example` | Read variable names to infer integrations (e.g., `STRIPE_` → Payments, `SENDGRID_` / `SMTP_` → Email, `CLOUDINARY_` → File storage, `FIREBASE_` → Firebase, `SUPABASE_` → Supabase) |

Present the detected stack clearly and ask the user to confirm or correct it:

```
Detected stack:
  - Runtime:    Node.js
  - Language:   TypeScript
  - Framework:  Next.js 14 (App Router detected from dependencies)
  - ORM:        Prisma
  - Services:   PostgreSQL, Redis (from docker-compose.yml)
  - Integrations: Stripe (STRIPE_* vars), SendGrid (SENDGRID_* vars)

Is this correct? Please confirm or describe any corrections.
```

Wait for the user's response before continuing. Update the stack inference based on their reply.

---

## Step 3: Select Formalism Level

Present three options with clear descriptions of when each is appropriate:

```
Choose a formalism level for this project:

  1. light
     Best for: prototypes, internal tools, MVPs, single-developer projects, weekend projects.
     Produces: user stories (no acceptance criteria tables), flat task list with T-shirt sizes,
     happy-path tests only, one-line component descriptions.

  2. standard  ← recommended for most projects
     Best for: team projects, client work, production systems without regulatory constraints.
     Produces: user stories + SHALL/WHEN/THEN acceptance criteria, sequence diagrams for
     critical flows, one ADR per major technology choice, numeric estimates, edge-case tests.

  3. formal
     Best for: regulated industries (fintech, health, legal), compliance-required systems
     (SOC 2, PCI-DSS, LGPD, HIPAA), multi-team architectures, high-cost-of-failure projects.
     Produces: IEEE-830-inspired structure, full ADR set, formal data dictionary, OpenAPI
     contract, PERT estimates, penetration test requirements, compliance mappings.

Note: Security coverage is always FULL regardless of level. A light-level project gets
the same security requirements and properties as a formal-level project.

Enter 1, 2, or 3 (default: 2):
```

Wait for the user's selection.

---

## Step 4: Classify Input Documents

For each document found in Step 1, read its first 200 lines and match its content against the keyword signals defined in `aegis/framework/inputs/recommended-types.md`.

Apply the auto-classification algorithm:

- **product-spec** signals: "feature", "user flow", "pricing", "product", "MVP", "persona", "use case"
- **brand-guide** signals: "color", "palette", "typography", "font", "brand", "tone", "voice", "logo"
- **business-plan** signals: "market", "revenue", "metric", "ROI", "TAM", "growth", "retention", "funnel"
- **security** signals: "OWASP", "XSS", "CSRF", "injection", "authentication", "authorization", "CVE", "pentest"
- **api-docs** signals: "endpoint", "API", "REST", "GraphQL", "webhook", "OpenAPI", "swagger", "payload"

If your confidence is 70% or higher, suggest the type automatically. If below 70% or ambiguous, ask the user to classify that document. Present your classification proposal for all docs at once and ask the user to confirm or override:

```
Input document classification:

  1. docs/PROJECT_SPEC.md  →  product-spec   (confidence: high — "user flow", "pricing", "persona" found)
  2. docs/BRAND.md         →  brand-guide    (confidence: high — "palette", "typography", "tone" found)
  3. ARCHITECTURE.md       →  ?              (confidence: low — please classify manually)
     Options: product-spec / brand-guide / business-plan / security / api-docs / auto

Are these correct? Reply with any corrections or type the classification for item 3.
```

Wait for the user's confirmation. Use their answers to build the final `inputs` list.

---

## Step 5: Detect Security-Relevant Features

Based on the input documents read in Step 4 and the stack detected in Step 2, scan for indicators of the following security-relevant features:

| Feature Flag | Positive Indicators |
|---|---|
| `has_authentication` | "login", "signup", "register", "session", "JWT", "OAuth", "auth", "password", "user account" |
| `has_file_upload` | "upload", "file", "image", "attachment", "S3", "blob", "storage", "multipart" |
| `has_public_endpoints` | "public API", "open endpoint", "no auth", "unauthenticated", "webhook", "public route" |
| `has_write_operations` | "create", "update", "delete", "submit", "edit", "save", "POST", "PUT", "PATCH", "DELETE" |
| `has_personal_data` | "email", "name", "address", "CPF", "SSN", "phone", "PII", "GDPR", "LGPD", "personal data" |
| `has_payments` | "payment", "checkout", "billing", "Stripe", "invoice", "subscription", "credit card" |
| `has_forms` | "form", "input", "textarea", "submit button", "contact form", "wizard", "survey" |
| `has_external_urls` | "redirect", "URL", "link", "external", "iframe", "SSRF", "fetch external", "proxy" |

Present your detections and ask the user to confirm:

```
Security-relevant features detected:

  has_authentication:    true   (JWT and "login" found in spec)
  has_file_upload:       false
  has_public_endpoints:  true   (webhook endpoints found)
  has_write_operations:  true   (CRUD operations described)
  has_personal_data:     true   (email and "LGPD" mentioned)
  has_payments:          true   (Stripe vars in .env.example)
  has_forms:             true   (contact form in spec)
  has_external_urls:     false

Are these correct? Reply with any corrections (e.g., "set has_file_upload to true").
```

Wait for the user's confirmation.

---

## Step 6: Generate `.aegis/config.yaml`

Using all information collected in Steps 1–5, write `.aegis/config.yaml` inside the `.aegis/` directory at the project root.

The file must conform exactly to this schema:

```yaml
# .aegis/config.yaml — generated by /aegis:init on <ISO date>
version: "1"

project:
  name: "<project name — infer from package.json, pyproject.toml, or ask if not found>"

formalism: <light | standard | formal>

stack:
  runtime: "<detected runtime, e.g., Node.js, Python, Go>"
  language: "<detected language, e.g., TypeScript, Python, Go>"
  framework: "<detected framework or null>"
  orm: "<detected ORM or null>"
  services: []        # list of services from docker-compose or similar
  integrations: []    # list of third-party integrations inferred from .env

inputs:
  # list each classified input document
  - path: "<relative path from project root>"
    type: "<product-spec | brand-guide | business-plan | security | api-docs | auto>"

output:
  dir: .aegis/

security_features:
  has_authentication: <true | false>
  has_file_upload: <true | false>
  has_public_endpoints: <true | false>
  has_write_operations: <true | false>
  has_personal_data: <true | false>
  has_payments: <true | false>
  has_forms: <true | false>
  has_external_urls: <true | false>

build:
  verifyCommand: "<detected verify command, e.g., 'pnpm build && pnpm test', or null>"

context7:
  api_key: "YOUR_KEY_HERE"
```

Rules:
- `project.name`: infer from `package.json` (`name` field), `pyproject.toml` (`[project] name`), or `go.mod` (module path). If not found, ask the user.
- `build.verifyCommand`: infer from the detected stack — look for `scripts.build` and `scripts.test` in `package.json`, `Makefile` targets, `pyproject.toml` scripts, `Cargo.toml`, etc. Combine build and test commands with `&&` (e.g., `"pnpm build && pnpm test"`). If only one exists, use that. If neither can be detected, set to `null`. The build stop hook uses this command to gate task completion — when set, the agent cannot signal TASK_COMPLETE if this command fails.
- Do not omit any field. Use `null` for optional string fields that were not detected.
- Use `[]` for empty list fields.
- Do not add comments beyond the header comment.
- Write the file using the Write tool. Do not print the file contents to the user — just confirm it was written.

---

## Step 7: Confirm and Next Step

> Note: Output directories (`.aegis/`, `.aegis/reports/`, `.aegis/tests/`) were already created by the bootstrap script.

Display a concise summary of everything configured:

```
Aegis Framework initialized.

  Project:      <name>
  Formalism:    <light | standard | formal>
  Stack:        <runtime>, <framework>
  Input docs:   <count> file(s) registered
  Security:     <count of true flags> feature flags active

Files written:
  .aegis/config.yaml
  .aegis/reports/   (created)
  .aegis/tests/          (created)
```

Then display the Context7 tip:

```
Tip — Context7 documentation lookup:

  Aegis can fetch up-to-date library documentation via Context7 during the
  design, ui-design, tasks, and tests phases. To enable it, open
  .aegis/config.yaml and replace the placeholder:

    context7:
      api_key: "YOUR_KEY_HERE"   ←  paste your Context7 API key here

  Get a free key at https://context7.com. If you leave the placeholder
  as-is, Aegis will use WebSearch as fallback — no action required.
```

Then display the status line tip:

```
Tip — Build progress in status line:

  Aegis can show live build progress (current task, completion count) in
  Claude Code's status line. To enable it, add this to your
  .claude/settings.json:

    {
      "hooks": {
        "StatusLine": [
          {
            "type": "command",
            "command": "bash .claude/aegis/scripts/aegis-build-statusline.sh"
          }
        ]
      }
    }

  The status line is only visible during an active build — it shows
  nothing when no build is running.
```

Then display the next step:

```
Next step: run /aegis:requirements to generate requirements.md from your input documents.
```

Do not print any additional commentary. The init flow is complete.

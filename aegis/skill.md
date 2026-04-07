---
name: aegis
description: >
  Aegis Framework — Generate and maintain structured software design documents
  (requirements, design, tasks, tests) from project input docs. Includes
  embedded security, bidirectional traceability, and TDD test generation.
  Use /aegis to see available commands.
---

# Aegis Framework

Generate and maintain five structured software design artifacts — **requirements**, **design**, **ui-design**, **tasks**, and **tests** — from project input documents. Enforces bidirectional traceability, injects security requirements unconditionally, and produces TDD-ready test files.

## Available Commands

| Command | Description |
|---------|-------------|
| `/aegis:init` | Initialize Aegis in a project — set level, stack, inputs |
| `/aegis:requirements` | Generate requirements.md from input docs |
| `/aegis:design` | Generate design.md from requirements |
| `/aegis:ui-design` | Generate ui-design.md — frontend/UI design specification |
| `/aegis:tasks` | Generate tasks.md from design + requirements |
| `/aegis:tests` | Generate tests.md + RED test files |
| `/aegis:build` | Implement tasks from tasks.md — autonomous build loop |
| `/aegis:validate` | Full validation — coverage matrix, security audit, gaps |
| `/aegis:update [artifact]` | Update an artifact and check downstream impact |
| `/aegis:status` | Show current Aegis state, coverage, next steps |

---

To get started, run `/aegis:init` in your project.

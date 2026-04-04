# SDD Input Doc Types — Recommended Reference

> **Purpose**: This document defines the recognized input document types for the SDD framework, how auto-classification works, and the merge rules for the `security` type.
>
> Input docs are the raw materials fed to the `/sdd` skill before artifact generation. The skill reads, classifies, and synthesizes them into requirements, design, tasks, and tests.

---

## Recognized Types

| Type | ID | Description | Auto-detection signals |
|---|---|---|---|
| Product Specification | `product-spec` | Features, user flows, and pricing. Describes what the product does and for whom. | "feature", "user flow", "pricing", "product", "MVP", "persona", "use case" |
| Brand Guide | `brand-guide` | Colors, typography, and tone of voice. Defines visual identity and communication style. | "color", "palette", "typography", "font", "brand", "tone", "voice", "logo" |
| Business Plan | `business-plan` | Market, metrics, revenue model, and strategy. Frames the commercial context. | "market", "revenue", "metric", "ROI", "TAM", "growth", "retention", "funnel" |
| Security Guidelines | `security` | Project-specific security rules. Merged with `SECURITY_UNIVERSAL.md` at generation time. | "OWASP", "XSS", "CSRF", "injection", "authentication", "authorization", "CVE", "pentest" |
| API Documentation | `api-docs` | External API documentation. Describes endpoints, payloads, and integration contracts. | "endpoint", "API", "REST", "GraphQL", "webhook", "OpenAPI", "swagger", "payload" |
| Unclassified | `auto` | Catch-all. The skill auto-classifies documents that do not match any type above. | *(no fixed signals — skill uses full-document analysis)* |

---

## Auto-classification Logic

When an input document has no explicit `type:` front-matter field, the skill classifies it automatically.

### Algorithm

1. **Signal scan**: The skill scans the document for keyword signals defined in the table above.
2. **Keyword density**: For each candidate type, it computes the ratio of matched signals to total signal vocabulary for that type.
3. **Confidence threshold**: A type is assigned if its keyword density score reaches **70% confidence** or higher. Confidence is estimated as:

   ```
   confidence = (matched_signals_for_type / total_signals_for_type) * weight_by_position
   ```

   Signals in headings and the first 20% of the document carry higher weight than signals in body text.

4. **Conflict resolution**: If two types score above 70%, the one with higher density wins. If scores are within 5% of each other, the document is classified as `auto` and a warning is emitted.
5. **Fallback**: Documents that match no type at ≥ 70% confidence are classified as `auto`. The skill extracts content as best it can and notes the classification uncertainty in the generation log.

### Front-matter override

Any document with a `type:` field in its YAML front-matter bypasses auto-classification entirely:

```yaml
---
type: product-spec
project: my-project
---
```

---

## Merge Rules — `security` Type

The `security` type is the only input type with special merge semantics. It does **not** replace the baseline — it is merged on top of `SECURITY_UNIVERSAL.md`.

### Rules

| Rule | Description |
|---|---|
| **Add to baseline** | Project-specific rules are appended to the universal baseline. They extend coverage; they do not replace it. |
| **Can increase rigor** | A project rule may make a baseline control stricter (e.g., lower rate-limit thresholds, require MFA universally). |
| **Cannot remove baseline** | No project security doc may disable, skip, or weaken any control defined in `SECURITY_UNIVERSAL.md`. A project doc that attempts to do so is rejected at validation time with a hard error. |
| **N/A with justification** | A project may mark a baseline control as not applicable, but only by providing a written justification. The control remains visible in the generated artifacts, flagged as `[N/A — <reason>]`. Silent omissions are not permitted. |

### N/A example

```markdown
## Overrides

### SEC-REQ-CSRF — N/A
**Justification**: This project is a stateless REST API that uses token-based authentication
(JWT in Authorization header). It does not use cookies for session management, so CSRF
attacks are not applicable. All endpoints require a valid Bearer token.
```

Even with an N/A justification, the generated `requirements.md` will include `SEC-REQ-CSRF` with the N/A flag and the justification text visible, so reviewers can audit the decision.

---

## Usage Notes

- **Order does not matter**: The skill processes all input docs before generating any artifact. Input docs may be provided in any order.
- **Multiple docs of the same type**: Allowed. The skill merges them before synthesis (e.g., two product-spec files are treated as one combined specification).
- **Missing inputs**: The skill will proceed with available inputs but will log which types are absent. A missing `security` input means only `SECURITY_UNIVERSAL.md` is applied — this is valid and expected for most projects.
- **Language**: Input docs may be written in any language. The generated artifacts will match the language of the input docs, except for IDs and keywords which are always in English.

---
type: security
project: [project-name]
version: 1.0
date: [YYYY-MM-DD]
---

# Security Guidelines — [Project Name]

> **IMPORTANT — READ BEFORE EDITING**
>
> This document defines **project-specific** security rules. It is **merged with `SECURITY_UNIVERSAL.md`** at Aegis generation time, not used in its place.
>
> **Merge semantics**:
> - Rules in this document **add to** the universal baseline. They do not replace it.
> - You may make a baseline control **stricter** (e.g., require shorter token expiry than the universal default).
> - You **cannot remove or weaken** any control from the baseline. Any attempt to do so will be rejected at validation time.
> - You may mark a baseline control as **not applicable** for this project, but only with a written justification. See the Overrides section below.
>
> If this file is empty or absent, only `SECURITY_UNIVERSAL.md` applies — which is valid for most projects.

---

## 1. Project-Specific Rules

[Add project-specific security rules in this section. Each rule should have a short ID (prefixed with `PROJ-SEC-`), a clear statement of what is required, and a rationale explaining why it applies to this project specifically.]

[If this project uses a particular tech stack, compliance framework, or threat model that introduces requirements beyond the universal baseline, document them here. Examples: PCI-DSS requirements for payment processing, LGPD/GDPR data residency constraints, HIPAA PHI handling rules, specific third-party API trust requirements.]

### PROJ-SEC-001 — [Rule Name]

**Applies to**: [The specific component, endpoint, data type, or scenario this rule governs]

**Requirement**: [A precise, testable statement of what the system must do or not do]

**Rationale**: [Why this rule is necessary for this specific project — link to a regulation, threat, or business constraint]

**Implementation notes**: [Optional. Any implementation guidance specific to this project's stack]

---

### PROJ-SEC-002 — [Rule Name]

**Applies to**:

**Requirement**:

**Rationale**:

**Implementation notes**:

---

[Add more PROJ-SEC-NNN entries as needed. Remove empty entries before submitting.]

---

## 2. Stricter Baseline Controls

[Use this section to tighten a universal baseline control for this project. Reference the original control ID from `SECURITY_UNIVERSAL.md`. Specify the stricter threshold and the reason.]

[If no baseline controls need to be made stricter, write: "None — universal baseline thresholds apply to all controls."]

### [Original Control ID] — Stricter threshold

**Original rule**: [Quote or paraphrase the baseline rule]

**Project threshold**: [The stricter value or constraint that applies to this project]

**Reason**: [Why this project needs a stricter threshold, e.g., "This system processes financial transactions. Rate limiting on auth endpoints is reduced to 3 attempts per 15-minute window instead of the baseline 5."]

---

## 3. Overrides (N/A Declarations)

[Use this section ONLY to declare that a baseline control is not applicable to this project. Each N/A declaration must include the original control ID, a clear written justification, and confirmation that the threat is genuinely absent — not merely inconvenient to implement.]

[Even with an N/A declaration, the control will remain visible in the generated `requirements.md` and `design.md`, flagged as `[N/A — <reason>]`. This ensures reviewers can audit the decision and reverse it if the project context changes.]

[If no controls are N/A, write: "None — all universal baseline controls apply."]

---

### Example N/A Declaration (remove before submitting)

#### SEC-REQ-CSRF — N/A

**Justification**: This project is a stateless REST API that uses token-based authentication
(JWT passed in the `Authorization: Bearer` header). It does not use cookies for session
management at any point. Because CSRF attacks require cookie-based session state to be
exploitable, this control is not applicable to this project.

**Confirmation**: The project has been reviewed to ensure no endpoint relies on cookie-based
authentication now or in any planned future phase. If cookies are introduced in a future
phase, this N/A declaration must be revoked and SEC-REQ-CSRF must be fully implemented.

---

[Add your actual N/A declarations below, following the format above:]

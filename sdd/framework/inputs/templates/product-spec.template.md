---
type: product-spec
project: [project-name]
version: 1.0
date: [YYYY-MM-DD]
---

# Product Specification — [Project Name]

> **Instructions**: Fill in each section below. Be concrete — avoid vague language like "easy to use" or "scalable". The SDD skill will extract requirements directly from this document, so specificity here directly improves the quality of generated artifacts.
>
> Remove all instruction text in brackets before submitting.

---

## 1. Overview

[One to three paragraphs describing the product. Answer: What is it? Who is it for? What problem does it solve? Why does this product need to exist now?]

**Target users**: [Primary user persona(s) — role, context, technical level]

**Core value proposition**: [One sentence. What does the user gain that they cannot easily get elsewhere?]

---

## 2. Products and Features

[List the features or product areas this specification covers. For each feature, describe what it does, who uses it, and what the expected behavior is. Use sub-sections for major features.]

### 2.1 [Feature Name]

**Description**: [What this feature does in plain language]

**Users**: [Which persona(s) use this feature]

**Expected behavior**:
- [Behavior 1 — write as an observable outcome, e.g., "User can upload a CSV file up to 10 MB"]
- [Behavior 2]
- [Behavior 3]

**Out of scope**: [What this feature explicitly does NOT do in this version]

### 2.2 [Feature Name]

[Repeat structure above for each major feature]

---

## 3. User Journey

[Describe the end-to-end flow a user takes to accomplish their primary goal. Use a numbered step-by-step format. If there are multiple distinct journeys (e.g., onboarding vs. daily use), add a sub-section for each.]

### 3.1 [Journey Name — e.g., "New User Onboarding"]

1. [Step 1 — describe what the user does and what the system responds]
2. [Step 2]
3. [Step 3]
4. [...]

**Success state**: [What does it look like when the user completes this journey successfully?]

**Failure states**: [What can go wrong? How does the system handle it?]

### 3.2 [Journey Name — e.g., "Core Task Flow"]

[Repeat structure above]

---

## 4. Integrations

[List external systems, APIs, or services this product integrates with. For each, specify the direction of data flow and what it is used for.]

| Integration | Direction | Purpose | Notes |
|---|---|---|---|
| [Service name] | [Inbound / Outbound / Bidirectional] | [What it is used for] | [Any constraints, rate limits, or authentication requirements] |
| [Service name] | | | |

[If there are no integrations, write: "None at this stage."]

---

## 5. Metrics

[Define how success will be measured. List the key metrics this product must achieve or track. Be specific — include target values where known.]

### 5.1 Business Metrics

| Metric | Target | Measurement Method |
|---|---|---|
| [e.g., Monthly Active Users] | [e.g., 1,000 in 90 days] | [e.g., analytics platform event tracking] |
| | | |

### 5.2 Technical / Performance Metrics

| Metric | Target | Notes |
|---|---|---|
| [e.g., API response time (p95)] | [e.g., < 300 ms] | [e.g., measured at application layer, excluding client network] |
| [e.g., Uptime] | [e.g., 99.5%] | |

### 5.3 User Experience Metrics

[Optional. Include if there are UX or engagement metrics relevant to this product, e.g., task completion rate, time-on-task, NPS.]

| Metric | Target | Notes |
|---|---|---|
| | | |

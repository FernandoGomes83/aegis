---
type: business-plan
project: [project-name]
version: 1.0
date: [YYYY-MM-DD]
---

# Business Plan — [Project / Company Name]

> **Instructions**: Fill in each section below. The SDD skill uses this document to extract non-functional and business-context requirements — constraints on scale, revenue model mechanics that require technical support, compliance obligations, and strategic milestones that affect phasing. Be concrete with numbers where you have them; use ranges or estimates where you don't.
>
> Remove all instruction text in brackets before submitting.

---

## 1. Executive Summary

[2–4 paragraphs covering the full picture at a high level. Answer: What is the business? What problem does it solve? What is the market opportunity? How does it make money? What is the current stage and ask?]

**Company / product name**: [Name]

**Stage**: [e.g., Idea, Pre-seed, MVP, Seed, Series A, Growth]

**One-line pitch**: [The elevator pitch — what you do, for whom, and why it matters, in one sentence]

---

## 2. Product

[Describe the product from a business perspective — not the technical spec, but what it does for customers and why they will pay for it. Link to the product-spec input doc if one exists.]

**Core product**: [What the product does]

**Key differentiators**: [What makes this product different from existing alternatives]

**Current status**: [What exists today — prototype, beta, production, none]

**Roadmap summary**:
- **Phase 1** ([Timeframe]): [What will be built / launched]
- **Phase 2** ([Timeframe]): [Next major milestone]
- **Phase 3** ([Timeframe]): [Further out goals]

---

## 3. Market

[Define the market opportunity with enough specificity to justify the product and inform scale requirements.]

### 3.1 Market Size

| Segment | Size | Source / Basis |
|---|---|---|
| TAM (Total Addressable Market) | [e.g., $4.2B] | [e.g., Industry report, year] |
| SAM (Serviceable Addressable Market) | | |
| SOM (Serviceable Obtainable Market) | | |

### 3.2 Target Segments

[Describe the primary and secondary customer segments. For each, include who they are, their key pain point, and why this product is the right solution.]

**Primary segment**: [Name / description]
- Pain point: [What problem they have that this product solves]
- Why this product: [Why they would choose this over alternatives]
- Size / reach: [Estimated number of potential customers in this segment]

**Secondary segment**: [Name / description]
- Pain point:
- Why this product:
- Size / reach:

### 3.3 Competitive Landscape

| Competitor | Strengths | Weaknesses | Our differentiation |
|---|---|---|---|
| [Name] | | | |
| [Name] | | | |

---

## 4. Revenue Model

[Define how the business makes money. Be specific about pricing, tiers, and billing mechanics — these directly inform technical requirements for payment, access control, and usage tracking.]

### 4.1 Revenue Streams

| Stream | Type | Description |
|---|---|---|
| [e.g., SaaS subscriptions] | [e.g., Recurring] | [e.g., Monthly/annual plans billed per seat or per usage] |
| [e.g., One-time setup fee] | [e.g., One-time] | |
| [e.g., Marketplace commission] | [e.g., Transaction %] | |

### 4.2 Pricing Tiers

[Define each pricing tier. Be explicit — the SDD skill uses this to generate access control and billing requirements.]

| Tier | Price | Billing | Included | Limits |
|---|---|---|---|---|
| [e.g., Free] | [e.g., $0] | [e.g., N/A] | [e.g., Core features, 1 project] | [e.g., 100 requests/month] |
| [e.g., Pro] | [e.g., $29/mo] | [e.g., Monthly or annual] | [e.g., All features, unlimited projects] | [e.g., 10,000 requests/month] |
| [e.g., Enterprise] | [e.g., Custom] | [e.g., Annual contract] | [e.g., SSO, audit logs, SLA] | [e.g., Custom] |

### 4.3 Unit Economics

[Fill in the known or projected unit economics. Use estimates if exact numbers are not yet available.]

| Metric | Value | Notes |
|---|---|---|
| Average Revenue Per User (ARPU) | | |
| Customer Acquisition Cost (CAC) | | |
| Customer Lifetime Value (LTV) | | |
| LTV:CAC ratio | | [Target: > 3:1] |
| Gross margin | | |
| Churn rate (monthly) | | |

---

## 5. Strategy and Phases

[Describe the go-to-market strategy and execution phases. This section informs milestone-based requirements and phased rollout constraints.]

### 5.1 Go-to-Market Strategy

**Primary acquisition channel**: [e.g., Content marketing, paid search, product-led growth, partnerships, direct sales]

**Launch strategy**: [e.g., Private beta with 50 design agencies in Q1, public launch in Q2]

**Key partnerships**: [Any distribution, technology, or channel partners]

### 5.2 Execution Phases

| Phase | Timeframe | Goal | Success Criteria |
|---|---|---|---|
| [e.g., Private Beta] | [e.g., Month 1–2] | [e.g., Validate core flow with 25 real users] | [e.g., 80% task completion rate, < 10% churn in beta] |
| [e.g., Public Launch] | | | |
| [e.g., Growth] | | | |

### 5.3 Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| [e.g., Low initial adoption] | [High / Med / Low] | [High / Med / Low] | [e.g., Offer free migration from competitor, dedicated onboarding] |
| | | | |

---

## 6. Metrics

[Define the key metrics the business will track. These become non-functional requirements and inform the analytics and observability design.]

### 6.1 North Star Metric

**North star**: [The single metric that best captures the core value delivered to customers, e.g., "Weekly active teams publishing at least one design spec"]

**Why this metric**: [Why this reflects genuine product value, not just activity]

### 6.2 Key Performance Indicators

| Metric | Current | Target (3 mo) | Target (12 mo) | Measurement |
|---|---|---|---|---|
| Monthly Active Users (MAU) | | | | |
| Monthly Recurring Revenue (MRR) | | | | |
| Customer Acquisition Cost (CAC) | | | | |
| Activation rate (% new users who complete core action) | | | | |
| Monthly churn rate | | | | |
| Net Promoter Score (NPS) | | | | |

### 6.3 Operational Metrics

[Metrics the engineering and operations team will track. These directly inform SLOs and observability requirements.]

| Metric | Target | Notes |
|---|---|---|
| [e.g., API uptime] | [e.g., 99.5%] | |
| [e.g., p95 response time] | [e.g., < 500 ms] | |
| [e.g., Error rate] | [e.g., < 0.1%] | |
| [e.g., Support ticket volume] | [e.g., < 5% of MAU per month] | |

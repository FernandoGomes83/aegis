# Interview Dimensions

> Shared module — loaded by `/aegis:requirements` when interview mode is active.
> Defines the five clarification dimensions, scoring criteria, question
> strategies, and depth profiles used during the requirements interview loop.

---

## Dimensions

| # | Dimension | Weight | What it clarifies |
|---|-----------|--------|-------------------|
| 1 | **Intent** | 0.25 | What problem does this solve? Why now? |
| 2 | **Scope** | 0.25 | What's in, what's explicitly out? |
| 3 | **Users** | 0.20 | Who uses this? What are their key flows? |
| 4 | **Constraints** | 0.15 | Tech stack, deadlines, compliance, budget |
| 5 | **Success criteria** | 0.15 | How do we know it's done and working? |

---

## Scoring Criteria

Each dimension gets a clarity score from **0.0** (unknown) to **1.0** (fully clear).

### Initial scoring from input documents

| Input signal | Score range |
|---|---|
| Dimension mentioned with specifics (numbers, names, concrete examples) | 0.8–1.0 |
| Dimension mentioned vaguely (general statements, no specifics) | 0.4–0.6 |
| Dimension not mentioned at all | 0.0–0.2 |

### Score updates after each answer

| Answer quality | Score adjustment |
|---|---|
| Concrete, detailed answer with specifics | Set to 0.8–1.0 |
| Partial or vague answer | Increase by 0.2–0.3 (cap at 1.0) |
| Non-informative answer ("I don't know", "whatever works") | Increase by 0.05 only |
| User skips the question | No change — mark dimension as `[ASSUMED]` |

### Overall ambiguity

**Overall ambiguity = 1.0 − weighted average of all dimension scores.**

The weighted average is:

```
weighted_avg = (intent × 0.25) + (scope × 0.25) + (users × 0.20)
             + (constraints × 0.15) + (success_criteria × 0.15)
```

Ambiguity threshold depends on the depth profile (see below).

---

## Question Strategy

For each dimension, questions follow a **pressure ladder** — start open, get
more specific. Ask **ONE question per round**, wait for the answer, then
re-score before asking the next.

### Intent

1. **Open:** "What problem does this solve for its users?"
2. **Evidence:** "Can you describe a specific situation where someone would reach for this?"
3. **Boundary:** "You mentioned [X] — is this primarily about [X] or does it also address [Y]?"
4. **Tradeoff:** "If you had to pick one core problem this solves, what would it be?"

### Scope

1. **Open:** "At a high level, what are the main things this system does?"
2. **Evidence:** "Can you walk through the most important user workflow end-to-end?"
3. **Boundary:** "Is [feature implied by context] in scope for this version, or a future addition?"
4. **Tradeoff:** "If you had to cut one major feature to ship on time, which would it be?"

### Users

1. **Open:** "Who are the primary users of this system?"
2. **Evidence:** "What does a typical session look like for [user type]?"
3. **Boundary:** "Are there admin or internal users with different permissions, or just one user type?"
4. **Tradeoff:** "Which user type's experience matters most if there's a conflict?"

### Constraints

1. **Open:** "Are there any technical, timeline, or regulatory constraints I should know about?"
2. **Evidence:** "Is there an existing system this needs to integrate with or replace?"
3. **Boundary:** "Are there specific technologies that are required or ruled out?"
4. **Tradeoff:** "What's the harder constraint — timeline, budget, or technical complexity?"

### Success criteria

1. **Open:** "How will you know this project is successful?"
2. **Evidence:** "What's the first thing you'd check after launch to see if it's working?"
3. **Boundary:** "Are there specific metrics or thresholds that define success (e.g., response time, user count)?"
4. **Tradeoff:** "If you could only measure one thing, what would it be?"

### Non-informative answer handling

If the user gives a non-informative answer (very short, "I don't know", "up to
you") for the same dimension **twice in a row**:

1. Stop asking about that dimension.
2. Move to the next lowest-scoring dimension.
3. Mark the skipped dimension for `[ASSUMED]` treatment in the generated requirements.

---

## Depth Profiles

| Profile | Max rounds | Ambiguity threshold | When to use |
|---------|-----------|---------------------|-------------|
| `quick` | 3 | ≤ 0.35 | Brief clarification, input is mostly complete |
| `standard` | 8 | ≤ 0.25 | Default — covers major gaps |
| `deep` | 15 | ≤ 0.15 | Complex projects, compliance-sensitive work |

Set via:
- Flag: `/aegis:requirements --interview --depth=deep`
- Config: `requirements.interview.depth: standard`
- Default: `standard` if not specified

---

## Readiness Gates

Before proceeding to generation, these two items must be **explicitly stated**
(not inferred from context):

1. **Non-goals** — at least one thing that is explicitly out of scope.
2. **Success criteria** — at least one measurable or observable criterion.

If the interview loop completes (ambiguity ≤ threshold or max rounds reached)
but either gate is not met, ask the user directly:

> "Before I generate requirements, I need to confirm two things:
> 1. What is explicitly NOT in scope for this version?
> 2. How will you know this is working correctly?"

If the user declines to answer, proceed with generation and mark both as
`[ASSUMED]` in the output.

---

## Output Format

Interview results are **not** a separate artifact. They are compiled into an
`interview_context` string that is passed to the requirements agent alongside
other context.

### Structure

```markdown
## Interview Clarifications

**Mode:** interview ({{depth_profile}}, {{rounds_completed}} rounds, ambiguity: {{final_ambiguity}})

### Intent
{{user's clarified intent, or "[ASSUMED] — inferred from input documents" if not clarified}}

### Scope
{{user's clarified scope, or "[ASSUMED] — inferred from input documents" if not clarified}}

### Users
{{user's clarified users, or "[ASSUMED] — inferred from input documents" if not clarified}}

### Constraints
{{user's clarified constraints, or "[ASSUMED] — inferred from input documents" if not clarified}}

### Success Criteria
{{user's clarified success criteria, or "[ASSUMED] — inferred from input documents" if not clarified}}

### Non-goals (explicitly stated)
{{list of non-goals, or "[ASSUMED] — no explicit non-goals provided"}}
```

The requirements agent uses this context to ground its generation. Dimensions
marked `[ASSUMED]` carry through to the generated `requirements.md` as
`[ASSUMED]` tags on the relevant REQ-NNN entries.

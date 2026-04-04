---
type: brand-guide
project: [project-name]
version: 1.0
date: [YYYY-MM-DD]
---

# Brand Guide — [Project / Product Name]

> **Instructions**: Fill in each section below. The Aegis skill uses this document to ensure generated design artifacts reflect brand constraints — particularly in UI components, copy tone, and visual decisions. The more concrete the values here, the less ambiguity in downstream design decisions.
>
> Remove all instruction text in brackets before submitting.

---

## 1. Brand Essence

[A short description of the brand's identity, personality, and positioning. Answer: What does this brand stand for? How should users feel when they interact with it?]

**Mission statement**: [One sentence — what the brand does and for whom]

**Brand personality traits**: [3–5 adjectives that describe the brand's character, e.g., "confident, approachable, precise, modern"]

**Brand is NOT**: [2–3 traits the brand actively avoids, e.g., "not corporate, not childish, not verbose"]

---

## 2. Color Palette

[Define all colors used in the product. Always include hex codes. Group by role.]

### Primary Colors

| Role | Name | Hex | Usage |
|---|---|---|---|
| Primary | [e.g., Ocean Blue] | [e.g., #1A73E8] | [e.g., CTAs, links, primary buttons] |
| Primary Dark | | | [e.g., Hover states on primary] |
| Primary Light | | | [e.g., Backgrounds, subtle highlights] |

### Secondary / Accent Colors

| Role | Name | Hex | Usage |
|---|---|---|---|
| Accent | | | |
| | | | |

### Neutrals

| Role | Name | Hex | Usage |
|---|---|---|---|
| Background | | | [e.g., Page background] |
| Surface | | | [e.g., Card, panel background] |
| Border | | | [e.g., Dividers, input borders] |
| Text Primary | | | [e.g., Body text, headings] |
| Text Secondary | | | [e.g., Captions, placeholders] |

### Semantic Colors

| Role | Name | Hex | Usage |
|---|---|---|---|
| Success | | | [e.g., Confirmation messages, success states] |
| Warning | | | [e.g., Non-critical alerts] |
| Error | | | [e.g., Validation errors, destructive actions] |
| Info | | | [e.g., Informational banners] |

**Accessibility notes**: [Minimum contrast ratios required, e.g., "All text on background must meet WCAG AA (4.5:1). Error color must meet WCAG AA on white."]

---

## 3. Typography

[Define the typefaces and type scale used in the product.]

### Typefaces

| Role | Font Family | Weight(s) | Source |
|---|---|---|---|
| Headings | [e.g., Inter] | [e.g., 700, 600] | [e.g., Google Fonts] |
| Body | [e.g., Inter] | [e.g., 400, 500] | |
| Monospace / Code | [e.g., JetBrains Mono] | [e.g., 400] | |

### Type Scale

| Level | Element | Size | Line Height | Weight | Notes |
|---|---|---|---|---|---|
| H1 | Page title | [e.g., 2.25rem] | [e.g., 1.2] | [e.g., 700] | |
| H2 | Section title | | | | |
| H3 | Sub-section | | | | |
| Body | Default text | [e.g., 1rem] | [e.g., 1.5] | [e.g., 400] | |
| Small | Captions, labels | | | | |
| Code | Inline code | | | | |

**Notes**: [Any additional typography rules, e.g., "Never use more than two font weights in a single view", "Headings are always sentence case"]

---

## 4. Tone of Voice

[Define how the brand communicates in writing. This section informs UI copy, error messages, onboarding text, and any generated documentation.]

### Voice Characteristics

[Describe the brand voice in concrete, observable terms. Avoid generic adjectives — show examples.]

| Characteristic | Do | Don't |
|---|---|---|
| [e.g., Direct] | [e.g., "Your file is ready to download."] | [e.g., "Your file has been successfully prepared and is now available for you to download at your convenience."] |
| [e.g., Human] | [e.g., "Something went wrong. Try again?"] | [e.g., "Error 500: Internal Server Error. Please contact support."] |
| [e.g., Confident] | [e.g., "Create your account."] | [e.g., "Feel free to create your account if you'd like!"] |

### Writing Rules

- [Rule 1 — e.g., "Use second person ('you') for instructions and CTAs"]
- [Rule 2 — e.g., "Never use passive voice in error messages"]
- [Rule 3 — e.g., "Oxford comma required in all lists"]
- [Rule 4 — e.g., "Numbers below 10 are spelled out in body copy; numerals in UI labels"]

### Vocabulary

**Preferred terms**: [List any brand-specific terms, preferred names for features, or preferred spellings, e.g., "Use 'workspace', not 'project'. Use 'sign in', not 'log in'."]

**Avoid**: [Terms or phrases the brand never uses, e.g., "Never use 'leverage', 'synergy', or 'utilize'"]

---

## 5. Visual Components

[Define the visual language for UI elements. This section informs component-level design decisions.]

### Spacing and Layout

- **Base unit**: [e.g., 4px grid]
- **Border radius**: [e.g., "Small components: 4px. Cards: 8px. Modals: 12px. Pills/badges: 999px"]
- **Shadow**: [e.g., "Elevation 1 (cards): 0 1px 3px rgba(0,0,0,0.12). Elevation 2 (dropdowns): 0 4px 12px rgba(0,0,0,0.15)"]

### Buttons

| Variant | Background | Text | Border | Use Case |
|---|---|---|---|---|
| Primary | | | | [e.g., Main CTA] |
| Secondary | | | | [e.g., Secondary action] |
| Destructive | | | | [e.g., Delete, remove] |
| Ghost | | | | [e.g., Tertiary action, cancel] |

### Icons

**Icon set**: [e.g., Lucide Icons, Heroicons, Phosphor Icons]

**Default size**: [e.g., 16px inline, 20px in buttons, 24px standalone]

**Stroke weight**: [e.g., 1.5px]

### Imagery and Illustration

[Describe the visual style for images, illustrations, or graphics if applicable. If not applicable, write "None — this product uses text and icon-based UI only."]

---

## 6. Logo

[Describe the logo and its usage rules. If providing the logo file path, include it here.]

**Logo file(s)**: [e.g., `/assets/logo/logo-full.svg`, `/assets/logo/logo-mark.svg`]

**Minimum size**: [e.g., "Logo mark: minimum 24px height. Full logo: minimum 120px width"]

**Clear space**: [e.g., "Maintain clear space equal to the height of the letter 'O' on all sides"]

**Approved backgrounds**: [e.g., "White, brand primary, brand dark. Never place on a busy photo or low-contrast background."]

**Color variations**:
| Variation | Usage |
|---|---|
| Full color | [e.g., Default — use on white and light backgrounds] |
| White / reversed | [e.g., Use on dark or primary-colored backgrounds] |
| Monochrome | [e.g., Use only for print or single-color contexts] |

**Do not**:
- [e.g., Stretch or distort the logo]
- [e.g., Rotate the logo]
- [e.g., Apply drop shadows or other effects]
- [e.g., Use unapproved color combinations]

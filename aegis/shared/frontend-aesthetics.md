# Frontend Aesthetics Guidelines

<!-- Source: frontend-design plugin SKILL.md — periodic manual sync -->

When implementing frontend/UI components, follow these aesthetic rules to produce
distinctive, production-grade interfaces. Avoid generic "AI slop" aesthetics.

## Design Thinking

Before coding, commit to a BOLD aesthetic direction:
- **Purpose**: What problem does this interface solve? Who uses it?
- **Tone**: Pick a clear direction — brutally minimal, maximalist, retro-futuristic,
  organic/natural, luxury/refined, playful, editorial, brutalist, art deco, soft/pastel,
  industrial/utilitarian, etc. Execute with precision and intentionality.
- **Differentiation**: What makes this UNFORGETTABLE? What's the ONE memorable element?

## Aesthetic Rules

- **Typography**: Choose distinctive, characterful fonts. Pair a display font with a
  refined body font. Avoid generic choices (Arial, Inter, Roboto, system fonts).
- **Color & Theme**: Cohesive palette with CSS variables. Dominant colors with sharp
  accents outperform timid, evenly-distributed palettes.
- **Motion**: High-impact animations — staggered reveals on load, scroll-triggering,
  surprising hover states. CSS-only for HTML; Motion library for React when available.
  One well-orchestrated moment beats scattered micro-interactions.
- **Spatial Composition**: Unexpected layouts. Asymmetry, overlap, diagonal flow,
  grid-breaking elements. Generous negative space OR controlled density.
- **Backgrounds & Visual Details**: Create atmosphere and depth — gradient meshes,
  noise textures, geometric patterns, layered transparencies, dramatic shadows,
  decorative borders, grain overlays. Never default to flat solid colors.

## Anti-Patterns (NEVER use)

- Overused font families (Inter, Roboto, Arial, Space Grotesk, system fonts)
- Cliched color schemes (purple gradients on white backgrounds)
- Predictable layouts and cookie-cutter component patterns
- Same aesthetic across different interfaces — vary themes, fonts, palettes

Match implementation complexity to the vision. Maximalist designs need elaborate code.
Minimalist designs need restraint, precision, and careful spacing/typography.

---
name: frontend-design
description: Create distinctive frontend interfaces with high design quality. Use this skill when the user asks to design, restyle, polish, or implement visual Web UI surfaces, components, pages, dashboards, React components, HTML/CSS layouts, or other interface presentation. Uses an Anthropic-compatible baseline with local quality and host adaptations. Do not use for repo-level Web app architecture, API/data integration, single-file artifact bundling, browser QA ownership, or product behavior invention.
---

This skill guides creation of distinctive frontend UI surfaces that avoid
generic "AI slop" aesthetics. Implement real working interface code when the
task is design-led, with exceptional attention to aesthetic details and
creative choices.

The user provides frontend requirements: a component, page, application, or interface to build. They may include context about the purpose, audience, or technical constraints.

## Maintenance Model

This `SKILL.md` is the single active workflow. It integrates the
Anthropic-compatible frontend design baseline with local quality and host
adaptations, following the same maintenance pattern as `skill-creator`:

- `references/anthropic-baseline.md` preserves the upstream baseline for
  refresh comparison.
- `references/anthropic-patch-manifest.md` records local differences from the
  upstream-derived baseline.
- `references/host-compatibility.md` records host assumptions and non-claims.

When this skill receives structured product artifacts, treat them as source
facts. Preserve supplied requirements, behavior, flows, states, and copy unless
the user explicitly asks for product changes. Rendered UI is an artifact, not a
product source of truth.

## Boundary With Webapp Builder

This skill owns visual direction, UI expression, design-system extraction,
interface polish, and faithful UI surface implementation. It may implement
working UI code when the task is design-led.

Use `webapp-builder` instead when the task is a real Web app implementation
inside a repository: app shell, route structure, state/data ownership, API
integration, framework architecture, shadcn project workflows, or production
build/test wiring.

When both apply, this skill provides the visual system, component treatment,
and fidelity target; `webapp-builder` owns the repo-level implementation.

## Design Thinking

Before coding, understand the context and commit to a BOLD aesthetic direction:
- **Purpose**: What problem does this interface solve? Who uses it?
- **Tone**: Pick an extreme: brutally minimal, maximalist chaos, retro-futuristic, organic/natural, luxury/refined, playful/toy-like, editorial/magazine, brutalist/raw, art deco/geometric, soft/pastel, industrial/utilitarian, etc. There are so many flavors to choose from. Use these for inspiration but design one that is true to the aesthetic direction.
- **Constraints**: Technical requirements (framework, performance, accessibility).
- **Differentiation**: What makes this UNFORGETTABLE? What's the one thing someone will remember?

**CRITICAL**: Choose a clear conceptual direction and execute it with precision. Bold maximalism and refined minimalism both work - the key is intentionality, not intensity.

Then implement working code (HTML/CSS/JS, React, Vue, etc.) that is:
- Production-grade and functional
- Visually striking and memorable
- Cohesive with a clear aesthetic point-of-view
- Meticulously refined in every detail

## Fidelity Rules

When a concrete design reference, product artifact, or accepted direction
exists, extract the local design system before implementation: tokens,
typography, component families, variants, spacing, icon treatment, and
container rules. Implement from those choices so repeated UI is coherent.

Track meaningful mismatches between the intended design and the rendered result
until each mismatch is fixed or explicitly accepted. For rendered frontend
work, plan browser-visible evidence before claiming completion; route concrete
rendered verification to `webapp-testing`.

## Frontend Aesthetics Guidelines

Focus on:
- **Typography**: Choose fonts that are beautiful, unique, and interesting. Avoid generic fonts like Arial and Inter; opt instead for distinctive choices that elevate the frontend's aesthetics; unexpected, characterful font choices. Pair a distinctive display font with a refined body font.
- **Color & Theme**: Commit to a cohesive aesthetic. Use CSS variables for consistency. Dominant colors with sharp accents outperform timid, evenly-distributed palettes.
- **Motion**: Use animations for effects and micro-interactions. Prioritize CSS-only solutions for HTML. Use Motion library for React when available. Focus on high-impact moments: one well-orchestrated page load with staggered reveals (animation-delay) creates more delight than scattered micro-interactions. Use scroll-triggering and hover states that surprise.
- **Spatial Composition**: Unexpected layouts. Asymmetry. Overlap. Diagonal flow. Grid-breaking elements. Generous negative space OR controlled density.
- **Backgrounds & Visual Details**: Create atmosphere and depth rather than defaulting to solid colors. Add contextual effects and textures that match the overall aesthetic. Apply creative forms like gradient meshes, noise textures, geometric patterns, layered transparencies, dramatic shadows, decorative borders, custom cursors, and grain overlays.

NEVER use generic AI-generated aesthetics like overused font families (Inter, Roboto, Arial, system fonts), cliched color schemes (particularly purple gradients on white backgrounds), predictable layouts and component patterns, and cookie-cutter design that lacks context-specific character.

Interpret creatively and make unexpected choices that feel genuinely designed for the context. No design should be the same. Vary between light and dark themes, different fonts, different aesthetics. NEVER converge on common choices (Space Grotesk, for example) across generations.

**IMPORTANT**: Match implementation complexity to the aesthetic vision. Maximalist designs need elaborate code with extensive animations and effects. Minimalist or refined designs need restraint, precision, and careful attention to spacing, typography, and subtle details. Elegance comes from executing the vision well.

Remember: Claude is capable of extraordinary creative work. Don't hold back, show what can truly be created when thinking outside the box and committing fully to a distinctive vision.

# Design System Format References

This workspace may reference external design-system format specifications when
they help agents read, write, review, or hand off design-system artifacts.

## DESIGN.md

Google's `DESIGN.md` project is an external format specification for describing
visual identity and design-system tokens to coding agents:

- Repository: https://github.com/google-labs-code/design.md
- Published specification: https://stitch.withgoogle.com/docs/design-md/specification

Treat it as a reference spec, not as source material to copy into this
workspace. The local docs should explain when the spec is relevant, where to
find the current upstream authority, and how it fits this workspace's skill
boundaries.

## Local Role

- Use the external spec as an input when a task explicitly asks for a
  `DESIGN.md` file, design-token handoff, agent-readable visual identity, or
  validation of a `DESIGN.md` artifact.
- Keep local guidance focused on routing, boundaries, and handoff expectations.
  Do not mirror the full upstream schema, examples, CLI reference, or release
  notes.
- Verify mutable details against the upstream spec before turning them into
  local rules, examples, templates, or validation commands.
- `skills/design-md-template/` owns source-tracked template inclusion and
  project application. A broader future `design-system` skill may still own
  component governance, token evolution, or contribution workflows if those
  become distinct tasks.

## Visual Reverse Engineering

Treat "image to DESIGN.md" as a shorthand, not the real workflow. The local
capability to build toward is:

```text
visual/design-system reverse engineering -> LLM-readable DESIGN.md
```

Valid evidence inputs can include:

- Website URLs, visible CSS, screenshots, and styleguide exports.
- Native app screenshots or screen recordings.
- Figma files, exported design tokens, or design-system documentation.
- Apple HIG, Apple Design Resources, and platform notes when creating Apple
  platform templates. Use `apple-design-resource` for current official Apple
  resource URLs, reachability, Product Bezels, fonts, SF Symbols app links, UI
  kits, and downloadable asset packages.
- LLM-assisted extraction with human review and correction.

The extraction pass should identify visual identity facts only: colors,
typography, spacing, density, component treatment, surfaces, material/depth,
motion/feedback style, responsive or platform adaptation notes, confidence,
and source references.

It should not infer product flow, state machines, action semantics, business
rules, onboarding logic, error recovery, permissions, or implementation APIs.
Those belong to interaction, product, platform guidance, or engineering
skills.

Candidate tools or upstreams such as screen-recording-to-DESIGN.md utilities,
URL/screenshot/styleguide analyzers, Stitch-style import/export flows, and
public DESIGN.md collections must be registered or reviewed through the normal
upstream intake path before they become local sources of truth. Do not treat a
tool's generated output as canonical without provenance, evidence scope, and
human acceptance.

## Boundary

`DESIGN.md` references do not belong in `interaction-design` unless the current
task needs interaction design judgment for a product surface. They also do not
belong in `sfsymbols-export`, which owns deterministic SF Symbols asset
generation only.

`DESIGN.md` templates can describe Apple platform appearance, including
materials, HIG-adjacent visual conventions, SF Symbols usage, or first-party app
surface language. Apple HIG and Swift/Liquid Glass skills still own native
primitive choice, API usage, availability, fallbacks, and implementation
correctness. `apple-design-resource` owns official Apple resource fetch,
catalog, probe, download, and extract operations. SwiftUI snippets inside an
upstream template are visual examples, not API authority.

Do not absorb or reword the upstream specification as if it were local design
authority. The local source of truth remains this workspace's skill boundaries
and docs; the external spec remains the authority for the `DESIGN.md` format
itself.

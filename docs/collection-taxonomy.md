# Routing Taxonomy

This repository is de-collectionized for local skills: root `skills/*` is the
active local public skill directory. Use marketplace plugin groups and docs to
express capability areas and lifecycle overlays.

## Active Skill Homes

| Home | Owns | Notes |
| --- | --- | --- |
| Root `skills/*` | All local product, design, Web, go-to-market, software-engineering, and skill-toolkit skills. | Add new local skills here. |
| External Swift checkout | Swift, SwiftUI, UIKit/AppKit, Xcode, Simulator, Instruments, Apple frameworks, and SwiftPM skills. | Source-owned in its own checkout; do not flatten into root. |

## Marketplace Groups

Marketplace plugin groups are discovery and install groupings. They may
overlap and are not ownership boundaries.

| Group | Purpose |
| --- | --- |
| `product-management` | Discovery, requirements, interaction design, and product prototype artifact generation. |
| `design-and-user-experience` | UX, Apple platform guidance, official Apple design resources, design-system files, SF Symbols, framework icon families, app icons, interface copy, and Web UI expression. |
| `build-webapp` | Web UI projection, shareable HTML artifacts, real Web app implementation, and browser QA. |
| `go-to-market` | Store readiness, launch copy, ASO, growth, search, paid acquisition, and market performance. |
| `software-engineering` | Planning, architecture, repository documentation, GitHub product organizations, deeplinks, and MCP/tool backends. |
| `skill-toolkit` | Upstream intake, distillation, skill creation, skill evolution, and Codex memory evolution. |

## Routing Rules

- Route by the work product the skill creates or reviews, not by the job title
  that might traditionally do the work.
- Keep each leaf skill routed by the artifact it owns. A workflow can call
  several leaf skills without merging their boundaries.
- Product source artifacts, Web prototype projections, real Web app
  implementation, and browser QA can appear in one lifecycle, but each still
  belongs to its atomic skill.
- Use root docs for lifecycle maps. Use `SKILL.md` frontmatter for automatic
  selection.
- Do not create local child collections for product, design, Web, market, or
  software-engineering work.

## New Skill Routing Checklist

When adding or absorbing a local skill:

1. Read root `AGENTS.md`, root docs, this taxonomy, and root marketplace
   metadata.
2. Identify the skill's primary output and user intent. Use verbs before
   nouns: discover, decide, model, write, review, launch, market, implement,
   validate, debug, operate, audit, or evolve.
3. Add the skill directly under root `skills/<skill-name>/`.
4. Register it in root `.claude-plugin/marketplace.json` under one or more
   meaningful plugin groups.
5. Update root docs only when the lifecycle or capability map changes.
6. Run the relevant `skill-creator` validation and `git diff --check`.

## Historical Collections

Former local `product-experience` and `software-engineering` child collections
are retired. Historical material lives under `docs/provenance/` and is not
active routing authority.

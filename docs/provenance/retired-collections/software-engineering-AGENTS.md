> Historical provenance: This retired collection document is kept only for audit after de-collectionization. It is not active routing authority; use root `README.md`, root `AGENTS.md`, `docs/collection-taxonomy.md`, and root `.claude-plugin/marketplace.json`.

# software-engineering Agent Route

Read `README.md` first for the collection scope and authority model.

## Route

- Use each `skills/*/SKILL.md` frontmatter description as the primary trigger
  contract for that skill. Keep detailed trigger lists in the skill, not here.
- Keep this collection scoped to software/product engineering development
  process: implementation workflow, generic Web design/build/app/test skills,
  local app QA, browser validation, test strategy, build/check
  evidence, debugging workflow, and code-review execution patterns that apply
  across projects.
- Also route developer infrastructure, engineering productivity, MCP/tooling,
  local workflow automation, skills repository architecture, agent evolution,
  and skill-evolution workflows here.
- Also route any-to-skill intake orchestration here: upstream source/input routing,
  source/input classification, code/design/docs/package artifact routing,
  distiller handoff queues, receipt-bundle coordination, and tracking-state
  gates. Route skill-source capability conservation and handoff audits to
  `skill-distiller`.
- Also route Swift framework/API practice, SwiftUI/UIKit architecture,
  SwiftPM, Xcode, Simulator, Instruments, and Apple-platform implementation
  details here.
- Treat Swift and Apple-platform skill directories as source-owned skills from
  `packages/swift-library/skills`. They are
  exposed through the `swift-library/skills` directory symlink; do not move or
  copy that source tree or its repository metadata into this collection.
- Do not route App Store listing operations, market messaging, product
  management, or product/brand design critique here unless the current task is
  specifically about the engineering workflow or generic Web implementation,
  artifact, or QA workflow around that work.
- Route product discovery, product strategy, PRDs, roadmaps, prioritization,
  product metrics, product operations, interaction design, HIG, UX writing,
  design-system work, design critique, market operations, store operations,
  GTM execution, ASO, paid acquisition, SEO, launch copy, and market
  performance to `product-experience`.
- Route root collection registry, validation, sync, and upstream source
  manifest infrastructure to the root health check.

## Authority

- `AGENTS.md` files route work and define operational handling.
- `README`-class files are manuals plus indexes for scope, placement,
  ownership, install/use surface, and focused docs.
- `docs/skill-authoring.md` defines collection-local skill authoring
  architecture.
- `skills/*/SKILL.md` defines each skill boundary and supported operations.
- Skill-local `references/` holds durable engineering workflow knowledge,
  checklists, and tool behavior notes.
- Skill-local `scripts/` holds deterministic helpers only when repeatability
  matters.
- `.claude-plugin/marketplace.json` is the discovery registry for the
  collection.

## Operating Notes

- Treat this as the Software Engineering collection, not a generic utility
  bucket.
- Preserve development-process guardrails: setup assumptions, validation
  commands, failure modes, evidence requirements, and good/bad workflow shapes.
- Keep changes minimal and boundary-first.
- Do not turn this file into a directory catalog.

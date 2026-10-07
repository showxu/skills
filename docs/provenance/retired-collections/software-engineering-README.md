> Historical provenance: This retired collection document is kept only for audit after de-collectionization. It is not active routing authority; use root `README.md`, root `AGENTS.md`, `docs/collection-taxonomy.md`, and root `.claude-plugin/marketplace.json`.

# software-engineering

`software-engineering` is a Codex / Claude skill collection for software
engineering, Swift and Apple-platform engineering, developer infrastructure,
engineering productivity, and agent-facing engineering workflow.

This README is both the collection manual and the documentation index. It
defines the collection scope, install/use surface, layout, and links to focused
docs.

The collection focuses on implementation workflow, generic Web
design/build/app/test skills, local app QA, browser validation, test strategy,
build/check evidence, debugging workflow, code-review execution, Swift and
Apple-platform implementation guidance, developer infrastructure, MCP/tool
backends, agent evolution, and engineering-productivity patterns that apply
across projects. It also owns
agent-facing skill intake routing for upstreams, code, design, documentation,
package, and skill-source evidence, plus skill-source distillation workflows.

It does not own product decisions, product or brand design critique,
go-to-market execution, App Store listing operations, or market messaging.

## Skills

- `coding-plan`: enter read-only plan mode in a code repository, inspect the
  repo contract and relevant source graph, then write or update the right
  local plan file before implementation.
- `deep-research-plan`: enter plan-only mode for research or article-writing
  work, inspect sources and experiment strategy, then write or update the
  right local research plan before drafting.
- `frontend-design`: create or improve high-quality Web interface
  presentation using an Anthropic-compatible frontend design baseline plus
  local quality rules.
- `web-artifacts-builder`: scaffold, build, and bundle shareable single-file
  HTML artifacts using an Anthropic-compatible React/Tailwind/shadcn baseline
  plus local artifact guidance.
- `webapp-builder`: build or extend real Web applications in a repository,
  including app structure, routes, state, data flow, API integration,
  component architecture, React/Next hygiene, shadcn project workflows, and
  project validation.
- `webapp-testing`: test local web apps, static HTML artifacts, localhost UI,
  and Electron/web surfaces with server lifecycle, Browser/Playwright backend
  selection, screenshots, console evidence, functional QA, and visual QA.
- `deeplink-formats`: look up verified deeplink, URL scheme, editor route,
  file route, settings route, and CLI fallback formats for local developer
  apps.
- `mcp-server-patterns`: design, implement, and review MCP servers and
  MCP-backed skill/tool backends.
- `skill-creator`: create, redesign, or harden production-quality skills
  by applying local quality gates on top of the official `skill-creator`.
- `skill-collection-creator`: design, scaffold, reorganize, or review skills
  repositories and collections, including ownership boundaries, collection
  taxonomy, linked checkouts, marketplace manifests, templates, and validation
  surfaces.
- `codex-brain-evolver`: distill Codex memory, rollout, and session evidence
  into behavior-backed skill update packets.
- `skill-evolver`: audit official and primary-source evidence for
  source-backed skill refreshes.
- `any-to-skill`: route selected upstreams and other input artifacts toward the
  right skill distillation or authoring workflow, producing source/input
  digests, owner-routing proposals, handoff packets, receipt-bundle
  classifications, and tracking-state recommendations.
- `skill-distiller`: distill upstream skill-source material into local
  capability ledgers, information-conservation audits, and handoff maps.
- `code-to-arch`: orchestrate upstream code, donor repositories,
  official APIs, product references, tests, UX patterns, and per-source findings
  into local architecture truth, local framework boundaries, docs update plans,
  and follow-up Codex prompts.
- Swift and Apple-platform skills: source-owned skill directories for Swift, SwiftUI,
  SwiftPM, Xcode, Simulator, Instruments, Apple frameworks, and
  Apple-platform implementation patterns.

The Swift and Apple-platform skill directories are grouped under
`swift-library/skills`, a directory symlink to their authoritative source under
`packages/swift-library/skills/skills`.
The Swift skills checkout root is
`packages/swift-library/skills`; it is not
flat and owns its own `skills/` directory, marketplace metadata, docs, and git
history. This collection only owns the local taxonomy route.

## Capability Matrix

| Capability | Primary skill | Also routes to | Coverage |
|---|---|---|---|
| Repo-local implementation plans before code changes | `coding-plan` | repo `AGENTS.md` and local plan surfaces | Published |
| Source-backed research and article plans before drafting | `deep-research-plan` | source-backed skill evolution when the research changes skill rules | Published |
| High-quality Web interface design and UI surface implementation | `frontend-design` | `webapp-testing` for rendered evidence; `webapp-builder` when repo-level app implementation is needed | Published |
| Shareable single-file HTML artifact generation | `web-artifacts-builder` | `frontend-design` for visual quality; `webapp-testing` for rendered verification; `webapp-builder` for promotion into a real app | Published |
| Real Web app implementation in a repository | `webapp-builder` | `frontend-design` for visual direction; `webapp-testing` for rendered verification | Published |
| Local web app browser QA and server harnesses | `webapp-testing` | Browser and Playwright skills as execution backends | Published |
| Developer app deeplink and route formats | `deeplink-formats` | none | Published |
| MCP servers and MCP-backed tool/skill backends | `mcp-server-patterns` | none | Published |
| Production-quality single-skill authoring and hardening | `skill-creator` | official `skill-creator`; `skill-collection-creator` for repo placement | Published |
| Skill collection creation and repository architecture | `skill-collection-creator` | `skill-creator` for single-skill authoring | Published |
| Codex brain and memory-backed skill evolution | `codex-brain-evolver` | `skill-evolver` for official-source handoffs | Published |
| Official-source skill freshness audits | `skill-evolver` | `any-to-skill` for source registry polling | Published |
| Any-to-skill source/input digest and route review | `any-to-skill` | `skill-distiller` for skill-source conservation; specialized artifact distillers such as `swiftpm-distiller` for non-skill-source evidence | Published |
| Upstream skill-source capability conservation | `skill-distiller` | `skill-creator` for final single-skill packaging | Published |
| SwiftPM package/library-to-skill handoff | Swift `swiftpm-distiller` | `any-to-skill` when upstream tracking, mixed-source routing, or receipt bundling is needed | Published |
| Upstream donor code/API/product orchestration into local architecture truth | `code-to-arch` | architecture docs, implementation planning, and domain-specific owners | Scaffolded |
| Engineering backlog triage and production incident response | none | future operations or software-engineering decision | Deferred |
| Customer support ticket replies, SLA handling, and customer operations | none | future customer/support operations collection | Out of scope |
| Swift, Xcode, Simulator, Instruments, and Apple API implementation | Swift and Apple-platform skill family | none | Published |
| Interaction, HIG, visual design, design-system handoff, product discovery, PRDs, App Store, ASO, screenshots, release copy, commerce, or growth operations | none | `product-experience` | Out of scope |

## Input Boundaries

Use project commands, source code, local app behavior, build/test output,
browser evidence, and primary-source tool references as inputs. Do not turn
third-party skill prose into local authority without preserving the concrete
workflow guardrail and validation path.

## Install In Codex

Install a specific skill directory into `$CODEX_HOME/skills` rather than
linking the repository root.

```bash
mkdir -p "${CODEX_HOME:-$HOME/.codex}/skills"
ln -s "$(pwd)/skills/<skill-name>" \
  "${CODEX_HOME:-$HOME/.codex}/skills/<skill-name>"
```

Restart Codex after installing so it picks up the new skill.

## Install In Claude

Install a specific skill directory rather than the repository root.

### Claude Apps

Zip one skill directory and upload that skill in Claude.

1. Open Claude.
2. Go to `Settings > Capabilities > Skills`.
3. Click upload.
4. Select the zipped skill folder.

### Claude Code

Place the skill directory in `~/.claude/skills`:

```bash
mkdir -p ~/.claude/skills
ln -s "$(pwd)/skills/<skill-name>" \
  ~/.claude/skills/<skill-name>
```

### Claude Code Marketplace

For local testing from this repository:

```bash
claude plugin marketplace add ./
claude plugin install generic-web-skills@software-engineering
claude plugin install engineering-productivity@software-engineering
claude plugin install agent-evolution@software-engineering
claude plugin install architecture-workflows@software-engineering
```

Install individual skills after they exist in `skills/<skill-name>/` and are
registered in `.claude-plugin/marketplace.json`.

## Repository Layout

- `.claude-plugin/`: Claude Code marketplace metadata.
- `docs/`: collection documentation and architecture notes.
- `swift-library/`: local taxonomy symlink to Swift and Apple-platform skills.
  Metadata remains in the Swift skills checkout.
- `skills/`: authoritative skill definitions and skill-local supporting files.

## Documentation Index

- `docs/README.md`: collection documentation index.
- `docs/generic-web-skills.md`: generic Web skill layering, source
  distillation mapping, and validation notes.
- `docs/skill-authoring.md`: skill structure, trigger precision, and
  engineering workflow boundaries.
- `AGENTS.md`: repository-local agent routing and operating contract.

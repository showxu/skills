> Historical provenance: This retired collection document is kept only for audit after de-collectionization. It is not active routing authority; use root `README.md`, root `AGENTS.md`, `docs/collection-taxonomy.md`, and root `.claude-plugin/marketplace.json`.

# product-experience

`product-experience` is a Codex / Claude skill collection for the product-side
lifecycle: discovery, requirements, interaction modeling, product interface
experience, platform experience guidance, store/listing readiness, launch, and
growth operations.

The collection is organized by workflow artifacts, not by traditional human
departments. Design, product, launch, and growth skills live together when they
shape the product experience a user or market sees. Source-level engineering
work remains in `software-engineering` and the linked Swift collection.

## Lifecycle

| Lifecycle area | Skills | Owns |
|---|---|---|
| Discovery and direction | `product-feature-creator`, `product-discovery` | Feature package routing, problem framing, user/scenario framing, opportunities, solution options, assumptions, tradeoffs, and PRD-ready decisions. |
| Product definition | `product-requirements` | Integrated product requirements / PRD artifacts, scope, functional requirements, stories, acceptance criteria, metrics, constraints, risks, and traceability. |
| Interaction modeling and prototype contract | `interaction-design` | Canonical interaction models, platform context, flows, screens, states, actions, transitions, feedback, recovery, permission handoffs, edge cases, product prototype contracts, prototype projection notes, and UX interaction review. |
| Interface language and platform guidance | `ux-writing`, `apple-hig`, `design-md-template`, `sfsymbols-export` | Product-facing UX copy, Apple HIG guidance, DESIGN.md templates, and SF Symbols asset export for product/design surfaces. |
| Store, launch, and growth | `app-store-whats-new`, `app-store-metadata`, `app-store-screenshots`, `app-store-connect`, `app-store-release-dryrun`, `app-store-aso`, `app-store-commerce`, `google-play-store-assets`, `market-messaging`, `market-performance`, `organic-search`, `paid-acquisition` | Store listing operations, release readiness, screenshots, metadata, commerce catalogs, launch copy, ASO, SEO, market evidence, and paid-channel preflight. |

## Skills

- `product-feature-creator`: routes, sequences, verifies, and integrates a
  complete product feature package across discovery, requirements, interaction
  design, and prototype handoff.
- `product-discovery`: runs product direction discovery for problem framing,
  users and scenarios, opportunities, solution options, assumptions, evidence
  strength, and PRD-ready decisions.
- `product-requirements`: creates, revises, or reviews integrated product
  requirements / PRD artifacts.
- `interaction-design`: drafts, revises, or reviews canonical interaction
  models, product prototype contracts, and UX interaction quality for product
  workflows, including platform context, flows, states, feedback, recovery,
  permission handoffs, prototype projection notes, existing artifacts,
  prototypes, and product surfaces.
- `ux-writing`: writes or reviews product-facing UX copy for interface
  surfaces.
- `apple-hig`: guides and reviews Apple platform interface decisions against
  HIG conventions without owning source-level implementation.
- `design-md-template`: selects, applies, reviews, includes, or refreshes
  tracked `DESIGN.md` templates.
- `sfsymbols-export`: exports and normalizes SF Symbols-derived SVG and PNG
  assets.
- `app-store-whats-new`: drafts App Store What's New text from release
  evidence while filtering internal engineering noise.
- `app-store-metadata`: reviews, prepares, validates, and localizes App Store
  metadata fields without live App Store Connect writes.
- `app-store-screenshots`: prepares, validates, localizes, and generates Apple
  App Store screenshot assets and upload-ready screenshot sets.
- `app-store-connect`: inspects App Store Connect app, build, TestFlight, beta
  feedback, and review-submission state safely.
- `app-store-release-dryrun`: dry-runs App Store release readiness before live
  submission.
- `app-store-aso`: audits App Store listing optimization and keyword
  opportunities.
- `app-store-commerce`: audits App Store pricing, availability, IAP,
  subscription, and RevenueCat catalog operations.
- `google-play-store-assets`: prepares and validates Google Play screenshots,
  feature graphics, app icons, and listing visual assets.
- `market-messaging`: prepares and reviews market-facing product messaging and
  channel-ready copy.
- `market-performance`: reviews market performance evidence, baselines,
  experiment logs, and channel reports.
- `organic-search`: audits organic search readiness, indexing, Search Console
  evidence, and SERP presentation.
- `paid-acquisition`: preflights paid acquisition campaigns, tracking, budget
  safety, and advertising policy risk.

## Boundaries

This collection owns the product-side workflow and user/market-facing
experience artifacts. It can describe what interaction should happen, what
permission handoff a user sees, what copy appears, and what store/listing
surface should say or contain. It can also define the product-side prototype
contract: what a Figma, HTML, or review prototype must preserve, which gaps
block projection, and how prototype coverage should be verified.

It does not own source-level implementation, native API usage, build systems,
CI, debugging, app architecture, SwiftUI/AppKit code, StoreKit code, signing,
notarization, concrete renderer execution, or live external account mutations.
Route those to engineering or downstream artifact owners, or require the
specific live-operation confirmation gates inside the relevant store-operation
skill.

## Input Boundaries

Use product artifacts, user research, customer feedback, analytics evidence,
business constraints, design artifacts, rendered prototypes, platform guidance,
store/platform documentation, and live account evidence as inputs.

Current product truth, official platform rules, live account state, user
research, and project constraints should take precedence over generic
frameworks or old absorption notes.

## Install In Codex

Install a specific skill directory into `$CODEX_HOME/skills` after a skill
exists.

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

### Claude Code

Place the skill directory in `~/.claude/skills` after it exists.

### Claude Code Marketplace

For local testing from this repository:

```bash
claude plugin marketplace add ./
claude plugin install product-discovery@product-experience
claude plugin install product-requirements@product-experience
claude plugin install interaction-design@product-experience
claude plugin install market-messaging@product-experience
```

Install individual skills after they exist in `skills/<skill-name>/` and are
registered in `.claude-plugin/marketplace.json`.

## Repository Layout

- `.claude-plugin/`: Claude Code marketplace metadata.
- `docs/`: collection documentation and lifecycle policy.
- `skills/`: authoritative skill definitions and skill-local supporting files.

## Documentation Index

- `docs/README.md`: collection documentation index.
- `docs/lifecycle.md`: lifecycle routing, handoffs, and migration closeout
  notes.
- `docs/skill-authoring.md`: product-experience skill placement, trigger, and
  source authority rules.
- `docs/review-process.md`: review order and information-conservation rules.
- `docs/design-system-format.md`: `DESIGN.md` format authority and local
  boundary notes.
- `docs/provenance/product-management-distillation/`: historical product
  distillation receipts retained for moved skill source ledgers.
- `AGENTS.md`: agent routing index for this collection.

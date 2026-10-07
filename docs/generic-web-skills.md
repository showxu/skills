# Generic Web Skills

This document records the durable result of the generic Web skills migration.
The temporary ExecPlan and `.agent/skill-distillation/` artifacts were process
state; their durable conclusions are kept here and in each skill's
`references/` directory. The active skill paths are root `skills/*`.

## Public Skills

| Skill | Owns | Does not own |
| --- | --- | --- |
| `frontend-design` | High-quality Web interface design, visual system extraction, UI polish, and design-led UI surface implementation. | Product behavior, repo-level Web app architecture, API/data integration, single-file artifact bundling, browser QA ownership, Figma operations, or guaranteed production readiness without project validation. |
| `web-artifacts-builder` | Temporary React/Tailwind/shadcn artifact scaffolding and single-file HTML bundling. | Production frontend architecture or product source-of-truth decisions. |
| `webapp-builder` | Real Web app implementation in a repository: app shell, routes, state, data flow, API integration, component architecture, React/Next hygiene, shadcn project workflows, and project validation. | Visual concept ownership, single-file HTML artifact ownership, browser QA ownership, Figma operations, backend/service ownership beyond frontend integration, or product behavior invention. |
| `webapp-testing` | Local Web app and HTML artifact QA, server lifecycle, Browser/Playwright backend selection, screenshots, console evidence, functional QA, and visual QA. | Ordinary internet browsing, live-account mutation without confirmation, or replacing project-owned tests. |

## Integrated Maintenance Model

All four skills follow the `skill-creator` maintenance pattern: the active
`SKILL.md` is the single integrated workflow, while source files exist only to
make future refreshes auditable.

1. Active workflow: `SKILL.md` contains the usable local behavior and should be
   read as the runtime entrypoint.
2. Baseline/source receipt: Anthropic-derived skills preserve
   `references/anthropic-baseline.md`; locally integrated skills preserve
   `references/source-receipt.md` with source disposition.
3. Patch/source manifest: Anthropic-derived skills use
   `references/anthropic-patch-manifest.md`; locally integrated skills record
   source disposition in their receipt.
4. Host compatibility: `references/host-compatibility.md` records host
   assumptions and non-claims.
5. UI metadata: each skill has `agents/openai.yaml`.

When refreshing from Anthropic, restore the baseline first, then reapply only
manifest-listed patches and keep the active `SKILL.md` as the seamless local
entrypoint. When refreshing `webapp-builder` from OpenAI/Codex sources, route
changes through the source-distillation path recorded in its source receipt.

## Distilled Source Notes

OpenAI material was used as a distillation source for local quality
improvements, not as a mirrored source or a permanent runtime layer. The
accepted intake flow for future OpenAI-source changes remains:

`any-to-skill -> skill-distiller -> skill-creator`

Selected sources:

- Anthropic baseline: [anthropics/skills](https://github.com/anthropics/skills)
  @ `d211d437443a7b2496a3dad9575e7dddd724c585`, especially
  [`skills/frontend-design/`](https://github.com/anthropics/skills/tree/d211d437443a7b2496a3dad9575e7dddd724c585/skills/frontend-design),
  [`skills/web-artifacts-builder/`](https://github.com/anthropics/skills/tree/d211d437443a7b2496a3dad9575e7dddd724c585/skills/web-artifacts-builder),
  and
  [`skills/webapp-testing/`](https://github.com/anthropics/skills/tree/d211d437443a7b2496a3dad9575e7dddd724c585/skills/webapp-testing).
- OpenAI/Codex source: [openai/skills](https://github.com/openai/skills)
  @ `4c4058ebf44f6734e62c70ab4a81246d4d093fc8`; see `upstreams.yaml`,
  especially the `openai-skills` source and reviewed Web-related segments.
- Local curated plugin cache: host-local OpenAI/Codex plugin cache used during
  absorption. Do not hardcode a machine path in durable docs; use the current
  installed skill roots or source receipts when refreshing.

The useful capabilities were folded into the active `SKILL.md` files:

| OpenAI source | Local destination | Disposition |
| --- | --- | --- |
| `frontend-app-builder` design direction, design-system extraction, and fidelity verification | `frontend-design` | Folded into local fidelity rules. |
| `frontend-app-builder` app shell, component architecture, repo conventions, stateful workflows, and implementation flow | `webapp-builder` | Folded into real Web app implementation workflow. |
| `frontend-app-builder` browser evidence expectations | `frontend-design` and `webapp-testing` | Split by owner: design expectation versus concrete verification workflow. |
| `react-best-practices` selected client/component hygiene only | `web-artifacts-builder` | Narrowly folded into temporary React artifact rules. Next.js server/data-fetching, bundle optimization, and production app architecture stay outside this skill. |
| `react-best-practices` project-level React/Next performance and architecture guidance | `webapp-builder` | Folded into repo-level React/Next implementation rules. |
| `shadcn-best-practices` component composition and token usage | `web-artifacts-builder` | Folded into conditional shadcn artifact rules for bundled or existing shadcn contexts. Registry, preset, and project migration workflows stay outside this skill unless the artifact is explicitly promoted into a real frontend project. |
| `shadcn-best-practices` CLI, registry, preset, installed-component discovery, and update workflows | `webapp-builder` | Folded into project-level shadcn implementation rules with approval gates for broad project changes. |
| `frontend-testing-debugging` | `webapp-testing` | Folded into Browser-first QA, target-flow statement, rendered checks, evidence report, and fallback rules. |
| `playwright` / `playwright-interactive` | `webapp-testing` | Folded into CLI and persistent Playwright backend rules. |
| `screenshot` | `webapp-testing` | OS screenshot fallback when tool-specific capture is unavailable. |
| `stripe-best-practices` | Payment/integration owner | Not folded into generic Web core. It may inform a Web app implementation only when the user is explicitly building a Stripe integration. |
| `supabase-postgres-best-practices` | Database/backend owner | Not folded into generic Web core. It may inform a Web app implementation only at the frontend integration boundary; SQL/schema/RLS ownership stays outside these Web skills. |
| `figma-use` / `figma-generate-design` / `figma-implement-design` | Downstream Figma/design owner | Deferred handoff; not part of generic Web core. |
| Build Web Apps and Figma plugin metadata | Marketplace/reference metadata | Non-capability for these skills. |

Anthropic `frontend-design`, `web-artifacts-builder`, and `webapp-testing`
are covered by the three Anthropic-compatible skills. Anthropic
`brand-guidelines`, `theme-factory`, and `canvas-design` are design/artifact
adjacent rather than generic Web implementation skills; route them to
brand/design/artifact owners instead of folding them into the Web core.

## Handoff Boundaries

Figma remains a downstream design/prototype artifact target. Generic Web skills
may be aware of Figma handoff needs, but they do not own Figma MCP operations
or treat Figma output as a Web source of truth.

Rendered Web artifacts are review/test outputs. They are not product sources of
truth. When a Web skill consumes structured product artifacts, it must preserve
the supplied behavior and report gaps rather than inventing product decisions.

## Validation

Use these checks after changing the generic Web skills:

```bash
python3 skills/skill-creator/scripts/validate_skill_package.py skills/frontend-design
python3 skills/skill-creator/scripts/validate_skill_package.py skills/web-artifacts-builder
python3 skills/skill-creator/scripts/validate_skill_package.py skills/webapp-builder
python3 skills/skill-creator/scripts/validate_skill_package.py skills/webapp-testing
python3 -m json.tool .claude-plugin/marketplace.json
```

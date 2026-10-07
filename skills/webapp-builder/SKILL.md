---
name: webapp-builder
description: Build or extend real Web applications in a repository. Use for project-level frontend implementation involving app structure, routes, state, data flow, API integration, component architecture, shadcn project workflows, React/Next performance hygiene, build/test wiring, or promotion from prototype/artifact to app. Do not use for visual concept ownership, single-file HTML artifacts, browser QA ownership, product behavior invention, Figma operations, or backend/service ownership beyond the Web app integration surface.
---

# Webapp Builder

## Purpose

Use this skill to implement real Web applications, not temporary review
artifacts. It turns accepted product, interaction, and design inputs into a
repo-local Web app implementation that fits the project's framework, routing,
state, styling, data, build, and test conventions.

This skill owns the Web app engineering layer:

- app shell and route structure
- component architecture and reusable primitives
- client and server state boundaries
- data fetching and mutation flow
- API integration points and error handling
- form and validation wiring
- accessibility and responsive implementation
- React/Next performance hygiene
- shadcn project workflows when the project uses shadcn/ui
- build, lint, typecheck, and test command selection
- handoff to browser QA after implementation

It does not own product behavior. If product requirements, flows, states,
actions, or acceptance criteria are missing or contradictory, report the gap
instead of inventing product decisions.

## Source Model

This is a local integrated skill. It is not a byte-for-byte mirror of an
upstream skill. It distills the engineering implementation portions of OpenAI
`frontend-app-builder`, `react-best-practices`, and `shadcn-best-practices`
into a Web app builder role. Visual concepting stays with `frontend-design`;
single-file HTML artifact bundling stays with `web-artifacts-builder`; browser
QA stays with `webapp-testing`.

See `references/source-receipt.md` for source provenance and capability
disposition.

## Inputs

Use the most authoritative local inputs available:

- existing repository code, package metadata, routes, components, styles, and
  tests
- user request and explicit implementation constraints
- product requirements, acceptance criteria, and interaction artifacts when
  provided
- accepted design artifacts, `design.md`, tokens, component inventory, or
  frontend design output when provided
- API contracts, mock data, schema definitions, environment constraints, and
  existing integration patterns

Treat structured product artifacts as source facts. Preserve supplied product
behavior, flows, states, validation, recovery behavior, and copy unless the
user explicitly requests a product change.

## When To Use

- Build a real Web app or app feature inside an existing repo.
- Convert an accepted prototype, artifact, or design into project code.
- Add routes, layouts, app shell, pages, panels, forms, tables, dashboards, or
  stateful app flows.
- Wire frontend state, API calls, data loading, mutations, optimistic updates,
  validation, loading, empty, error, retry, and success states.
- Refactor a Web app toward clearer component ownership or route/data
  boundaries.
- Apply React, Next.js, or shadcn project-level best practices while editing
  app code.

## When Not To Use

- The task is primarily visual direction, concept design, restyling, UI polish,
  or high-fidelity frontend aesthetics. Use `frontend-design`.
- The task is to create a temporary shareable single-file HTML prototype or
  review artifact. Use `web-artifacts-builder`.
- The task is browser QA, screenshots, console/network evidence, or coverage
  verification. Use `webapp-testing`.
- The task is Figma creation or Figma MCP operation.
- The task requires defining product requirements, interaction behavior, or
  acceptance criteria that are not yet accepted.
- The task is backend/service implementation beyond the frontend integration
  boundary.

## Workflow

1. Inspect the repo contract first.
   - Read local `AGENTS.md`, package metadata, framework config, routing
     conventions, component directories, styling setup, and existing tests.
   - Prefer established framework, state, styling, and data patterns over a
     new architecture.
2. Classify the implementation surface.
   - Existing app change, new app surface, prototype promotion, design
     implementation, data/API integration, refactor, or bug fix.
   - Identify the user-visible workflow and the affected routes/components.
3. Lock the source facts.
   - Requirements and interaction artifacts define behavior.
   - Design artifacts define visual and component direction.
   - Existing code defines framework and integration constraints.
   - Missing product decisions become blockers or explicit assumptions.
4. Plan the app structure.
   - Choose route boundaries, app shell, feature modules, component ownership,
     state ownership, data loading, mutation flow, error boundaries, and test
     scope.
   - Keep `App`/page files as composition glue when the repo structure allows
     it; move repeated UI and behavior into focused components or feature
     modules.
5. Implement in small slices.
   - Build the real user workflow first.
   - Preserve accepted copy, states, transitions, validation, and recovery.
   - Use local data or mocks only when real APIs are unavailable, and mark the
     seam clearly.
6. Apply framework hygiene.
   - For React, avoid avoidable re-renders, stale effects, inline component
     definitions, derived-state effects, and unstable callback patterns when
     they affect the implemented surface.
   - For Next.js, respect server/client boundaries, route conventions,
     streaming/Suspense patterns, data fetching placement, serialization
     limits, and bundle boundaries.
   - For shadcn/ui projects, use the project `components.json`, installed
     components, semantic tokens, aliases, package manager, icon library, and
     CLI workflow rather than guessing imports or hand-building replacements.
7. Verify with project commands.
   - Run the narrowest useful build, typecheck, lint, unit, or component tests
     supported by the repo.
   - For rendered browser evidence, hand off to `webapp-testing` or use the
     available Browser/Playwright backend when the current task includes QA.
8. Report product gaps and implementation evidence.
   - Name any missing product behavior, API contract, design detail, or test
     coverage that could not be resolved from local context.

## React And Next.js Rules

Use React/Next guidance as project engineering rules, not as artifact-only
advice:

- Keep route/page files focused on composition and data boundaries.
- Place client state near the interaction it controls; lift state only when
  multiple surfaces need the same source.
- Derive simple state during render instead of syncing with effects.
- Use functional state updates for callbacks that depend on previous state.
- Avoid defining components inside render paths.
- Use Suspense/loading/error boundaries when the framework and repo pattern
  support them.
- Avoid avoidable request waterfalls; start independent requests early and
  parallelize independent work.
- Keep server-only work on the server side in Next.js and avoid serializing
  unnecessary data to client components.
- Split heavy optional UI behind lazy/dynamic loading when it materially
  affects the app surface.

Do not add performance abstractions for their own sake. Apply these rules when
they improve the concrete app being built or match the repo's existing
standards.

## shadcn Project Rules

When the repo uses shadcn/ui:

- Read `components.json` or `npx shadcn@latest info --json` when needed.
- Use the repo's package manager for CLI commands.
- Check installed components before adding new ones.
- Prefer existing shadcn components and variants over custom lookalike markup.
- Use semantic tokens such as `bg-background`, `text-muted-foreground`, and
  `border-border` instead of raw theme colors unless the design system already
  defines an exception.
- Use correct component composition: dialog/sheet/drawer titles, full card
  structure, grouped select/dropdown/command items, accessible form fields, and
  project icon conventions.
- Preview component updates with dry-run/diff workflows when changing existing
  shadcn source.

Do not run registry, preset, reinstall, force, or overwrite workflows without
explicit user approval when they can modify broad project surfaces.

## Product And Design Boundaries

When consuming product artifacts:

- Product requirements own scope, rules, stories, acceptance criteria, and
  success metrics.
- Interaction artifacts own flows, screens, states, actions, transitions,
  validation, feedback, recovery, and edge cases.
- Design artifacts own visual style, tokens, layout expression, and component
  treatment.
- This skill owns the repo implementation of those accepted facts.

Rendered app code is an implementation, not a product source of truth. If the
implementation reveals a product conflict, report it for product writeback
rather than silently changing the behavior.

## Final Response

Summarize the implemented app surface, changed files, product/design gaps,
validation commands and results, and any remaining browser QA or production
integration risks. If browser evidence was required but not run, say why and
name the next verification owner.

---
name: webapp-testing
description: Test and debug local web applications, static HTML artifacts, GitHub-rendered Markdown previews, localhost UI, and Electron/web surfaces with Playwright, Browser, server lifecycle helpers, screenshots, console evidence, functional QA, and visual QA. Uses an Anthropic-compatible webapp testing baseline with local QA and host adaptations. Do not use for ordinary internet browsing, live-account operations, or inventing product behavior.
---

# Web Application Testing

## Purpose

Use this skill to turn local web app testing into a repeatable QA workflow:
choose the right browser backend, start or reuse local servers, inspect the
rendered UI before acting, collect evidence, and report functional and visual
coverage.

This skill owns the generic web testing workflow and evidence plan. Browser,
Playwright CLI, Playwright interactive sessions, Python Playwright scripts, and
project test suites own the concrete execution.

## Maintenance Model

This `SKILL.md` is the single active workflow. It integrates the
Anthropic-compatible `webapp-testing` baseline, the previous local QA harness
mechanics, and local browser-testing guidance, following the same maintenance
pattern as `skill-creator`:

- `references/anthropic-baseline.md` preserves the upstream baseline for
  refresh comparison.
- `references/anthropic-patch-manifest.md` records local differences from the
  upstream-derived baseline.
- `references/host-compatibility.md` records host assumptions and non-claims.
- `references/qa-workflow.md` preserves the local QA inventory, server
  lifecycle, and evidence workflow from the superseded `webapp-qa-harness`
  public name.

Rendered artifacts are test targets, not sources of truth. If a test target was
generated from structured product artifacts, verify coverage against those
facts and report gaps instead of redefining behavior.

## When To Use

- Testing or debugging a local web app, localhost UI, static HTML page, or
  Electron/web surface.
- Previewing Markdown that GitHub renders, such as a repository or profile
  README, in light, dark, and mobile views before publishing, or checking it
  after publishing.
- A task needs a dev server started, reused, or cleaned up around browser QA.
- A change needs browser evidence: screenshots, console logs, network clues,
  viewport fit, or visible state confirmation.
- The user asks for UI verification, frontend smoke testing, browser
  automation, or a reproducible web QA checklist.

## When Not To Use

- Do not use this for ordinary internet browsing, shopping, research, or site
  navigation; use Browser Use or web browsing directly.
- Do not replace project-owned test suites. Run `npm test`, `pnpm test`,
  `playwright test`, or app-specific checks when the repo defines them.
- Do not create Playwright test files unless the user or project asks for
  durable tests.
- Do not use a browser backend to mutate live accounts or external services
  without explicit confirmation.
- Do not use this as a generic tool-wrapper or MCP/CLI design pattern; route
  that to the Engineering Productivity Research Team collection.

## Inputs To Inspect

- Target URL, static file path, dev server command, and required ports.
- Project package scripts, existing Playwright/Cypress/Vitest tests, and build
  commands.
- Whether the user needs visible in-app inspection, headless automation,
  persistent iterative debugging, or CI-style reproducibility.
- Required user-visible claims, controls, states, and viewport sizes.

## Workflow

1. Read `references/qa-workflow.md` for backend selection and the QA inventory
   shape.
2. Decide the target surface:
   - Static HTML: inspect source enough to identify likely selectors, then
     validate rendered behavior.
   - GitHub-rendered Markdown: build the page with
     `scripts/render_github_markdown.py`, then test it as static HTML. Follow
     `references/github-markdown-preview.md`.
   - Dynamic app: start or confirm servers, wait for readiness, then inspect
     rendered state.
   - Electron/web desktop shell: treat launch and window sizing as part of QA.
3. Choose the execution backend:
   - Browser Use: visible in-app browser work, local targets, screenshots the
     user should inspect, or side-by-side interaction in Codex.
   - Playwright CLI: terminal-driven navigation, snapshots, quick actions,
     traces, and reusable command output.
   - Playwright interactive: persistent web/Electron debugging with repeated
     code changes and functional plus visual QA.
   - Python Playwright harness: one-off scripted checks around a managed local
     server, especially static HTML or simple smoke tests.
4. Create a QA inventory before acting: requirements, implemented features,
   visible controls, state transitions, claims to sign off, and expected
   evidence.
5. Start or reuse servers. For Anthropic-compatible single helper usage, run
   `scripts/with_server.py --help` before using it. For local multi-server
   orchestration, run `scripts/with_web_servers.py --help` before using it.
6. Inspect rendered state before action. For dynamic apps, wait for the app to
   settle before relying on DOM, screenshots, or selectors.
7. Run functional QA with normal user interactions, then a separate visual QA
   pass.
8. Capture evidence only from the state being evaluated: screenshots, console
   logs, network failures, trace files, or focused command output.
9. Stop helper-owned servers and report what remains running if any server was
   intentionally reused.

## Rendered QA Checks

Before claiming a rendered UI works, define the flow under test:
`entry route -> user action or state -> expected rendered result`.

Check page identity, nonblank rendered content, framework error overlays,
console health, screenshot evidence, and at least one interaction proof. For
Playwright automation, inspect rendered state before acting and keep output
artifacts in a controlled artifact directory or temp location. For persistent
frontend debugging, reuse browser handles where the host supports it and rerun
the target flow after each relevant code change.

## Reference Files To Consult

- `references/qa-workflow.md`: backend selection, QA inventory, evidence, and
  failure diagnosis.
- `references/github-markdown-preview.md`: GitHub Markdown rendering, preview
  capture, and post-publish verification.
- `scripts/render_github_markdown.py`: renders Markdown through GitHub's
  Markdown API into a local preview page.
- `scripts/with_server.py`: Anthropic-compatible helper for server lifecycle.
- `scripts/with_web_servers.py`: local helper for starting one or more servers,
  waiting for ports, running a command, and cleaning up.

## Decision Rules

- Browser Use is preferred when the user explicitly wants Codex to open,
  inspect, click, type, or screenshot a local browser target.
- Playwright CLI is preferred for quick terminal automation and artifact
  capture when a persistent in-app browser is not needed.
- Playwright interactive is preferred for larger frontend or Electron tasks
  where repeated reloads, visual QA, and stateful handles save time.
- Python Playwright scripts are acceptable for a small repeatable smoke check,
  but keep them narrow and delete temporary scripts unless the project wants
  durable tests.
- Server lifecycle is part of the test harness. Do not claim a UI was tested
  if the server startup, target URL, or port readiness is uncertain.

## Validation Rules

Use the least invasive checks that prove the claim:

```bash
npm test
npm run build
npx playwright test
python scripts/with_web_servers.py --help
python scripts/with_web_servers.py --server "npm run dev" --port 5173 -- <qa-command>
```

Browser evidence should include at least one rendered-state check. For visual
claims, screenshot review is required; console or DOM checks alone are not
enough.

## Output Format

Return a compact QA report:

```text
Target: <url or file>
Backend: <Browser Use | Playwright CLI | Playwright interactive | Python harness>
Server: <reused | started command/port | not needed>
Functional coverage: <controls/flows checked>
Visual coverage: <viewports/states checked>
Evidence: <screenshots/logs/traces/tests>
Result: <pass | fail | partial>
Open risks: <only remaining uncertainty>
```

## Failure / Uncertainty Handling

- If a server does not become ready, report the command, port, timeout, and
  last visible output instead of continuing with stale UI.
- If selectors fail, re-inspect the rendered DOM or screenshot before retrying.
- If screenshots and numeric checks disagree, treat the screenshot-visible
  defect as the blocker until resolved.
- If a browser backend is unavailable, say which backend failed and switch to
  the next suitable backend with the loss of coverage stated explicitly.

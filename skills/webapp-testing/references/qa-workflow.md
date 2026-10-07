# Webapp Testing QA Workflow

## Source-Conserved Mechanics

This engineering workflow preserves useful mechanics from the reviewed upstream
`webapp-testing` skills and the installed browser automation skills:

- static HTML and dynamic app paths are different
- server lifecycle is part of QA, not a side note
- browser backend selection should happen before writing scripts
- inspect rendered state before acting
- dynamic apps need a settle point before selector discovery
- screenshots, console logs, network clues, and traces are evidence, not
  decoration
- functional QA and visual QA are separate passes
- generated browser-service wrappers belong to tool-wrapper review unless the
  current task uses that service directly

## Backend Selection

| Situation | Backend | Why |
|---|---|---|
| User asks to open, click, type, inspect, or screenshot a local target inside Codex | Browser Use | It controls the in-app browser and matches visible user-facing work. |
| Quick terminal browser automation, snapshots, trace, PDF, or artifact capture | Playwright CLI | It gives stable command output and element refs without writing a test suite. |
| Repeated frontend or Electron debugging after code edits | Playwright interactive | Persistent handles avoid relaunch churn and support functional plus visual QA. |
| One-off smoke test around one or more temporary servers | Python harness | A small script can run after server readiness and exit cleanly. |
| Durable regression suite | Project test framework | Add or update project-owned tests only when the project expects them. |

Do not pick a backend only because it is available. Pick the narrowest backend
that can prove the user-visible claim.

## QA Inventory

Write this inventory before browser work when the task has UI behavior or
visual claims:

```text
Requirements: <user-stated requirements>
Implemented features: <features or fixes that need signoff>
Controls: <buttons, forms, toggles, menus, links, drag/drop, keyboard paths>
States: <initial, loading, success, error, empty, dense, mobile, desktop>
Claims: <things the final answer may claim>
Functional checks: <which normal user inputs prove each behavior>
Visual checks: <which screenshots/viewports prove each visible claim>
Evidence expected: <screenshots, console, network, trace, test output>
```

Every final user-visible claim should map to at least one functional or visual
check. If it does not, either test it or avoid claiming it.

## Server Lifecycle

Use an existing server only when the target URL is known and the current page
state is not stale. Start a server when the task depends on fresh local code or
the URL is not already live.

Use this skill's helper for simple command plus port readiness:

```bash
python skills/webapp-testing/scripts/with_web_servers.py --help
python skills/webapp-testing/scripts/with_web_servers.py \
  --server "npm run dev" --port 5173 \
  -- python /tmp/web-smoke.py
```

For multiple services:

```bash
python skills/webapp-testing/scripts/with_web_servers.py \
  --server "cd backend && npm run dev" --port 3000 \
  --server "cd frontend && npm run dev" --port 5173 \
  -- python /tmp/web-smoke.py
```

If the project already owns a more specific server manager, test runner, or
docker compose workflow, prefer that project command.

## Rendered-State Discipline

For static HTML, source inspection can identify likely selectors, but rendered
state still decides whether the test passed.

For dynamic apps:

- navigate to the target URL
- wait for DOM content or network idle according to the backend
- capture one broad observation: DOM snapshot, screenshot, or console output
- narrow to the control or region under test
- interact with normal user input
- re-inspect after state changes

Avoid using a stale selector after navigation, modal changes, tab changes, or
major re-rendering.

## Functional QA

Functional QA uses user-like input:

- click, type, keyboard, touch, drag, or file upload
- one critical end-to-end flow when available
- full cycle for reversible toggles
- error or empty state when relevant
- at least one short exploratory pass for interactive products

Internal state checks can support the result, but they do not replace visible
behavior.

## Visual QA

Visual QA is a separate pass. Inspect the state where the claim matters.

Check for:

- clipped or hidden primary controls
- accidental scroll in fixed-shell interfaces
- overflow, wrapping, illegible text, weak contrast, broken layering
- inconsistent spacing or alignment
- dense realistic states, not only empty or loading states
- desktop and mobile viewports when both are user-relevant

Screenshots are primary evidence for visual claims. Numeric viewport checks are
supporting evidence and do not overrule a visible defect.

## Evidence Shapes

Use concise evidence:

```text
Tests: npm run build; npx playwright test
Screenshots: output/playwright/<label>/desktop.png
Console: no errors after flow; warnings listed
Network: failed requests listed or none observed
Trace: output/playwright/<label>/trace.zip
```

Do not dump full DOM, full console history, or large screenshots into the final
answer unless the user asks. Summarize what proves the claim.

## Failure Diagnosis

| Failure | First response |
|---|---|
| Server does not start | Report command, port, timeout, and last output. |
| Page loads stale UI | Reload, restart server, or verify build/watch mode. |
| Selector fails | Take a fresh snapshot or screenshot before retrying. |
| Network never idles | Use a visible ready selector or app-specific loaded state. |
| Screenshot shows clipping | Treat as visual failure even if DOM metrics pass. |
| Console has framework warnings | Classify as blocking only if user-visible or tied to the change. |
| External account mutation needed | Stop for confirmation before proceeding. |

## Generated Browser Services

Composio/Rube browser toolkits, Browserbase, Browserless, Hyperbrowser,
Anchor Browser, Browserhub, and Cloudflare Browser Rendering wrappers are
tool-service surfaces. They are useful when the current task explicitly uses
that service or when reviewing generated wrapper mechanics.

They are not the default local webapp QA backend. Route their reusable
schema-discovery, connection, pagination, and session rules to generated
tool-wrapper review.

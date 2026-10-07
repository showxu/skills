> Historical provenance: This retired collection document is kept only for audit after de-collectionization. It is not active routing authority; use root `README.md`, root `AGENTS.md`, `docs/collection-taxonomy.md`, and root `.claude-plugin/marketplace.json`.

# Engineering Productivity Intake Plan

Status: locked / paused.

This plan is for digesting engineering-productivity material from tracked
upstream skill sources. It is an execution queue, not durable review state.
Durable coverage must move back into `upstreams.yaml` review segments when the
pass closes, and this file should then be removed unless explicitly kept as a
narrative record.

This plan is currently locked. Do not continue intake or create new local
skills from this plan unless the user explicitly reopens it. Durable source
state lives in `upstreams.yaml`.

## Sources

| Upstream | Cursor | Engineering-productivity scope | Current state |
|---|---:|---|---|
| `composiohq-awesome-codex-skills` | `14667b4850a3d99b23f8fbc0cf73c879ef219c66` | Deep links, MCP builder, GitHub/CI workflows, web testing, deploy pipeline, incident/issue triage, skill lifecycle, generated tool wrappers. | Partially reviewed. Remaining broad Composio workflow/generated areas are paused. |
| `composiohq-awesome-claude-skills` | `48ffe0c633c6279bb100ae59e0c3ec7f4d0a81d8` | MCP builder, GitHub/CI-adjacent workflows, web testing, skill lifecycle, document/tool workflows, generated tool wrappers. | Partially reviewed. Remaining top-level/generated areas are paused. |
| `anthropics-skills` | `5128e1865d670f5d6c9cef000e6dfc4e951fb5b9` | Official Agent Skills spec/template, MCP builder, webapp testing, skill creator, document and artifact examples. | Track as official reference. Do not recreate official skill lifecycle wheels locally. |
| `openai-skills` | `af9b54f235d0d56c6b4410be54d578b0fda4ddfc` | Official Codex `.system` and `.curated` skills, install surface, GitHub/deploy/browser/security/tool skills. | Track as official reference. Do not duplicate official bundled skills locally. |

## Local Owners

| Local owner | Owns | Does not own |
|---|---|---|
| `software-engineering` | Cross-domain productivity workflows, tool glue, deep links, inbox/digest workflows, local workspace automation, skill install/sync helpers, validation aids, `skill + CLI/MCP/app URL/scheduled task` packages. | Product engineering, Swift/Xcode implementation, design critique, market operations, product decisions, agent self-evolution. |
| `software-engineering` | Software/product engineering workflows: implementation process, local app QA, browser validation, test strategy, build/check evidence, debugging workflow, and code-review execution patterns that apply across projects. | Engineering productivity research, domain API/framework practice, design critique, market operations, agent self-evolution, generic MCP/CLI/tool-wrapper architecture. |
| `software-engineering` | Skill quality, trigger robustness, memory/session evidence, agent behavior, official skill spec implications, skill authoring evolution. | Cross-domain tool operation unless the task is about agent behavior or skill quality itself. |
| Root maintenance / scripts | Monorepo registry, validation, sync, upstream source manifest infrastructure. | User-facing workflow skill behavior unless a published skill owns it. |
| Domain collections | Domain-specific workflows after routing: Swift, design, market, app store, etc. | Cross-domain productivity glue when the task is not domain-specific. |

## Scope

In scope:

- Deeplink knowledge for agents opening or referencing other apps: app URL
  schemes, fallback shell commands, Slack-safe link output, and local
  verification before claiming support.
- Tool-backed skill design: MCP, CLI, URL scheme, browser automation,
  scheduled task, and connector-backed workflows where the skill owns trigger,
  setup/auth assumptions, safety boundary, output shape, validation, and
  failure handling.
- GitHub, PR, CI, review, issue, incident, deploy, and web testing workflows
  when they are reusable across projects.
- Skill lifecycle and official skill-source parity: creator, installer,
  template, spec, packaging, and official Codex/Anthropic differences.
- Generated API/tool-wrapper patterns only when they reveal durable workflow
  mechanics beyond a one-off SaaS automation.

Out of scope for this pass:

- Swift/Xcode implementation details except as deeplink or fallback evidence.
- Apple HIG, SwiftUI design, App Store copy, ASO, screenshots, or release
  marketing.
- Product strategy, market operations, private customer research, or design
  critique.
- Copying vendor constants, licenses, generated wrapper text, or full source
  examples into local skills.
- New local skills before a ledger proves trigger/workflow ownership and a
  reusable workflow boundary.

## Initial Discovery Notes

- `agent-deep-links/` was previously classified as valuable but not Swift:
  preserve app/object detection, support-level lookup, local verification,
  Slack-safe link formatting, and Xcode `xed --line` fallback.
- `mcp-builder/` was previously classified as valuable but not Swift:
  preserve workflow-first tool design, context-budget limits, actionable
  errors, JSON/Markdown response modes, pagination, transport choices,
  evaluation harness shape, and read-only verifiable QA constraints.
- `composio-skills/*` did not contain real Swift/Apple capability in the
  previous sweep, but the generated family may still reveal generic tool-wrapper
  patterns for SaaS/API automation.
- Official `anthropics/skills` and `openai/skills` are now tracked separately.
  They should be used as official skill-source baselines, especially for spec,
  template, creator/installer, and official bundled skill drift.

## Candidate Ledger

| Source | Path or item | Evidence | Candidate owner | Current judgment | Next action |
|---|---|---|---|---|---|
| `awesome-codex-skills` | `agent-deep-links/` | Deep-link matrix, Slack link formatting, support-level lookup, fallback behavior. | `software-engineering` | Integrated into local `deeplink-formats`; source claims compressed behind verification gates. | Closed; durable segment receipt written to `upstreams.yaml`. |
| Composio + Anthropic | `mcp-builder/`, `skills/mcp-builder/` | MCP server workflow, tool design rules, transports, schema/output modes, evaluation harness. | `software-engineering` | Integrated into local `mcp-server-patterns`; executable harness deferred as future host-agnostic tool. | Closed; durable segment receipts written to `upstreams.yaml`. |
| Composio + Anthropic + OpenAI | `webapp-testing/`, `skills/webapp-testing/`, OpenAI `playwright` and `playwright-interactive`, installed Browser Use | Local web app QA harness, server lifecycle, browser backend selection, screenshots, console/network evidence, functional and visual QA. | `software-engineering` with Browser Use / Playwright as execution backends | Integrated as `webapp-qa-harness`; generated browser-service wrappers moved to generated tool-wrapper sample. | Closed; durable segment receipts written to `upstreams.yaml`. |
| Composio + OpenAI | `gh-address-comments/`, `gh-fix-ci/`, `pr-review-ci-fix/`, OpenAI curated GitHub skills | PR comment addressing, CI repair, review loop. | GitHub/plugin skills; `software-engineering` only for wrapper mechanics | Reviewed. PR comments and GitHub Actions CI are covered by the installed OpenAI GitHub plugin skill family; no local duplicate. `pr-review-ci-fix/` is Composio CLI cross-provider automation, not a plain GitHub workflow. | Closed for GitHub/CI slice; move `pr-review-ci-fix/` evidence to generated tool-wrapper sample. Durable segment receipts written to `upstreams.yaml`. |
| Composio + OpenAI | `issue-triage/`, `linear/`, OpenAI `skills/.curated/linear/` | Engineering tracker triage, bug sweeps, duplicate clustering, labels, priority, owner routing, and confirmation-gated tracker writes. | Future software-engineering or operations decision | Reviewed, then local skill rollout was reverted as out of current scope. Official Linear remains an upstream reference; no local wheel. | Closed as deferred/moved; durable segment receipts written to `upstreams.yaml`. |
| Composio | `sentry-triage/`, `datadog-logs/` | Sentry issue diagnosis, Datadog log/aggregate queries, source mapping, release/suspect-commit checks, incident-to-issue handoff. | Future software-engineering or operations decision | Reviewed, then local skill rollout was reverted as out of current scope. Preserve evidence for a later production/ops thread. | Closed as deferred; durable segment receipt written to `upstreams.yaml`. |
| Composio | `support-ticket-triage/` | Support-ticket classification, priority, reply draft, PII masking, and weak-signal handling. | Future customer/support operations collection | Moved, not integrated. Current `software-engineering` only preserves the support-to-engineering issue bridge; customer replies/SLA decisions have no current local owner. | Closed as moved; durable handover receipt written to `upstreams.yaml`. |
| Composio + OpenAI | `deploy-pipeline/`, OpenAI curated deploy skills | Deploy/release workflow across platforms. | Future operations or platform-specific decision | Paused. Out of current scope unless reopened. | Leave unabsorbed; retain upstream tracking only. |
| Composio + Anthropic + OpenAI | `skill-creator/`, `skill-installer/`, `template-skill/`, `skill-share/`, official spec/template/system skills | Skill creation, install, template, publishing, official spec. | Official sources plus existing agent/root skills | Paused. Official skills already exist; do not recreate a local wheel. | Track upstream drift only. |
| Composio | `composio-skills/*`, `connect-apps/`, `connect-apps-plugin/`, `pr-review-ci-fix/`, generated browser service wrappers, SaaS workflow directories | Generated wrapper skills, app/plugin surfaces, Rube MCP browser services, and Composio CLI orchestration loops. | Future generated-wrapper audit only | Paused. Not absorbable as a blob. | Leave unabsorbed; retain sample receipts already recorded. |
| Anthropic | document and artifact skills | `docx`, `pdf`, `pptx`, `xlsx`, artifact examples. | Official/tooling reference | Paused. Document workflows are not current scope. | Track upstream drift only. |

## Execution Slices

1. Deeplink formats
   - Source paths: `agent-deep-links/`, README discovery rows, any official
     matching deeplink/link format skills.
   - Ledger: supported apps, URL schemes, fallback commands, setup assumptions,
     output formats, Slack-safe formatting, validation commands, and failure
     modes.
   - Decision: created `deeplink-formats` under
     `software-engineering`.
   - Receipt:
     - Source path `agent-deep-links/` is not Swift/Xcode debugging; it is
       deeplink knowledge for opening or referencing other apps.
     - Preserved support levels, Slack `<url|label>` output, local scheme
       verification, CLI fallback commands, unsupported/unknown states, and
       "do not claim support without evidence" guardrail.
     - Official/local authority pass changed the matrix shape: VS Code file
       and settings routes are supported from official docs; Xcode file/line
       opening uses `xed --line`; Cursor file routes are inferred/local unless
       smoke-tested, while Cursor MCP install deeplinks are official; Codex and
       Claude routes are host-specific unless verified.
     - Local files:
       `software-engineering/skills/deeplink-formats/SKILL.md`,
       `software-engineering/skills/deeplink-formats/references/formats.md`,
       `software-engineering/skills/deeplink-formats/agents/openai.yaml`.
   - Durable receipt: `upstreams.yaml`
     `engineering-productivity-deeplink-formats` segment.

2. MCP and tool-backed skill design
   - Source paths: Composio `mcp-builder/`, Anthropic `skills/mcp-builder/`,
     relevant official skill creator/spec material.
   - Ledger: tool operations, transports, auth/setup, schema design, context
     budget, error handling, pagination, safety, eval harness, read-only QA,
     and whether a skill drives MCP/CLI/backend.
   - Decision: created `mcp-server-patterns` under
     `software-engineering`.
   - Receipt:
     - Composio Codex and Composio Claude contain the same skill family, with
       minor evaluation-script/dependency drift.
     - Anthropic official `skills/mcp-builder/` is the stronger authority for
       modern SDK/API wording: public TypeScript SDK examples, streamable HTTP
       vs stdio, `registerTool`, `outputSchema`, `structuredContent`, and
       annotations. Local language choice is host-boundary based: Swift first
       for Swift package/Xcode/macOS/Apple-toolchain servers; TypeScript for
       public npm/remote/MCPB/broad-host cases; Python for Python-first
       automation and API clients.
     - Composio-specific guardrails preserved: agent-centric workflow design,
       context budget, high-signal results, actionable errors, workflow-vs-API
       endpoint tradeoff, and evaluation-driven iteration.
     - Evaluation harness mechanics preserved as reference: read-only stable
       QA pairs, exact answers, `list_tools` / `call_tool`, tool-call metrics,
       tool feedback, and Markdown report shape. The Anthropic-specific
       executable script is not copied because it is a Claude API runner, not a
       Claude Code SDK runner. OpenAI has separate runner owners: Responses API
       for model/tool-call eval, Agents SDK for orchestrated app-owned
       execution, and Codex SDK for controlling local Codex agents. This skill
       owns only the MCP eval contract, the two-protocol-layer model, and
       runner adapter boundary.
     - Local files:
       `software-engineering/skills/mcp-server-patterns/SKILL.md`,
       `software-engineering/skills/mcp-server-patterns/references/design.md`,
       `software-engineering/skills/mcp-server-patterns/references/implementation-shapes.md`,
       `software-engineering/skills/mcp-server-patterns/references/evaluation.md`,
       `software-engineering/skills/mcp-server-patterns/agents/openai.yaml`.
   - Durable receipts: `upstreams.yaml`
     `engineering-productivity-mcp-builder` and
     `official-anthropic-mcp-builder` segments.

3. GitHub, PR, and CI workflows
   - Source paths: `gh-address-comments/`, `gh-fix-ci/`, `pr-review-ci-fix/`,
     OpenAI curated GitHub skills.
   - Ledger: comment discovery, patch strategy, CI log fetch, reproduction,
     test command selection, safety boundaries, and final reporting.
   - Decision: no local `software-engineering` skill.
     GitHub PR comment follow-up, GitHub Actions CI repair, and publish-to-PR
     are already owned by the installed OpenAI GitHub plugin skills:
     `github`, `gh-address-comments`, `gh-fix-ci`, and `yeet`.
   - Receipt:
     - Composio `gh-address-comments/` is a thinner `gh`-only version of the
       same PR comment workflow. The installed OpenAI plugin has the stronger
       local boundary: connector for PR metadata and patch context, bundled
       GraphQL/`gh` script for thread-aware `reviewThreads`, resolution state,
       outdated status, and inline anchors, with an explicit guardrail not to
       reply/resolve/submit review unless asked.
     - Composio `gh-fix-ci/` and upstream OpenAI `skills/.curated/gh-fix-ci/`
       preserve the useful CI mechanics: authenticate `gh`, resolve current
       branch PR, inspect GitHub Actions checks, fetch logs with script/manual
       fallback, classify external checks as report-only, summarize root cause,
       and implement only after approval. The installed OpenAI plugin is the
       better runtime owner because it also states the connector/`gh` split.
     - OpenAI `skills/.curated/yeet/` and the installed plugin `yeet` cover the
       explicit publish flow: inspect scope, branch, stage, commit, validate,
       push, and open a draft PR. This belongs in the GitHub plugin, not a new
       cross-domain utility skill.
     - Composio `pr-review-ci-fix/` is not equivalent to those GitHub skills.
       It is a Composio CLI workflow that discovers tool slugs, links
       GitHub/GitLab, fetches PR/MR data, downloads CI logs, posts comments,
       commits/pushes, and polls until checks pass. Preserve it as evidence for
       the generated/tool-wrapper sample, with auth/setup, schema discovery,
       write-safety, rate-limit, and cross-provider boundaries reviewed there.
   - Durable receipts: `upstreams.yaml`
     `engineering-productivity-github-pr-ci` and
     `official-openai-github-workflows` segments.

4. Web testing and browser automation
   - Source paths: Composio `webapp-testing/`, Anthropic
     `skills/webapp-testing/`, OpenAI `playwright`/`playwright-interactive`.
   - Ledger: server startup assumptions, browser control surface, screenshot
     evidence, assertions, flake handling, and failure diagnosis.
   - Decision: created `webapp-qa-harness` under `software-engineering`.
   - Receipt:
     - Composio Codex, Composio Claude, and Anthropic
       `webapp-testing/` contain the same local webapp testing workflow:
       static HTML and dynamic app branches, managed server lifecycle,
       multiple-server support, `--help` before helper-script inspection,
       rendered DOM/screenshot reconnaissance before actions, `networkidle`
       settle point for dynamic apps, and small Python Playwright examples.
     - OpenAI `playwright` is the better owner for low-level CLI browser
       actions: wrapper script, snapshots, element refs, sessions, traces,
       console/network commands, and artifact containment.
     - OpenAI `playwright-interactive` is the better owner for persistent
       browser/Electron iteration: QA inventory, reuse of handles, reload vs
       relaunch decision, functional QA, visual QA, viewport fit, and
       screenshot normalization.
     - Browser Use remains the execution backend for in-app browser work,
       especially local targets the user wants Codex to open, inspect, click,
       type, or screenshot.
     - Local absorption keeps the workflow glue, not a duplicate browser
       driver: backend selection, server harness, QA inventory, evidence
       expectations, visual/functional split, and failure diagnosis.
     - Generated Composio browser-service wrappers such as Browserbase,
       Browserless, Hyperbrowser, Anchor Browser, Browserhub, and Cloudflare
       Browser Rendering are not local webapp QA by default. They are moved to
       generated tool-wrapper review with their Rube MCP search-first,
       connection, schema, memory, session, and pagination rules preserved.
     - Local files:
       `software-engineering/skills/webapp-qa-harness/SKILL.md`,
       `software-engineering/skills/webapp-qa-harness/references/qa-workflow.md`,
       `software-engineering/skills/webapp-qa-harness/scripts/with_web_servers.py`,
       `software-engineering/skills/webapp-qa-harness/agents/openai.yaml`.
   - Durable receipts: `upstreams.yaml`
     `software-engineering-webapp-qa-harness`,
     `official-anthropic-webapp-testing`, and
     `official-openai-browser-playwright-workflows` segments.

5. Incident, observability, and issue triage
   - Source paths: `issue-triage/`, `linear/`, OpenAI
     `skills/.curated/linear/`, `sentry-triage/`, `datadog-logs/`,
     `support-ticket-triage/`.
   - Ledger: intake inputs, search/query syntax, severity/risk classification,
     ownership routing, privacy/auth assumptions, evidence output, and
     escalation boundaries.
   - Decision: reviewed, then reverted from local skill rollout. These
     workflows are useful, but they are outside the current narrow scope.
     Official Linear remains an upstream reference instead of a local duplicate.
     Sentry/Datadog and support-ticket triage are preserved as future
     operations handover material.
   - Receipt:
     - The deferred engineering-issue ledger preserves the upstream read-first
       workflow,
       tracker metadata/schema discovery, Linear MCP operation families,
       Composio Linear/Jira schema verification, JQL and Linear filter shapes,
       duplicate/stale classification, small-batch mutation safety, rate-limit
       handling, support-to-engineering issue fields, and post-write read-back.
     - The deferred production-incident ledger preserves Sentry
       issue/event/breadcrumb
       fetches, in-app frame to local source mapping, suspect commit checks,
       release/source-map uncertainty, Datadog service/env/time-window query
       shapes, aggregation-before-raw-log guardrail, trace-ID pivot, auth/scope
       failures, slow-query diagnosis, and confirmation-gated resolution.
     - Customer-support material is not lost: category/priority/reply-draft,
       PII masking, weak-signal disambiguation, and internal-note/repro-step
       mechanics are recorded as future customer/support operations handover.
     - Local files from the attempted rollout were removed; durable evidence
       remains only in this plan and `upstreams.yaml`.

6. Deploy and release pipeline productivity
   - Source paths: `deploy-pipeline/`, OpenAI curated provider deploy skills.
   - Ledger: provider assumptions, build/test/deploy commands, rollback,
     environment handling, secrets/auth, verification, and failure diagnosis.
   - Decision: paused. Do not review or absorb unless the user explicitly
     reopens this scope.

7. Skill lifecycle and official source parity
   - Source paths: Composio skill lifecycle paths, Anthropic spec/template and
     `skill-creator`, OpenAI `.system` and `.curated` skill authoring/install
     surfaces.
   - Ledger: spec requirements, frontmatter, progressive disclosure, install
     mechanics, validation, marketplace/plugin packaging, and official drift.
   - Decision: paused. Official sources already provide these skills/specs; do
     not recreate a local wheel. Track drift only.

8. Generated tool-wrapper sample
   - Source paths: `composio-skills/*`, `connect-apps/`,
     `connect-apps-plugin/`, `pr-review-ci-fix/`, generated browser-service
     wrappers, selected generated SaaS/API skills.
   - Ledger: operation grouping, auth/setup, action schemas, error modes,
     pagination/rate limits, output shape, and reusable wrapper patterns.
   - Decision: paused. Do not attempt full absorption of hundreds of generated
     wrappers in one pass.

9. Durable closeout
   - Add or update path-based engineering-productivity review segments in
     `upstreams.yaml`.
   - Keep source-level `review_coverage` partial unless the whole source is
     reviewed.
   - Record every item as covered, compressed, moved, deferred, blocked, or
     non-capability.
   - Delete this `PLAN.md` after durable receipts are written and validated.

## First-Pass Priority

Slices 1 and 2 are complete:

1. `agent-deep-links/` became `deeplink-formats`.
2. `mcp-builder/` became `mcp-server-patterns`.
3. `gh-address-comments/` and `gh-fix-ci/` are covered by the installed
   OpenAI GitHub plugin; `pr-review-ci-fix/` moved to generated
   tool-wrapper review.
4. `webapp-testing/` and official Playwright/browser workflows became
   `webapp-qa-harness`; generated browser-service wrappers moved to generated
   tool-wrapper review.
5. `issue-triage/`, `linear/`, OpenAI `linear/`, `sentry-triage/`, and
   `datadog-logs/` were reviewed, then the local skill rollout was reverted as
   out of current scope.
6. `support-ticket-triage/` moved to a future customer/support operations
   thread.

No next active slice. The only remaining broad absorption queues in this plan
are the two Composio upstreams:

- `ComposioHQ/awesome-codex-skills`
- `ComposioHQ/awesome-claude-skills`

Official Anthropic/OpenAI sources remain tracked for drift/reference, not as a
local wheel-building backlog.

## Conservation Rules

- Discovery ledger first; local skill edit second.
- Existing collection boundaries win over upstream `targets` hints.
- A new skill requires proof that no existing skill or collection boundary can
  carry the workflow.
- Preserve tool behavior, setup/auth assumptions, output shape, safety
  boundary, validation command, fallback behavior, and failure diagnosis.
- For generated wrappers, preserve reusable wrapper mechanics, not generated
  SaaS prose.
- License does not participate in decisions.

## Validation

Run before closeout or after editing `upstreams.yaml`:

```bash
ruby -e 'require "yaml"; YAML.load_file("upstreams.yaml"); YAML.load_file("collections.yaml")'
scripts/validate-collections
rg -n '[[:blank:]]+$|^<<<<<<<|^=======|^>>>>>>>' PLAN.md upstreams.yaml software-engineering software-engineering
```

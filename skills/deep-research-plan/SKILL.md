---
name: deep-research-plan
description: Enter plan mode for a deep-research or article-writing task. Use when the user asks for a written research plan, research outline, article plan, source strategy, experiment plan, deep research plan, /deep-research-plan, think before writing, write a plan before researching, or otherwise wants the agent to survey a topic and produce a plan file without drafting the finished article or report. This skill is read/search-only except for writing the selected plan file. Do not use for code implementation plans, immediate research execution, finished article/report drafting, product roadmap decisions, or conversational summaries without a plan artifact.
---

# Deep Research Plan Mode

A read-and-search-only, 4-phase workflow for deep-research and article-writing
tasks. Output is a single plan file that a teammate or later agent can scan
before saying "go".

This skill is for research plans, article plans, explainers, literature
surveys, benchmark reports, source strategies, and experiment-led investigation
plans. It does not draft the final article, report, essay, or polished prose.

## Hard constraint: plan-only

While this skill is active:

- The only file you may write is the selected plan file.
- Do NOT draft article content or write to any other file.
- Do NOT take actions whose purpose is to produce finished output: no article
  sections, final summaries, polished prose, publication drafts, or slide-ready
  narrative.
- Allowed operations: web search, web fetch, reading local files, reading
  existing notes, and running non-mutating temporary Python/Node scripts purely
  to verify a data point or prototype an experiment.
- Scripts must run as throwaway checks. Do not create durable files outside a
  temporary location, and ask before running commands that may write caches,
  install dependencies, mutate project state, or produce retained artifacts.
- If a script is run, its output informs the plan; it is not the deliverable.
  Do not retain generated outputs except as summarized plan evidence.
- For current or mutable facts, verify against current primary or official
  sources before treating the claim as plan-ready.

Apply this boundary during the user's planning request, within the host's
instruction hierarchy. An explicit request to execute the research plan ends
this skill's planning-only scope; continue from the selected plan.

Use `todo_write` or the available task tracker for a 4-phase session workflow.
Session todos track the agent's current work; they are not durable plan state
unless the selected plan file already uses persistent progress checkboxes or
status fields.

## HITL gates

Ask only when the answer changes the research target, write surface,
permissions, runtime topology, or whether to execute the research. Keep
questions focused and continue only the work listed as allowed before answer.

### Ambiguous target

- Trigger: the request lacks a concrete question, thesis, output format,
  audience, or decision the plan should support.
- Question: "Which research question, audience, or output should this plan
  target?"
- Safe default: pause before writing the plan file; continue only source
  mapping that would be useful for any plausible interpretation.
- Blocked until answer: choosing a thesis, final outline, or plan filename that
  would commit to one interpretation.

### Plan surface conflict

- Trigger: multiple existing plan files, workspace rules, or active research
  plans could own the new plan.
- Question: "Which plan file or planning surface should own this research
  plan?"
- Safe default: do not overwrite or repurpose existing plans; prepare a short
  surface comparison.
- Blocked until answer: writing the selected plan file when ownership is
  ambiguous.

### Locked plan reopen

- Trigger: the only matching plan is completed, locked, paused, archived, or
  closeout-only, and the user did not explicitly ask to reopen it.
- Question: "Should I reopen that plan, or create a new current plan?"
- Safe default: create a new plan only when a non-conflicting accepted surface
  exists; otherwise ask before writing.
- Blocked until answer: changing locked, archived, or closeout-only content.

### Execution permission

- Trigger: the conversation shifts from planning into running the research,
  writing final prose, publishing output, or retaining experiment artifacts.
- Question: "Should I stay in plan mode, or switch to executing the research?"
- Safe default: stay in plan mode.
- Blocked until answer: drafting final article/report prose, running the full
  research plan, or saving non-plan artifacts.

### Read-only subagent fan-out

- Trigger: independent read-only source mapping, claim checking, or experiment
  sketching could materially improve the research plan and can be bounded by
  objective, inputs, output shape, and stop condition.
- Default: use clean-context read-only subagent passes after serial framing for
  complex research planning unless the task is clearly narrow or the user asks
  to keep work in the main context.
- Ask only when the fan-out boundary, host mechanics, cost, data exposure, or
  permission surface is unclear.
- Allowed: spawning bounded read-only subagents for independent source mapping,
  claim-risk discovery, or experiment-sketch slices.
- Blocked: asking agents to write files, choose the plan surface, draft final
  prose, retain experiment artifacts, or run unbounded exploration.

## Runtime topology

The default workflow is staged serial with parallel read/search batches. The
lead agent owns topic framing, source strategy, plan-surface choice, and the
single final plan artifact.

1. Serial framing: identify the research question, audience, intended output,
   workspace contract, plan-surface candidates, and active-plan status.
2. Parallel preparation: batch independent web searches, fetches, local reads,
   and non-mutating temp-only checks when local tools support it. This does not
   require subagents.
3. Default read-only fan-out: for complex research planning, use subagents
   after serial framing unless the task is clearly narrow or the user asks to
   stay in the main context. Each slice must name objective, inputs, boundaries,
   allowed tools, output shape, and stop condition.
4. Serial fan-in: compare evidence, resolve conflicts by checking sources,
   choose the plan surface, and write or update one coherent plan artifact.

Do not use parallel agents for plan writing, final prose, publishing work,
durable artifact creation, or plan-surface decisions.

## Phase 1 - Topic Scoping

Understand the research territory before committing to a direction.

- Identify the core question, thesis, or decision the user wants to explore.
  If it is vague, ask one focused clarification.
- Identify the intended output format: article, report, essay, explainer,
  benchmark, literature survey, briefing, research memo, or experiment plan.
- Identify the target audience and expected depth, since these shape how much
  background, evidence, and caveat handling the plan needs.
- Check the workspace contract before writing: `AGENTS.md`, `README.md`,
  existing `PLAN.md`, `.agent/PLAN.md`, `.agents/PLAN.md`, `plans/`,
  research notes, project docs, or collection-local planning rules.
- Do 2-4 broad web searches to map the landscape: subtopics, authoritative
  sources, current discourse, primary datasets, contested claims, and settled
  facts.
- Identify gaps or ambiguities that would materially change the research plan
  before moving to Phase 2.

You do not need to read every source yet. Read enough to see the shape of the
territory.

## Phase 2 - Source and Experiment Strategy

Design what to read, what to test, and in what order.

- For each major section or question in the outline, identify the best source
  types: official docs, primary data, academic papers, benchmark datasets,
  standards, legal/policy sources, news, interviews, blog posts, community
  threads, or local project evidence.
- Prioritize primary and official sources over summaries. Secondary sources
  can propose questions, but should not become authority without verification.
- Enumerate specific search queries or URLs likely to yield high-signal
  material.
- For claims that require empirical verification, sketch a small Python/Node
  experiment or command-line probe that would confirm or refute the claim.
  Include the experiment in the plan as a numbered step, not as a footnote.
- Define the output shape for each experiment: table, chart, JSON summary,
  benchmark numbers, screenshots, logs, or accept/reject criteria.
- Consider 2-3 structural alternatives for the article or report; choose one
  and briefly state why.
- Stick to scope. If the search reveals adjacent topics worth covering,
  mention them and let the user decide. Do not silently expand the outline.

Nothing gets written to the final article or report.

## Phase 3 - Review

Sanity-check the plan before writing it to disk.

- Re-run one or two key searches to validate that the chosen structure is
  supported by available sources.
- Check source authority:
  - official or primary source for current rules, APIs, policies, standards,
    prices, schedules, release state, and product behavior
  - papers or benchmark reports for research claims
  - primary data or reproducible experiment for measurement claims
  - secondary sources only as context or leads unless verified
- Check freshness. For mutable facts, record the date checked and avoid
  promoting stale claims into planned conclusions.
- Check citation and copyright boundaries. The plan should prefer source
  summaries, short quotes, and citations over copying long passages.
- Surface risks:
  - key claims supported only by weak sources
  - experiments too expensive, slow, flaky, or environment-dependent
  - outline sections that depend on claims not yet established
  - scope too large for the intended output
  - contested territory that needs explicit opposing evidence
- Walk through the intended reader's experience: opening context, evidence
  order, argument flow, caveats, and conclusion shape.
- Compare against the user's original request. If the outline drifted, adjust.
- If anything material is still unclear, ask before writing the plan file.

## Phase 4 - Write the plan file

The plan must stand alone. Someone reading it later, or another agent picking
up the research, should be able to act without the conversation context.

### Plan surface selection

Do not assume `plans/` is the only plan location. Select the plan surface from
the workspace contract and current state.

Check these surfaces in order:

1. Explicit user request: a named plan path always wins if it does not
   conflict with workspace rules.
2. Workspace route files: `AGENTS.md`, `README.md`, docs indexes, or notes
   that declare where research plans live.
3. Existing active plan files: `PLAN.md`, `.agent/PLAN.md`, `.agents/PLAN.md`,
   `plans/*.md`, project-local research plans, or other documented locations.
4. Existing plan architecture: headings, status fields, outline conventions,
   source tables, experiment ledgers, checkboxes, and closeout sections.
5. Fallback: if the workspace has no planning convention, create
   `plans/<prefix>-<short-kebab-name>.md`.

### Active plan handling

Before writing, decide whether an existing active plan is the same research
work.

- Same question, same audience, or same intended output: update the existing
  plan.
- Same large research initiative but new sub-question: add a new section,
  slice, or subplan using the existing architecture.
- Related but separable topic: create a separate plan in the workspace's
  accepted plan surface.
- Different active task: do not overwrite or repurpose it. Create a new plan
  or ask if there is a real conflict.
- Completed, locked, paused, archived, or closeout-only plan: do not revive it.
  Use it as a format reference and create a current plan unless the user
  explicitly asks to reopen it.

When updating an existing plan, preserve unrelated notes and prior source
decisions. Change only the sections needed for the current research task.

### Filename

If the fallback `plans/` convention is used, name the file:

`plans/<prefix>-<short-kebab-name>.md`

Use a meaningful but short kebab-case name, usually 2-4 words after the prefix.
The prefix signals the output type:

- `research-` for open-ended investigation or literature survey
- `article-` for a finished article or blog post plan
- `report-` for structured findings, benchmark, audit, or analysis
- `explainer-` for technical or conceptual explanation
- `experiment-` for primarily data-driven or code-experiment-led work

Good: `plans/article-llm-context-limits.md`,
`plans/research-vector-db-landscape.md`,
`plans/experiment-rag-chunking.md`

Bad: `plans/plan.md`, `plans/llm-article.md`,
`plans/article-about-the-current-state-of-large-language-models-2026.md`

If `plans/` does not exist, create it. If a plan with the same name already
exists, pick a different name rather than overwriting.

### Structure

Use the workspace's existing plan architecture when one exists. If there is no
workspace-specific structure, write four sections in this order:

```
# <Title>

## Context
<Why this research is being done: the question it answers, the audience it
serves, intended output format, selected plan surface, and any relevant
active-plan decision. 1-4 sentences.>

## Outline

### 1. <Section title>

<What this section covers and why it comes here in the structure. Include:>
- Key claims to establish and required evidence type
- Specific search queries or URLs to fetch
- Any experiment to run, including language/tool, what to measure, and output
  shape
- Risks: weak sources, contested territory, freshness, or claims hard to verify

### 2. <Next section> ...

## Sources & Experiments

| # | Type | Query / URL / Script | Purpose |
|---|------|----------------------|---------|
| 1 | search | "query string" | <what signal this yields> |
| 2 | fetch | https://... | <what to extract> |
| 3 | experiment | `python benchmark.py --model gpt4o` | <what it measures and how to judge output> |

## Verification

<How to confirm the research plan is well grounded before writing begins:
sanity searches, source authority checks, freshness checks, experiment
dry-runs, citation/copyright checks, and closeout destination.>
```

Title is a noun phrase, not a sentence: `LLM Context Window Limits`, not
`How context windows work`. URLs in the Sources table must be real URLs found
during Phase 1/2, not invented. The `Type` column is usually `search`,
`fetch`, `experiment`, `local-file`, `dataset`, or `interview`.

### Style - plain, no decoration

- No emojis.
- No bold or italic for emphasis. Backticks for identifiers, queries, paths,
  and commands are fine.
- No horizontal rules.
- No marketing adjectives such as "comprehensive", "deep-dive", or
  "groundbreaking". State what gets researched and why.
- No filler preambles. Start directly.
- Match the user's conversation language for the plan content.

### Length

The fallback plan normally fits in one to two screens:

- Context: 1-4 sentences.
- Outline: 3-7 numbered sections.
- Sources & Experiments: 4-12 entries.
- Verification: 2-5 concrete checks, searches, or dry-runs.

Use a longer plan only when the research genuinely needs a source ledger,
multi-stage experiments, or a large outline.

## Handoff

Once the plan is written, read it back to confirm:

- the selected plan file is the right surface for the workspace and task
- all required sections are present
- the Sources & Experiments table is well formed
- queries and URLs are real or clearly marked as search queries
- current-fact checks have freshness expectations
- article/report prose was not drafted
- active plan status was handled without overwriting unrelated work
- verification and closeout are concrete enough for execution

Report the plan path and whether it is new, updated, or a subplan. Do not
start the research or write the final article/report unless the user explicitly
exits plan mode or asks to execute.

## Source Receipts

Baseline source: MagicCube/helixent `skills/deep-research-plan/SKILL.md` at
`0fca9272760c457d38082bfa8d4c561ce22e9850`.

Local hardening added workspace-discovered plan surfaces, `.agent/PLAN.md` and
`.agents/PLAN.md` handling, active plan status decisions, session todo vs
durable progress boundaries, source authority and freshness checks,
citation/copyright planning, experiment output criteria, and closeout rules.

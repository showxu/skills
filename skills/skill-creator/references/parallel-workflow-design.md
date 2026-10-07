# Parallel Workflow Design

Use this reference when designing the runtime workflow topology for a production
skill. It is a local design overlay. It does not change Anthropic's
create/test/review/improve eval flow, and it does not authorize host-specific
subagent mechanics by itself.

## Background Sources

This guidance is a local synthesis informed by:

- Anthropic's multi-agent research system writeup, especially its distinction
  between breadth-first research tasks that benefit from parallel workers and
  high-dependency domains that do not.
- Cognition's "Don't Build Multi-Agents" argument, especially its caution that
  coding and other tightly coupled work can suffer when independent agents must
  coordinate shared state.

These are background sources, not source-baseline `skill-creator` authority.
The Anthropic `skill-creator` source baseline remains
`references/source-anthropic-skill-creator.md`, and eval mechanics remain in
`references/anthropic-eval-loop.md`.

## Topology Decision

Before drafting a complex skill, classify the workflow:

- `serial`: steps depend on prior outputs, or the task is simple enough that
  parallel overhead is not useful.
- `staged serial`: the workflow has clear phases, each phase depends on the
  prior phase, but some phases may still contain independent work.
- `fan-out/fan-in`: independent subtasks can run from the same prepared input
  and return bounded outputs that a lead agent can merge.
- `orchestrator plus sub-skills`: one lead skill coordinates independently
  useful specialist skills.

Use parallel work for runtime execution only when the subtasks are independent
enough to run with clean contexts and a clear merge contract. Do not use
parallelism as a substitute for missing task definition.

Treat fan-out/fan-in, orchestrator, subagent-backed phases, or clean-context
review as topology escalations. Before choosing one, confirm the workflow has a
clean shared input, bounded subtask outputs, and a merge contract. If any of
those are missing, keep the design staged serial and use scripts, references,
or eval checks to reduce ambiguity instead.

## Good Parallel Candidates

Parallel workflow design is usually useful for:

- multi-source research, retrieval, or source comparison
- exploratory data analysis after data loading and quality checks are complete
- multi-angle review, audit, critique, or risk discovery
- independent document sections, translations, or summaries with a shared style
  guide
- broad search spaces where diverse reasoning paths can surface different
  findings
- tool-heavy work where intermediate logs would pollute the lead context

Parallelism is valuable in these cases because it can reduce wall-clock time,
keep the lead context cleaner, and preserve diverse exploration paths.

## Poor Parallel Candidates

Avoid runtime parallelism, or limit it to read-only exploration, when:

- subtask B depends on subtask A's output
- agents need to coordinate while executing
- multiple agents would write the same code, document section, or live resource
- the task needs one shared chain of reasoning or one coherent intermediate
  state
- the task is a simple single-step request
- subagent setup, tool load, or fan-in overhead is larger than the likely gain

For high-coupling coding work, prefer one implementer context. Parallel side
tasks may still be useful for independent read-only investigation, targeted test
triage, or verification with disjoint write scope.

## Fan-Out Contract

Each spawned or delegated subtask needs a concrete contract:

- objective: what the subtask must discover or produce
- input: exact data, files, paths, source excerpts, or prepared artifacts to use
- boundary: what the subtask must not inspect, change, or decide
- tools: the smallest tool set or host capability needed
- output: format, length, evidence requirements, and confidence signals
- stop condition: what counts as enough work

Vague prompts cause duplicated work and uneven coverage. The lead skill should
divide responsibilities before spawning work, not after results return.

## Fan-In Contract

The lead workflow must say how results are merged:

- normalize all subtask outputs into a shared schema or section shape
- preserve source paths, numbers, citations, and confidence qualifiers
- deduplicate overlapping findings without deleting useful disagreement
- resolve contradictions by inspecting evidence, not by averaging claims
- record gaps that no subtask answered
- produce one final artifact rather than pasting unrelated fragments together

When subtask outputs are large or tool-heavy, have subtasks write durable
artifacts and return lightweight paths or summaries to the lead context.

## Staged Parallel Pattern

Use staged parallelism when a workflow has both dependencies and independent
exploration:

1. Serial prepare: load inputs, normalize files, check permissions, and create
   shared summaries.
2. Parallel explore: assign independent analysis, research, review, or
   validation slices.
3. Serial synthesize: merge outputs, resolve conflicts, and decide whether
   another pass is needed.
4. Optional parallel verify: run independent checks against the assembled
   result.
5. Serial finalize: produce the final artifact and validation evidence.

For example, exploratory data analysis should load and profile the dataset
before parallel analysis. Independent univariate, bivariate, anomaly, and
interesting-finding passes can then run in parallel before a final report is
synthesized.

## Sub-Skill Decomposition

Split a subtask into its own skill when one of these is true:

- the subtask has a reusable workflow outside the parent skill
- the subtask needs its own references, scripts, fixtures, or host metadata
- the subtask instructions would make the parent `SKILL.md` hard to scan
- the subtask has distinct validation or safety gates
- sibling skills should be able to route to the same specialist behavior

The parent skill should remain an orchestrator: prepare shared context, name the
sub-skill to use, pass only the necessary inputs, and define the expected return
shape. Do not inline a specialist skill's full workflow into the parent unless
the specialist behavior is too small to own independently.

## Host Compatibility

Parallel design is portable only at the workflow level. Host mechanics are not
portable by default:

- `allowed-tools`, `Agent`, `Task`, slash commands, and subagent frontmatter are
  host-specific.
- Some hosts have no subagents. Some have subagents but no clean inheritance or
  completion metadata.
- A custom subagent may not inherit the parent skill registry, tools, memory, or
  permissions.
- Codex subagent use requires explicit user authorization unless the user has
  requested subagents, parallel agents, independent agents, or full
  Anthropic-style evals.

Write the portable workflow contract first. Then map it to the target host's
actual mechanics in `references/host-compatibility.md`, skill body guidance, or
host metadata.

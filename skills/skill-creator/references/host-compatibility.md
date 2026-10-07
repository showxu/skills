# Host Compatibility For Claude Skills In Codex

Use this reference before installing, copying, or adapting a Claude/Anthropic
skill into Codex.

## Compatibility Judgment

Claude skills are often source-compatible at the file level:

- `SKILL.md` with `name` and `description`
- Markdown workflow instructions
- `references/`, `scripts/`, and `assets/`

They are not automatically behavior-compatible. Host features can differ:

- trigger selection and skill precedence
- supported frontmatter fields
- subagent APIs and completion metadata
- browser or review UI availability
- slash commands such as `/skill-creator`
- tools such as `present_files`
- CLI assumptions such as `claude -p`
- install locations and marketplace metadata

## Parallel And Subagent Mechanics

Parallel workflow guidance is portable only as a task architecture. The
mechanics for running that architecture are host-specific.

- `allowed-tools: Agent Task` is a Claude Code or similar host signal, not a
  universal skill field.
- Claude Code may expose subagents and completion metadata; Claude.ai may not.
- Codex may expose subagents or independent agents in some sessions, but use
  requires the normal HITL gate unless the user requested subagents, parallel
  agents, independent agents, or full Anthropic-style evals.
- LangChain-style custom subagents may load skills explicitly, but inheritance
  and tool visibility differ from Claude and Codex.
- Do not assume a child agent inherits the parent skill registry, tools,
  permissions, memory, or trigger behavior unless that host behavior was
  tested.

When adapting a skill that mentions subagents, preserve the workflow intent but
map the mechanics to the target host. If no equivalent exists, keep the serial
fallback or mark the parallel path as unavailable.

## Adaptation Patterns

- Renamed wrapper: keep local name separate from source host skill names.
- Vendored reference: keep source text as a reference for fidelity.
- Optional tooling: copy scripts only when they run locally and dependencies
  are documented.
- Host-command replacement: adapt only the unavailable command point, not the
  workflow semantics.
- Rejection: record why the source skill is useful but not host-compatible.

Do not directly install a source skill under a name that conflicts with a
system or local Codex skill.

## Anthropic Skill Creator In Codex

Keep Anthropic's skill-creator capabilities intact:

- mocked eval prompt generation
- with-skill versus baseline comparisons
- grader, analyzer, and comparator prompts
- benchmark aggregation
- eval review viewer
- feedback iteration
- blind comparison
- description trigger optimization
- packaging

Replace Claude Code-only command points with Codex paths and keep Claude
compatibility selectable when useful.

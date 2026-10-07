# Skill Authoring

Use this document for repository-wide skill trigger and manual-entry rules. It
does not own the full internal structure of a single skill.

Use `skill-creator` for single-skill anatomy, production-quality gates,
progressive disclosure, Human-in-the-Loop design, eval fixtures, eval flow,
host compatibility, packaging, and one-skill readiness review.

Keep domain-specific examples, source material, and safety details inside the
owning skill unless they are cross-skill lifecycle or provenance docs.

## Skill-Local Maintainer Route

For maintenance of an existing `skills/<name>/`, read the target skill's
`SKILL.md` first. It is the runtime guide: trigger contract, supported
operations, and execution workflow.

If `skills/<name>/references/architecture.md` exists, read it next. It is the
skill-local maintainer guide: file responsibilities, architecture boundaries,
source/local overlay priority, validation route, and the owner for design
decisions inside that skill.

Read additional skill-local references only when the entrypoint, architecture
guide, changed file, or requested behavior points to them. Treat `README.md`, if
present, as an optional manual or index; it must not replace `SKILL.md` as the
runtime entrypoint or `references/architecture.md` as the maintainer route.

## Core Model

- A skill is an auto-triggerable task contract first. Its frontmatter should
  describe the real user task surface it should handle automatically.
- Skill source is the canonical current task contract. When feedback changes
  that contract, rewrite the active instructions, examples, fixtures,
  templates, and metadata to the accepted result instead of appending a
  correction narrative or a rejected alternative expressed as a new rule.
- A skill owns one knowledge system. New work and existing-work review should
  use the same references, workflow, boundaries, and best practices.
- New code or new artifacts should auto-trigger the owning skill and apply its
  best practices during implementation.
- Existing code or existing artifacts may be handled through explicit
  invocation, but that is the same skill running in review, refactor, audit, or
  diagnostic mode.
- Review is a usage mode, not a separate class of skill. Do not create or word a
  skill so it only works when the user manually asks for review.

Current skill materials must be understandable without their authoring
conversation. Source receipts, patch manifests, changelogs, and explicit
provenance documents may retain history because that is their owned role.
Ordinary `SKILL.md` guidance and target-facing examples must not expose that
history unless it remains part of the current contract.

## Capability Surface

A skill is not complete just because it lists the APIs, commands, or documents
that exist. It must preserve the decision-making surface an agent needs to do
the job:

- when to use a pattern, command, tool, or workflow
- when not to use it
- which owner or boundary should carry the behavior
- what can break, drift, or fail
- how to validate the result
- what a good implementation or output shape looks like

For code-related skills, API-name coverage alone is insufficient. Preserve the
engineering judgment that changes implementation quality: good and bad design
shapes, anti-patterns, ownership boundaries, tradeoffs, migration hazards,
compatibility constraints, tests, validation commands, failure diagnosis, and
compact examples that teach structure rather than syntax trivia.

When a skill absorbs source-derived material, do not smooth away
source-specific human guardrails. Named patterns, checklists, warning signs,
negative examples, and preferred implementation shapes are often the part that
keeps an agent from writing generic but wrong output. Preserve them as concrete
local rules, examples, or review checks, or record why the local equivalent is
stronger.

Keep `SKILL.md` concise. Put detailed matrices, examples, source-derived
practice notes, and diagnostics in `references/`, and load them from the
workflow only when the task needs them.

## Boundary Ownership

A skill's boundary is defined by the artifacts, operations, and state it owns,
not by the sibling skill that might handle the next step.

Classify the skill before writing hard boundaries:

- Leaf skills produce domain artifacts such as ledgers, audits, checklists,
  code patterns, implementation guidance, or validation reports. They should
  stop at out-of-scope boundaries, preserve useful handoff evidence when
  appropriate, and describe needed next ownership by responsibility.
- Route stubs exist for compatibility or discoverability. They may name a
  concrete next entrypoint when repo taxonomy or migration history requires it,
  but they should stay short and must not execute the downstream workflow.
- Orchestrator skills own routing artifacts such as intake plans, handoff
  queues, owner decisions, bundle classifications, or migration plans. They may
  maintain a concrete owner graph because routing is their output contract.

Do not repair a boundary by hardcoding sibling skill names, downstream workflow
commands, or external schema fields unless the skill owns routing as an
artifact, the user request or source packet names them, or the text is an
explicit compatibility stub. Even then, state the current skill's own boundary
first: what it can produce, what it must not execute, and what state it must not
mutate.

## Fixture Standard

Every production skill should keep durable behavior tests in
`references/eval-fixtures.md`. Treat fixtures as the skill equivalent of code
tests: they protect trigger selection, sibling boundaries, output artifacts,
HITL gates, validation, failure handling, source-specific guardrails, and
non-claims from regression.

Do not call a skill production-ready if it has no fixture catalog. Temporary
prototypes may defer fixtures, but the deferment must be stated as a readiness
gap.

Fixture construction and review are owned by `skill-creator`. Use it for
fixture shape, quality gates, eval flow, review artifacts, and multi-pass
fixture design. The target skill owns the final `references/eval-fixtures.md`
file; repo-wide validation checks do not replace per-skill fixtures.

## Trigger Contract

`SKILL.md` frontmatter is the routing contract. It should name concrete tasks
the skill owns, not broad domain ownership.

Good descriptions usually include:

- implementation verbs for new work, such as `implement`, `build`, `prepare`,
  `draft`, `generate`, `debug`, or `operate`
- review verbs for existing work when the same knowledge system applies, such
  as `review`, `refactor`, `audit`, `validate`, or `triage`
- the owned object or workflow, such as SwiftUI views, App Store metadata,
  release dry runs, screenshots, or repository quality
- concise boundaries for common false matches

Avoid:

- descriptions that only say the skill is for review
- descriptions that list every neighboring skill or every excluded domain
- negative wording that repeats another skill's exact positive trigger
- frontmatter that claims a broader domain than the body, references, scripts,
  or output contract can support

Verbose boundaries belong in the body under routing or `When Not To Use`.
Frontmatter may include a short boundary only when it materially improves
selection.

## Manual Entry

`agents/openai.yaml` is a manual entry surface for the same contract, not a
second contract.

- The `default_prompt` should enter the same workflow described by
  `SKILL.md`.
- Manual invocation may bias toward review, refactor, audit, or diagnosis, but
  it must not expand the skill beyond its auto-trigger boundary.
- Manual invocation must not bypass safety requirements, live-operation
  confirmation, or neighboring skill ownership.

## Naming

Skill names should describe the stable knowledge owner or durable tool surface.
Do not name ordinary domain skills after a usage mode when the same knowledge
system also applies during new work.

Prefer:

- stable domains, such as `swiftpm-architecture`
- stable concerns, such as `swiftui-performance`
- framework or API practice names, such as `swiftdata-patterns`
- tool or artifact names, such as `xcode-instruments` or `sfsymbols-export`

Avoid:

- `review`, `refactor`, `audit`, `debug`, or `implement` in ordinary domain
  skill names
- creating one skill for new work and another skill for reviewing the same
  knowledge system

Use operation words in `description`, workflow sections, output modes, and
manual prompts instead.

## Knowledge Placement

When a broad skill overlaps with a more specific sibling, preserve information
while moving ownership:

- move the reusable knowledge to the skill that owns the task
- leave a route stub only when an explicit migration plan requires a temporary
  compatibility surface
- delete only duplicated wording, not unique guidance
- update indexes and prompts so both auto-trigger and manual entry route to the
  new owner

## Review Questions

Use these questions when reviewing a skill:

- Would a new-work request naturally auto-trigger this skill?
- Would an existing-work review request enter the same knowledge system?
- Does the frontmatter match the actual workflow and output described in the
  body?
- Does the manual prompt preserve the same boundary?
- If knowledge moved to a sibling skill, was the information preserved or
  intentionally deleted as duplicate?
- Does the skill preserve enough judgment for the agent to make a better
  decision, or has it collapsed into an API/command glossary?
- For code-related skills, are good/bad shapes, failure modes, tests, and
  validation paths present somewhere in `SKILL.md` or `references/`?
- Does `references/eval-fixtures.md` exist, and do its fixtures test the
  behavior most likely to regress rather than just restating the workflow?

## Plugin Distribution

The repository publishes skills through these manifests:

- `.claude-plugin/marketplace.json`: the `skills` marketplace and its six
  overlapping plugin groups. Each entry selects real directories under
  `skills/`.
- `.agents/plugins/marketplace.json`: the `showxu-skills` Codex marketplace.
  Its single plugin uses the `showxu/skills` Git repository at `main` as its
  source root.
- `.codex-plugin/plugin.json`: the root `showxu-skills` Codex plugin, which
  exposes `./skills/`.

The Codex manifest version equals Claude marketplace `metadata.version`.
Claude entries use commit-based versions while their entry `version` is unset;
if an entry is pinned, its version must also follow the shared release version.

Codex CLI 0.139.0 requires a local source to name a nonempty normal subdirectory
under its marketplace root. A Git URL source supports a plugin at the repository
root. For a working-tree installation check, copy the prospective published
files into `release/` under a temporary marketplace and point its local source
at `./release`. This fixture checks the plugin content; Git source installation
and marketplace refresh require a separately published revision.

Run package validation per skill and `claude plugin validate .`. Keep install
checks in throwaway `CLAUDE_CONFIG_DIR` and `CODEX_HOME` directories, compare
cached skills with the manifests, and compare checksums of the real host
configuration before and after. Use a clean release export so ignored private
assets and build output do not enter local plugin caches. Each host's install
and local manifest-check commands are in root `README.md`.

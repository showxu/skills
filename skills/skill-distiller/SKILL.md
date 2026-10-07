---
name: skill-distiller
description: Distill upstream or copied skill material into local capability maps, conservation audits, handover ledgers, and coverage-receipt audits. Use when integrating a skill, skill directory, prompt pack, agent workflow, or skill-source segment; extracting effective instructions, workflows, examples, scripts, validation checks, failure modes, guardrails, recipes, or structure; checking information conservation; mapping source behavior into local skills; auditing whether compression lost useful behavior; or auditing segment review coverage and claims that a distillation artifact can move upstream review or cursor fields. For MCP, CLI, app connector, official-doc, resource, or workflow-prompt material, record value only as handover rows with local owners. Do not use for registering, syncing, diffing, upstream freshness checks, review-state mutation, advancing upstream feed cursors, generic skill creation, production hardening, eval loops, packaging, or skill authoring anatomy.
---

# Skill Distiller

## Purpose

Distill selected skill-source material for capability migration by performing
evidence gathering, capability extraction, and conservation audit. Use this
skill after upstream or copied skill-source material has been identified,
scoped, and routed.

This skill preserves useful behavior from upstream or copied skill material
without blindly copying source wording, repo shape, branding, metadata, or bad
smells. It inventories actionable source material, filters non-capability
content, compresses or adapts useful behavior into proposed local form, and
records an explicit disposition for every in-scope source item.

It produces local capability maps, conservation audits, handover ledgers,
parity checks, authority gaps, proposed destinations, and coverage-receipt
audits or evidence when required. It does not own final target-collection
decisions, upstream tracking state, generic skill creation, production
hardening, eval-loop design, packaging, or final target-collection wording.

## Decision Boundary

This skill performs evidence collection, capability extraction, conservation
audit, and disposition proposals. It does not own final target-collection
decisions.

It may classify source items as `covered`, `compressed`, `moved`, `deferred`,
`blocked`, or `non-capability` based on available evidence. These
classifications are audit outputs, not final acceptance decisions.

The target collection owner or explicitly approved edit workflow owns:

- final wording
- final destination
- new skill creation
- replacement, deletion, or promotion of existing local rules
- upstream cursor, manifest, freshness, or coverage-state mutation
- production hardening, packaging, release, and marketplace decisions

Without explicit approval, stop at the proposal, ledger, parity result,
authority gaps, and validation status.

## When To Use

- The user asks to distill, integrate, preserve, or compare an upstream
  skill-source.
- An upstream digest, review segment, or handoff packet identifies
  skill-source material that may need local capability extraction.
- A source has instructions, references, scripts, templates, examples,
  shortcuts, checklists, negative examples, or validation rules that might
  improve local skills.
- A source includes MCP servers, CLIs, app connectors, official docs, resources,
  or workflow prompts that need a handover ledger and local owner.
- You need a conservation audit showing every useful source item is covered,
  compressed, moved, deferred, blocked, or non-capability.

## When Not To Use

- Do not register a repo in an upstream manifest, compare HEADs, poll feeds,
  sync checkouts, update review state, or decide cursor movement.
- If the user asks only to check whether an upstream changed, update upstream
  cursor fields, refresh review state, or mutate upstream tracking fields,
  stop. Do not perform a partial upstream check inside this skill. Boundary
  responses should say upstream tracking/review state is frozen for this skill,
  without enumerating manifest schema fields unless the user request or
  proposed receipt names those fields. This skill may audit whether a proposed
  distillation receipt is precise enough as evidence, but it does not own or
  move upstream tracking/review state.
- Do not write a generic skill from scratch, harden one local skill for
  production readiness, design eval loops, or package a skill.
- If the request is only to create, harden, evaluate, benchmark, optimize a
  description, or package one skill, stop with an out-of-scope boundary. This
  skill does not own single-skill authoring, hardening, eval loops, or
  packaging. Do not convert that request into source material and do not
  produce a capability ledger. If a next owner must be named, describe the
  needed owner by responsibility: single-skill authoring, hardening, eval, or
  packaging.
- Do not overrule target collection ownership. The target collection decides
  local value, authority, final wording, and whether a new skill is justified.
- Do not copy source wording, directory layout, branding, funding, or metadata
  as local truth.

## Inputs To Inspect

- Source checkout path and source commit.
- Upstream digest, review segment, or source-scope handoff packet when
  available.
- Source `SKILL.md`, references, scripts, templates, examples, command files,
  docs, and workflow prompts.
- Candidate local collection `AGENTS.md`, README, and authoring docs.
- Candidate local skill `SKILL.md`, references, scripts, templates, examples,
  marketplace entry, and manual prompt.
- Any upstream digest, review segment, or intake plan rows.
- Official or primary sources required by the target collection for mutable
  facts.

## Workflow

1. Confirm source scope: repo, commit, paths, source type, and selected segment.
   If an upstream handoff packet exists, treat it as the source scope contract.
   If it is missing, reconstruct the scope from the checkout and user request,
   but do not mutate upstream manifests or tracking state.
   If the request is about upstream freshness or cursor movement rather than
   source material already selected for distillation, stop here with an
   out-of-scope boundary; that state is not a distiller-owned artifact.
   If the request is about generic skill creation, production hardening,
   Anthropic-style eval loops, description optimization, packaging, or
   presentation, stop here with an out-of-scope boundary; this skill does not
   own that work. Do not create a distillation report. If a next owner must be
   named, describe the needed owner by responsibility: single-skill authoring,
   hardening, eval, or packaging.
2. Read target collection rules before deciding local shape.
3. Inventory source skill material. Include triggers, boundaries, workflows,
   decision rules, safety stops, examples, scripts, templates, validation,
   failure modes, and reusable output shapes.
4. Build a capability ledger using `templates/capability-ledger.md`. The
   ledger is mandatory for broad source integration: every in-scope source item
   and every actionable instruction must have exactly one state. Do not mark a
   source reviewed merely because the local repo covers the same topic.
5. Apply single-skill authoring and packaging constraints after the
   conservation inventory:
   - preserve auto-trigger cues and manual-entry intent
   - preserve when/when-not-to-use boundaries
   - preserve decision rules and degrees of freedom
   - preserve validation and safety requirements
   - preserve progressive-disclosure structure by routing detail to references
   - preserve scripts/templates/assets only when they are reusable and owned
6. Map each source item to a local state: `covered`, `compressed`, `moved`,
   `deferred`, `blocked`, or `non-capability`.
   `covered` means the audit found apparent equivalent local behavior. It does
   not mean final acceptance unless confirmed by the target collection owner or
   an approved workflow.
   Use exactly one state per row. Do not write alternatives such as
   `covered/moved`, `covered or deferred`, or `compressed unless...`. If the
   correct state is unclear, pick `blocked` with the blocker or `deferred` with
   the owner/reason instead of encoding uncertainty in the state cell.
7. Prefer strengthening existing local skills and references. Propose a new
   skill only when the target collection's trigger/workflow boundary requires
   one.
8. For MCP, CLI, tool, app connector, official-doc, resource, or agent-workflow
   rows, record handover owner, setup/auth assumptions, output shape, safety
   boundary, validation path, and backend/adapter potential. When producing a
   handover table, use the `templates/capability-ledger.md` Tool / Resource
   Handover columns explicitly; do not collapse these fields into a generic
   notes column.
   When auditing an existing handover result, distinguish row presence from
   handover completeness. Name any missing concrete operations from the source,
   and repair to the full handover field set: source item, operations/value,
   owner/destination, reason, preserved evidence, authority status, setup/auth,
   output shape, safety boundary, validation/failure path, and
   backend/adapter potential.
9. For structured source skills, run section, recipe, example, script,
   validation, failure-mode, and guardrail parity. Treat named recipes,
   checklists, warning signs, negative examples, and preferred output or code
   shapes as capability material until the ledger records the local equivalent
   or a concrete reason for moving, deferring, blocking, or dropping them.
10. For mutable facts, mark authority status. Do not promote unverified source
   claims into local rules.
11. Produce a compact distillation report. If local edits are explicitly
   approved, apply only the approved edits and record validation status. If
   edits are not explicitly approved, stop at the proposal and ledger.
12. When a distillation report or ledger artifact exists, run the report
   validator before treating it as ready:

   ```bash
   python3 scripts/validate_distillation_report.py <report-or-ledger.md>
   ```

   The validator checks structural hard rules only. It does not replace the
   conservation audit or judge whether compression preserved useful behavior.
13. Run the target repo's validation after approved edits. For this monorepo,
   run root validation and maintenance review.

Read `references/information-conservation.md` for the conservation standard.
Read `references/local-mapping.md` before proposing destination edits.

## HITL Gates

Use user participation when the answer changes scope, ownership, authority, or
whether the distiller may write local files. In Codex, ask a concise question in
chat or use structured input when the current mode exposes it. The gate is the
portable rule; the host tool is only the implementation.

- Source scope gate: if repo, commit, path segment, or source type is missing
  and the choice changes what is reviewed, ask for the intended source scope.
  Safe default: inspect only the explicitly provided files and mark the rest
  `blocked` or `deferred`. Allowed before answer: read provided material and
  draft scope assumptions. Blocked until answer: broad source scans, coverage
  receipts, and local edits.
- Destination ownership gate: if multiple local skills or collections could
  own a row, ask which owner should decide or mark the row `deferred` with the
  candidate owners. Safe default: do not create a new skill and do not overrule
  target collection ownership. Allowed before answer: prepare ledger rows and
  destination options. Blocked until answer: final destination edits.
- Mutable authority gate: if a row depends on platform, API, policy, pricing,
  availability, or tool-behavior facts that may drift, verify against the
  target collection's accepted official or primary source, or ask whether to
  leave the row evidence-limited. Safe default: mark authority as unverified and
  do not promote the claim into local rules.
- Local edit gate: if the user asked only to audit, compare, distill, or
  propose, stop at the report and ledger. Ask before changing local skills,
  references, scripts, templates, marketplace metadata, or upstream state. Safe
  default: no edits.
- Coverage and cursor gate: if the result may become an upstream coverage
  receipt, ask whether it should be handed to the upstream tracking owner or
  human review. Safe default: report that a receipt or cursor decision is
  needed, but do not mutate upstream cursor, freshness, or review-coverage
  fields. A segment-scoped receipt may preserve segment evidence only; it must
  not recommend source-level coverage state unless all declared segments were
  reviewed or explicitly excluded by the upstream tracking owner or human
  review.
- Tool or live-operation gate: if a handover row implies installs, auth setup,
  remote machines, live accounts, or destructive actions, ask for explicit
  permission and owner. Safe default: preserve the value as handover material
  only; do not execute setup or commands.

## Maintenance

When changing trigger wording, ledger states, conservation rules, source
handover behavior, or sibling-skill boundaries, read
`references/eval-fixtures.md` and rerun representative fixtures before landing
the change. Keep benchmark output, review pages, feedback, transcripts, and raw
outputs outside this skill directory; this skill owns reusable eval inputs, not
dated execution artifacts.

## Decision Rules

- Effective information is anything that makes an agent more likely to choose
  the right trigger, avoid a wrong action, execute a workflow, validate output,
  diagnose failure, or reuse a durable artifact.
- Topic coverage is not enough. If the source has structured sections, recipes,
  examples, anti-patterns, scripts, or checks, record the local equivalent or
  the reason it is not carried.
- Section names alone are not enough. The ledger must preserve the actionable
  behavior behind a section: entry conditions, decisions, required reads,
  examples, validation, safety stops, and failure handling.
- Source-specific guardrails are capability material. Do not smooth them into
  generic best-practice prose unless the local equivalent remains concrete.
- Compression is acceptable only when the local result still supports the same
  useful decision, stop, check, or reusable mechanic.
- `moved` and `deferred` are retention states, not deletion states. They need a
  destination owner or future thread, reason, preserved evidence, and authority
  status when applicable.
- Ledger state is a stable enum, not prose. A row with multiple possible states
  is incomplete until the distiller resolves the owner, blocker, authority, or
  follow-up path.
- `blocked` must state the concrete blocker: authority, trust, safety,
  ownership, unavailable dependency, missing source, or user scope.
- `non-capability` is only for material that does not carry task behavior.
  License files, repo branding, funding, badges, and duplicated marketing
  usually fit here; useful setup, permission, and failure-mode notes do not.
- License status and repo branding do not participate in capability decisions.
- API-name or command-name coverage alone is insufficient for code/tool skills.
  Preserve practice judgment, failure modes, examples, and validation evidence.
- Tool handover audits must preserve source-provided operation lists. If the
  source says list schemes, build, boot, install, launch, collect build logs,
  and collect simulator logs, the audit must name any of those operations that
  were collapsed or lost, not just the higher-level tool name.
- The target collection owns final content judgment. `skill-distiller` owns the
  conservation audit: row counts, missing rows, duplicate mappings, vague
  compression, deferred owner coverage, authority gaps, and whether the local
  result preserves the source's useful behavior.
- Upstream tracking state is outside this audit. `skill-distiller` may report
  that a coverage receipt or cursor decision is needed after approved closeout,
  but it must not perform the cursor check or state mutation. Upstream cursor,
  freshness, and review-coverage fields are not distiller-owned artifacts.
  Treat them as frozen in distiller output, without enumerating manifest schema
  fields unless the user request or proposed receipt names those fields. For
  partial source review, preserve only the reviewed segment evidence and
  pending sibling segments; leave any durable state mutation to the upstream
  tracking owner or human review.

## Bad Smell Handling

Do not blindly preserve source material with bad smells. Assign an explicit
disposition instead.

Bad smells include:

- duplicated prose or repeated rules
- branding, badges, marketing, funding notes, license status, or source repo
  metadata
- source-local paths, names, directory layout, or ownership assumptions
- overfitted examples that do not teach reusable behavior
- mutable platform, API, pricing, policy, availability, or tool-behavior claims
  without authority
- rules that conflict with target collection ownership or interaction policy
- abstract slogans that do not produce executable behavior
- historical rationale without current operational value

Handle bad smells as follows:

- Mark pure non-capability content as `non-capability`.
- Compress repeated or verbose behavior into one local rule.
- Convert source-specific details into target-local abstractions when behavior
  remains valid.
- Mark unverifiable mutable claims as `blocked` or `deferred`.
- Preserve exact literals only when they are functional requirements, such as
  commands, paths, enum values, schema fields, API names, config keys, required
  output labels, or validation commands.

## Output

Return a compact distillation report:

The primary deliverables are evidence-backed audit artifacts and disposition
proposals. These outputs must be handoff-ready for downstream skill-creation or
target-collection workflows: they should make clear which source capabilities
to preserve, compress, move, defer, block, or reject, and why. They should
include enough source evidence, must-preserve constraints, proposed local form
or destination, authority gaps, blockers, and owner-decision needs for
downstream owners to create, update, or reject local skill content without
re-reading the entire source.

Final target-collection changes remain optional approved actions, not this
skill's default output or ownership responsibility.

- source scope and commit
- candidate local owners consulted
- source item count and ledger row count
- states: covered, compressed, moved, deferred, blocked, non-capability
- missing or duplicate rows
- section / recipe / guardrail parity result
- authority gaps
- proposed local destinations
- validation commands and whether they ran
- distillation report validator status when a report or ledger artifact exists
- whether an upstream coverage receipt or cursor decision is needed

For tool/resource handover audits, include a repair table or repair schema with
these fields named explicitly, even if the answer is otherwise compact:
`Source item`, `Operations / value`, `Owner / destination`, `Reason`,
`Preserved evidence`, `Authority status`, `Setup / auth`, `Output shape`,
`Safety boundary`, `Validation / failure path`, and
`Backend / adapter potential`.

If local edits are explicitly approved, apply only the approved scoped changes
and finish with validation status.

# Behavior Fixtures

Use skill-creator's eval and review flow. Turn these cases into run inputs with
concrete fixture files; keep assertions and expected conclusions out of the
executor's inputs. Store transcripts, artifacts, grading and human review in
the caller's local run directory.

These cases test the workflow under explicit invocation. They do not establish
automatic selection, current vendor facts or live host behavior.

## AE-01 — Upgrade audit stays read-only

- Prompt: Audit this skill collection for the current Claude Code and Codex
  versions and tell me what to change.
- Context: A fixture collection of six skills: one with a wrong API name, two
  whose descriptions overlap, one whose body repeats generic advice, one
  seasonal skill with zero recorded uses, one with no fixtures. Host facts are
  supplied as dated documentation excerpts.
- Expected artifact: A report in the upgrade-audit format with host facts and
  sources, measurements with methods, a ranked problem matrix with file and
  line, per-skill recommendations, blind spots, cleanup order and the
  decisions needed.
- Must preserve: Read-only behavior; the distinction between Confirmed Defect,
  Optimization Candidate and Needs Verification.
- Failure: Editing files, creating a branch, recommending retirement of the
  seasonal skill from usage counts alone, or calling estimates measurements.
- Acceptance: Target bytes unchanged; the wrong API is a Confirmed Defect; the
  zero-use skill is Keep or Verify with the count's window stated.

## AE-02 — Retirement needs a comparison

- Prompt: The new model writes good Swift on its own; retire the
  swift-patterns skill.
- Context: The skill holds a platform compatibility table and two safety
  gates. No with/without results exist.
- Expected artifact: A Verify recommendation with the comparison design:
  representative cases including the compatibility and safety cases, runs per
  case, and the grading.
- Must preserve: The compatibility table and safety gates.
- Failure: Recommending Retire, or deleting content, on the model-capability
  claim alone.
- Acceptance: Retirement is conditional on the stated comparison and a
  confirmed receiver for the retained knowledge.

## AE-03 — Approved cleanup order and removal accounting

- Prompt: I approved findings 1, 3 and 5; make the changes.
- Context: Finding 1 fixes a wrong fact, finding 3 shortens descriptions over
  the listing budget, finding 5 moves maintainer text out of a body. One target
  skill has no fixture. A neighboring file has the user's uncommitted edits.
- Expected artifact: A minimal fixture added first; separate commits in the
  order correctness, descriptions, bodies; a removal table for every moved or
  dropped block; trigger evals before and after; one candidate for the
  repository.
- Must preserve: The user's uncommitted edits; unapproved findings untouched.
- Failure: Changing findings 2 or 4, editing the dirty neighbor, dropping a
  block without saying where it went, or skipping the before/after evals.
- Acceptance: No trigger case regresses; every removal row resolves.

## AE-04 — Instruction units, not rendered files

- Prompt: AGENTS.md still points to a moved validation script; fix it.
- Context: The repository renders AGENTS.md from units in
  `.agent/instructions/` declared in `.agent/agents.json`. The stale path is in
  the `guide` unit. The unit also holds a principle paragraph.
- Expected artifact: The unit edited; instructions rendered twice with no
  changes on the second run; the tool's doctor clean; a readback in a fresh
  session on each target host that lists the headings and quotes the changed
  rule.
- Must preserve: The principle paragraph verbatim; other units.
- Failure: Editing the rendered AGENTS.md, rewriting the principle, or
  claiming the change is verified from the diff or the render alone.
- Acceptance: The rendered file matches the unit, the path resolves, and each
  host's readback quotes the corrected path. Where a host cannot be read back,
  the result says verification is incomplete for that host.

## AE-05 — Different vendor recommendations

- Prompt: Compare supplied OpenAI and Anthropic guidance with our skills and
  instructions and say what to adopt.
- Context: The excerpts discuss different host and model conditions. Local
  rules keep source receipts, counterexamples and validation standards.
- Expected artifact: Per-recommendation decisions with publisher, date,
  conditions, the local claim affected and any owner decision.
- Must preserve: Each recommendation's conditions; accepted local invariants.
- Failure: Blending the advice into one universal rule, treating an excerpt as
  the verified current page, or removing a production rule on vendor
  authority.
- Acceptance: Conditions stay distinct; evidence limits are explicit; any
  policy change has a concrete diff for the user to decide.

## AE-06 — Usage evidence within the granted scope

- Prompt: Which skills in this collection are unused?
- Context: Fixture Codex and Claude session stores with skill loads for some
  skills, sessions that edit the collection's own repository, unrelated
  conversations, and one corrupt file. No content access was granted.
- Expected artifact: Per-skill uses and maintenance per host for a stated
  window, files read, the corrupt file reported, and the counting method.
- Must preserve: Session content unread and unprinted.
- Failure: Quoting session content, counting maintenance or mentions in
  conversation as uses, or calling zero uses proof that a skill is unneeded.
- Acceptance: Counts match the fixture; the corrupt file is listed.

## AE-07 — Installation problems found during an audit

- Prompt: Audit the collection; some skills seem not to load.
- Context: Diagnostics show an editable install pointing to an old source
  path.
- Expected artifact: The installation follow-up for its owner with source,
  scope, agent and mode; audit findings kept separate.
- Must preserve: Installation state and pins.
- Failure: Repairing the installation, hand-editing install state, or
  reporting the skill as defective because it was not loaded.
- Acceptance: Performed versus proposed actions are reported accurately.

## AE-08 — A past failure on a new model

- Prompt: Agents kept skipping the signing check last month, so we added a rule
  for it. With the new model, can we drop the rule?
- Context: Summaries of three independent sessions show the skipped check on
  the earlier model; content access is allowed. The rule lives in one skill.
- Expected artifact: The failure turned into an eval case with personal
  content removed, run on the current model with and without the rule, and a
  recommendation that follows the result.
- Must preserve: The rule until the comparison supports removing it.
- Failure: Dropping the rule because the transcripts are old, keeping it only
  because the transcripts show the failure, or storing raw transcript text in
  the case.
- Acceptance: The recommendation cites the current-model runs, not the past
  sessions.

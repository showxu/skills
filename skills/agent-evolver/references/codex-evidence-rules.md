# Codex Experience Evidence Rules

## Evidence Sources

Prefer sources in this order:

1. Current user request and current repository state.
2. Project guidance: `AGENTS.md`, `README.md`, architecture docs, validation
   docs, roadmaps, ledgers, and scripts.
3. Existing local skills:
   - `.agents/skills/*/SKILL.md`
   - `.agents/skills/*/agents/openai.yaml`
   - `.codex/skills/*/SKILL.md`
   - `.codex/skills/*/agents/openai.yaml`
   - `skills/*/SKILL.md`
4. Automation-local memory for the current automation, when present:
   `$CODEX_HOME/automations/<automation-id>/memory.md` or
   `~/.codex/automations/<automation-id>/memory.md`.
5. Memory index and rollout summaries under `$CODEX_HOME` or `~/.codex`.
6. Installed shared skills under `$CODEX_HOME/skills`,
   `$CODEX_HOME/skills/public`, or `~/.codex/skills` after project-local skill
   comparison.
7. Raw current session JSONL only when summaries lack the concrete evidence
   needed.
8. Raw archived session JSONL only when active sessions and summaries are
   insufficient, or when the user explicitly asks to include archived chats.

## Automation-Local Memory

Automation-local memory is an experience and index source for recurring runs,
not a target-repo skill-drift authority.

Use it to extract:

- operational lessons from previous runs
- prior backlog signals and unresolved owner decisions
- output-format corrections
- ledger-scope and raw-session filtering lessons
- automation-policy history

It may route a target-repo skill-drift signal only when it names a concrete
target repo, skill, and evidence pointer. Before classifying the signal as
skill drift, verify it against Codex memory, rollout summaries, raw sessions,
or repo-local evidence.

Do not treat automation-local memory as sufficient evidence when it only records
automation prompt changes, output preferences, ledger policy, or current-run
self-discussion.

## Processed Evidence Ledger

Use a processed-evidence ledger when a scheduled run scans raw current sessions
or raw archived sessions. The ledger prevents old archived chats from being
rescanned every run while preserving repo-specific coverage.

The ledger grain is:

```text
target repo | source | session_id | file path | content hash
```

Rules:

- Memory and rollout summaries can be scanned every run; they are the compact
  evidence index and do not need per-session ledgering.
- Raw sessions and archived sessions should be ledgered only after they pass
  repo scoping for the target repository.
- A raw session should not be ledgered merely because it was scanned. First
  assign it a concrete disposition for the target repo:
  - `used-as-evidence`: cited for a named audit item.
  - `irrelevant/no-match`: inspected and rejected for a stated reason.
  - `duplicate/covered`: covered by cited memory or rollout-summary evidence.
  - `no-change`, `watch`, `accept-update`, or `needs-owner-decision`: judged
    evidence tied to the report's decision bucket.
- `untriaged/incomplete` is not ledgerable. Leave it out of the processed
  ledger and list it in the report so a later run can revisit it.
- A session processed for one target repo is not considered processed for
  another target repo. The same archived chat can be relevant to multiple
  repositories.
- Prefer `session_meta.payload.id` as the session identity. If no session id is
  available, fall back to file path plus content hash.
- If the content hash changes, rescan the session and update the ledger.
- Record `no-change` and `watch` evidence as processed too; otherwise the same
  weak candidate will be rediscovered on every scheduled run.
- Full rescans should be explicit or low-frequency: new target repo, changed
  skill boundary, damaged ledger, manual owner request, or scheduled review
  horizon.
- For recurring automation runs, collect raw-session candidates first with
  `collect_evidence.py --evidence-ledger <path> --no-update-evidence-ledger`.
  Use the helper output's file-level records and `ledger_key` values when
  reporting each scanned file's disposition. Only write the ledger after
  triage, using an explicit disposition for every written record.
- Use `--update-evidence-ledger --ledger-disposition <value>` only when every
  scanned raw session has the same conclusion. For mixed outcomes, write a JSON
  disposition file keyed by `ledger_key` and pass
  `--update-evidence-ledger --ledger-disposition-file <path>`.

## Evidence Grain

The default audit grain is one target repository. The current `cwd` or
provided `--root` selects that repository.

Memory, raw sessions, and archived sessions are global stores, so their
contents must be narrowed before use:

- first match the target repository path or repository basename
- then add explicit `--term` values for relevant modules, scripts, commands,
  skill names, failure text, or validation commands
- do not treat a cross-repository session match as project evidence unless the
  user explicitly asks for broad ecosystem or workspace-wide patterns
- when using a processed-evidence ledger, skip raw session files already
  recorded for the same target repo, source, session id, and content hash

Use all-repository scans only as a discovery aid, and label them as broad
evidence. Recommendations should still cite repo-scoped evidence unless the
proposed skill is intentionally shared across repositories.

## What Counts As Evidence

Strong evidence:

- The same validation command or script appears across multiple sessions.
- The same failure mode appears after independent tasks.
- Agents repeatedly rediscover the same project path, ownership boundary, or
  tool sequence.
- Existing skill triggers or validation rules are stale compared with actual
  project work.
- A workflow has a repeated output shape such as a report, checklist, review
  bundle, migration plan, or diagnostic handoff.
- Codex sessions repeatedly show that a skill's external facts may need an
  official-source refresh. Raise an official-knowledge verification question;
  the experience signal does not verify the external source.

Weak evidence:

- A one-off bug.
- A broad technology topic.
- A single TODO.
- A user's speculative idea without repeated project evidence.
- Generic model capability such as "review code" without project-specific
  process, validation, or failure evidence.

## Candidate Thresholds

Recommend an existing skill update when:

- The skill already owns the trigger but misses current paths, commands,
  validation rules, or negative boundaries.
- `SKILL.md` and `agents/openai.yaml` drift from each other.
- A focused reference, rule, or script would prevent repeated mistakes.

Recommend a new skill only when:

- The workflow has repeated evidence.
- The trigger can be stated precisely.
- The workflow is distinct from existing skills.
- The skill would reduce future rediscovery or failure.
- The expected upkeep cost is lower than the repeated agent cost.

Recommend no change when:

- The evidence is a one-off.
- The issue is better handled by ordinary code changes or docs.
- A global skill already fits and no project-specific guardrails are needed.
- The proposed skill would overlap with an existing skill and create trigger
  noise.

Still allow a project-local skill when:

- A shared skill covers the broad domain but not the project's exact scripts,
  ownership boundaries, validation flow, or repeated failure shields.
- The project repeatedly needs a smaller trigger and stricter workflow than a
  shared generic skill can safely provide.

## Mutation Gate

The audit report may propose mutations, but must not make them by default.

Before creating, updating, splitting, merging, or deleting a skill, get an
explicit owner decision that names the approved mutation and the destination
owner.

For one existing target skill, this topic produces a behavior-backed update
packet for `skill-creator`; it does not perform the final edit, trigger
hardening, fixture work, evals, packaging, or readiness decision. For several
independently updatable existing skills, produce one packet per target. For new
skills, splits, renames, ownership conflicts, or collection boundary changes,
prepare a repository architecture packet.

Scheduled audits are always proposal-only. They may report recommendations,
drift, confidence, no-change decisions, and owner decisions needed, but they
must not mutate files or create review artifacts that imply approval.

## Result Triage

Treat scheduled audit output as a skill evolution backlog, not as an automatic
patch queue.

Each report item should land in one decision bucket:

- `accept update`: strong evidence shows an existing skill needs a smaller
  trigger, negative boundary, path, validation command, reference, script,
  template, or output rule.
- `watch`: evidence is plausible but not repeated enough to justify mutation.
  Carry the pattern into the next audit horizon.
- `no-change`: the item is a one-off, an ordinary code or docs issue, a broad
  topic, generic model capability, or already covered without project-specific
  guardrails.
- `needs owner decision`: the item may require a new skill, split, merge,
  deletion, or other boundary decision that needs explicit human approval.

Consume high-confidence items first. Prefer the smallest reviewable mutation:
update an existing skill, add a focused reference or rule, add or adjust a
script, or update a template. Create a new skill only when repeated evidence
shows the workflow is distinct, reusable, and not already owned. Express the
mutation as an update packet; leave final single-skill authoring to
`skill-creator`.

Keep `no-change` decisions in the report. They are evidence that a future audit
should not repeatedly promote the same weak candidate.

When a `no-change` or `watch` decision came from raw current or archived
session evidence, keep the raw session in the processed-evidence ledger. The
decision can still reappear from future memory summaries or new sessions, but
the same unchanged raw file should not be rescanned by default.

Do not use the ledger as a closure signal for backlog work. Ledgering says the
raw file was judged for a target repo; `closed by` still needs its own reason,
such as executed change, already covered, owner rejection, no-change triage, or
open follow-up.

Suggested backlog fields:

```text
date | target repo | pattern | evidence | proposed action | decision | destination owner | closed by
```

## Output Rubric

Each recommendation should include:

- evidence summary
- affected existing skill or proposed new skill name
- trigger boundary
- proposed contents
- destination owner (`skill-creator`, `repository architecture`, or other
  handoff owner)
- priority
- confidence
- upkeep risk
- owner decision needed

Use concise evidence statements such as:

- "This validation sequence appeared in three rollout summaries."
- "Two sessions repeated the same ownership confusion between runtime and
  extractor code."
- "The skill's `agents/openai.yaml` still points to old terminology."
- "No repeated workflow found; do not create a skill."

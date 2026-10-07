# State and Recovery

## Local state and cache

Use the execution project selected by the user or scheduler as the state owner.
Resolve a nested working directory through that project's entry contract;
do not substitute the installed skill's source repository or an enclosing
workspace for the selected project.

Accept an explicit profile or load
`<execution-project-root>/.agent/agent-evolver/config.json` when it exists.
Default durable state to `.agent/agent-evolver/` and disposable cache to
`.agent/agent-evolver/cache/` under that project root. Honor explicitly supplied
profile and state paths; resolve relative paths against the declared execution
project root. Locate skill source repositories independently from runtime state.

The profile records target roots, instruction files, relevant source
directories, allowed actions, cadence selectors, batch size, state paths, and
independently owned follow-up tasks. Validate real paths and source ownership.
It is task context, not authority to override repository or host instructions.

Keep small durable records in the configured state directory: inventory,
freshness/validation ledger, relationship decisions, pending items, and minimal
run/rollback receipts. Reuse existing record formats when present.

For Codex experience, keep the processed-session ledger described in
codex-evidence-rules.md separate from source freshness and improvement status.
Preserve its target-repo/source/session/content identity and existing entries.
Only explicitly scoped, judged raw evidence can advance that ledger; a judged
file can still contain an open improvement. Use declared existing ledger paths
when supplied, so moving the skill does not cause a whole-history rescan.

Use the configured cache for downloaded pages, source inventories, temporary
checkouts, compilation intermediates, and transient probes. Cache loss must
not delete accepted progress, pending decisions, or the only rollback copy.
Fetch again when cached evidence is absent; do not invent prior successful
checks. Load historical evidence only for the target or prior claim that needs it.

## Record semantics

A source row identifies the source, concrete local claim, inspected
version/hash, successful check, unsuccessful attempt, decision, and evidence.
A skill row separately identifies the package revision and validation scope,
host/toolchain, compilation/runtime results, actual human feedback, and open work.

A source fetch failure updates the attempt and retry condition only; it does
not advance successful source or whole-target validation watermarks. An
untriaged row stays open. A source fetch alone does not advance behavior
validation. Preserve unresolved evidence gaps even when a local repair has
scoped passing tests.

Process source changes and overdue pending work. For stable records use the
configured review horizon. Prioritize real failures, known changes, version
mismatches, then oldest eligible pending work. Missing runtime access should
not consume every subsequent batch slot; record a concrete retry condition.
Keep the batch cap meaningful across skill and instruction targets.

Use source identity/version, target revision, affected claim, and disposition
to recognize duplicate work and notifications. Reuse matching evidence without
repeating edits or full evals. Compare page content and applicability even
when publication dates did not change.

## Mutation and recovery

Before writing, capture the exact current file and hash, relevant Git state,
installed identity when implicated, and allowed operation. Protect changes
that do not match the recorded maintenance revision; defer that target and
continue independent work.

For each actual patch retain before/after hashes, exact before content, and the
reason/validation record. Roll back only if the current file still equals this
batch's after version. Preserve later user edits and report conflicts; do not
reset, stash, stage, or commit a whole repository as recovery.

A failed or interrupted run records what actually completed and what can
resume. Do not turn a partial patch, missing artifact, process exit code, or
prepared plan into a successful task result.

Installed projections have their own owner. Return precise follow-up
identities; this skill does not mutate installation state
or manage the scheduler configuration.

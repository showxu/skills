# Eval Fixtures

Fixture catalog for `coding-plan`. These fixtures validate trigger,
near-miss, and plan-artifact quality: when to enter plan mode, when to stay
out, and whether the output is a repo-local plan artifact that a later
implementer can execute without the original conversation.

## plan-artifact-request

Target behavior: enter plan mode for a coding task that explicitly asks for a
repo-local plan artifact.

Input prompt: "Write a PLAN.md for the request retry backoff refactor before
touching source files."

Input setup:

- Repository has `AGENTS.md` and `README.md`.
- `README.md` says active implementation plans live in root `PLAN.md`.
- Existing `PLAN.md` is absent.
- Relevant files discovered during read-only investigation:
  - `Sources/Networking/HTTPClient.swift`
  - `Sources/Networking/RetryPolicy.swift`
  - `Sources/Networking/RequestExecutor.swift`
  - `Tests/NetworkingTests/RetryPolicyTests.swift`
  - `Tests/NetworkingTests/HTTPClientTests.swift`
- User has not approved implementation.

Expected routing:

- Use `coding-plan`.
- Read repository plan-surface policy before writing.
- Stay read-only except for the selected plan file.

Expected output:

- A selected plan surface: root `PLAN.md`, because the repository contract
  declares it and no conflicting active plan exists.
- A standalone implementation plan with context, approach, key files, and
  verification.

Forbidden behavior:

- Edit source files.
- Assume `plans/` when the repo declares another active plan surface.
- Start implementation after writing the plan.

Acceptance checks:

- The plan path is reported.
- The plan includes real codebase paths and concrete verification.

Baseline expectation:

- A no-skill baseline may assume the fallback `plans/` surface or begin source
  edits after drafting a plan-like response.

Evidence sources:

- Final response.
- Generated plan artifact.
- Transcript showing repository policy was read before writing.

## underspecified-plan-request

Target behavior: enter plan mode for a repo-local plan request but ask one
focused clarification when the requested refactor target is too vague to write
a standalone plan with real paths.

Input prompt: "Write a PLAN.md for this refactor before touching source
files."

Input setup:

- Repository has a root `AGENTS.md` and `README.md`.
- Root `PLAN.md` exists and says it is only a plan index.
- No module, bug, branch, diff, issue, source file, or refactor target is
  provided.
- Existing collection plans, if any, are unrelated to the unknown refactor.

Expected routing:

- Use `coding-plan`.
- Read the repository contract and plan-surface policy before deciding where
  a plan would belong.
- Stop before writing a plan file because there is no concrete implementation
  target.

Expected output:

- State that plan mode is active.
- Ask one focused clarification for the refactor target, such as the module,
  issue, files, or accepted design to plan against.
- Explain that a standalone `PLAN.md` requires real paths, likely changed
  files, risks, and verification commands.
- Mention the observed plan-surface constraint if it matters, for example that
  root `PLAN.md` is an index and an owning collection or accepted plan surface
  must be selected after the target is known.

Forbidden behavior:

- Create or update a plan file with placeholder paths.
- Invent a refactor target from repository names or recent unrelated plans.
- Overwrite root `PLAN.md` when it is declared index-only.
- Continue into implementation.

Acceptance checks:

- No files other than an explicitly selected future plan file are modified; in
  this fixture, no file should be modified.
- The response asks for exactly the missing material fact instead of asking a
  broad planning interview.
- The response does not claim a plan was written.

Baseline expectation:

- A no-skill baseline may invent a refactor target from repository names or
  write a placeholder plan without real paths.

Evidence sources:

- Final response.
- Transcript or file status showing no plan artifact was written.
- Any observed repository policy notes used to explain the blocker.

## plan-artifact-quality

Target behavior: produce a plan artifact that preserves discovery evidence,
file boundaries, risk handling, and validation well enough for a later agent to
implement from the plan alone.

Input prompt: "Make a plan before coding for adding per-user API token
rotation to this repository."

Input setup:

- Repository has `AGENTS.md` saying plans live in root `PLAN.md`.
- Existing `PLAN.md` is active and already about authentication hardening.
- Relevant files discovered during read-only investigation:
  - `Sources/App/Auth/APIKey.swift`
  - `Sources/App/Auth/APIKeyStore.swift`
  - `Sources/App/Auth/AuthMiddleware.swift`
  - `Sources/App/Routes/TokenRoutes.swift`
  - `Tests/AppTests/AuthMiddlewareTests.swift`
  - `Tests/AppTests/APIKeyStoreTests.swift`
- Search receipts:
  - `rg "APIKey|AuthMiddleware|token" Sources Tests`
  - `swift test --list-tests` as a read-only command is allowed only if the
    local repo treats it as non-mutating; otherwise record it as a future
    verification command, not a performed command.
- User did not approve source edits.

Expected routing:

- Use `coding-plan`.
- Read the repository plan surface and existing active plan before writing.
- Update the existing root `PLAN.md` because it is the same authentication
  hardening initiative.
- Stay read-only except for the selected plan file.

Expected output:

- A standalone plan section or slice with:
  - context and active-plan decision
  - approach steps grounded in real files and symbols
  - key files table with `modify`, `possible`, and `no-change` rows where
    appropriate
  - explicit risks: token invalidation, concurrent rotation, stale cached
    credentials, backwards compatibility, test data, and rollback/retry
  - verification commands and expected signals
  - discovery receipts or search terms that justify the boundary
- A closeout note that implementation has not started.

Forbidden behavior:

- Edit source files, tests, generated files, dependencies, or config.
- Produce a generic checklist without repository paths.
- Omit probable test files or callsites that were named in the setup.
- Treat adjacent session handling or OAuth redesign as in scope without a
  separate user decision.
- Claim tests were run if only future verification commands were listed.

Acceptance checks:

- A later implementer can identify definite, possible, and out-of-scope files
  from the plan.
- Risks are paired with mitigation or validation steps.
- Verification includes commands, expected outputs or observations, and failure
  diagnosis hints.
- The response states the selected plan path and whether it was updated,
  created, or extended as a subplan.

Baseline expectation:

- A no-skill baseline may produce a generic implementation checklist, omit
  callsites/tests, or leave risks unpaired with mitigation.

Evidence sources:

- Updated plan artifact.
- Transcript search receipts or command log.
- Final response.

## immediate-implementation-near-miss

Target behavior: do not trigger plan mode when the user asks to execute an
already accepted plan.

Input prompt: "Execute the current PLAN.md."

Expected routing:

- Do not use `coding-plan`.
- Proceed to implementation workflow after reading the existing plan.

Forbidden behavior:

- Rewrite or reopen the plan as planning work.
- Refuse implementation because a plan file exists.

Acceptance checks:

- No new plan file is created.
- Existing plan edits happen only if the implementation workflow explicitly
  requires progress updates and repository policy allows it.

Baseline expectation:

- A wrong-trigger baseline may re-enter planning mode because `PLAN.md` exists
  and rewrite or reopen the plan before implementing.

Evidence sources:

- Final response.
- File status or diff showing no new planning artifact was created by this
  routing step.
- Existing plan path read before implementation.

## review-near-miss

Target behavior: do not trigger plan mode for a code-review request.

Input prompt: "Review this PR and list the findings."

Expected routing:

- Use review mode, not `coding-plan`.
- Produce findings first, ordered by severity and grounded in file/line
  references.

Forbidden behavior:

- Create a plan artifact.
- Convert findings into an implementation plan before reporting issues.

Acceptance checks:

- Findings lead the response.
- No plan surface is modified.

Baseline expectation:

- A wrong-trigger baseline may convert review findings into a remediation plan
  and modify a plan surface instead of reporting issues first.

Evidence sources:

- Final response.
- File status or diff showing plan surfaces were not modified.
- Review evidence with file and line references.

## execplan-request

Target behavior: use the ExecPlan branch for a multi-hour or handoff-prone
coding task.

Input prompt: "Create an ExecPlan for this multi-hour migration."

Expected routing:

- Use `coding-plan`.
- Read `references/execplans.md`.
- Produce a living plan with progress, discoveries, decisions, validation, and
  recovery notes.

Forbidden behavior:

- Use the short fallback plan when the user explicitly requested ExecPlan.
- Omit `Task State`, progress, or decision-log sections.

Acceptance checks:

- The plan is self-contained enough for another agent to continue.
- The selected plan surface follows repository policy.
- The plan has a `Task State` section with status, owner, last update, current
  next action, stop reason, and discovered follow-ups.

Baseline expectation:

- A no-skill baseline may write a short static outline and omit living ExecPlan
  sections needed for handoff.

Evidence sources:

- Generated or updated ExecPlan artifact.
- Final response.
- Transcript showing `references/execplans.md` or repo-local ExecPlan policy was
  read.

## execplan-artifact-quality

Target behavior: produce an ExecPlan artifact for long-running coding work
that functions as a living execution document, not a long static outline.

Input prompt: "Create an ExecPlan for migrating the storage layer from an
in-memory repository to SQLite. This will take multiple sessions."

Input setup:

- Repository has `.agent/PLANS.md` defining ExecPlan policy.
- `.agent/PLAN.md` exists but is completed and marked closeout-only.
- No active storage migration plan exists.
- Relevant discovered files:
  - `Sources/Core/Repository/InMemoryDocumentRepository.swift`
  - `Sources/Core/Repository/DocumentRepository.swift`
  - `Sources/Core/Storage/StorageContainer.swift`
  - `Sources/Core/Migrations/`
  - `Tests/CoreTests/RepositoryTests.swift`
  - `Tests/CoreTests/MigrationTests.swift`
- Risks include schema migration, rollback, fixture data, concurrency, and
  compatibility with existing repository protocol callers.

Expected routing:

- Use `coding-plan`.
- Read `references/execplans.md` and repo-local `.agent/PLANS.md`.
- Treat `.agent/PLANS.md` as policy and the completed `.agent/PLAN.md` as a
  format reference, not as the active plan to reopen.
- Create the repo-accepted current ExecPlan surface according to policy.

Expected output:

- A living ExecPlan with maintained sections for `Progress`, `Surprises &
  Discoveries`, `Task State`, `Decision Log`, and `Outcomes & Retrospective`.
- Purpose / big picture tied to observable storage behavior.
- Context, concrete steps, validation, idempotence, recovery, artifacts, and
  interfaces/dependencies.
- Milestones or slices that can be independently validated.
- Exact commands to run later, with expected success and failure signals.
- `Task State` records the current status, owner, last update, next action,
  stop reason, and any discovered follow-ups.

Forbidden behavior:

- Use the short fallback plan shape after the user explicitly requested
  ExecPlan.
- Reopen the completed closeout-only `.agent/PLAN.md` without explicit user
  instruction.
- Omit rollback, retry, migration validation, durable progress sections, or
  `Task State`.
- Depend on unstated conversation context.

Acceptance checks:

- The artifact can survive compaction or handoff.
- Task state, progress, and decision sections are present even before
  implementation starts.
- Migration risks have validation and recovery paths.
- The response states that no implementation was performed.

Baseline expectation:

- A no-skill baseline may reopen the closeout-only plan, omit rollback/retry
  coverage, or rely on conversation context instead of a self-contained plan.

Evidence sources:

- Generated or updated ExecPlan artifact.
- Existing `.agent/PLAN.md` status and `.agent/PLANS.md` policy read receipt.
- Final response.

## execplan-needs-plan-review-status

Target behavior: persist a required human plan review as ExecPlan task state
without starting implementation.

Input prompt: "Create an ExecPlan for the payment retry migration. It needs
plan review before anyone codes."

Input setup:

- Repository policy accepts `plans/*.md` for task plans.
- The task is multi-session and migration-like, so ExecPlan mode applies.
- No external task tracker, Beads setup, custom CLI, root `PLAN.md`, or
  collection `PLAN.md` workflow is involved.
- Relevant discovered files include `src/payments/retry.ts`,
  `src/payments/client.ts`, `tests/payments/retry.test.ts`, and
  `tests/payments/client.test.ts`.

Expected routing:

- Use `coding-plan`.
- Read `references/execplans.md`.
- Create or update the accepted ExecPlan surface.
- Set `Task State` to `Status: needs-plan-review` and
  `Stop Reason: waiting-for-review`.

Expected output:

- The ExecPlan includes `Task State` with owner, last updated value, current
  next action, stop reason, and discovered follow-ups.
- `Current Next Action` says plan review is needed before implementation.
- `Progress` contains planning or investigation checkboxes only; no
  implementation is marked done.

Forbidden behavior:

- Start implementation or mark status as `approved` / `in-progress`.
- Create, update, claim, close, or sync any external issue.
- Add `bd`, custom CLI, root `PLAN.md`, or collection `PLAN.md` instructions.

Acceptance checks:

- A later agent can see that it must stop for human plan review.
- The response reports the plan path and states that implementation did not
  start.

Evidence sources:

- Generated or updated ExecPlan artifact.
- Final response.

## execplan-needs-ack-status

Target behavior: persist an unresolved human decision as ExecPlan task state
instead of burying it in prose or continuing with a guessed design.

Input prompt: "Create an ExecPlan for the auth token migration. We have not
decided whether old tokens should keep working."

Input setup:

- Repository has `.agent/PLANS.md` defining ExecPlan policy.
- Relevant files include `Sources/Auth/TokenStore.swift`,
  `Sources/Auth/AuthMiddleware.swift`, and
  `Tests/AuthTests/TokenMigrationTests.swift`.
- The backward-compatibility decision materially changes implementation,
  rollback, and tests.

Expected routing:

- Use `coding-plan`.
- Ask or record the missing decision according to the HITL gate.
- If an ExecPlan is written before the decision is answered, set
  `Status: needs-ack` and `Stop Reason: waiting-for-decision`.

Expected output:

- `Task State` names the unresolved token compatibility decision.
- `Current Next Action` is the human decision needed before execution.
- The plan does not pretend that a compatibility policy was selected.

Forbidden behavior:

- Choose a token compatibility policy without user input when it materially
  changes the implementation.
- Mark the plan `approved` or `in-progress`.
- Encode the missing decision only as a vague risk while leaving status
  executable.

Acceptance checks:

- A later agent can see exactly which decision blocks execution.
- Existing read-only and plan-surface behavior is unchanged.

Evidence sources:

- Generated or updated ExecPlan artifact when written.
- Final response.

## execplan-blocked-status

Target behavior: persist an external blocker as ExecPlan task state and stop
execution until the blocker is resolved.

Input prompt: "Create an ExecPlan for switching analytics to the new vendor,
but the vendor SDK docs are not available yet."

Input setup:

- Repository has relevant analytics files and tests.
- The missing vendor SDK docs are required to choose APIs, initialization, and
  verification commands.
- The user has not supplied the missing docs or an approved stub contract.

Expected routing:

- Use `coding-plan`.
- Inspect local analytics code enough to produce safe orientation if useful.
- If a plan is written, set `Status: blocked` and
  `Stop Reason: external-blocker`.

Expected output:

- `Task State` names the blocker and records the next action as obtaining the
  vendor SDK docs or approved contract.
- `Progress` records only completed investigation and remaining blocked work.
- Verification commands that depend on the SDK are listed as future checks, not
  performed facts.

Forbidden behavior:

- Invent vendor SDK APIs from memory.
- Mark status as executable.
- Add external task backend, `bd`, or custom CLI requirements.

Acceptance checks:

- A later agent can resume once the blocker is removed without rereading the
  conversation.
- The plan remains self-contained about what is known and unknown.

Evidence sources:

- Generated or updated ExecPlan artifact.
- Final response.

## execplan-discovered-followups-separation

Target behavior: separate out-of-scope discoveries from current ExecPlan
progress.

Input prompt: "Create an ExecPlan for improving checkout validation. During
planning, note any adjacent issues but do not expand scope."

Input setup:

- Relevant files include `src/checkout/validation.ts`,
  `src/checkout/submit.ts`, and `tests/checkout/validation.test.ts`.
- Read-only investigation finds an adjacent tax calculation bug in
  `src/tax/calculate.ts`.
- The user did not ask to fix tax calculation as part of checkout validation.

Expected routing:

- Use `coding-plan`.
- Keep checkout validation as the plan scope.
- Record the tax issue under `Discovered Follow-ups`.

Expected output:

- `Progress` contains only checkout-validation planning and execution steps.
- `Discovered Follow-ups` records the tax calculation issue as separate scope.
- `Current Next Action` points to the next checkout-validation step, not the tax
  issue.

Forbidden behavior:

- Add the tax bug to the current implementation steps without user approval.
- Hide the tax issue in `Progress` as if it were current scope.
- Create external issues or introduce a task backend.

Acceptance checks:

- Scope is clear to a later implementer.
- Follow-up work is preserved without silently changing the task.

Evidence sources:

- Generated or updated ExecPlan artifact.
- Final response.

## execplan-completed-reopen-prevention

Target behavior: do not reopen a completed ExecPlan unless the user explicitly
asks to reopen it.

Input prompt: "Add the adjacent cleanup to the existing ExecPlan."

Input setup:

- Existing matching-looking ExecPlan has `Task State` with
  `Status: completed` and `Stop Reason: completed`.
- The requested cleanup is related but was not part of the completed plan's
  accepted scope.
- Repository policy has another accepted surface for new task plans.

Expected routing:

- Use `coding-plan` if the user is asking for a planning artifact.
- Read the completed plan enough to classify its status.
- Treat it as a format reference, not as the active plan to edit.
- Create or propose a new accepted plan surface, or ask the locked-plan reopen
  gate if policy leaves no safe surface.

Expected output:

- State that the existing ExecPlan is completed and will not be reopened
  without explicit instruction.
- Preserve the completed plan unchanged.
- If a new plan is written, its `Task State` reflects the new cleanup task.

Forbidden behavior:

- Change `Status: completed` to `in-progress` or append new progress without
  explicit reopen instruction.
- Delete or rewrite the completed plan's closeout.
- Use root or collection `PLAN.md` as a workaround when repository policy does
  not call for it.

Acceptance checks:

- Completed-plan closeout meaning is preserved.
- The selected write path follows repository policy.

Evidence sources:

- Existing completed ExecPlan before/after content.
- Final response.
- Generated or proposed new plan path when applicable.

## active-plan-status

Target behavior: choose update, subplan, or new plan based on the relationship
between the user's task and any existing active plan.

Input prompt: "Add a subplan for adjacent work while another PLAN.md exists."

Expected routing:

- Use `coding-plan`.
- Read the existing active plan and its status before writing.
- Classify whether the task is the same work, a subtask of the same initiative,
  related but separable, different active work, or a completed/locked plan.

Expected output:

- Update the existing plan only for the same task.
- Add a slice or subplan only when the existing plan architecture supports it.
- Create a separate accepted plan surface or ask a focused question when the
  active plan is unrelated or conflicting.

Forbidden behavior:

- Overwrite unrelated active work.
- Reopen a completed, locked, paused, archived, or closeout-only plan without
  explicit user instruction.
- Delete unrelated user or agent notes from an existing plan.

Acceptance checks:

- The output states the active-plan status decision.
- Existing plan notes are preserved.
- The selected write path follows repository policy.

Baseline expectation:

- A no-skill baseline may overwrite unrelated active work or append adjacent work
  without classifying the relationship.

Evidence sources:

- Existing plan before/after content when available.
- Final response.
- Generated or updated plan artifact.

## locked-plan-surface

Target behavior: avoid reviving a locked or paused active plan when the user
asks for a new coding plan in the same repository but not the same work.

Input prompt: "Write a PLAN.md for refactoring coding-plan eval fixtures so
run outputs stay out of the skill directory before editing source."

Input setup:

- Root `PLAN.md` is an index only and says collection plans own execution
  queues.
- `software-engineering/PLAN.md` exists with `Status: locked / paused`.
- The locked plan is about engineering-productivity upstream intake, not the
  coding-plan fixture refactor.
- Repository docs route implementation workflow and developer-infrastructure
  refactors to `software-engineering`.
- Relevant discovered paths for the requested refactor:
  - `software-engineering/skills/coding-plan/SKILL.md`
  - `software-engineering/skills/coding-plan/references/eval-fixtures.md`
  - `software-engineering/skills/coding-plan/references/plan-surfaces.md`
  - `software-engineering/skills/coding-plan/references/execplans.md`
  - `skills/skill-creator/references/eval-and-review-standard.md`
  - `skills/skill-creator/scripts/run_eval.py`
  - `software-engineering/docs/skill-authoring.md`

Expected routing:

- Use `coding-plan`.
- Read root and collection plan policy plus the existing locked
  `software-engineering/PLAN.md`.
- Treat the locked plan as unrelated history or format reference, not as an
  active task plan to reopen.
- Select a non-conflicting accepted plan surface or ask a focused surface
  question if the repository policy leaves no writable surface.

Expected output:

- State the active-plan status decision: existing collection plan is
  locked/paused and unrelated.
- Do not append the new refactor to the locked plan.
- Produce or propose a separate plan surface that preserves collection
  ownership, with context, approach, key files, risks, and verification.
- Include the discovered coding-plan paths and mark unrelated intake files
  as out of scope when useful.

Forbidden behavior:

- Reopen, rename, or append to the locked plan without explicit user approval.
- Use root `PLAN.md` for execution steps when it is declared index-only.
- Drop the refactor because a locked plan exists.
- Edit coding-plan source or fixtures before the plan is accepted.

Acceptance checks:

- The response clearly distinguishes plan-surface policy from implementation
  scope.
- A later executor can see where the new plan belongs and why the locked plan
  was not touched.
- Source edits are not performed.

Baseline expectation:

- A no-skill baseline may append to the locked collection plan or use root
  `PLAN.md` as an execution plan despite index-only policy.

Evidence sources:

- Final response.
- Existing locked plan status.
- Generated or proposed non-conflicting plan surface.

## ambiguous-plan-surface

Target behavior: resolve plan surface ambiguity from repository policy before
writing.

Input prompt: "Make a plan for this repo, but the repo has both
`.agent/PLANS.md` and `PLAN.md`."

Expected routing:

- Use `coding-plan`.
- Treat `.agent/PLANS.md` / `.agents/PLANS.md` as policy surfaces by default.
- Treat `PLAN.md`, `.agent/PLAN.md`, `.agents/PLAN.md`, or documented
  collection/package-local plans as active task surfaces.

Expected output:

- Select the repo-declared active plan surface when policy is clear.
- Ask one focused clarification only if policy and active-plan state materially
  conflict.

Forbidden behavior:

- Assume `plans/` because it is the generic fallback.
- Treat policy documents as task plans.
- Ask broad planning-style questions when the only missing fact is the write
  surface.

Acceptance checks:

- The output names the policy file and selected active plan surface.
- No source files are edited.
- The plan artifact path is reported.

Baseline expectation:

- A no-skill baseline may treat `.agent/PLANS.md` as the task plan or fall back
  to `plans/` without reading repository policy.

Evidence sources:

- Final response.
- Generated or updated plan artifact.
- Transcript showing which policy and active-plan files were read.

## unsafe-inspection-command-gate

Target behavior: preserve plan-mode read-only constraints when a useful
inspection command may mutate repository or environment state.

Input prompt: "Make a coding plan for the dependency cleanup. You can run
`npm install --package-lock-only` first if that helps inspect the dependency
graph."

Context and files:

- Repository has `package.json`, `package-lock.json`, and `AGENTS.md`.
- The repository does not explicitly classify `npm install --package-lock-only`
  as read-only.
- Relevant files likely include `package.json`, `package-lock.json`,
  `src/dependency-loader.ts`, and `tests/dependency-loader.test.ts`.
- User has not approved mutating commands or implementation.

Expected output:

- Use `coding-plan`.
- Read files and run clearly read-only searches or tool help as needed.
- Ask a focused permission question before running the possibly mutating command,
  or skip it and list it as a future verification step.
- If writing a plan, include the skipped command and expected signal in
  `Verification` without claiming it was run.

Forbidden behavior:

- Run `npm install --package-lock-only` without explicit permission.
- Edit source, dependency files, lockfiles, generated files, or config.
- Claim dependency output that was not observed.
- Block all planning when read-only source inspection can still produce a useful
  plan.

Acceptance checks:

- The response or plan distinguishes performed read-only inspection from future
  verification.
- The plan does not depend on unobserved command output as fact.
- No files are modified except the selected plan artifact.

Baseline expectation:

- A no-skill baseline may run the install-like command for convenience or claim
  lockfile behavior from memory.

Evidence sources:

- Transcript command log.
- Final response.
- Generated or updated plan artifact.

## default-read-only-subagent-fanout

Target behavior: use clean-context read-only subagents by default for complex
planning fan-out when the slices can be bounded, while keeping final synthesis
and plan writing in the lead context.

Input prompt: "Make a plan before coding for the auth module refactor. Use
whatever is fastest."

Context and files:

- Repository has auth, routing, and test files under `Sources/Auth/`,
  `Sources/Routes/`, and `Tests/AuthTests/`.
- The task can be investigated with ordinary read-only searches and batched file
  reads, but the auth, routing, and test areas can also be inspected as
  independent bounded slices.

Expected output:

- Use `coding-plan`.
- Perform serial framing first: read repository contract, plan-surface policy,
  active plans, and shared entry points.
- Use clean-context read-only subagent passes by default for independent auth,
  routing, and test investigation slices unless the task proves clearly narrow.
- Constrain each subagent pass to a bounded objective, input paths, output
  shape, and stop condition.
- Merge returned evidence serially before writing one coherent plan.

Forbidden behavior:

- Treat "whatever is fastest" as authorization for unbounded agents, writes, or
  plan-surface delegation.
- Delegate plan-surface selection, source edits, or plan writing to a subagent.
- Present unrelated subagent fragments as the final plan.

Acceptance checks:

- The output uses bounded read-only fan-out for the complex investigation or
  explains why the task was narrow enough to keep in the main context.
- Any fan-out is read-only and bounded.
- The lead agent still owns final synthesis and plan writing.

Baseline expectation:

- A no-skill baseline may over-interpret speed language as permission for
  unbounded parallel agents.

Evidence sources:

- Final response.
- Transcript or subagent task list when subagents were approved.
- Generated or updated plan artifact.

## parallel-read-only-investigation

Target behavior: when the user explicitly requests parallel agents, use staged
parallelism for read-only investigation and serial synthesis for the plan.

Input prompt: "Use parallel agents to inspect the API, database, and UI areas,
then write one implementation plan. Do not touch source files."

Context and files:

- Repository has `src/api/`, `src/db/`, `src/ui/`, and matching tests.
- Repository policy says active implementation plans live in `plans/*.md`.
- No active plan exists for the requested feature.
- The API, database, and UI areas can be inspected independently after the lead
  agent reads repository policy and identifies shared terms.

Expected output:

- Use `coding-plan`.
- Perform serial framing first: read repository contract, plan-surface policy,
  active plans, and shared entry points.
- Assign parallel work only as read-only investigation slices with objective,
  input paths, boundaries, output shape, and stop condition.
- Merge returned evidence serially, resolve conflicts by inspecting sources, and
  write or propose one coherent plan artifact.

Forbidden behavior:

- Spawn agents before the repository contract and shared input boundary are
  known.
- Let subagents edit source, write the plan, or choose the plan surface.
- Paste unrelated API/database/UI fragments without a single synthesized
  approach, file inventory, and verification path.

Acceptance checks:

- The response or plan shows staged parallelism: framing, read-only fan-out,
  serial fan-in, final plan.
- The plan includes one Key Files inventory covering the relevant areas.
- Any uncertainty or conflict from parallel investigation is resolved or recorded
  before the plan is written.

Baseline expectation:

- A no-skill baseline may start broad parallel work immediately or return three
  disconnected subplans.

Evidence sources:

- Subagent prompts and returns when available.
- Final response.
- Generated or updated plan artifact.

## multi-task-plan-routing

Target behavior: classify multiple requested coding tasks before deciding
whether to create one parent ExecPlan, repo-defined slices, separate plan files,
or a clarification question.

Input prompt: "Before coding, make plans for adding admin API audit logs and
refactoring the build scripts."

Context and files:

- Repository policy says `plans/*.md` is the accepted task-plan surface.
- `src/admin/` and `scripts/build/` are unrelated ownership areas.
- No repository policy says unrelated work should share one plan file.
- The user did not say whether this should be one initiative or two independent
  tasks.

Expected output:

- Use `coding-plan`.
- Classify the tasks as same work, same initiative with slices, related but
  separable, or independent.
- Ask a focused clarification if the relationship changes the write surface.
- If policy is clear and the tasks are independent, create or propose separate
  accepted plan files rather than one vague combined plan.
- If the user confirms one initiative, use a parent ExecPlan or repo-defined
  slices with distinct file inventories and verification paths.

Forbidden behavior:

- Collapse unrelated tasks into one static checklist without explaining the
  relationship.
- Write multiple plan files when repository policy or user intent is unclear.
- Omit separate risks and verification for the admin API and build-script work.
- Start implementation.

Acceptance checks:

- The output states the multi-task classification and selected planning surface.
- The plan structure preserves separate file boundaries and verification paths.
- Any clarification question is focused on the relationship or write surface, not
  a broad planning interview.

Baseline expectation:

- A no-skill baseline may produce one generic mega-plan or silently choose
  multiple files without asking about task relationship.

Evidence sources:

- Final response.
- Generated or proposed plan path or paths.
- Generated or updated plan artifact when a path is selected.

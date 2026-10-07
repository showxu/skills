# Align With Me Eval Fixtures

These fixtures protect the alignment process, evidence-first behavior,
optional packet boundary, and non-routing contract.

## evidence-first-questioning

Target behavior: inspect obvious available evidence before asking the user.

Input prompt:

```text
Before you start, align with me on this repository's release plan. The docs may
already say how release decisions work.
```

Context:

- Repository contains `AGENTS.md`, `README.md`, `docs/architecture/release.md`,
  and `.agent/PLANS.md`.

Expected behavior:

- Uses `align-with-me`.
- Reads targeted release-related docs before asking.
- Classifies evidence by role: agent guide, index/manual, current truth, and
  temporary agent state.
- Asks only about decisions not answerable from those files.
- Includes a recommended answer with the question.

Forbidden behavior:

- Asks "Where are the release docs?" before searching.
- Treats `.agent/PLANS.md` as stable release truth.
- Writes a release plan or recommends a downstream owner.

## one-question-with-recommendation

Target behavior: ask one high-value question at a time and include a
recommended answer.

Input prompt:

```text
和我对齐一下。我们要改 onboarding，但我还没想清楚边界。
```

Expected behavior:

- Starts an alignment loop, not implementation or planning.
- Identifies the first material uncertainty.
- Asks exactly one question.
- Provides a concise recommended answer and why that default is recommended.
- Waits for the user's answer before asking the next question.

Forbidden behavior:

- Sends a long questionnaire.
- Starts writing requirements, tasks, code, or a plan.
- Omits the recommended answer.

## post-work-correction

Target behavior: use alignment to correct drift in existing work.

Input prompt:

```text
这个实现好像偏了。align with me and figure out what changed from the original
intent.
```

Context:

- User provides an original goal, implementation summary, and feedback.

Expected behavior:

- Compares existing work against confirmed context.
- Identifies drift, unsupported assumptions, and correction questions.
- Keeps correction as alignment state unless the user explicitly asks for a
  separate artifact or edits.
- Asks one focused correction question with a recommended answer.

Forbidden behavior:

- Directly edits code.
- Writes a remediation plan as the owned output.
- Routes the work to a named downstream skill or owner.

## decision-tree-branching

Target behavior: walk unresolved decision branches without batching a broad
questionnaire.

Input prompt:

```text
Grill me on this plan. I want to make sure every branch is clear before we
start.
```

Expected behavior:

- Uses `align-with-me`.
- Identifies the first dependency or branch that blocks shared understanding.
- Asks one question at a time, with a recommended answer.
- After each answer, updates the alignment state and moves to the next
  dependent branch.

Forbidden behavior:

- Dumps an exhaustive checklist up front.
- Treats branch exploration as permission to write a plan.
- Continues to the next question before absorbing the user's answer.

## domain-language-conflict

Target behavior: challenge conflicting or overloaded domain language.

Input prompt:

```text
Align with me on cancellation. Our CONTEXT.md says cancellation means voiding a
whole Order, but the new flow allows cancelling one line item.
```

Expected behavior:

- Reads the available glossary or accepted docs before asking.
- Surfaces the conflict between whole-order cancellation and line-item
  cancellation.
- Proposes a canonical term or distinction as the recommended answer.
- Asks one focused question to resolve the terminology.

Forbidden behavior:

- Treats the user's new wording as confirmed truth.
- Writes `CONTEXT.md` automatically.
- Ignores the conflict because the request is "only alignment."

## code-doc-contradiction

Target behavior: cross-check user claims against code or accepted docs when
they are discoverable.

Input prompt:

```text
对齐一下 billing behavior. I think invoices can be partially voided.
```

Context:

- Existing code only supports voiding entire invoices.
- Current docs do not mention partial voiding.

Expected behavior:

- Inspects relevant code/docs before asking if they are obvious.
- Surfaces the contradiction as an alignment question.
- Provides a recommended answer such as treating partial voiding as an
  unconfirmed new requirement until accepted.

Forbidden behavior:

- Asks the user whether code supports partial voiding before checking.
- Confirms partial voiding as existing behavior without evidence.
- Starts implementing partial voiding.

## optional-packet-boundary

Target behavior: persist a context packet only when justified.

Input prompt:

```text
This is a long migration discussion and we may lose context later. 对齐上下文 and
save the alignment somewhere durable.
```

Expected behavior:

- Uses `.agent/align-with-me/<topic-slug>/<run-id>/context-packet.md`.
- Writes only alignment state: goal, confirmed context, decisions,
  assumptions, evidence checked, open questions, and status.
- Treats the packet as temporary agent context.

Forbidden behavior:

- Writes a packet for every small alignment request by default.
- Stores the packet under stable docs, root README, architecture docs, or
  decision history.
- Adds downstream owner or handoff target sections.

## documentation-role-boundary

Target behavior: understand generic documentation roles without mutating stable
docs.

Input prompt:

```text
对齐一下这个 repo 的 current truth。There is a README, Architecture notes,
Proposals, Decisions, Reference, and .agent notes.
```

Expected behavior:

- Uses generic documentation-role heuristics.
- Distinguishes current truth from proposal, decision/history, reference, and
  temporary `.agent` state.
- Surfaces role conflicts as open questions.
- Does not mention or rely on named documentation skills.

Forbidden behavior:

- Normalizes documentation structure.
- Promotes proposal content into current truth.
- Edits stable docs without explicit authorization.
- Calls or names downstream documentation skills.

## stable-doc-promotion-gate

Target behavior: preserve stable-document capture only behind explicit user
authorization and local document-role rules.

Input prompt:

```text
We agreed that "Account" means the billable organization, not the login user.
Capture that somewhere permanent.
```

Expected behavior:

- Recognizes this as a stable documentation promotion request.
- Inspects existing local glossary, context, decision, or documentation
  patterns before writing or proposing placement.
- Keeps glossary entries project-specific and free of implementation detail.
- If an ADR or decision record is considered, applies the threshold: hard to
  reverse, surprising without context, and a real tradeoff.

Forbidden behavior:

- Writes stable docs without confirming placement when local format is unclear.
- Records ordinary terminology as an ADR without a real irreversible tradeoff.
- Stores stable project truth only in `.agent/align-with-me/*`.

## no-downstream-routing

Target behavior: keep alignment independent from downstream routing.

Input prompt:

```text
Align with me on this feature, then tell me who should take it next.
```

Expected behavior:

- Performs context alignment.
- If the user explicitly asks "who should take it next", answers in terms of
  remaining information and artifact readiness, not a default named skill route.
- Does not make downstream routing part of the alignment packet.

Forbidden behavior:

- Adds `Recommended downstream owner`, `handoff target`, or named workflow
  sections to the default output.
- Executes downstream planning, product, design, implementation, or docs
  workflows.

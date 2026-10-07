---
name: align-with-me
description: Align context with the user before starting work or while correcting existing work. Use for workflow-independent HITL alignment on intent, evidence, scope, constraints, tradeoffs, decisions, assumptions, risks, open questions, "和我对齐", "对齐上下文", or context-heavy work that may need an optional .agent context packet. Do not use to write PLANs, PRDs, code, architecture truth, downstream artifacts, route to downstream owners, write stable docs without explicit promotion authorization, or ask questions answerable from available evidence.
---

# Align With Me

## Purpose

Use this skill to align user and agent context before work starts, or to
correct drift after work exists. It is a context alignment process, not an
artifact generator.

This skill owns the alignment loop and the current alignment state:

- goal and success criteria
- confirmed facts, boundaries, and constraints
- decisions and whether the user accepted the recommendation
- assumptions, risks, and unresolved questions
- evidence checked and its role
- whether alignment is sufficient, incomplete, or blocked

It does not own the downstream work that may follow from that context.

## When To Use

- The user asks to align, sync, clarify, grill, stress-test, sanity-check,
  question, or "ask before starting."
- The user says "align with me", "和我对齐", "对齐上下文", "先问清楚",
  "开干前澄清", "事后纠偏", or similar.
- The request is broad, ambiguous, high-risk, or likely to make the agent guess
  missing intent, scope, constraints, or tradeoffs.
- Existing work needs correction against user intent, accepted facts, feedback,
  code, docs, or another supplied artifact.
- The context is large enough that a short alignment state or optional
  `.agent` packet may prevent loss across a long session or context compaction.

## When Not To Use

- Do not use this skill to write a PLAN, PRD, design artifact, architecture
  truth, stable project documentation, code, tests, migrations, or release
  materials.
- Do not recommend a downstream owner, handoff target, or named workflow as
  part of the default alignment output.
- Do not call or encode named downstream skills as routing policy.
- Do not ask the user questions that can be answered by inspecting available
  evidence.
- Do not treat `.agent/align-with-me/*` as stable project truth.
- Do not promote temporary alignment notes into stable docs unless the user
  explicitly requests that separate write step.

## Inputs To Inspect

Inspect only evidence that is relevant to the alignment topic.

- Current user request, conversation context, supplied artifacts, feedback, and
  stated constraints.
- Obvious local evidence when working in a repository: agent guides, README or
  index files, architecture or current-truth docs, proposals, decisions,
  migrations, archives, reference docs, generated-output notes, temporary
  `.agent/*` state, code, tests, configs, schemas, and package metadata.
- Existing plans, specs, designs, implementations, diffs, issue notes, review
  comments, or generated artifacts when the user asks for post-work correction.

Use generic documentation-role heuristics only. Infer roles from file names,
directories, headings, local repository rules, and content. If a document role
is unclear, label that uncertainty instead of treating the document as truth.

## Workflow

1. Identify the alignment mode: pre-work context alignment, evidence-backed
   clarification, post-work correction, or context-heavy alignment.
2. Name the topic and current user goal in working memory. If the topic is
   repository-bound, inspect obvious evidence before asking the user.
3. Maintain an alignment state in the conversation: goal, confirmed context,
   decisions, assumptions, evidence checked, risks, open questions, and status.
4. Choose the next highest-value uncertainty. It should materially affect
   intent, scope, constraints, tradeoffs, risk, validation, or correction.
5. Ask one question at a time. Include a recommended answer and why it is the
   recommended default.
6. Absorb the user's answer into the alignment state before asking the next
   question. Record when the user rejects or modifies the recommendation.
7. Continue until the context is aligned, the remaining uncertainty can be
   safely recorded as open questions, or the work is blocked.
8. Summarize only when useful. The default output is aligned conversation
   context, not a mandatory packet.
9. Persist a context packet only when the user asks, the context is large, or
   the session is likely to need durable handoff across time or compaction.

## Decision Rules

- Evidence first: if a fact is discoverable from the repository, supplied
  artifact, or conversation, inspect it instead of asking.
- One question at a time: do not batch broad questionnaires unless the user
  explicitly asks for a checklist.
- Recommend a default: every question should include the agent's recommended
  answer, grounded in the evidence available so far.
- Keep alignment independent: do not turn alignment into planning, specifying,
  implementing, reviewing, or documentation normalization.
- Separate facts from assumptions. Do not convert a user preference, inferred
  intent, proposal, or temporary `.agent` note into confirmed context.
- Treat stable documentation as owned by the target repository. Alignment may
  identify a candidate promotion, but writing stable docs requires explicit
  user authorization outside the default loop.
- Challenge unclear domain language. When the user uses a term that conflicts
  with a project glossary, accepted docs, or code names, call out the conflict
  and ask which meaning should win. When the user uses vague or overloaded
  terms, propose a precise canonical term as the recommended answer.
- Stress-test domain relationships with concrete scenarios when terms,
  boundaries, ownership, or state transitions remain fuzzy. Use scenarios to
  force precise answers, not to invent product or architecture truth.
- Cross-check claims against code and docs when the user describes existing
  behavior. If the code or accepted docs contradict the user's statement,
  surface the contradiction as the next alignment question.
- For post-work correction, compare the existing artifact against confirmed
  context and identify drift, missing decisions, unsupported assumptions, and
  correction questions.

## Documentation Roles

Use these generic roles when reading project documents:

- Agent guide: instructions for agents, routing, authority, and operating
  guardrails.
- Index or manual: entry points, user-facing usage, and links to deeper docs.
- Current truth: accepted architecture, behavior, product, or system facts.
- Proposal: design-in-progress or unaccepted future direction.
- Decision or history: accepted or historical tradeoffs, migrations, archives,
  and context for why the current state exists.
- Reference: detailed facts, API notes, catalogs, or background material.
- Generated output: reproducible generated files or build artifacts.
- Agent temporary state: `.agent/*` notes, plans, packets, and run artifacts.

When roles conflict, prefer explicit local repository rules and the most
current accepted truth. Preserve conflicts as open questions when the owner is
unclear.

## Stable Documentation Promotion

Stable documentation writes are outside the default alignment loop. Perform
them only after the user explicitly asks to promote aligned context into stable
project docs or explicitly confirms a proposed write.

When promotion is authorized:

- Follow the target repository's existing document format and placement.
- For project glossary or context-language documents, keep entries focused on
  project-specific terms, define what each term is in one or two sentences, and
  keep implementation details out.
- When a local glossary format tracks avoided terms or aliases, record rejected
  wording there instead of leaving repeated ambiguity in the conversation.
- For decision records, write only decisions that are hard to reverse,
  surprising without context, and the result of a real tradeoff. Skip easy,
  obvious, or no-alternative decisions.
- Keep promoted docs distinct from `.agent/align-with-me/*`, which remains
  temporary agent context.

## Optional Context Packet

Default persistence is chat context only.

When a durable packet is useful, write:

```text
.agent/align-with-me/<topic-slug>/<run-id>/context-packet.md
```

Use this shape:

```text
# Alignment Packet: <topic>

Status: aligned | needs-more-context | blocked

## Goal
- ...

## Confirmed Context
- ...

## Decisions
| Decision | Recommended answer | User answer | Status |
| --- | --- | --- | --- |

## Assumptions
| Assumption | Why it is assumed | Risk if wrong |
| --- | --- | --- |

## Evidence Checked
| Source | Role | What it says | Confidence |
| --- | --- | --- | --- |

## Open Questions
| Question | Why it matters | Blocks progress? |
| --- | --- | --- |

## Corrections
- ...
```

Include `Corrections` only for post-work correction. Do not include a
downstream owner or handoff target section.

## Output

For ordinary alignment, continue the conversation with the next focused
question or a short alignment state when enough context is clear.

When summarizing in chat, use:

```text
Alignment State

Goal:
Confirmed context:
Decisions:
Assumptions:
Evidence checked:
Open questions:
Alignment status: aligned / needs-more-context / blocked
```

If blocked, name the missing decision, evidence, or permission and stop before
inventing context.

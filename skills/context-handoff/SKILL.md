---
name: context-handoff
description: Write scoped context handoff packets so a future session, agent, or human can resume work without rereading the whole conversation. Use when the user asks to hand off, compact, summarize for the next agent/session, preserve context, create a resume packet, or says "上下文交接", "交接包", "下一棒", "新会话", "压缩上下文", "续上", or similar. Supports project, user, and session scope; does not write stable docs or execute downstream work.
---

# Context Handoff

## Purpose

Use this skill to capture the current working context into a scoped handoff
packet. The packet lets a future agent, session, or human resume from the same
state without rereading the whole conversation.

This skill owns context handoff packets only. It does not own the downstream
work described inside the packet.

## When To Use

- The user asks to hand off, compact, summarize for the next agent or session,
  preserve context, create a resume note, or continue later.
- The user says "handoff", "上下文交接", "交接包", "交接给下一个会话",
  "下一棒", "新会话", "压缩上下文", "给下一个 agent",
  "下一个智能体", "下一个助手", "续上", or similar.
- The user asks for a handoff because work is about to cross session
  boundaries, context compaction, branch/worktree switches, or agent changes.
- Existing work has enough decisions, evidence, diffs, commands, open
  questions, and constraints that a normal chat summary would be lossy, and the
  user has asked to preserve or transfer that context.

## When Not To Use

- Do not write a PLAN, PRD, architecture truth, product document, design
  artifact, issue, ADR, README, stable project docs, code, tests, release note,
  or downstream workflow artifact.
- Do not mutate project source files except the scoped handoff packet itself.
- Do not treat a handoff packet as stable project truth.
- Do not include secrets, API keys, passwords, tokens, private keys, payment
  data, direct personal contact details, or live credentials.
- Do not duplicate full content already captured in plans, PRDs, issues,
  design docs, commits, diffs, or stable docs. Link or reference those artifacts
  instead.
- Do not execute the next workflow. Suggested next steps are context for the
  receiver, not permission to act.

## Scope Decision

Choose the narrowest durable scope that matches the receiver.

- `project`: The handoff is for continuing work in the current repository or
  project. Write under the project root:

  ```text
  .agent/context-handoff/<topic-slug>/<run-id>/handoff.md
  ```

- `user`: The handoff is personal, cross-project, or agent-wide context for the
  user. Write under the user's personal agent work-state root:

  ```text
  ~/.agent/context-handoff/<topic-slug>/<run-id>/handoff.md
  ```

  Use this only when the content should outlive one project and is safe outside
  the project boundary.

- `session`: The handoff is a one-time transfer and should not persist in the
  project or user state. Write to the operating system temp directory:

  ```text
  <tmpdir>/context-handoff-<topic-slug>-<run-id>.md
  ```

Default to `project` when the work is repository-bound. Default to `session`
when the user asks for a temporary transfer, says not to write into the current
workspace, or the repository has no declared or ignored agent work-state root.
Use `user` only when the user explicitly asks for personal or cross-project
persistence, or the content is clearly user preference or durable agent memory
rather than project state.

Ask one concise scope question when the destination materially changes what can
be included. Recommended default should be the safest narrow scope.

## Workflow

1. Identify the receiver, scope, topic, and resume goal from the user's request.
2. Inspect obvious current evidence instead of asking: conversation state,
   current repository path, changed files, recent commands, relevant plans,
   packets, issues, PRDs, docs, diffs, and validation output already produced.
3. Classify each fact by scope:
   - project-specific facts stay in project or session packets;
   - personal reusable preferences may go to user packets;
   - secrets and sensitive identifiers are omitted or redacted;
   - stable artifacts are referenced, not copied.
4. Write the handoff packet at the selected location.
5. Report the absolute path and the scope. If the packet intentionally omitted
   sensitive or duplicated material, say that briefly. Include a short
   copy-ready resume prompt in the final chat response so the user can start the
   next session without opening the packet first.

Do not ask the user for facts that are visible in the current conversation,
workspace, or supplied artifacts.

## Optional Packet Fields

Start with the smallest packet that lets the receiver resume without guessing.
Use the fields below as an optional menu, not a required form. For complex
handoffs, this full field set is acceptable:

````text
# Context Handoff: <topic>

Scope:
Audience:
Created:
Source context:

## Resume Goal
- ...

## Current State
- ...

## Key Decisions
- ...

## Key Evidence And Artifacts
- ...

## Local State
- ...

## Validation
- ...

## Open Questions Or Blockers
- ...

## Risks Or Constraints
- ...

## Next Steps
- ...

## Suggested Entry Points
- ...

## Suggested Resume Prompt
```text
...
```

## Redactions Or Omissions
- ...
````

Omit any section that does not add concrete resume value. Do not include
placeholder tables or headings just to satisfy the template. Keep the packet
concise enough that the receiver can read it quickly, but concrete enough to
resume without guessing.

A lightweight handoff may be only: resume goal, current state, key artifacts or
paths, blockers, next steps, suggested entry points when useful, and redactions when
any material was omitted.

## Scope-Specific Rules

For `project` packets:

- Include repository-relative paths, branch/worktree notes, relevant diffs or
  changed-file summaries, commands run, validation status, and project-local
  open questions.
- Store only under `.agent/context-handoff/*`.
- Use project scope only when `.agent/` is repo-declared, ignored, or explicitly
  chosen for project-local work-state. Otherwise use `session` or ask one scope
  question before writing into the workspace.
- Do not promote packet content into stable docs unless the user separately
  authorizes that write.

For `user` packets:

- Include only cross-project preferences, durable personal context, or reusable
  working agreements.
- Strip project-private implementation details unless the user explicitly asks
  to preserve them and they are safe outside the repo.
- Avoid writing third-party confidential material, proprietary paths, live
  account details, or user-specific secrets.

For `session` packets:

- Optimize for immediate continuation.
- Prefer absolute paths and exact command snippets only when they are needed to
  resume this machine-local work.
- Prefer `session` for upstream-style temporary handoffs, one-off transfers,
  and requests that say not to write into the project or current workspace.
- Treat the file as temporary; do not cite it as durable truth later unless the
  user asks to promote or relocate it.

## Suggested Entry Points

Include this section only when it helps the receiver resume faster. List only
skills, docs, commands, issue links, or entry points that were already used,
explicitly requested by the user, or are clearly required by the resume goal.
Do not invent downstream owner routing, and do not treat the list as permission
to execute those workflows.

## Final Response

After writing a packet, keep the final chat response short and include:

- the packet's absolute path;
- the selected scope;
- a small copy-ready resume prompt that tells the next session to read the
  packet path and continue from its resume goal, current state, open questions,
  and next steps.

The copy prompt must not grant new permissions for code writes, publishing,
installs, account actions, PR creation, or downstream workflow execution beyond
the user's actual request.

## Redaction Rules

Before writing, scan for sensitive material:

- API keys, tokens, passwords, private keys, session cookies, and auth headers.
- Personal contact details, payment details, and government identifiers.
- Live account identifiers when not needed for resumption.
- Proprietary source content that is not needed because a path, issue URL, or
  artifact reference is enough.

Replace sensitive values with `[REDACTED:<kind>]` and preserve only the minimum
context required to continue safely.

## Relationship To Alignment

Alignment and handoff are separate:

- Alignment establishes shared context and resolves uncertainty.
- Handoff packages already-known context for a future receiver.

If context is still materially ambiguous, record open questions instead of
inventing answers. If the user wants ambiguity resolved before handoff, run the
alignment loop first, then write the handoff packet.

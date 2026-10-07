# Human-In-The-Loop Design

Use this reference when a skill needs user judgment, permission, routing,
feedback, or subagent consent.

HITL rules are local quality gates. They do not change the Anthropic eval
stage order.

## Gate Shape

Each gate should name:

- Trigger: condition that requires user input.
- Question: exact short question.
- Why it matters: workflow, risk, or output impact.
- Options: acceptable answers or decision paths.
- Safe default: what to do if the user declines, skips, or does not answer.
- Allowed before answer: safe work that can continue.
- Blocked until answer: writes, live actions, installs, broad scans,
  subagents, or subjective rewrites that must wait.
- Artifact: where the decision is recorded when durable state exists.

## Host-Specific Structured Questions

Some hosts expose structured HITL tools, such as Claude-side
`AskUserQuestion` or Codex structured input tools when the current mode permits
them. These tools are host-specific mappings for the gate above. They are not
portable skill semantics and they do not change the Anthropic eval flow.

Use a structured question tool when the decision has a small set of mutually
exclusive options, the answer changes permissions or workflow, or the choice
should be recorded as durable review context. Keep the prompt short, name the
safe default, and avoid open-ended "what should I do?" questions.

Host mapping:

- Anthropic or Claude host: map the gate to `AskUserQuestion` when that host
  exposes it; otherwise ask the same short question in normal chat.
- Codex host: use `request_user_input` only when that tool is available and
  the current collaboration mode permits it; otherwise ask a concise plain-text
  question in chat and continue only the work listed as allowed before answer.
- Static review UI: treat `review.html` plus `feedback.json` as structured
  feedback intake for eval review, not as permission for unrelated live
  actions.

Structured HITL is still a gate. It must not authorize subagents, external
publishing, destructive edits, live account mutation, or broad installs unless
the question explicitly covered that action.

## Common Gates

- Routing gate: missing fact changes the target skill, target artifact, or
  output owner.
- Permission gate: irreversible edit, destructive operation, live account,
  broad install, networked mutation, or external publishing.
- Scope gate: request may mean narrow fix, broad refactor, docs-only pass, or
  multi-target change.
- Topology escalation gate: a complex skill may need fan-out/fan-in,
  orchestrator, subagent-backed phases, or clean-context review instead of a
  leaf or staged serial design.
- Judgment gate: answer depends on taste, product intent, brand voice,
  business tradeoff, or subjective preference.
- Feedback gate: review output or eval artifact requires human scoring before
  self-revision.
- Subagent gate: independent passes would help, but the user did not request
  subagents, parallel agents, independent agents, or full Anthropic-style evals.

Do not treat generic continuation words such as "next", "continue", "ok", or
"go on" as authorization for new risk, live writes, broad installs, subagents,
or publishing.

# Subagent Roles

Use these as the default collection roles when a distillation task has clearly
scoped, independent evidence gathering across multiple donors, source types, or
review angles. If the host or current user/system policy does not allow
subagents, use the same roles as serial sections in the main context.

Default subagent runtime: use `gpt-5.3-codex` with `xhigh` reasoning effort for
these roles when the host supports explicit model selection. If unavailable, use
the current host default and keep the same role boundaries.

Run independent roles in parallel when possible. Keep overlapping scopes,
dependent follow-up questions, synthesis, and HITL decisions in the main
context.

## Central Rule

Subagents must not directly edit `Docs/Architecture`. Subagents write
findings, evidence, extraction, and risk. The main agent owns synthesis and
architecture truth updates.

## Local Truth Reader

Reads local README, `AGENTS.md`, `Docs/Architecture`, `Docs/Reference`,
`Docs/Proposals`, `Docs/Decisions`, `.agent` plans, package/project layout,
examples, and tests.

Output: local truth summary, existing boundaries, doc destinations, conflicts,
and gaps.

## Official Donor Researcher

Inspects official APIs, official docs, official packages, platform
conventions, and canonical examples.

Output: authoritative semantics, public API shape, lifecycle rules, official
constraints, and evidence links.

## Community Donor Researcher

Inspects mature open-source implementations and community libraries.

Output: practical capability coverage, edge cases, implementation pressures,
test practices, and donor-specific baggage.

## Product / UX Donor Researcher

Inspects product flows, screen models, interaction patterns, onboarding,
approval, status, error, or reconnect flows.

Output: state model, interaction semantics, recovery paths, and visual or
product coupling to reject.

## Test / Fixture Donor Researcher

Inspects tests, fixtures, benchmark harnesses, compatibility suites, or
regression practices.

Output: fixture contracts, scenario taxonomy, baseline/regression policies,
and test harness assumptions to reject.

## Boundary Reviewer

Identifies donor baggage, coupling, dependency risk, naming drift, runtime
assumptions, over-copying risk, and under-absorption risk.

Output: boundary findings, rejected baggage, and HITL Boundary Gate questions.

## Local Framework Architect

Proposes local reconstruction options such as semantic model, DSL/API shape,
runtime abstraction, facade, renderer boundary, or layered architecture.

Output: options and tradeoffs only. This role does not bypass main-agent
synthesis or HITL gates.

## Case Capture Writer

Writes reusable case capture only after the user asks to preserve the lesson.

Output: compact case capture using the case template. This role does not add
curated case artifacts by default.

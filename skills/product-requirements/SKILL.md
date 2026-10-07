---
name: product-requirements
description: Draft, revise, or review integrated product requirements, PRDs, feature specs, and product specification source-of-truth documents. Use for scope, non-goals, functional requirements, user stories, acceptance criteria, feature-level success metrics, business rules, constraints, risks, open questions, and downstream traceability. Do not use for interaction behavior ownership, flows, screens, states, actions, transitions, renderer output, code/build plans, UX craft, QA automation, GTM execution, or project-management timelines and status mechanics.
---

# Product Requirements

## Purpose

Create product requirements that are clear enough for product, design, and
prototype consumers to understand the current target product boundary without
turning the work into a build plan.

The skill owns the product source-of-truth artifact: problem, target users,
evidence, why now, solution outline, measurable outcomes, functional
requirements, non-goals, user stories, acceptance criteria, feature-level
success metrics, business rules, constraints, risks, dependencies, open
questions, and traceability fields needed by product interaction design and
package verification.

User stories, acceptance criteria, and feature-level success metrics are
sections of this requirements source. They are not separate public
product-experience feature-package skills.

## When To Use

- The user asks for a PRD, product requirements document, requirements spec,
  product spec, feature spec, or source-of-truth product artifact.
- The user has loose notes, research, stakeholder input, or a feature idea that
  needs a structured product requirements artifact.
- The user asks to review or improve a product requirements draft.
- The user asks for a complete product spec that includes stories, acceptance
  criteria, business rules, or feature-level success metrics.
- The output should describe what product behavior should exist and why, not
  how to build it.

## When Not To Use

- Existing-code reconstruction; use a product evidence owner such as
  code-derived product documentation.
- Detailed interaction behavior, flows, screens, states, actions, transitions,
  or wireframe semantics as the owned artifact.
- Deep analytics, instrumentation specs, dashboards, or experiments when they
  go beyond feature-level success metrics.
- UX craft, HIG interpretation, visual design, design systems, or interface
  writing.
- Technical design, task breakdown, code/build planning, code changes, QA
  automation, CI, or release engineering.
- GTM launch copy, ASO, SEO, paid acquisition, market messaging, or store
  operations.
- Timeline commitments, milestone calendars, sprint plans, or program status
  tracking.

## Inputs To Inspect

- Existing product docs, discovery notes, customer feedback, analytics evidence,
  support themes, sales notes, stakeholder constraints, and roadmap context.
- Related code or design artifacts only as evidence. Label code/build or visual
  observations as evidence, not product intent.
- Existing repository product documentation conventions.
- If present, previous requirements, stories, interaction notes, acceptance
  criteria, metrics, business rules, and decisions.

## Workflow

1. Identify the output mode: feature brief, one-page PRD, full PRD, integrated
   product spec, or requirements-section revision.
2. Read the relevant evidence before drafting. Prefer user-provided product
   truth over generic frameworks.
3. Clarify only decisions that materially change scope, owner, audience,
   source-of-truth location, success metrics, or launch risk. If the missing
   information can be represented as an open question, continue.
4. Draft the requirements using `references/template.md`.
5. Keep the problem, target users, why now, feature-level success metrics,
   scope, non-goals, requirements, stories, acceptance criteria, business
   rules, constraints, and traceability explicit. Use plain product language.
6. When stories or acceptance criteria need deeper detail, revise those
   sections inside this requirements source.
7. Run a readiness pass for context, problem, users, metrics, scope, stories,
   acceptance, risks, dependencies, assumptions, placeholders, and open
   questions.
8. Keep technical considerations high level: dependencies, constraints,
   unknowns, and downstream readiness. Do not design architecture or tasks.
9. Validate against the quality checklist and relevant fixtures before
   presenting the result.

## Reference Files

- `references/template.md`: PRD and feature brief template.
- `references/example.md`: completed requirements example.
- `references/source-ledger.md`: receipt-backed source decisions.
- `references/eval-fixtures.md`: durable behavior fixtures for this skill.

## Decision Rules

- Lead with the problem and evidence, not the proposed feature.
- Include success metrics with baseline, target, and measurement method when
  possible. If unavailable, write an open measurement question.
- State in-scope, out-of-scope, and future opportunities explicitly.
- Include optional sections only when the product context warrants them; do not
  add generic boilerplate to look complete.
- Separate product constraints from technical design.
- Use numbered or stable requirement identifiers when the document is likely to
  feed stories or acceptance criteria.
- Keep user stories and acceptance criteria traceable to requirement IDs. Do
  not let section revisions create new product scope without updating the
  requirements source.
- Put feature-level success metrics here. Route deeper analytics,
  instrumentation, dashboards, experiments, or result reviews outside the
  feature-package stage flow.
- Do not own interaction behavior details. Requirements may state product
  behavior at a spec level, but flows, screens, states, actions, transitions,
  validation/recovery detail, and wireframe semantics belong to the
  interaction-design source artifact.
- Treat design links, code observations, and stakeholder notes as evidence until
  the product decision is stated.
- Capture timing as a risk or dependency, not as a delivery calendar.

## Validation Rules

- Requirements are testable, unambiguous, and traceable to a problem or goal.
- User stories, acceptance criteria, business rules, and feature-level metrics
  are present when the requested spec requires them, or intentionally marked
  out of scope.
- Stories and acceptance criteria trace to requirement IDs and do not invent
  scope.
- Non-goals, risks, dependencies, and open questions are present when relevant.
- Success metrics are measurable or marked as open.
- Required sections are present or intentionally omitted with a reason.
- Placeholder, TBD, and thin fields are surfaced in readiness notes.
- No section instructs the agent to implement, run tests, submit releases, or
  execute market launch work.
- No section commits sprint dates, milestone calendars, or program-management
  schedules.
- Source-derived claims are labeled as evidence when they are not product truth.
- Output does not become an interaction model, renderer plan, technical design,
  or code/build task list.

## Output Format

Use the template unless the user provides a target path or the workspace has a
clear local product-docs convention. If no path or convention is available,
return the artifact content and mark placement as a local decision still needed.
When this artifact is part of a package workflow, do not decide package
placement here; return requirements content for the package owner to place.

For chat-only output, return the artifact content and a short `Open Questions`
section.

## Failure / Uncertainty Handling

- If product intent conflicts across sources, show the conflict and keep both
  claims under `Open Questions` or `Decision Needed`.
- If the user asks for code/build detail, preserve the product constraint and
  route that work by responsibility.
- If the user asks for milestone dates or sprint cadence, record timing
  assumptions as risks or open questions instead of producing a schedule plan.
- If evidence is thin, keep the requested product boundary intact, label
  assumptions and open questions, and route discovery only when the user wants
  evidence validation.

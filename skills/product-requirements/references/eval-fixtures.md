# Product Requirements Eval Fixtures

## full-prd-from-loose-notes

Target behavior: Produce a product requirements artifact from loose product
notes while preserving explicit scope boundaries.

Input prompt: "We need a PRD for saved report filters. Analysts rebuild the
same filters every week. Team leads want shared views. Keep sharing outside
the current target if Product has not decided the permission model."

Context and files:

- none

Expected output:

- Uses `product-requirements` ownership.
- Produces an integrated requirements artifact, not code/build tasks.
- Includes problem, users, why now, goals, feature-level metrics, scope,
  requirements, user stories, acceptance criteria, business rules, risks,
  dependencies, traceability, and open questions.
- Labels sharing as outside the current target or a future opportunity when
  risk is mentioned.

Forbidden behavior:

- Starts technical design.
- Omits success metrics.
- Treats sharing as confirmed in scope.

Acceptance checks:

- Output contains PRD sections for problem, users, goals, metrics, scope,
  requirements, stories, acceptance criteria, business rules, risks,
  dependencies, traceability, and open questions.
- Sharing is excluded from the current target or moved to future opportunities.

Baseline expectation:

- A generic PRD writer may overcommit requested ideas or omit measurable
  outcomes.

Evidence sources:

- Generated requirements artifact.

Owner notes:

- Derived from `H1-ralph-prd.md`, `H2-dean-prd.md`, `H3-phuryn-create-prd.md`,
  and `H8-pop-deliver-prd.md`.

## too-little-evidence

Target behavior: Draft only as far as evidence supports and surface gaps.

Input prompt: "Write a full PRD for AI dashboards. We should just do it."

Context and files:

- none

Expected output:

- Produces a brief or draft PRD with explicit evidence gaps.
- Asks only high-impact questions or records open questions.
- Does not invent users, metrics, or market evidence.

Forbidden behavior:

- Fabricates detailed customer evidence.
- Blocks entirely when a draft with open questions would be useful.

Acceptance checks:

- Output labels missing evidence and limits claims to supplied context.
- Output still provides a useful draft or brief when the user needs momentum.

Baseline expectation:

- A generic writer may either fabricate specifics or refuse to draft anything.

Evidence sources:

- Generated PRD draft, evidence gaps, and open questions.

Owner notes:

- Covers uncertainty handling and evidence discipline from source receipts.

## code-build-boundary

Target behavior: Keep PRD ownership separate from code/build planning.

Input prompt: "Make a PRD and then break it into tickets with API design."

Context and files:

- none

Expected output:

- Creates or outlines the product requirements portion.
- States that API design and task breakdown are outside `product-experience`
  product requirements ownership.
- Preserves product constraints that downstream consumers will need.

Forbidden behavior:

- Writes endpoint schemas or code/build tasks as if owned by this skill.

Acceptance checks:

- Output does not include API schemas, ticket breakdowns, or code/build tasks
  as owned deliverables.
- Product constraints are retained for downstream use.

Baseline expectation:

- A generic assistant may comply with both PRD and build planning in one
  artifact.

Evidence sources:

- Generated PRD and boundary notes.

Owner notes:

- Preserves collection boundary against code/build ownership.

## stories-and-acceptance-integrated

Target behavior: Treat stories and acceptance criteria as sections of the
requirements source.

Input prompt: "Create the product spec for saved filters, including stories and
acceptance criteria, but do not write the interaction model yet."

Context and files:

- none

Expected output:

- Uses `product-requirements` ownership.
- Includes stories, acceptance criteria, business rules, feature-level metrics,
  and traceability inside the requirements artifact.
- Revises detailed story or acceptance content inside requirements.
- Leaves flows, screens, states, actions, transitions, and wireframe semantics
  for the interaction-design source artifact.

Forbidden behavior:

- Routes all stories or acceptance criteria away as if requirements cannot own
  those sections.
- Writes a canonical interaction model or renderer plan.

Acceptance checks:

- Output includes integrated story and acceptance sections with requirement
  links.
- Output keeps interaction behavior out of requirements ownership.

Baseline expectation:

- A generic PRD writer may route stories and acceptance criteria away from the
  product spec or mix them with interaction design.

Evidence sources:

- Generated integrated requirements artifact.

Owner notes:

- Documents the three-stage consolidation of stories and acceptance criteria
  into `product-requirements`.

## review-existing-prd

Target behavior: Review an existing PRD using the same requirements quality
model used for authoring.

Input prompt: "Review this PRD for readiness: it has a solution but no metrics,
risks, or non-goals."

Context and files:

- Existing PRD content can be supplied in the prompt or attached files.

Expected output:

- Reviews through the same requirements quality model.
- Calls out missing measurable outcomes, risks, and scope boundaries.
- Suggests concrete product-level repairs.

Forbidden behavior:

- Treats review as a separate non-trigger path.
- Focuses on grammar instead of product readiness.

Acceptance checks:

- Output includes findings for missing metrics, risks, and non-goals.
- Repairs stay at product requirements level.

Baseline expectation:

- A generic document review may focus on wording and miss product readiness.

Evidence sources:

- Review findings and suggested product-level repairs.

Owner notes:

- Uses the manual-entry review contract for the same skill.

## readiness-checklist

Target behavior: Review a PRD draft for completeness without replacing product
requirements with a generic checklist.

Input prompt: "Review this PRD draft: it has a feature name and solution, but
users are vague, success metrics say 'improve engagement', risks are empty, and
there are several TBDs."

Context and files:

- Existing PRD content can be supplied in the prompt or attached files.

Expected output:

- Uses `product-requirements` review ownership.
- Calls out thin users, vague metrics, missing risks, and unresolved TBDs.
- Suggests concrete product-level repairs.
- Keeps optional sections conditional.

Forbidden behavior:

- Replaces the draft with a huge generic PRD template.
- Treats TBDs as final requirements.
- Writes code/build tasks, API design, or sprint plans.

Acceptance checks:

- Output includes readiness findings for users, metrics, risks, assumptions or
  TBDs, scope, and handoff readiness.
- Repairs remain at product requirements level.

Baseline expectation:

- A generic reviewer may focus on formatting or paste a checklist without
  preserving the product source-of-truth boundary.

## calendar-mechanics-boundary

Target behavior: Preserve product requirements ownership while rejecting
project-management schedule mechanics.

Input prompt: "Write the PRD and include a week-by-week delivery timeline with
sprint dates and milestone owners."

Context and files:

- none

Expected output:

- Produces the product requirements artifact.
- Captures timing pressure as a dependency, risk, or open question.
- Avoids producing sprint calendars or project-management schedule mechanics.

Forbidden behavior:

- Adds week-by-week execution plans as if owned by this skill.
- Converts requirements into a program status tracker.

Acceptance checks:

- Output includes PRD content and captures timing as dependency, risk, or open
  question.
- Output does not include sprint calendars, milestone-owner schedules, or
  project status tracking.

Baseline expectation:

- A generic PRD response may include schedule mechanics because the prompt asks
  for them.

Evidence sources:

- Generated PRD and boundary note.

Owner notes:

- Preserves product requirements versus project-management boundary.

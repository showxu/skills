# Product Discovery Eval Fixtures

## opportunity-validation

Target behavior: Convert loose research evidence into an opportunity validation
decision before PRD work starts.

Input prompt: "We think saved report filters are a good idea. Support has 12
tickets about rebuilding filters, but we have not interviewed users. Should we
write the PRD?"

Expected output:

- Uses `product-discovery` ownership.
- Separates evidence from assumptions.
- Maps target users, current workaround, opportunity, and validation gaps.
- Recommends proceed, pivot, stop, or keep learning.
- Names PRD-ready inputs if evidence is strong enough.
- Keeps product direction, current target boundary, and open tradeoffs visible.

Forbidden behavior:

- Writes a full PRD as the owned output.
- Claims the opportunity is validated without evidence strength.
- Starts technical design or visual design.

Acceptance checks:

- Output includes desired outcome, opportunity map, assumptions, evidence
  strength, direction recommendation, and PRD-ready inputs.
- Output names the next cheapest test when evidence is weak.

## assumption-mapping

Target behavior: Prioritize discovery assumptions by risk and certainty.

Input prompt: "Map assumptions for saved filters: users want personal saved
views, shared filters are required, engineering can store preferences, and
users will understand apply behavior."

Expected output:

- Categorizes assumptions as desirability, viability, feasibility, or
  usability.
- Prioritizes high-risk, low-certainty items first.
- Suggests validation tests.

Forbidden behavior:

- Treats all assumptions as equal priority.
- Converts assumptions directly into PRD requirements.

Acceptance checks:

- Output includes assumption category, risk, certainty, priority, and test.

## ideation-heavy-discovery

Target behavior: Turn an assumption-led idea into product direction framing
inside discovery without pretending it is research-backed validation.

Input prompt: "I want to skip research for now. Brainstorm the direction for
saved report filters and get it ready for a PRD."

Expected output:

- Uses `product-discovery` ownership.
- Captures target users, scenario, product promise, current target boundary,
  non-goals, assumptions, risks, and PRD-ready inputs.
- Marks evidence as thin or missing rather than inventing validation.
- Treats ideation-heavy direction framing as discovery-owned work, not a
  separate source of truth.

Forbidden behavior:

- Routes the main direction framing away from discovery.
- Writes a full PRD.
- Claims research-backed confidence without evidence.

Acceptance checks:

- Output includes direction framing, tradeoffs, current target boundary,
  assumptions, and open decisions.
- Output distinguishes assumptions from evidence.

## solution-validation-boundary

Target behavior: Use prototypes or experiments as validation evidence without
claiming prototype creation, UX craft, or app-build ownership.

Input prompt: "We have a clickable prototype for saved report filters. Review
whether the solution is validated."

Expected output:

- Treats the prototype as evidence input.
- Checks task success, comprehension, value, and behavior signals.
- Recommends proceed, pivot, stop, or keep learning.
- Routes concrete prototype revision outside discovery if needed.

Forbidden behavior:

- Edits the prototype as this skill's owned output.
- Reviews visual polish or design system quality.
- Claims production readiness.

Acceptance checks:

- Output evaluates evidence strength and decision criteria.
- Output keeps ownership boundaries clear.

## discovery-sprint-plan

Target behavior: Plan a short discovery learning cycle without turning it into
delivery scheduling.

Input prompt: "We have two weeks to learn whether saved filters are worth
building. Plan the discovery sprint."

Expected output:

- Uses `product-discovery` ownership.
- States hypotheses, fastest learning actions, evidence review points, and
  decision criteria.
- Keeps opportunities, assumptions, problem validation, and solution validation
  visible.

Forbidden behavior:

- Creates sprint tickets, code/build tasks, or release dates.
- Treats the learning cycle as proof that the opportunity is validated.

Acceptance checks:

- Output includes discovery hypotheses and proceed/pivot/stop or keep-learning
  criteria.
- Output avoids delivery schedule mechanics.

## research-input-boundary

Target behavior: consume journey maps, proto-personas, and research summaries
as product discovery evidence without claiming UX craft or validation certainty.

Input prompt: "We have a proto-persona and a journey map from design. Use them
to decide whether saved report filters should proceed to PRD."

Expected output:

- Uses `product-discovery`.
- Treats persona and journey map as evidence inputs with source quality.
- Separates repeated signals from assumptions and validation gaps.
- Recommends proceed, pivot, stop, or keep learning.
- Routes design craft or usability-study design concerns out of PM ownership.

Forbidden behavior:

- Treats proto-persona or journey map as validated truth by default.
- Reviews visual design or design-system quality.
- Writes the PRD as the owned output.

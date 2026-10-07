---
name: product-discovery
description: Run product direction discovery before requirements / PRD work. Use for problem framing, user and scenario framing, opportunity framing, solution brainstorming, lightweight strategy, tradeoff analysis, direction selection, risks, assumptions, evidence strength review, and PRD-ready decision inputs. Do not use for formal PRDs, product interaction design, rendered prototypes, user-story or acceptance-criteria source sections, visual design, technical design, GTM execution, or project-management status.
---

# Product Discovery

## Purpose

Define whether and how a product opportunity should enter PRD-ready
specification. This skill owns direction discovery: problem framing, target
users and scenarios, opportunity framing, solution brainstorming, lightweight
strategy, tradeoff analysis, current target direction selection, risks,
assumptions, evidence strength, and PRD-ready decision inputs.

Discovery is not visual design, technical feasibility ownership, GTM research,
or code/build planning. It may consume interviews, analytics, support
themes, sales notes, prototype test findings, and stakeholder constraints as
evidence, but it must keep source quality and uncertainty visible.
It may also work from a subjective or assumption-led idea when the user wants
to skip research, as long as assumptions are labeled instead of presented as
evidence.

## When To Use

- The user wants to shape direction before writing requirements or a PRD.
- The user has a loose product idea and wants product brainstorming, current
  target boundary framing, or PRD-ready inputs.
- The user wants to validate an opportunity before writing a PRD.
- The user has research notes, customer feedback, support tickets, analytics,
  interview findings, journey evidence, proto-personas, or research summaries
  and needs product discovery synthesis.
- The user needs assumption mapping or a test plan for problem-solution fit.
- The user asks whether an idea should proceed into requirements.
- A product feature package needs discovery evidence or a proceed/pivot/stop
  decision before downstream artifacts.

## When Not To Use

- Formal PRDs, feature specs, or requirements source-of-truth artifacts.
- Product interaction design, clickable or rendered prototypes, user stories,
  or acceptance criteria as source-of-truth sections.
- UX craft, visual design, design systems, technical design, code/build plans,
  QA automation, GTM execution, or project-management status.
- Deep market research, competitor teardown, channel analysis, or launch
  messaging unless the user frames it as product decision evidence.

## Inputs To Inspect

- User research, interviews, survey notes, support themes, sales calls,
  analytics, experiment results, prototype findings, stakeholder constraints,
  and product strategy context.
- Existing discovery notes, requirements, interaction-design notes, sketches,
  research summaries, or rendered artifacts as context. Treat non-structured
  artifacts as evidence, not separate discovery truth.
- Research summaries, interview scripts, journey maps, and proto-personas as
  assumption-bearing evidence. Treat them as validated only when their source
  quality supports that claim.
- Any stated desired outcome, baseline metric, target segment, solution idea,
  assumption, risk, or decision deadline.

## Workflow

1. Identify the discovery mode: subjective direction framing, opportunity
   framing, solution brainstorming, tradeoff analysis, assumption mapping,
   problem validation, solution validation, discovery sprint plan, or readiness
   review.
2. Capture the raw idea, desired outcome, baseline, target horizon, target
   users, current target boundary, and decision to be made.
3. Map opportunities before solutions when evidence is available. When the user
   wants assumption-led ideation, keep solution options visible and label
   assumptions.
4. Frame solution directions, deliberate non-goals, future opportunities, and
   tradeoffs before selecting a current target direction.
5. List assumptions by desirability, viability, feasibility, and usability.
   Prioritize high-risk, low-certainty assumptions first. Use
   `scripts/assumption_mapper.py` when a scored assumption table is useful.
6. Validate the problem with current behavior evidence: frequency, severity,
   workarounds, willingness to solve, and measurable cost.
7. When using interviews, journey maps, personas, or research summaries,
   capture source quality, segment fit, repeated patterns, contradictions, and
   validation gaps before turning them into product claims.
8. Validate the solution with the smallest useful test: concept, prototype,
   fake-door, concierge, beta cohort, or another explicit experiment.
9. For a discovery sprint or learning cycle, define hypotheses, the fastest
   learning actions, evidence review points, and the decision criteria. Keep it
   as discovery learning, not a delivery schedule.
10. Grade evidence strength and gaps. Prefer triangulated behavior evidence over
   stated preference alone.
11. Return a selected direction or proceed, pivot, stop, or keep-learning
   recommendation with the evidence, assumptions, tradeoffs, risks, and
   PRD-ready decision inputs.

## Reference Files

- `references/template.md`: discovery output template.
- `references/source-ledger.md`: receipt-backed source decisions.
- `references/eval-fixtures.md`: durable behavior fixtures.

## Decision Rules

- Do not start with a solution when the opportunity is still unclear unless the
  user explicitly wants assumption-led ideation; in that case label the
  solution as a hypothesis.
- Keep multiple plausible opportunities or solution tests visible until
  evidence justifies convergence.
- Tie every opportunity or recommendation to an evidence source or mark it as
  an assumption.
- Test high-risk, low-certainty assumptions before low-risk polish questions.
- Use at least two evidence types for major proceed decisions when available.
- Treat prototype findings as validation evidence, not as app-build or final
  visual design.
- Treat journey maps and proto-personas as hypotheses until supported by
  research or behavioral evidence.
- Treat broad company strategy, portfolio roadmap ranking, investment review,
  and market strategy as background or deferred planning work unless they are
  directly needed to select the current product direction.
- Route UX craft, usability study design craft, and design-validation critique
  to design-side owners; keep only product decision evidence here.
- Treat technical feasibility as an input or blocker; route technical design to
  software-engineering owners.
- Route formal requirements to `product-requirements` after the discovery
  decision.

## Validation Rules

- Desired outcome, target users, scenario, opportunity, solution direction,
  tradeoffs, assumptions, validation method, evidence strength, and decision
  recommendation are explicit when relevant.
- Assumptions are categorized and prioritized by risk and certainty.
- Discovery sprint plans define learning hypotheses, evidence review points,
  and decision criteria without turning into delivery schedules.
- Problem validation distinguishes observed behavior from stated preference.
- Solution validation names the smallest useful test and decision criteria.
- Proceed decisions state why evidence is strong enough; keep-learning or stop
  decisions state the missing or contradictory evidence.
- The output does not become a PRD, interaction-design artifact, prototype,
  technical design, UX craft review, market launch plan, or project schedule.

## Output Format

Use the template unless the user provides a target path or the workspace has a
clear local product-docs convention. If no path or convention is available,
return the artifact content and mark placement as a local decision still needed.
When this artifact is part of a package workflow, do not decide package
placement here; return discovery content for the package owner to place.

For chat-only output, return:

```text
Product Discovery: <opportunity>

Raw idea or direction input:
- ...

Desired outcome:
- ...

Opportunity map:
- ...

Solution directions and tradeoffs:
- ...

Assumptions:
- ...

Validation plan or evidence:
- ...

Evidence strength:
- Strong / Medium / Weak

Recommendation:
- Proceed / Pivot / Stop / Keep learning

PRD-ready decision inputs:
- ...

Open questions:
- ...
```

## Failure / Uncertainty Handling

- If evidence is thin, produce a discovery plan instead of pretending the idea
  is validated.
- If problem and solution evidence conflict, separate them and recommend the
  next cheapest test.
- If the user asks for a PRD before discovery is ready, provide the discovery
  finding and name what must become PRD-ready framing.
- If the request crosses into design, engineering, GTM, or project management,
  preserve product evidence and route non-owned work by responsibility.

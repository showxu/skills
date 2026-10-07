# Collection Review Checklist

Use this when the user names a specific collection or linked source for
repository-architecture review.

For collection architecture, placement, taxonomy, marketplace, manifest, linked
checkout, or migration judgment, use this directory as the repository
architecture reference surface. For single-skill production readiness, do not
duplicate the creator rubric here; delegate to `skill-creator`.

## Review Entry

1. Find the collection or linked source through the target repo's declared
   skill surface, marketplace metadata, or source manifests.
2. Read root `docs/skill-authoring.md` for repository-wide trigger rules.
3. Read the collection `AGENTS.md`, `README.md`, and any authoring or review
   docs before judging collection-local skills.
4. Use `skill-creator` for single-skill or selected multi-skill production
   review.
5. Keep domain-specific source examples and safety rules in the collection.
6. Prefer repairing the nearest existing skill or reference before proposing a
   new skill.
7. For scheduled or broad reviews, define explicit target scope and route
   production-quality findings through `skill-creator`. Cadence and automation
   mechanics are outside this checklist.

## Review Checks

- Does each `SKILL.md` description name concrete use cases instead of broad
  domain ownership?
- Can the skill auto-trigger for new work in its owned task surface?
- Does explicit invocation use the same knowledge system for review, refactor,
  audit, or diagnosis instead of defining a second contract?
- Does the description match what the skill-local body actually owns: its
  workflow, inputs, output shape, safety boundary, references, and scripts?
- Does each neighboring skill have a clear negative boundary when overlap is
  likely?
- Does `agents/openai.yaml` match the `SKILL.md` frontmatter intent and offer a
  useful manual-entry prompt?
- Are renamed skills, stale paths, or old terminology absent outside explicit
  compatibility notes?
- If the finding is collection architecture, does the repository architecture
  reference surface produce a verdict or next action?
- If the finding is one-skill quality, did `skill-creator` produce a pass,
  warning, fail, or deferred status?

## Output

Report findings as review evidence first. Only make edits when the user asks
for fixes or the active request clearly includes fixing the reviewed issues.
For broad reviews, include a collection decision table with `skill`,
`reason_selected`, `scope_run`, `routing_decision`, `status`,
`recommended_action`, and `next_owner`.

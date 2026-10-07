# Rules

Rules define documentation role boundaries and normalization behavior for
Python repositories using `pyproject.toml` as the project fact source. Roles
map to repository paths in the `SKILL.md` Role Model.

Read only the rule files needed for the current operation.

Role rules, bundled from the `repository-docs` skill (edit them there and
re-derive):

- `route-vs-index.md`: document roles and authority, including agent route,
  edit guardrails, review rules, and tool entry files.
- `readme-layering.md`: root README, directory and documentation indexes, and
  where detailed content belongs.
- `code-review-rules.md`: the `## Code Review Rules` section and the files
  that carry it to a specific reviewer.

Python project rules:

- `proposal-vs-truth-vs-history.md`: proposal, current truth, and historical
  record classification under `docs/`.
- `architecture-description-primacy.md`: current architecture truth belongs in
  `docs/architecture/*`.
- `canonical-artifacts.md`: collapse iterative feedback into standalone current
  documentation without correction narratives or rejected-concept residue.
- `architecture-doc-format.md`: lightweight arc42-style architecture document
  shape.
- `decision-record-format.md`: lightweight ADR/MADR-style decision record
  shape.
- `proposal-doc-format.md`: lightweight proposal document shape.
- `governance-vs-documentation-placement.md`: `.github`, root governance, and
  `docs/` placement.
- `path-casing.md`: lowercase Python documentation path casing.
- `python-project-facts.md`: `pyproject.toml`, package layout, entry points,
  dependency groups, tooling, and generated Python artifact facts.
- `python-api-docs-placement.md`: Python API docs, generated docs output, and
  generated code placement.

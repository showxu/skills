> Historical provenance: This retired collection document is kept only for audit after de-collectionization. It is not active routing authority; use root `README.md`, root `AGENTS.md`, `docs/collection-taxonomy.md`, and root `.claude-plugin/marketplace.json`.

# Review Process

Use this process when adding, splitting, renaming, moving, or materially
changing a skill in `product-experience`.

## Review Order

1. Read root `README.md`, root `AGENTS.md`, `collections.yaml`, and root
   `docs/collection-taxonomy.md`.
2. Read this collection's `README.md`, `docs/lifecycle.md`, and
   `docs/skill-authoring.md`.
3. Read the target `skills/<skill>/SKILL.md`.
4. Read only the relevant skill-local references, templates, scripts, assets,
   or examples.
5. Identify mutable product, platform, accessibility, store, policy, market,
   design-system, tool, or account-state claims.
6. Verify current official, product, account, or primary sources before
   treating those claims as authoritative. If verification is unavailable,
   mark the finding as evidence-limited.
7. Check `.claude-plugin/marketplace.json` after the skill directory is final.

## Information Conservation

When reviewing an external guide, old collection doc, source repository, or
large local receipt for integration, record how useful material was handled:

- `integrated`: implemented in a local skill, reference, script, example, or
  template
- `compressed`: retained as a smaller rule, checklist, rubric, or output shape
- `moved`: assigned to a different local skill or reference
- `deferred`: useful, but intentionally scheduled for later
- `excluded`: intentionally not retained, with the reason recorded

Preserve reusable decisions, boundaries, safety stops, output shapes,
validation behavior, and examples that affect agent behavior. Do not retain
source branding, unrelated installation prose, license files, funding files,
full upstream docs, or long examples that do not define a reusable pattern.

## Handoff

Final repository checks are handled by root validation:

```bash
scripts/validate-collections
skills/skill-monorepo-health-check/scripts/review-collections --root .
scripts/skills-sync --dry-run
```

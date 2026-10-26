---
description: Flag skill changes that lose source-backed behavior, promote one-off values, expose restricted material, or overstate readiness.
---
## Code Review Rules

### Skill behavior

- Flag a trigger or workflow change that loses a source-backed decision,
  permission boundary, or failure path. Preserve the behavior in its owning
  skill and update a representative fixture; structural validation alone
  cannot prove semantic equivalence.
- Flag examples or defaults that promote one machine, organization, or task
  into reusable policy. Keep those values configurable or in the example
  that owns them.

### Publication and provenance

- Flag changes that expose private research downloads or remove still-valid
  third-party notices. Publish the authored guidance and permitted resources;
  keep source-specific attribution and redistribution terms with their owner.
- Flag readiness claims based only on package validation. Report the actual
  execution or review evidence, and distinguish static checks from host
  installation and behavioral evaluation.

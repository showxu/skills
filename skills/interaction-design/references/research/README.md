# Interaction Design Research

This directory contains formal research owned by the `interaction-design` skill.
It is the durable research corpus for future `UI Design Schema` and
`Interaction Design Schema` work. The current phase is per-app factual research
only.

These reports are facts-first references. They do not replace the active
canonical model template, and they do not define the final local schema by
themselves. They also do not authorize changes to active skill contracts.

Cross-app synthesis should happen only after the app reports are complete and
reviewed. Until then, keep reports descriptive: what the app actually exposes,
what evidence supports that claim, what remains unknown, and what may later be
useful for schema design.

## Research Pipeline

```text
source observations and evidence records
-> research fact store
-> UI Design Schema / Interaction Design Schema synthesis
-> possible active skill contract changes after review
```

The `*.schema.yaml` files are the fact store. Their `draft_schema_mapping`
fields are hypotheses for later schema synthesis only. They are not source
facts, not active contract fields, and not evidence that the current local
schema is healthy or final.

## Structure

- `apps/`: product-level research reports for reference apps, tools, runtimes,
  and specs. Each app report may have a matching `*.schema.yaml` with
  field-level schema facts.
- `deep-research/`: cross-app deep research reports for UI Design Schema,
  Interaction Design Schema, and their combined schema architecture. These are
  synthesis inputs, not active schema contracts.
- `artifacts/`: app-produced source files, exported packages, runtime files,
  local probes, manifests, and downloaded app-bundle samples that support the
  app reports. These are research inputs, not active skill examples or product
  sources of truth.
- `schema-facts.md`: promoted field-level schema facts from the app reports and
  research artifacts. Use this as a cross-app index; use per-app
  `apps/*.schema.yaml` files as the field-level fact store.

## Deep Research Inputs

- `deep-research/ui-and-interaction-design-schema-deep-research.md`
- `deep-research/ui-design-schema-deep-research.md`
- `deep-research/interaction-design-schema-deep-research.md`

## Current Scope

The current per-app research set covers:

- Figma
- Sketch
- Flinto
- ProtoPie
- Rive
- Principle
- Axure RP
- Framer
- Origami Studio
- dotLottie / LottieFiles State Machine
- Penpot
- UXPin

## Out Of Scope For This Phase

- Cross-app schema synthesis.
- Final `UI Design Schema` or `Interaction Design Schema` field decisions.
- Active `interaction-design` template or contract changes.
- Importer/exporter/runtime implementation.
- Treating any reference app as the local source of truth.

## Intended Follow-Up

After the app reports are accepted, write separate synthesis reports for:

- Interaction Design Schema
- UI Design Schema
- platform/native expression schema
- projection and prototype artifact contract
- source evidence, traceability, and coverage model

# Reference App Reports

These reports capture product facts, public APIs/specs, official docs, local
source artifacts, artifact probes, and known gaps for mature interaction,
prototype, design, animation, and runtime systems.

The scope of this directory is factual research for individual apps only. It is
not the cross-app synthesis layer and it does not define the local schema. Each
report should preserve the app's own concepts before judging whether a concept
belongs in a future local schema.

Each report follows the same rough shape:

- product positioning
- mature workflow shape
- evidence inventory, with official docs/source/artifacts separated from
  inference
- schema facts, with app-specific field-level facts separated from cross-app
  synthesis
- file, project, API, or runtime artifact model
- interaction model
- UI layer model
- state, variable, condition, and logic model
- motion, animation, transition, preview, runtime, and handoff model
- confirmed / inferred / unknown facts
- useful facts for later local schema design
- facts not to absorb

This directory is not a cross-app synthesis. Do not treat repeated structures
as final local schema until a separate synthesis report is written.

For field-level schema facts, use each app's `*.schema.yaml` next to its
Markdown report. For promoted cross-app facts, use `../schema-facts.md`.
Individual app reports remain the source for narrative context, app-specific
evidence, and unknowns.

The `draft_schema_mapping` entries in schema files are not facts. They are
hypotheses for future `UI Design Schema` and `Interaction Design Schema`
synthesis. They must be re-reviewed during schema redesign and must not be used
as validation of the current local schema.

## Schema Fact Files

- `figma.schema.yaml`
- `sketch.schema.yaml`
- `flinto.schema.yaml`
- `protopie.schema.yaml`
- `rive.schema.yaml`
- `dotlottie.schema.yaml`
- `origami.schema.yaml`
- `axure.schema.yaml`
- `uxpin.schema.yaml`
- `framer.schema.yaml`
- `principle.schema.yaml`
- `penpot.schema.yaml`

## Evidence Levels

- `official_spec`: a public formal spec.
- `official_api`: public API or plugin API documentation.
- `official_docs`: product documentation, help center, or product pages.
- `source_available`: inspectable source code or public repository.
- `artifact_probe`: local file/package/runtime probe.
- `inferred`: reasoned conclusion from evidence; must be marked as such.

## Report Discipline

- Keep app facts separate from local recommendations.
- Prefer current official docs and source over old summary files.
- Cite external reference sources with official public URLs, such as vendor docs,
  official GitHub repositories, or OpenAI-published sources. Do not use local
  checkout paths as source references.
- Local paths may appear only for files stored in this research corpus under
  `research/artifacts/`. Do not reference internal audit records from formal app
  reports.
- Do not copy a vendor's file format as the local schema.
- Do not turn UI-layer facts into product behavior.
- Do not treat code-backed or runtime-backed features as required for the
  product interaction model.
- Record deferred areas explicitly when the app is useful later but not needed
  for the first schema pass.

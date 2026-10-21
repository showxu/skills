# Behavioral fixtures

## organization-family

Target behavior: Apply an authored organization family presentation template.

Input prompt: "Prepare our shared DESIGN for repository social cards, website, terminal demos and both organization profiles."

Context and files:

- The authored github-organization-family template and accepted organization name, palette, font rights, assets and source routes.

Expected output:

- Adapt the checked-in template, preserving its DESIGN.md format, every renderer token, the Social preview and Website subsections and owner/title/about/icon source roles; report local source revision and resolved placeholders.

Forbidden behavior:

- Import an app template brand, invent an upstream source receipt, claim the stand-in palette or unresolved placeholders are complete or publish GitHub surfaces.

Acceptance checks:

- The adapted file lints with zero errors and warnings and renders the terminal, social preview and profile outputs; copy and operational sources retain their owners; no unrelated brand names, hues or fonts appear.

Baseline expectation:

- An upstream-only template workflow may reject original local material or copy app styling into organization presentation.

Evidence sources:

- Generated artifacts, renderer/check output and executor response.

Owner notes:

- Neutral fixture inputs; execution evidence stays in ignored output.

## upstream-provenance

Target behavior: Preserve tracking for third-party templates.

Input prompt: "Apply this newly found third-party DESIGN template to our project."

Context and files:

- The template is absent from integrated upstream review segments and has no reviewed local inclusion.

Expected output:

- Treat it as an upstream review/inclusion request and retain source path, revision and review evidence before applying it as canonical.

Forbidden behavior:

- Classify third-party content as authored local material to bypass source tracking.

Acceptance checks:

- The response keeps root upstream tracking authoritative and distinguishes template review from application.

Baseline expectation:

- A broadened local-template route could incorrectly admit unreviewed third-party material.

Evidence sources:

- Generated artifacts, renderer/check output and executor response.

Owner notes:

- Neutral fixture inputs; execution evidence stays in ignored output.

## source-derived-front-matter

Target behavior: Include an upstream template with machine-readable design
values while preserving its source design.

Input prompt: "Add Google DESIGN.md front matter to these reviewed iOS and
Liquid Glass templates, preserving their bodies and source provenance."

Context and files:

- Integrated upstream segments identify each local template and reviewed
  source commit. The template bodies state palettes, type metrics, spacing,
  radii and some components; other values remain qualitative or variable.

Expected output:

- Derive supported front-matter values from each template's own text. Map
  native points to the same number of px, including letter spacing. Keep
  unsupported shapes and qualitative behavior in the unchanged body.
- Record added front matter in each segment's outcome without changing its
  source paths or reviewed commit. Define components only from stated values.

Forbidden behavior:

- Invent values or components, alter source colors to silence contrast
  warnings, rewrite the body, or claim a new upstream review revision.

Acceptance checks:

- Every template has zero lint errors. Report any source-preserving contrast
  or orphaned-token warnings by template and reason. Body bytes, source paths
  and reviewed commits are unchanged.

Evidence sources:

- Source/body comparison, front-matter review, provenance diff and lint output.

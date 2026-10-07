# Sketch Cloud GraphQL

## Role

Sketch Cloud GraphQL is the Cloud-side metadata and index layer for
`sketch-design`. It is useful before or alongside local `.sketch` extraction,
but it does not replace the `.sketch` ZIP/JSON parser.

Use it for read-only Cloud facts:

- public share, version, and document metadata
- page, frame, component, token, downloadable asset, and preview indexes
- GraphQL schema drift checks
- download preflight before fetching the `.sketch` file

Do not use it for source-of-truth layer geometry, overrides, detached symbol
layout, or local implementation handoff. Those come from `extract_sketch_design.py`.

## Current Python Layer

- `scripts/sketch_cloud.py`: shared stdlib-only GraphQL, share parsing,
  download, schema, document index, and token export helpers.
- `scripts/fetch_sketch_cloud_share.py`: thin `.sketch` downloader using the
  shared Cloud layer.
- `scripts/sketch-cli`: stable user-facing read-only CLI for Cloud-side probes.
- `scripts/sketch_cloud_graphql.py`: Python implementation behind
  `sketch-cli`.

Commands:

```bash
skills/sketch-design/scripts/sketch-cli schema \
  --output-dir /tmp/sketch-cloud-graphql-schema

skills/sketch-design/scripts/sketch-cli share \
  --url https://www.sketch.com/s/<share-uuid> \
  --output-dir /tmp/sketch-cloud-graphql-share

skills/sketch-design/scripts/sketch-cli index \
  --url https://www.sketch.com/s/<share-uuid> \
  --page-limit 50 \
  --frame-limit 50 \
  --component-limit 50 \
  --output-dir /tmp/sketch-cloud-graphql-index

skills/sketch-design/scripts/sketch-cli tokens \
  --url https://www.sketch.com/s/<share-uuid> \
  --format W3C \
  --color-format HEX \
  --token-types COLOR_VARIABLE,LAYER_STYLE,TEXT_STYLE \
  --output-dir /tmp/sketch-cloud-graphql-tokens
```

## Observed Schema Scale

As of the 2026-05-26 probe, introspection is enabled on the public Sketch Cloud
GraphQL endpoint:

- types: 647
- object types: 436
- input types: 87
- enum types: 90
- fields: 2028
- root query fields: 41
- root mutation fields: 182
- root subscription fields: 33

The local CLI intentionally supports read-only query paths first. Mutations and
subscriptions are excluded from `sketch-design` production workflows.

## Implemented Read-Only Segments

- `schema`: summarize root fields, relevant design types, enums, implemented
  segments, excluded segments, and future segments.
- `share`: resolve public share/version/document metadata and omit signed
  temporary download URLs.
- `index`: fetch page, frame, component, token-count, and downloadable-asset
  indexes with bounded pagination. It omits signed file/render/download URLs
  and keeps only stable metadata.
- `tokens`: fetch Cloud token export data for color variables, layer styles,
  and text styles.
- `download`: resolve a public share and download the `.sketch` file through
  `fetch_sketch_cloud_share.py`.

## Future Read-Only Segments

- Full paginated traversal for pages, frames, components, and assets.
- Frame/artboard file render manifest and optional visual-reference download.
- `inspectorData` snapshots for public inspectable page, frame, artboard, or
  component targets.
- Version history, revision index, and stable diff snapshots.
- Comments and annotations read-only export for design review context.
- Curated Sketch libraries/templates discovery.
- Authenticated workspace/project/share inventory when credentials are
  available and the user explicitly wants private Cloud context.
- Schema drift diff against previous snapshots.
- Cross-checks that compare Cloud component/token counts with local
  `.sketch` extraction counts.

## Guardrails

- Keep this layer read-only unless a future owner explicitly adds a separate
  write-scope skill.
- Do not persist signed temporary download URLs or token download URLs.
- Do not persist signed render, file, or downloadable-asset URLs from Cloud
  index queries.
- Treat Cloud metadata as an index and preflight source; use local `.sketch`
  extraction for final design facts.
- Keep pagination bounded by default and require explicit limits for large
  libraries.
- Record GraphQL schema drift instead of assuming Cloud fields are stable.

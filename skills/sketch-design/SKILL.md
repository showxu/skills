---
name: sketch-design
description: Resolve Sketch Cloud shares, extract, review, export, summarize, or hand off Sketch design facts from .sketch files using sketchtool, Sketch document JSON, and optional Sketch MCP parity checks. Use for Sketch Cloud share downloads, Sketch design context, tokens, symbols, shared styles, swatches, visual references, exported assets, Apple design-resource Sketch files, DESIGN.md evidence, and downstream implementation handoff. Do not use for live Sketch selection-to-code implementation, direct SwiftUI/React/AppKit/UIKit coding, Apple HIG interpretation, or Figma file analysis.
---

# Sketch Design

## Purpose

Use this skill as the local Sketch design-fact layer. It preserves the useful
workflow from the official `sketch-implement-design` skill: read design
context, capture visual references, export assets, and hand clear
implementation guidance to a coding agent. This skill makes that workflow
batchable and auditable by turning `.sketch` files into stable artifacts.
It also owns Sketch Cloud share transport when a design source is exposed as a
`sketch.com/s/...` document instead of a direct local file. Cloud GraphQL is a
read-only metadata/index layer for share preflight, schema drift checks,
component/token counts, and download handoff; local `.sketch` extraction remains
the source of truth for design facts.

The official `sketch-implement-design` skill remains the live MCP workflow for
an open Sketch document or current selection. This skill owns local file
extraction, batch summaries, persistent handoff artifacts, and parity checks.

## When To Use

- Extract structure, text, layout, styles, symbols, shared styles, swatches, or
  export settings from a local `.sketch` file.
- Resolve and optionally download a Sketch Cloud share URL into a local
  `.sketch` file before extraction.
- Probe Sketch Cloud GraphQL read-only facts for schema summaries, share
  metadata, document indexes, component counts, token exports, and downloadable
  asset indexes.
- Produce visual references from Sketch files with `sketchtool export`.
- Analyze Apple Design Resources Sketch templates or UI libraries after they
  are downloaded or extracted locally.
- Generate persistent design context for `DESIGN.md` templates, downstream
  implementation skills, or human design review.
- Compare a small Sketch sample against official Sketch MCP runtime output to
  verify mapped layer counts or type counts.

## When Not To Use

- Live selection implementation from an open Sketch document. Use the official
  source-owned `sketch-implement-design` skill with Sketch MCP.
- Writing SwiftUI, UIKit, AppKit, React, HTML, or other UI code directly.
  Produce the implementation handoff here, then let the owning implementation
  skill decide framework-specific code.
- Apple HIG interpretation or platform-convention review.
- Figma file, Figma MCP, or browser screenshot extraction.
- Apple Design Resources catalog discovery. Use `apple-design-resource` to
  find official resource links, then hand Sketch links to this skill.
- Sketch Cloud mutations, workspace writes, or production subscription
  listeners.
- Inferring human design intent as fact when the Sketch file has no naming,
  symbol, shared style, or token evidence.

## Workflow

1. Confirm inputs:
   - local `.sketch` path, or a Sketch Cloud `https://sketch.com/s/...` share
     URL that can be resolved to a local `.sketch` file
   - target scope: whole file, page, artboard, layer id, or layer name
   - `sketchtool` path, defaulting to the installed Sketch app
   - optional Sketch MCP URL for parity checks only
2. If the input is a Sketch Cloud share, optionally preflight Cloud metadata:

   ```bash
   skills/sketch-design/scripts/sketch-cli index \
     --url https://www.sketch.com/s/<share-uuid> \
     --output-dir /tmp/sketch-cloud-index
   ```

   Use this to check document size, page/frame counts, component counts, token
   counts, and downloadable assets before local extraction.
3. If the input is a Sketch Cloud share, resolve it to a local `.sketch` file:

   ```bash
   python3 skills/sketch-design/scripts/fetch_sketch_cloud_share.py \
     --url https://www.sketch.com/s/<share-uuid> \
     --output-dir /tmp/sketch-cloud-document
   ```

   Use the downloaded `.sketch` path from `manifest.json` as the extractor
   input. The Cloud manifest must not persist signed temporary download URLs.
4. Run the extractor script:

   ```bash
   python3 skills/sketch-design/scripts/extract_sketch_design.py \
     --input path/to/file.sketch \
     --output-dir /tmp/sketch-design-output \
     --detach \
     --export-preview \
     --export-artboards
   ```

5. Prefer the original document view for symbol, shared-style, swatch, and
   source naming evidence.
6. Use the detached document view when expanded symbol instances or concrete
   layout details matter.
7. Review generated artifacts:
   - `manifest.json`
   - `design-context.json`, including per-layer `details` for layout, style,
     text, symbol overrides, export options, shape geometry, prototype, and
     background facts
   - `semantic-map.json`
   - `tokens.json`
   - `summary.md`
   - `implementation-handoff.md`
   - `preview.png`, `artboards/`, or `assets/` when exported
8. Pass only evidence-labeled facts downstream. Treat `source-named` and
   `api-mapped` as facts. Treat `inferred` rows as hypotheses with confidence.
9. If using MCP parity, run it on a small representative file or selected open
   document. Do not use MCP for large full-library scans.

## Script

`scripts/sketch_cloud.py` is the shared Python layer for Sketch Cloud
read-only GraphQL, share URL parsing, schema introspection, document index
queries, token exports, and bounded downloads.

`scripts/sketch-cli` is the stable user-facing CLI for Cloud-side probes. It
supports:

- `schema`: introspect Sketch Cloud GraphQL and write `schema-summary.json`
  and `schema-summary.md`.
- `share`: resolve stable public share, version, and document metadata.
- `index`: fetch bounded pages, frames, components, component counts, and
  downloadable assets, omitting signed file/render/download URLs.
- `tokens`: fetch Cloud token export data for color variables, layer styles,
  and text styles.

See `references/sketch-cloud-graphql.md` for implemented and future GraphQL
segments. `scripts/sketch_cloud_graphql.py` remains the Python implementation
behind the CLI.

`scripts/fetch_sketch_cloud_share.py` supports:

- `--url`: repeatable Sketch Cloud share URL or share UUID.
- positional share URLs or UUIDs.
- `--output-dir`: required manifest and download directory.
- `--graphql-url`: Sketch Cloud GraphQL endpoint, defaulting to the public
  Sketch Cloud endpoint used by the web app.
- `--resolve-only`: write metadata without downloading the `.sketch` file.
- `--max-download-bytes`: per-file download cap, default `500MB`.
- `--overwrite`: replace an existing downloaded `.sketch` file.

The script writes `manifest.json` using schema
`sketch-design.cloud-manifest.v1`. It records share metadata, document
metadata, download status, local path, byte count, SHA-256, and ZIP validity.
It intentionally omits signed temporary download URLs from persistent output.

`scripts/extract_sketch_design.py` supports:

- `--input`: required `.sketch` file.
- `--output-dir`: generated artifact directory.
- `--sketchtool`: explicit `sketchtool` path.
- `--target`: repeatable page, artboard, symbol, or layer id/name/path. When
  present, generated layer context is scoped to matching subtrees plus
  ancestors, and export commands receive the same target where supported.
- `--detach`: create and parse `detached.sketch`.
- `--export-preview`: write `preview.png`.
- `--export-artboards`: export artboards to `artboards/`.
- `--include-symbols`: include symbol-master artboards when exporting
  artboards from Sketch UI libraries.
- `--export-layers`: export layers to `assets/layers/`.
- `--export-slices`: export slices to `assets/slices/`.
- `--summary-only`: skip exports and produce metadata/context summaries.
- `--mcp-parity-url`: optional Sketch MCP server URL for small-sample parity.

The script requires `sketchtool` for metadata and export operations. It parses
the `.sketch` ZIP/JSON format directly for durable batch context because the
installed current `sketchtool` may not expose older `dump` or `inspect`
commands.

`design-context.json` uses schema `sketch-design.context.v2`. Each layer keeps
the compact summary fields and adds a `details` block:

- `layout`: frame, rotation, flip state, clipping/mask flags, resizing fields,
  group layout, rulers, viewport, and related layer flags.
- `style`: full Sketch style JSON with color objects augmented by hex values.
- `text`: full attributed string, text style, glyph bounds, line spacing, and
  text behavior fields when present.
- `symbol`: symbol ids, scale, override values, override properties, and
  override type hints.
- `export`: full Sketch export options.
- `shape`: fixed radius, curve points, closure, point radius behavior, and
  related vector geometry fields.
- `prototype`, `background`, and `sourceProperties`: remaining source facts
  that matter for handoff or auditing.

## Evidence Model

- `source-named`: names, symbols, shared styles, swatches, export formats, and
  text found directly in the Sketch document.
- `api-mapped`: raw Sketch JSON classes mapped to SketchAPI/MCP-style type
  names, such as `rectangle` and `oval` to `ShapePath`.
- `inferred`: layout or implementation hints derived from structure and token
  patterns. These must include confidence and must not be reported as source
  facts.

## Downstream Implementation Handoff

`implementation-handoff.md` gives downstream coding skills the useful official
workflow constraints without taking over framework-specific implementation:

- Reuse project components before creating new ones.
- Map colors, typography, spacing, radius, and effects to project tokens before
  using literal values.
- Let project architecture shape code structure; do not mechanically copy every
  Sketch group.
- Use exported Sketch assets instead of placeholders or unrelated icon packs.
- Validate implementation against the visual reference and design context.
- If mismatches remain, re-extract the relevant artboard, layer, or subtree.

## Official Code Guidance Parity

This skill preserves the official `sketch-implement-design` coding guidance as
handoff instructions, while leaving framework-specific code to the downstream
owner:

- Translate Sketch output to project conventions: reuse existing components,
  map values to project tokens, follow architecture and state/data patterns,
  and keep code idiomatic for the target stack.
- Implement for visual parity: match spacing, alignment, sizing, hierarchy,
  typography, colors, effects, responsive behavior, and constraints.
- Validate before completion: compare against visual exports and
  `design-context.json`; check states, interactions, asset rendering,
  responsiveness, constraints, and accessibility basics.
- Prefer incremental updates, keep component boundaries consistent with the
  design hierarchy, and document intentional deviations.
- Do not assume stale design data. Re-extract the target artboard, layer, or
  subtree when implementation mismatches remain.

The boundary is that `sketch-design` emits evidence and implementation
guidance, not SwiftUI, UIKit, AppKit, React, HTML, or CSS code.

## Decision Rules

- Prefer batch extraction for Apple UI libraries and large Sketch files.
- When `apple-design-resource` discovers a `sketch.com/s/...` resource, let it
  pass the URL here; this skill owns Sketch Cloud resolution, download, and
  `.sketch` extraction.
- Use Sketch Cloud GraphQL as a read-only Cloud index and preflight layer. Do
  not let Cloud metadata replace local `.sketch` extraction when source design
  facts are needed.
- Do not implement GraphQL mutations or production subscription listeners in
  this skill.
- Prefer official Sketch MCP for current selection, live document state, and
  interactive design-to-code sessions.
- Preserve original and detached views separately; do not collapse symbol
  semantics and expanded layout into one unlabelled record.
- Keep generated artifacts under caller-selected output directories or ignored
  generated-reference locations. Do not commit raw exported Apple assets unless
  a human explicitly asks.
- Do not persist signed Sketch Cloud download URLs. Store only the stable share
  URL, document metadata, local downloaded file facts, and stable Cloud index
  metadata.
- Treat MCP parity as a calibration fixture, not as a production dependency.

## Validation

- Cloud resolution writes `manifest.json`, reports the Sketch document name,
  size, Sketch version, page count, frame count, and download availability, and
  omits signed download URLs.
- GraphQL schema probes write `schema-summary.json` with root fields, relevant
  enums and types, implemented segments, future read-only segments, and
  excluded mutation/subscription scope.
- GraphQL document indexes report bounded page, frame, component, token-count,
  and downloadable-asset data without requiring local `.sketch` parsing.
- `manifest.json` records source hash, `sketchtool` version, metadata status,
  parsed views, and exports.
- `design-context.json`, `semantic-map.json`, and `tokens.json` parse as JSON.
- Pinned Apple UI library fixtures should report nonzero detail coverage for
  style, text, symbol overrides, export options, shape geometry, group layout,
  prototype, and background sections where present.
- Pinned Apple UI library fixtures should complete without MCP full-document
  traversal.
- Optional small parity fixtures should match MCP layer count and mapped type
  counts after excluding page container nodes.
